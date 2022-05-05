// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "brstmbottg",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/zmeyc/telegram-bot-swift.git", from: "2.1.2"),
        .package(url: "https://github.com/FreeApp2014/SwiftyCM.git", from: "2.0.0-beta.7"),
        .package(url: "https://github.com/JohnSundell/ShellOut.git", from: "2.0.3")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "brstmbottg",
            dependencies: ["SwiftyCM", "TelegramBotSDK", "ShellOut"]),
    ]
)
