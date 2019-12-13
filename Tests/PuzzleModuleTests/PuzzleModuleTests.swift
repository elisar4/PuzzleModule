import XCTest
@testable import PuzzleModule

final class PuzzleModuleTests: XCTestCase {
    func testExample() {
        XCTAssertEqual(PuzzleModule.insets, UIEdgeInsets.zero)
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
