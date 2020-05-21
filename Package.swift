// swift-tools-version:5.2

import PackageDescription

let package = Package(
	name: "Resolver",
	products: [
		.library(name: "Resolver", targets: ["Resolver"])
	],
	dependencies: [
		.package(name: "UniSocket", url: "https://github.com/seznam/swift-unisocket", from: "0.14.0"),
		.package(name: "DNS", url: "https://github.com/Bouke/DNS.git", from: "1.2.0")
	],
	targets: [
		.target(name: "Resolver", dependencies: ["UniSocket", "DNS"]),
		.testTarget(name: "ResolverTests", dependencies: ["Resolver"])
	],
	swiftLanguageVersions: [.v5]
)
