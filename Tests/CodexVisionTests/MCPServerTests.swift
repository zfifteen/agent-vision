import Foundation
import Testing
@testable import CodexVisionCore

private final class FakeCamera: CameraControlling {
    private(set) var startCount = 0
    private(set) var stopCount = 0

    func start() throws -> String {
        startCount += 1
        return "started"
    }

    func latestFrame() throws -> CameraFrame {
        CameraFrame(
            jpegData: Data([0xFF, 0xD8, 0xFF, 0xD9]),
            timestamp: "2026-05-05T20:00:00Z",
            width: 2,
            height: 1
        )
    }

    func snapshot() throws -> CameraFrame {
        try latestFrame()
    }

    func stop() throws -> String {
        stopCount += 1
        return "stopped"
    }
}

@Test func initializeReturnsServerInfo() throws {
    let server = MCPServer(camera: FakeCamera())
    let response = try decode(server.handleLine(#"{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}"#))
    let result = try #require(response["result"] as? [String: Any])
    let serverInfo = try #require(result["serverInfo"] as? [String: Any])
    #expect(serverInfo["name"] as? String == "codex-vision")
    #expect(serverInfo["version"] as? String == "1.0.0")
}

@Test func toolsListIncludesCameraTools() throws {
    let server = MCPServer(camera: FakeCamera())
    let response = try decode(server.handleLine(#"{"jsonrpc":"2.0","id":2,"method":"tools/list"}"#))
    let result = try #require(response["result"] as? [String: Any])
    let tools = try #require(result["tools"] as? [[String: Any]])
    let names = tools.compactMap { $0["name"] as? String }
    #expect(names == ["codex_vision_snapshot", "codex_vision_start", "codex_vision_frame", "codex_vision_stop"])
}

@Test func frameToolReturnsImageContentAndMetadata() throws {
    let server = MCPServer(camera: FakeCamera())
    let response = try decode(server.handleLine(#"{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"codex_vision_frame","arguments":{}}}"#))
    let result = try #require(response["result"] as? [String: Any])
    let content = try #require(result["content"] as? [[String: Any]])
    let image = try #require(content.first)
    let metadata = try #require(result["structuredContent"] as? [String: Any])
    #expect(image["type"] as? String == "image")
    #expect(image["mimeType"] as? String == "image/jpeg")
    #expect(metadata["width"] as? Int == 2)
    #expect(metadata["height"] as? Int == 1)
}

@Test func snapshotToolReturnsImageContentAndMetadata() throws {
    let server = MCPServer(camera: FakeCamera())
    let response = try decode(server.handleLine(#"{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"codex_vision_snapshot","arguments":{}}}"#))
    let result = try #require(response["result"] as? [String: Any])
    let content = try #require(result["content"] as? [[String: Any]])
    let image = try #require(content.first)
    let metadata = try #require(result["structuredContent"] as? [String: Any])
    #expect(image["type"] as? String == "image")
    #expect(image["mimeType"] as? String == "image/jpeg")
    #expect(metadata["width"] as? Int == 2)
    #expect(metadata["height"] as? Int == 1)
}

@Test func unknownToolReturnsMCPToolError() throws {
    let server = MCPServer(camera: FakeCamera())
    let response = try decode(server.handleLine(#"{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"missing_tool","arguments":{}}}"#))
    let result = try #require(response["result"] as? [String: Any])
    #expect(result["isError"] as? Bool == true)
}

private func decode(_ line: String?) throws -> [String: Any] {
    let line = try #require(line)
    let data = Data(line.utf8)
    return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
}
