// swift-tools-version:4.0

import PackageDescription

let package = Package(
	name: "Resolver",
	products: [
		.library(name: "Resolver", targets: ["Resolver"])
	],
	dependencies: [
		.package(url: "git@gitlab.kancelar.seznam.cz:pvs/swift-unisocket", from: "0.12.0"),
		.package(url: "git@gitlab.kancelar.seznam.cz:pvs/swift-dns", from: "1.0.0")
	],
	targets: [
		.target(name: "Resolver", dependencies: ["UniSocket", "DNS"])
	]
)
