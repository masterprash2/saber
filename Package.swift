// swift-tools-version:5.1

import PackageDescription

var package = Package(
    name: "Saber",
    products: [
        .executable(
            name: "saber",
            targets: ["SaberLauncher"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/SourceKitten.git", from: "0.29.0"),
        .package(url: "https://github.com/Carthage/Commandant.git", from: "0.17.0"),
    ],
    targets: [
        .target(
            name: "Saber",
            dependencies: ["SourceKittenFramework"]
        ),
        .target(
            name: "SaberCLI",
            dependencies: ["Saber", "Commandant"]
        ),
        .target(
            name: "SaberLauncher",
            dependencies: ["Saber", "SaberCLI", "Commandant"]
        ),
        .testTarget(
            name: "SaberTests",
            dependencies: ["Saber"]
        ),
        .testTarget(
            name: "SaberCLITests",
            dependencies: ["Saber", "SaberCLI"]
        )
    ],
    swiftLanguageVersions: [.v5]
)

#if os(OSX)
package.dependencies.append(
    .package(url: "https://github.com/xcode-project-manager/xcodeproj.git", from: "7.10.0")
)
package.targets[1].dependencies.append("XcodeProj")
#endif
