// swift-tools-version:4.2

import PackageDescription

let package = Package(
	name: "POSBackEnd",
	products: [
		.executable(name: "POSBackEnd", targets: ["POSBackEnd"])
	],
	dependencies: [
		.package(url: "https://github.com/PerfectlySoft/Perfect-HTTPServer.git", from: "3.0.0"),
	],
	targets: [
		.target(name: "POSBackEnd", dependencies: ["PerfectHTTPServer"])
	]
)
