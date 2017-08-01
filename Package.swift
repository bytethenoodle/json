import PackageDescription

let package = Package(
    name: "JSON",
    dependencies: [
        // Core protocols, extensions, and functionality
        .Package(url: "https://github.com/bytethenoodle/core.git", majorVersion: 2),

        // Data structure for converting between multiple representations
        .Package(url: "https://github.com/bytethenoodle/node.git", majorVersion: 2),
    ]
)
