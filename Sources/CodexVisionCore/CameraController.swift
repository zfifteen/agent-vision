import AVFoundation
import CoreImage
import Foundation

public struct CameraFrame: Equatable {
    public let jpegData: Data
    public let timestamp: String
    public let width: Int
    public let height: Int
    public let meanBrightness: Double

    public init(jpegData: Data, timestamp: String, width: Int, height: Int, meanBrightness: Double = 1) {
        self.jpegData = jpegData
        self.timestamp = timestamp
        self.width = width
        self.height = height
        self.meanBrightness = meanBrightness
    }
}

public protocol CameraControlling {
    /// Start a persistent camera session for streaming mode.
    func start() throws -> String
    /// Return the latest frame from an active streaming session.
    func latestFrame() throws -> CameraFrame
    /// Start the camera, return one frame, and release the camera before returning or throwing.
    func snapshot() throws -> CameraFrame
    /// Stop the active camera session and clear cached frame state.
    func stop() throws -> String
}

public enum CameraError: Error, Equatable {
    case cameraUnavailable
    case permissionDenied
    case permissionUnknown
    case captureInputFailed(String)
    case frameUnavailable
    case frameNotUsable
    case jpegEncodingFailed
}

private final class CameraPermissionResult: @unchecked Sendable {
    var granted = false
}

extension CameraError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return "No built-in macOS camera is available."
        case .permissionDenied:
            return "Camera permission was denied for CodexVision.app."
        case .permissionUnknown:
            return "Camera permission could not be resolved."
        case .captureInputFailed(let reason):
            return "Camera input failed: \(reason)"
        case .frameUnavailable:
            return "The camera session has not produced a frame yet."
        case .frameNotUsable:
            return "The camera produced frames, but they were still black after three attempts. Check the lens cover and lighting, then try again."
        case .jpegEncodingFailed:
            return "The latest camera frame could not be encoded as JPEG."
        }
    }
}

public final class AVCameraController: NSObject, CameraControlling, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let minimumUsableMeanBrightness = 0.02
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "codex-vision.capture.session")
    private let frameQueue = DispatchQueue(label: "codex-vision.capture.frames")
    private let ciContext = CIContext()
    private var configured = false
    private var latest: CameraFrame?

    public func start() throws -> String {
        _ = try startSessionIfNeeded()
        return "Codex Vision camera session started."
    }

    public func latestFrame() throws -> CameraFrame {
        let deadline = Date().addingTimeInterval(1)
        while true {
            if let frame = cachedFrame() {
                return frame
            }

            if Date() >= deadline {
                throw CameraError.frameUnavailable
            }
            Thread.sleep(forTimeInterval: 0.05)
        }
    }

    public func snapshot() throws -> CameraFrame {
        let startedSession = try startSessionIfNeeded()
        defer {
            if startedSession {
                do {
                    _ = try stop()
                } catch {
                    fputs("Codex Vision failed to stop camera after snapshot: \(error.localizedDescription)\n", stderr)
                }
            }
        }

        for attempt in 1...3 {
            let frame = try waitForFrame(timeout: 3)
            if frame.meanBrightness >= minimumUsableMeanBrightness {
                return frame
            }

            if attempt < 3 {
                Thread.sleep(forTimeInterval: 5)
            }
        }

        throw CameraError.frameNotUsable
    }

    public func stop() throws -> String {
        sessionQueue.sync {
            if session.isRunning {
                session.stopRunning()
            }
        }
        frameQueue.sync {
            latest = nil
        }
        return "Codex Vision camera session stopped."
    }

    private func startSessionIfNeeded() throws -> Bool {
        try authorizeCamera()

        return try sessionQueue.sync {
            if session.isRunning {
                return false
            }

            if !configured {
                try configureSession()
                configured = true
            }

            session.startRunning()
            return true
        }
    }

    private func cachedFrame() -> CameraFrame? {
        frameQueue.sync {
            latest
        }
    }

    private func waitForFrame(timeout: TimeInterval) throws -> CameraFrame {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let frame = cachedFrame() {
                return frame
            }
            Thread.sleep(forTimeInterval: 0.05)
        }

        throw CameraError.frameUnavailable
    }

    private func authorizeCamera() throws {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return
        case .denied, .restricted:
            throw CameraError.permissionDenied
        case .notDetermined:
            let semaphore = DispatchSemaphore(value: 0)
            let result = CameraPermissionResult()
            AVCaptureDevice.requestAccess(for: .video) { allowed in
                result.granted = allowed
                semaphore.signal()
            }
            semaphore.wait()
            if !result.granted {
                throw CameraError.permissionDenied
            }
        @unknown default:
            throw CameraError.permissionUnknown
        }
    }

    private func configureSession() throws {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .unspecified) else {
            throw CameraError.cameraUnavailable
        }

        session.beginConfiguration()
        session.sessionPreset = .photo

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                throw CameraError.captureInputFailed("AVCaptureSession rejected the built-in camera input.")
            }
            session.addInput(input)
        } catch let error as CameraError {
            session.commitConfiguration()
            throw error
        } catch {
            session.commitConfiguration()
            throw CameraError.captureInputFailed(error.localizedDescription)
        }

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        output.setSampleBufferDelegate(self, queue: frameQueue)

        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            throw CameraError.captureInputFailed("AVCaptureSession rejected the video frame output.")
        }
        session.addOutput(output)
        session.commitConfiguration()
    }

    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let meanBrightness = meanBrightness(of: pixelBuffer) ?? 0
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        guard let jpeg = ciContext.jpegRepresentation(of: ciImage, colorSpace: colorSpace, options: [:]) else {
            return
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        latest = CameraFrame(
            jpegData: jpeg,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            width: width,
            height: height,
            meanBrightness: meanBrightness
        )
    }

    private func meanBrightness(of pixelBuffer: CVPixelBuffer) -> Double? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return nil
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let rowBytes = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let xStep = max(width / 32, 1)
        let yStep = max(height / 18, 1)
        let bytes = baseAddress.assumingMemoryBound(to: UInt8.self)
        var total = 0.0
        var count = 0

        for y in stride(from: 0, to: height, by: yStep) {
            let row = bytes.advanced(by: y * rowBytes)
            for x in stride(from: 0, to: width, by: xStep) {
                let pixel = row.advanced(by: x * 4)
                let blue = Double(pixel[0])
                let green = Double(pixel[1])
                let red = Double(pixel[2])
                total += (0.2126 * red + 0.7152 * green + 0.0722 * blue) / 255.0
                count += 1
            }
        }

        guard count > 0 else {
            return nil
        }
        return total / Double(count)
    }
}
