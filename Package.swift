import PackageDescription

let package = Package(
	name: "Swerver",
	dependencies: [
		.Package(url: "https://github.com/Swerver/libuv-swift.git", majorVersion: 1),
		.Package(url: "https://github.com/Swerver/libpq-swift.git", majorVersion: 1),
		.Package(url: "https://github.com/jparishy/CryptoSwift.git", majorVersion: 0)
	]
)
