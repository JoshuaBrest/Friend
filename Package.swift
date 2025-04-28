// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Friend",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(
            url: "https://github.com/MrKai77/Luminare",
            branch: "main"),
        .package(url: "https://github.com/exPHAT/SwiftWhisper", branch: "master"),
        .package(url: "https://github.com/AudioKit/AudioKit", branch: "main"),
        .package(url: "https://github.com/MacPaw/OpenAI", branch: "main"),
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui.git", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "Friend",
            dependencies: [
                .byName(name: "Luminare"),
                .byName(name: "SwiftWhisper"),
                .byName(name: "AudioKit"),
                .byName(name: "OpenAI"),
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
            ],
            path: "./Sources/",
            resources: [
                .copy("./Resources")
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-F/System/Library/PrivateFrameworks",
                    "-framework", "Skylight",
                    "-F/System/Library/Frameworks",
                    "-framework", "CoreDisplay",
                ])
            ]
        )
    ]
)
