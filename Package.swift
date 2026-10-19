// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "ARMAMELogic",
    products: [.library(name: "ARMAMELogic", targets: ["ARMAMELogic"])],
    targets: [
        .target(name: "ARMAMELogic", path: "ios/Shared"),
        .testTarget(name: "ARMAMELogicTests", dependencies: ["ARMAMELogic"], path: "tests/Swift")
    ]
)
