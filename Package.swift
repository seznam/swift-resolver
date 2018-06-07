// swift-tools-version:4.0

import PackageDescription

let package = Package(
	name: "Resolver",
	products: [
		.library(name: "Resolver", targets: ["Resolver"])
	],
	dependencies: [
		.package(url: "https://github.com/seznam/swift-unisocket", from: "0.13.1"),
		.package(url: "https://github.com/Bouke/DNS.git", from: "1.0.0")
	],
	targets: [
		.target(name: "Resolver", dependencies: ["UniSocket", "DNS"]),
		.testTarget(name: "ResolverTests", dependencies: ["Resolver"])
	],
	swiftLanguageVersions: [4]
)
