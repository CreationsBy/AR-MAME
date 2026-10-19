import XCTest
@testable import ARMAMELogic

final class SpatialTests: XCTestCase {
    func testHardwareRotationAndPhysicalScaling() {
        let center = SpatialMath.pacmanPoint(x: 144, y: 112)
        XCTAssertEqual(center.x, 0); XCTAssertEqual(center.z, 0)
        let left = SpatialMath.pacmanPoint(x: 144, y: 0)
        let right = SpatialMath.pacmanPoint(x: 144, y: 224)
        for meters: Float in [0.6, 25, 100] { XCTAssertEqual((right.x-left.x)*meters, meters) }
    }
    func testFourWayNeverEmitsDiagonalAndDeadZoneReleases() {
        XCTAssertEqual(SpatialMath.directions(x: 0.9, y: -0.8, fourWay: true, deadZone: 0.2), [7])
        XCTAssertEqual(SpatialMath.directions(x: 0.9, y: -0.8, fourWay: false, deadZone: 0.2), [7,4])
        XCTAssertEqual(SpatialMath.directions(x: 0.1, y: -0.1, fourWay: false, deadZone: 0.2), [])
    }
    func testMeshRunsRespectTransparencyAndRows() {
        let color: UInt32 = 0xff0099ff
        let result = SpatialMath.runs(pixels: [color,color,0,color,0,0], width: 3, height: 2, stride: 3)
        XCTAssertEqual(result, [.init(x: 0,y: 0,length: 2,rgba: color), .init(x: 0,y: 1,length: 1,rgba: color)])
    }
    func testSegmentationKeepsDisconnectedObjectsSeparate() {
        let red: UInt32 = 0xff0000ff
        let result = Segmentation.components(pixels: [red,red,0,red,red, 0,0,0,red,red], width: 5, height: 2)
        XCTAssertEqual(result.map(\.count), [4,2])
        XCTAssertEqual(Segmentation.components(pixels: [red], width: 9, height: 9).count, 0)
    }
    func testInvalidScaleCannotCorruptSceneTransforms() {
        XCTAssertEqual(SpatialMath.clampedWidth(.nan), 0.6)
        XCTAssertEqual(SpatialMath.clampedWidth(-5), 0.1)
        XCTAssertEqual(SpatialMath.clampedWidth(500), 250)
    }
}
