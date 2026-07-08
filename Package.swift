// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "WindowPilot",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "WindowPilot", targets: ["WindowPilot"])
    ],
    targets: [
        .executableTarget(
            name: "WindowPilot",
            exclude: [
                "Resources/Assets/AppIconSource.png",
                "Resources/AppIcon.icns",
                "Resources/Info.plist"
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("Carbon"),
                .linkedFramework("ServiceManagement")
            ]
        )
    ]
)
