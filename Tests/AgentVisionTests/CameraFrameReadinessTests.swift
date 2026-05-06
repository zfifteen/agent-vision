import Foundation
import Testing
@testable import AgentVisionCore

@Test func frameReadinessRejectsBlackFramesAndAcceptsThresholdFrames() {
    let blackFrame = CameraFrame(
        jpegData: Data(),
        timestamp: "2026-05-05T20:00:00Z",
        width: 2,
        height: 1,
        meanBrightness: CameraFrameReadiness.minimumUsableMeanBrightness - 0.001
    )
    let usableFrame = CameraFrame(
        jpegData: Data(),
        timestamp: "2026-05-05T20:00:01Z",
        width: 2,
        height: 1,
        meanBrightness: CameraFrameReadiness.minimumUsableMeanBrightness
    )

    #expect(CameraFrameReadiness.isUsable(blackFrame) == false)
    #expect(CameraFrameReadiness.isUsable(usableFrame) == true)
}
