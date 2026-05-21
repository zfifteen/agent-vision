import Foundation
import Testing
@testable import AgentVisionCore

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
            height: 1,
            meanBrightness: 0.5
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
    #expect(serverInfo["name"] as? String == "agent-vision")
    #expect(serverInfo["version"] as? String == "1.0.3")
}

@Test func toolsListIncludesCameraTools() throws {
    let server = MCPServer(camera: FakeCamera())
    let response = try decode(server.handleLine(#"{"jsonrpc":"2.0","id":2,"method":"tools/list"}"#))
    let result = try #require(response["result"] as? [String: Any])
    let tools = try #require(result["tools"] as? [[String: Any]])
    let names = tools.compactMap { $0["name"] as? String }
    let titles = tools.compactMap { $0["title"] as? String }
    #expect(names == ["agent_vision_snapshot", "agent_vision_mood", "agent_vision_start", "agent_vision_frame", "agent_vision_stop"])
    #expect(titles == ["Snapshot", "Mood Frame", "Start Streaming", "Latest Frame", "Stop Streaming"])
    #expect(result["nextCursor"] is NSNull)
}

@Test func frameToolReturnsImageContentAndMetadata() throws {
    let server = MCPServer(camera: FakeCamera())
    let response = try decode(server.handleLine(#"{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"agent_vision_frame","arguments":{}}}"#))
    let result = try #require(response["result"] as? [String: Any])
    let content = try #require(result["content"] as? [[String: Any]])
    let image = try #require(content.first)
    let metadata = try #require(result["structuredContent"] as? [String: Any])
    let annotations = try #require(image["annotations"] as? [String: Any])
    #expect(image["type"] as? String == "image")
    #expect(image["mimeType"] as? String == "image/jpeg")
    #expect(annotations["audience"] as? [String] == ["assistant", "user"])
    #expect(annotations["priority"] as? Double == 1.0)
    #expect(metadata["width"] as? Int == 2)
    #expect(metadata["height"] as? Int == 1)
    #expect(metadata["meanBrightness"] as? Double == 0.5)
}

@Test func snapshotToolReturnsImageContentAndMetadata() throws {
    let server = MCPServer(camera: FakeCamera())
    let response = try decode(server.handleLine(#"{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"agent_vision_snapshot","arguments":{}}}"#))
    let result = try #require(response["result"] as? [String: Any])
    let content = try #require(result["content"] as? [[String: Any]])
    let image = try #require(content.first)
    let metadata = try #require(result["structuredContent"] as? [String: Any])
    let annotations = try #require(image["annotations"] as? [String: Any])
    #expect(image["type"] as? String == "image")
    #expect(image["mimeType"] as? String == "image/jpeg")
    #expect(annotations["audience"] as? [String] == ["assistant", "user"])
    #expect(annotations["priority"] as? Double == 1.0)
    #expect(metadata["width"] as? Int == 2)
    #expect(metadata["height"] as? Int == 1)
    #expect(metadata["meanBrightness"] as? Double == 0.5)
}

@Test func moodToolReturnsImageContentWithoutSemanticInference() throws {
    let server = MCPServer(camera: FakeCamera())
    let response = try decode(server.handleLine(#"{"jsonrpc":"2.0","id":6,"method":"tools/call","params":{"name":"agent_vision_mood","arguments":{}}}"#))
    let result = try #require(response["result"] as? [String: Any])
    let content = try #require(result["content"] as? [[String: Any]])
    let image = try #require(content.first)
    let text = try #require(content.last)
    let metadata = try #require(result["structuredContent"] as? [String: Any])
    let annotations = try #require(image["annotations"] as? [String: Any])
    #expect(image["type"] as? String == "image")
    #expect(image["mimeType"] as? String == "image/jpeg")
    #expect(annotations["audience"] as? [String] == ["assistant"])
    #expect(annotations["priority"] as? Double == 1.0)
    #expect(text["text"] as? String == "Agent Vision mood frame 2x1 captured at 2026-05-05T20:00:00Z. Analyze this frame through the slash-command file materialization path before applying mood calibration.")
    #expect(metadata["width"] as? Int == 2)
    #expect(metadata["height"] as? Int == 1)
    #expect(metadata["meanBrightness"] as? Double == 0.5)
}

@Test func startAndStopToolsReturnTextAndInvokeCamera() throws {
    let camera = FakeCamera()
    let server = MCPServer(camera: camera)

    let startResponse = try decode(server.handleLine(#"{"jsonrpc":"2.0","id":9,"method":"tools/call","params":{"name":"agent_vision_start","arguments":{}}}"#))
    let startResult = try #require(startResponse["result"] as? [String: Any])
    let startContent = try #require(startResult["content"] as? [[String: Any]])
    #expect(startResult["isError"] as? Bool == false)
    #expect(startContent.first?["text"] as? String == "started")
    #expect(camera.startCount == 1)

    let stopResponse = try decode(server.handleLine(#"{"jsonrpc":"2.0","id":10,"method":"tools/call","params":{"name":"agent_vision_stop","arguments":{}}}"#))
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

    let response = try decode(server.handleLine(#"{"jsonrpc":"2.0","id":11,"method":"tools/call","params":{"name":"agent_vision_frame","arguments":{}}}"#))
    let result = try #require(response["result"] as? [String: Any])
    let content = try #require(result["content"] as? [[String: Any]])
    #expect(result["isError"] as? Bool == true)
    #expect(content.first?["text"] as? String == "The camera session has not produced a frame yet.")
}

@Test func unusableFrameErrorPropagatesAsToolError() throws {
    let camera = FakeCamera()
    camera.latestFrameError = CameraError.frameNotUsable
    let server = MCPServer(camera: camera)

    let response = try decode(server.handleLine(#"{"jsonrpc":"2.0","id":13,"method":"tools/call","params":{"name":"agent_vision_frame","arguments":{}}}"#))
    let result = try #require(response["result"] as? [String: Any])
    let content = try #require(result["content"] as? [[String: Any]])
    #expect(result["isError"] as? Bool == true)
    #expect(content.first?["text"] as? String == "The camera produced frames, but they were still black after three attempts. Check the lens cover and lighting, then try again.")
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

@Test func topLevelNonObjectReturnsInvalidRequest() throws {
    let server = MCPServer(camera: FakeCamera())
    let response = try decode(server.handleLine(#"[]"#))
    let error = try #require(response["error"] as? [String: Any])
    #expect(error["code"] as? Int == -32600)
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

@Test func notificationWithKnownMethodIsIgnored() throws {
    let server = MCPServer(camera: FakeCamera())
    #expect(server.handleLine(#"{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}"#) == nil)
}

@Test func notificationWithUnknownMethodIsIgnored() throws {
    let server = MCPServer(camera: FakeCamera())
    #expect(server.handleLine(#"{"jsonrpc":"2.0","method":"missing/method","params":{}}"#) == nil)
}

@Test func runProcessesNewlineDelimitedRequestsAndIgnoresNotifications() throws {
    let server = MCPServer(camera: FakeCamera())
    let input = Pipe()
    let output = Pipe()
    let request = """
    {"jsonrpc":"2.0","method":"notifications/initialized","params":{}}
    {"jsonrpc":"2.0","id":14,"method":"tools/list"}

    """

    input.fileHandleForWriting.write(Data(request.utf8))
    input.fileHandleForWriting.closeFile()
    server.run(input: input.fileHandleForReading, output: output.fileHandleForWriting)
    output.fileHandleForWriting.closeFile()

    let text = String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
    let lines = text.split(separator: "\n")
    #expect(lines.count == 1)
    let response = try decode(String(lines[0]))
    #expect(response["id"] as? Int == 14)
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
