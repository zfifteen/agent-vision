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
                return errorResponse(id: nil, code: -32700, message: "Parse error")
            }

            let id = message["id"]
            guard let method = message["method"] as? String else {
                return nil
            }

            switch method {
            case "initialize":
                return successResponse(id: id, result: initializeResult())
            case "tools/list":
                return successResponse(id: id, result: ["tools": toolDefinitions()])
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
            case "codex_vision_snapshot":
                let frame = try camera.snapshot()
                return toolFrameResponse(id: id, frame: frame)
            case "codex_vision_start":
                return toolTextResponse(id: id, text: try camera.start())
            case "codex_vision_frame":
                let frame = try camera.latestFrame()
                return toolFrameResponse(id: id, frame: frame)
            case "codex_vision_stop":
                return toolTextResponse(id: id, text: try camera.stop())
            default:
                return toolErrorResponse(id: id, text: "Unknown Codex Vision tool: \(name)")
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
                "name": "codex-vision",
                "version": "1.0.0"
            ]
        ]
    }

    private func toolDefinitions() -> [[String: Any]] {
        [
            [
                "name": "codex_vision_snapshot",
                "description": "Take one Codex Vision snapshot: start the built-in macOS camera, return one JPEG frame, then stop the camera.",
                "inputSchema": emptyInputSchema()
            ],
            [
                "name": "codex_vision_start",
                "description": "Start streaming mode by keeping the persistent Codex Vision capture session active.",
                "inputSchema": emptyInputSchema()
            ],
            [
                "name": "codex_vision_frame",
                "description": "Return the latest live JPEG frame from the active streaming-mode Codex Vision camera session.",
                "inputSchema": emptyInputSchema()
            ],
            [
                "name": "codex_vision_stop",
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
            "bytes": frame.jpegData.count
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
                    "text": "Codex Vision frame \(frame.width)x\(frame.height) captured at \(frame.timestamp)."
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
        let data = try! JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        return String(decoding: data, as: UTF8.self)
    }
}
