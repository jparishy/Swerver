import PackageDescription

let package = Package(
	dependencies: [
		.Package(url: "../Dependencies/LibUV", majorVersion: 1),
		.Package(url: "../Dependencies/LibPQ", majorVersion: 1),
		.Package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", majorVersion: 0)
	]
)
