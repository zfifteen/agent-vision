import CodexVisionCore
import Darwin

let arguments = CommandLine.arguments.dropFirst()
guard arguments.first == "mcp" else {
    fputs("Usage: CodexVision mcp\n", stderr)
    exit(64)
}

MCPServer(camera: AVCameraController()).run()
