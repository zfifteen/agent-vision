import Foundation

public final class MCPServer {
    private let camera: CameraControlling

    public init(camera: CameraControlling) {
        self.camera = camera
    }

    public func run(
        input: FileHandle = .standardInput,
        output: FileHandle = .standardOutput
    ) {
        var buffer = Data()

        while true {
            let chunk = input.availableData
            if chunk.isEmpty {
                break
            }
            buffer.append(chunk)

            while let newline = buffer.firstIndex(of: 0x0A) {
                let lineData = buffer[..<newline]
                buffer.removeSubrange(...newline)
                let line = String(decoding: lineData, as: UTF8.self)
                writeResponse(for: line, to: output)
            }
        }

        if !buffer.isEmpty {
            let line = String(decoding: buffer, as: UTF8.self)
            writeResponse(for: line, to: output)
        }
    }

    private func writeResponse(for line: String, to output: FileHandle) {
        guard !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        let response = handleLine(line)
        if let response {
            output.write(Data((response + "\n").utf8))
        }
    }

    public func handleLine(_ line: String) -> String? {
        do {
            let data = Data(line.utf8)
            guard let message = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return errorResponse(id: nil, code: -32600, message: "Invalid Request")
            }

            let id = message["id"]
            let hasID = message.keys.contains("id")
            guard let methodValue = message["method"] else {
                if hasID {
                    return errorResponse(id: id, code: -32600, message: "Invalid Request")
                }
                return nil
            }
            guard let method = methodValue as? String else {
                if !hasID {
                    return nil
                }
                return errorResponse(id: id, code: -32600, message: "Invalid Request")
            }
            if !hasID {
                return nil
            }

            switch method {
            case "initialize":
                return successResponse(id: id, result: initializeResult())
            case "tools/list":
                return successResponse(id: id, result: [
                    "tools": toolDefinitions(),
                    "nextCursor": NSNull()
                ])
            case "tools/call":
                return handleToolCall(id: id, params: message["params"])
            default:
                return errorResponse(id: id, code: -32601, message: "Method not found: \(method)")
            }
        } catch {
            return errorResponse(id: nil, code: -32700, message: "Parse error")
        }
    }

    private func handleToolCall(id: Any?, params: Any?) -> String {
        guard
            let params = params as? [String: Any],
            let name = params["name"] as? String
        else {
            return errorResponse(id: id, code: -32602, message: "Invalid tool call parameters")
        }

        do {
            switch name {
            case "agent_vision_snapshot":
                let frame = try camera.snapshot()
                return toolFrameResponse(id: id, frame: frame)
            case "agent_vision_start":
                return toolTextResponse(id: id, text: try camera.start())
            case "agent_vision_frame":
                let frame = try camera.latestFrame()
                return toolFrameResponse(id: id, frame: frame)
            case "agent_vision_stop":
                return toolTextResponse(id: id, text: try camera.stop())
            default:
                return toolErrorResponse(id: id, text: "Unknown Agent Vision tool: \(name)")
            }
        } catch {
            return toolErrorResponse(id: id, text: error.localizedDescription)
        }
    }

    private func initializeResult() -> [String: Any] {
        [
            "protocolVersion": "2025-06-18",
            "capabilities": [
                "tools": [:]
            ],
            "serverInfo": [
                "name": "agent-vision",
                "version": "1.0.0"
            ]
        ]
    }

    private func toolDefinitions() -> [[String: Any]] {
        [
            [
                "name": "agent_vision_snapshot",
                "title": "Snapshot",
                "description": "Take one Agent Vision snapshot: start the built-in macOS camera if needed, return one JPEG frame, then stop only if snapshot started the camera.",
                "inputSchema": emptyInputSchema()
            ],
            [
                "name": "agent_vision_start",
                "title": "Start Streaming",
                "description": "Start streaming mode by keeping the persistent Agent Vision capture session active.",
                "inputSchema": emptyInputSchema()
            ],
            [
                "name": "agent_vision_frame",
                "title": "Latest Frame",
                "description": "Return the latest live JPEG frame from the active streaming-mode Agent Vision camera session.",
                "inputSchema": emptyInputSchema()
            ],
            [
                "name": "agent_vision_stop",
                "title": "Stop Streaming",
                "description": "Stop streaming mode, release the camera, and clear the cached frame.",
                "inputSchema": emptyInputSchema()
            ]
        ]
    }

    private func emptyInputSchema() -> [String: Any] {
        [
            "type": "object",
            "properties": [:],
            "additionalProperties": false
        ]
    }

    private func toolTextResponse(id: Any?, text: String) -> String {
        successResponse(id: id, result: [
            "content": [
                [
                    "type": "text",
                    "text": text
                ]
            ],
            "isError": false
        ])
    }

    private func toolFrameResponse(id: Any?, frame: CameraFrame) -> String {
        let metadata: [String: Any] = [
            "timestamp": frame.timestamp,
            "mimeType": "image/jpeg",
            "width": frame.width,
            "height": frame.height,
            "bytes": frame.jpegData.count,
            "meanBrightness": frame.meanBrightness
        ]

        return successResponse(id: id, result: [
            "content": [
                [
                    "type": "image",
                    "data": frame.jpegData.base64EncodedString(),
                    "mimeType": "image/jpeg"
                ],
                [
                    "type": "text",
                    "text": "Agent Vision frame \(frame.width)x\(frame.height) captured at \(frame.timestamp)."
                ]
            ],
            "structuredContent": metadata,
            "isError": false
        ])
    }

    private func toolErrorResponse(id: Any?, text: String) -> String {
        successResponse(id: id, result: [
            "content": [
                [
                    "type": "text",
                    "text": text
                ]
            ],
            "isError": true
        ])
    }

    private func successResponse(id: Any?, result: Any) -> String {
        encode([
            "jsonrpc": "2.0",
            "id": id ?? NSNull(),
            "result": result
        ])
    }

    private func errorResponse(id: Any?, code: Int, message: String) -> String {
        encode([
            "jsonrpc": "2.0",
            "id": id ?? NSNull(),
            "error": [
                "code": code,
                "message": message
            ]
        ])
    }

    private func encode(_ object: [String: Any]) -> String {
        do {
            let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
            return String(decoding: data, as: UTF8.self)
        } catch {
            return #"{"error":{"code":-32603,"message":"Response encoding failed"},"id":null,"jsonrpc":"2.0"}"#
        }
    }
}
