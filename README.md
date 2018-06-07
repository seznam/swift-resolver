![](https://img.shields.io/badge/Swift-4.1-orange.svg?style=flat)
![macOS](https://img.shields.io/badge/os-macOS-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)
![Apache 2](https://img.shields.io/badge/license-Apache2-blue.svg?style=flat)
![Build Status](https://travis-ci.com/seznam/swift-resolver.svg?branch=master)

# Resolver

Let your swift application query DNS easily.

## Usage

Get hostname of the system:

```swift
import Resolver

if let hostname = Resolver.getHostname() {
	print("my hostname is '\(hostname)'")
} else {
	print("failed to get my hostname")
}
```

Get nameservers used by the system:

```swift
import Resolver

let ns = Resolver.getNameserver()

if ns.isEmpty {
	print("failed to get nameservers")
} else {
	print("nameservers used by this system: \(ns)")
}
```

Query DNS server using default nameservers and custom timeout:

```swift
import Resolver

do {
	let resolver = Resolver(timeout: 3)
	let answer = try resolver.resolve("www.seznam.cz")
	print(answer)
} catch ResolverError.error(let detail) {
	print(detail)
}
```

Discover services using custom nameservers:

```swift
import Resolver

do {
	let resolver = Resolver(nameserver: [ "77.75.74.80", "77.75.75.230" ])
	let answer = try resolver.discover("_autodiscover._tcp.email.cz")
	print(answer)
} catch ResolverError.error(let detail) {
	print(detail)
}
```

## Credits

Written by [Daniel Bilik](https://github.com/ddbilik/), copyright [Seznam.cz](https://onas.seznam.cz/en/), licensed under the terms of the Apache License 2.0.
