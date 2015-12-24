import PackageDescription

let package = Package(
	name: "Swerver",
	dependencies: [
		.Package(url: "../Dependencies/libpq", majorVersion: 1),
		.Package(url: "../Dependencies/libuv", majorVersion: 1),
		.Package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", majorVersion: 0)
	]
)
