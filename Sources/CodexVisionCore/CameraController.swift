import AVFoundation
import CoreImage
import Foundation

public struct CameraFrame: Equatable {
    public let jpegData: Data
    public let timestamp: String
    public let width: Int
    public let height: Int

    public init(jpegData: Data, timestamp: String, width: Int, height: Int) {
        self.jpegData = jpegData
        self.timestamp = timestamp
        self.width = width
        self.height = height
    }
}

public protocol CameraControlling {
    func start() throws -> String
    func latestFrame() throws -> CameraFrame
    func snapshot() throws -> CameraFrame
    func stop() throws -> String
}

public enum CameraError: Error, Equatable {
    case cameraUnavailable
    case permissionDenied
    case permissionUnknown
    case captureInputFailed(String)
    case frameUnavailable
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
        case .jpegEncodingFailed:
            return "The latest camera frame could not be encoded as JPEG."
        }
    }
}

public final class AVCameraController: NSObject, CameraControlling, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "codex-vision.capture.session")
    private let frameQueue = DispatchQueue(label: "codex-vision.capture.frames")
    private let ciContext = CIContext()
    private var configured = false
    private var latest: CameraFrame?

    public func start() throws -> String {
        try authorizeCamera()

        try sessionQueue.sync {
            if session.isRunning {
                return
            }

            if !configured {
                try configureSession()
                configured = true
            }

            session.startRunning()
        }

        return "Codex Vision camera session started."
    }

    public func latestFrame() throws -> CameraFrame {
        let deadline = Date().addingTimeInterval(1)
        while true {
            if let frame = frameQueue.sync(execute: { latest }) {
                return frame
            }

            if Date() >= deadline {
                throw CameraError.frameUnavailable
            }
            Thread.sleep(forTimeInterval: 0.05)
        }
    }

    public func snapshot() throws -> CameraFrame {
        _ = try start()
        defer {
            do {
                _ = try stop()
            } catch {
                fputs("Codex Vision failed to stop camera after snapshot: \(error.localizedDescription)\n", stderr)
            }
        }

        Thread.sleep(forTimeInterval: 1)
        let deadline = Date().addingTimeInterval(3)
        while Date() < deadline {
            if let frame = try? latestFrame() {
                return frame
            }
            Thread.sleep(forTimeInterval: 0.05)
        }

        throw CameraError.frameUnavailable
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
            height: height
        )
    }
}
