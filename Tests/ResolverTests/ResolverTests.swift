import XCTest

@testable import Resolver

class ResolverTests: XCTestCase {

	static var allTests = [
		("testHostname", testHostname),
		("testNameserver", testNameserver),
		("testResolve", testResolve),
		("testDiscover", testDiscover),
		("testNXDomain", testNXDomain),
		("testTimeout", testTimeout)
	]

	func testHostname() {
		let hostname = Resolver.getHostname()
		print(hostname ?? "")
		XCTAssert(hostname != nil && hostname!.count > 0)
	}

	func testNameserver() {
		let nameserver = Resolver.getNameserver()
		print(nameserver)
		XCTAssert(nameserver.count > 0)
	}

	func testResolve() {
		let resolver = Resolver()
		let result: [ResolverTarget]?
		do {
			result = try resolver.resolve("www.example.com")
		} catch {
			print(error)
			result = nil
		}
		print(result ?? "")
		XCTAssert(result != nil &&
			result!.count > 0 &&
			result!.first!.name == "www.example.com."
		)
	}

	func testDiscover() {
		let resolver = Resolver()
		let result: [ResolverTarget]?
		do {
			result = try resolver.discover("_xmpp-server._tcp.jabber.cz")
		} catch {
			print(error)
			result = nil
		}
		print(result ?? "")
		XCTAssert(result != nil &&
			result!.count > 0 &&
			result!.first!.port != nil &&
			result!.first!.priority != nil &&
			result!.first!.weight != nil
		)
	}

	func testNXDomain() {
		let resolver = Resolver()
		let result: [ResolverTarget]?
		var errstr: String = ""
		do {
			result = try resolver.resolve("ftp.example.com")
		} catch ResolverError.error(let detail) {
			result = nil
			errstr = detail
		} catch {
			print(error)
			result = nil
		}
		XCTAssert(result == nil && errstr == "NXDOMAIN")
	}

	func testTimeout() {
		let timeout = 2
		let resolver = Resolver(nameserver: [ "127.10.10.10" ], timeout: 2)
		let from = Date().timeIntervalSince1970
		do {
			_ = try resolver.resolve("github.com")
		} catch {
			print(error)
		}
		let to = Date().timeIntervalSince1970
		let duration = to - from
		XCTAssert(duration >= Double(timeout) && duration < Double(timeout + 1))
	}

}
