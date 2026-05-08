import AgentVisionCore
import Darwin
import Foundation

let arguments = CommandLine.arguments.dropFirst()

switch arguments.first {
case "mcp":
    MCPServer(camera: AVCameraController()).run()
case "capture-file":
    guard arguments.count == 3 else {
        fputs("Usage: AgentVision capture-file OUTPUT_PATH RESULT_FIFO\n", stderr)
        exit(64)
    }
    let outputPath = String(arguments[arguments.index(arguments.startIndex, offsetBy: 1)])
    let resultPath = String(arguments[arguments.index(arguments.startIndex, offsetBy: 2)])
    runCaptureFile(outputPath: outputPath, resultPath: resultPath)
case "mcp-fifo":
    guard arguments.count == 3 else {
        fputs("Usage: AgentVision mcp-fifo INPUT_FIFO OUTPUT_FIFO\n", stderr)
        exit(64)
    }
    let inputPath = String(arguments[arguments.index(arguments.startIndex, offsetBy: 1)])
    let outputPath = String(arguments[arguments.index(arguments.startIndex, offsetBy: 2)])
    guard
        let input = FileHandle(forReadingAtPath: inputPath),
        let output = FileHandle(forWritingAtPath: outputPath)
    else {
        fputs("AgentVision could not open MCP FIFO handles.\n", stderr)
        exit(66)
    }
    MCPServer(camera: AVCameraController()).run(input: input, output: output)
case "authorize-camera":
    let camera = AVCameraController()
    do {
        _ = try camera.start()
        Thread.sleep(forTimeInterval: 0.5)
        _ = try camera.stop()
    } catch {
        fputs("\(error.localizedDescription)\n", stderr)
        exit(1)
    }
default:
    fputs("Usage: AgentVision mcp|mcp-fifo|capture-file|authorize-camera\n", stderr)
    exit(64)
}

private func runCaptureFile(outputPath: String, resultPath: String) -> Never {
    let result = FileHandle(forWritingAtPath: resultPath)
    func finish(_ object: [String: Any], status: Int32) -> Never {
        if let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]) {
            result?.write(data)
            result?.write(Data("\n".utf8))
        }
        result?.closeFile()
        exit(status)
    }

    guard outputPath.hasPrefix("/") else {
        finish([
            "ok": false,
            "error": [
                "code": "invalid_output",
                "message": "--output must be an absolute path."
            ]
        ], status: 64)
    }

    guard !FileManager.default.fileExists(atPath: outputPath) else {
        finish([
            "ok": false,
            "error": [
                "code": "output_exists",
                "message": "Output file already exists."
            ]
        ], status: 73)
    }

    do {
        let outputURL = URL(fileURLWithPath: outputPath)
        try FileManager.default.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let frame = try AVCameraController().snapshot()
        try frame.jpegData.write(to: outputURL, options: .withoutOverwriting)
        finish([
            "ok": true,
            "path": outputPath,
            "mimeType": "image/jpeg",
            "width": frame.width,
            "height": frame.height,
            "bytes": frame.jpegData.count,
            "meanBrightness": frame.meanBrightness,
            "timestamp": frame.timestamp
        ], status: 0)
    } catch {
        finish([
            "ok": false,
            "error": [
                "code": "capture_failed",
                "message": error.localizedDescription
            ]
        ], status: 70)
    }
}
