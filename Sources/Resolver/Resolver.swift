import Foundation
import UniSocket
import DNS

public enum ResolverError: Error {
	case error(detail: String)
}

public typealias ResolverTarget = (name: String, address: String, port: Int?, weight: Int?, priority: Int?)

public class Resolver {

	let nameserver: [String]
	let domain: [String]
	let timeout: UInt

	public init(nameserver: [String]? = nil, domain: [String]? = nil, timeout: UInt = 2) {
		if let n = nameserver {
			self.nameserver = n
		} else {
			self.nameserver = Resolver.getNameserver()
		}
		if let d = domain {
			self.domain = d
		} else {
			self.domain = Resolver.getDomain()
		}
		self.timeout = timeout
	}

	public class func getHostname() -> String? {
		let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: Int(_POSIX_HOST_NAME_MAX))
		_ = Glibc.gethostname(buffer, Int(_POSIX_HOST_NAME_MAX))
		var result: String?
		if let string = String(cString: buffer, encoding: .utf8) {
			result = string
		}
		buffer.deallocate()
		return result
	}

	public class func getNameserver() -> [String] {
		var nameserver: [String] = []
		do {
			for line in try String(contentsOfFile: "/etc/resolv.conf", encoding: .utf8).components(separatedBy: .newlines) {
				var key = line.trimmingCharacters(in: CharacterSet(charactersIn: " "))
				if key.hasPrefix("nameserver ") {
					key.removeFirst(11)
					nameserver.append(key.trimmingCharacters(in: CharacterSet(charactersIn: " ")))
				}
			}
			guard !nameserver.isEmpty else {
				throw UniSocketError.error(detail: "no nameservers")
			}
		} catch {
			nameserver = [ "127.0.0.1" ]
		}
		return nameserver
	}

	public class func getDomain() -> [String] {
		var domain: [String] = []
		do {
			for line in try String(contentsOfFile: "/etc/resolv.conf", encoding: .utf8).components(separatedBy: .newlines) {
				var key = line.trimmingCharacters(in: CharacterSet(charactersIn: " "))
				if key.hasPrefix("domain ") {
					key.removeFirst(7)
					domain.append(key.trimmingCharacters(in: CharacterSet(charactersIn: " ")))
				} else if key.hasPrefix("search ") {
					key.removeFirst(7)
					for value in key.components(separatedBy: " ") {
						domain.append(value)
					}
				}
			}
		} catch {
			domain = []
		}
		return domain
	}

	private func query(_ name: String, type: ResourceRecordType = .host, timeout: UInt? = nil) throws -> [ResourceRecord] {
		let tmout = UniSocketTimeout(connect: timeout ?? self.timeout, read: timeout ?? self.timeout, write: timeout ?? self.timeout)
		var nameserver = self.nameserver
		var domain = [String]()
		if name.hasSuffix(".") {
			domain.append("")
		} else {
			domain = self.domain
			if name.contains(".") {
				domain.insert("", at: 0)
			}
		}
		var result: [ResourceRecord]?
		var errstr = "TIMEOUT"
		while result == nil, domain.count > 0, nameserver.count > 0 {
			var qname: String
			if let search = domain.first, !search.isEmpty {
				qname = "\(name).\(search)"
			} else {
				qname = name
			}
			if qname.hasSuffix(".") {
				qname.removeLast()
			}
			do {
				let request = try Message(type: .query, recursionDesired: true, questions: [ Question(name: "\(qname)", type: type) ]).serialize()
				var answer: Message?
				var sock: UniSocket? = try UniSocket(type: .udp, peer: nameserver.first!, port: 53, timeout: tmout)
				while let s = sock {
					sock = nil
					answer = nil
					try s.attach()
					try s.send(request)
					let response = try s.recv(min: 10)
					try s.close()
					guard response.count > 0 else {
						throw UniSocketError.error(detail: "timeout")
					}
					answer = try Message.init(deserialize: response)
					if answer!.truncation {
						sock = try UniSocket(type: .tcp, peer: nameserver.first!, port: 53, timeout: tmout)
					}
				}
				if let a = answer {
					switch a.returnCode {
					case .formatError:
						throw ResolverError.error(detail: "FORMERR")
					case .serverFailure:
						throw ResolverError.error(detail: "SERVFAIL")
					case .notImplemented:
						throw ResolverError.error(detail: "NOTIMPL")
					case .queryRefused:
						throw ResolverError.error(detail: "REFUSED")
					case .nonExistentDomain:
						errstr = "NXDOMAIN"
						domain.removeFirst()
					default:
						result = a.answers
					}
				}
			} catch UniSocketError.error(let detail) {
				errstr = detail
				nameserver.removeFirst()
			} catch ResolverError.error(let detail) {
				errstr = detail
				nameserver.removeFirst()
			} catch {
				domain.removeFirst()
			}
		}
		guard let r = result else {
			throw ResolverError.error(detail: errstr)
		}
		return r
	}

	public func resolve(_ name: String, timeout: UInt? = nil) throws -> [ResolverTarget] {
		var result = [ResolverTarget]()
		var queue = [ResourceRecord]()
		var cname: String? = nil
		queue = try query(name, type: .host, timeout: timeout)
		queue += try query(name, type: .host6, timeout: timeout)
		while !queue.isEmpty {
			let record = queue.removeFirst()
			if let host = record as? HostRecord<IPv4> {
				result.append((name: host.name, address: host.ip.presentation, port: nil, weight: nil, priority: nil))
			} else if let host = record as? HostRecord<IPv6> {
				result.append((name: host.name, address: host.ip.presentation, port: nil, weight: nil, priority: nil))
			} else if let alias = record as? AliasRecord {
				cname = alias.canonicalName
			} else if let r = record as? Record {
				throw ResolverError.error(detail: "unexpected response \(r.type)")
			} else {
				throw ResolverError.error(detail: "unexpected response")
			}
			if queue.isEmpty, result.isEmpty, let alias = cname {
				queue += try query(alias, type: .host, timeout: timeout)
				queue += try query(alias, type: .host6, timeout: timeout)
			}
		}
		return result
	}

	public func discover(_ service: String, timeout: UInt? = nil) throws -> [ResolverTarget] {
		var result = [ResolverTarget]()
		for record in try query(service, type: .service, timeout: timeout) {
			if let srv = record as? ServiceRecord {
				for host in try resolve(srv.server) {
					let target = ResolverTarget(name: host.name, address: host.address, port: Int(srv.port), weight: Int(srv.weight), priority: Int(srv.priority))
					var i = 0
					_ = result.map {
						if target.priority! >= $0.priority! {
							i += 1
						}
					}
					result.insert(target, at: i)
				}
			} else if let r = record as? Record {
				throw ResolverError.error(detail: "unexpected response \(r.type)")
			} else {
				throw ResolverError.error(detail: "unexpected response")
			}
		}
		return result
	}

}
