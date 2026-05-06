import CodexVisionCore
import Darwin
import Foundation

let arguments = CommandLine.arguments.dropFirst()

switch arguments.first {
case "mcp":
    MCPServer(camera: AVCameraController()).run()
case "mcp-fifo":
    guard arguments.count == 3 else {
        fputs("Usage: CodexVision mcp-fifo INPUT_FIFO OUTPUT_FIFO\n", stderr)
        exit(64)
    }
    let inputPath = String(arguments[arguments.index(arguments.startIndex, offsetBy: 1)])
    let outputPath = String(arguments[arguments.index(arguments.startIndex, offsetBy: 2)])
    guard
        let input = FileHandle(forReadingAtPath: inputPath),
        let output = FileHandle(forWritingAtPath: outputPath)
    else {
        fputs("CodexVision could not open MCP FIFO handles.\n", stderr)
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
    fputs("Usage: CodexVision mcp|mcp-fifo|authorize-camera\n", stderr)
    exit(64)
}
