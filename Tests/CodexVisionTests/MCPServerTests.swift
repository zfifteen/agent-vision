import Foundation
import Testing
@testable import CodexVisionCore

private final class FakeCamera: CameraControlling {
    private(set) var startCount = 0
    private(set) var stopCount = 0
    var latestFrameError: Error?

    func start() throws -> String {
        startCount += 1
        return "started"
    }

    func latestFrame() throws -> CameraFrame {
        if let latestFrameError {
            throw latestFrameError
        }
        return CameraFrame(
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
    let titles = tools.compactMap { $0["title"] as? String }
    #expect(names == ["codex_vision_snapshot", "codex_vision_start", "codex_vision_frame", "codex_vision_stop"])
    #expect(titles == ["Snapshot", "Start Streaming", "Latest Frame", "Stop Streaming"])
    #expect(result["nextCursor"] is NSNull)
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

@Test func startAndStopToolsReturnTextAndInvokeCamera() throws {
    let camera = FakeCamera()
    let server = MCPServer(camera: camera)

    let startResponse = try decode(server.handleLine(#"{"jsonrpc":"2.0","id":9,"method":"tools/call","params":{"name":"codex_vision_start","arguments":{}}}"#))
    let startResult = try #require(startResponse["result"] as? [String: Any])
    let startContent = try #require(startResult["content"] as? [[String: Any]])
    #expect(startResult["isError"] as? Bool == false)
    #expect(startContent.first?["text"] as? String == "started")
    #expect(camera.startCount == 1)

    let stopResponse = try decode(server.handleLine(#"{"jsonrpc":"2.0","id":10,"method":"tools/call","params":{"name":"codex_vision_stop","arguments":{}}}"#))
    let stopResult = try #require(stopResponse["result"] as? [String: Any])
    let stopContent = try #require(stopResult["content"] as? [[String: Any]])
    #expect(stopResult["isError"] as? Bool == false)
    #expect(stopContent.first?["text"] as? String == "stopped")
    #expect(camera.stopCount == 1)
}

@Test func cameraErrorPropagatesAsToolError() throws {
    let camera = FakeCamera()
    camera.latestFrameError = CameraError.frameUnavailable
    let server = MCPServer(camera: camera)

    let response = try decode(server.handleLine(#"{"jsonrpc":"2.0","id":11,"method":"tools/call","params":{"name":"codex_vision_frame","arguments":{}}}"#))
    let result = try #require(response["result"] as? [String: Any])
    let content = try #require(result["content"] as? [[String: Any]])
    #expect(result["isError"] as? Bool == true)
    #expect(content.first?["text"] as? String == "The camera session has not produced a frame yet.")
}

@Test func unknownToolReturnsMCPToolError() throws {
    let server = MCPServer(camera: FakeCamera())
    let response = try decode(server.handleLine(#"{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"missing_tool","arguments":{}}}"#))
    let result = try #require(response["result"] as? [String: Any])
    #expect(result["isError"] as? Bool == true)
}

@Test func malformedJSONReturnsParseError() throws {
    let server = MCPServer(camera: FakeCamera())
    let response = try decode(server.handleLine(#"{"jsonrpc":"2.0","id":7,"method":"tools/list""#))
    let error = try #require(response["error"] as? [String: Any])
    #expect(error["code"] as? Int == -32700)
}

@Test func requestWithoutMethodReturnsInvalidRequestWhenIdIsPresent() throws {
    let server = MCPServer(camera: FakeCamera())
    let response = try decode(server.handleLine(#"{"jsonrpc":"2.0","id":8}"#))
    let error = try #require(response["error"] as? [String: Any])
    #expect(error["code"] as? Int == -32600)
}

@Test func notificationWithoutMethodIsIgnored() throws {
    let server = MCPServer(camera: FakeCamera())
    #expect(server.handleLine(#"{"jsonrpc":"2.0"}"#) == nil)
}

@Test func notificationWithNonStringMethodIsIgnored() throws {
    let server = MCPServer(camera: FakeCamera())
    #expect(server.handleLine(#"{"jsonrpc":"2.0","method":7}"#) == nil)
}

@Test func requestWithNonStringMethodReturnsInvalidRequestWhenIdIsPresent() throws {
    let server = MCPServer(camera: FakeCamera())
    let response = try decode(server.handleLine(#"{"jsonrpc":"2.0","id":12,"method":7}"#))
    let error = try #require(response["error"] as? [String: Any])
    #expect(error["code"] as? Int == -32600)
}

private func decode(_ line: String?) throws -> [String: Any] {
    let line = try #require(line)
    let data = Data(line.utf8)
    return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
}
