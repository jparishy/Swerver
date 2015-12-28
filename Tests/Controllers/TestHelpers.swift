import XCTest
import Foundation
import libuv
import libpq
import CryptoSwift
@testable import Swerver

let TestApplicationSecret = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

class TestApplication : Application {
	let databaseConfiguration: DatabaseConfiguration? = nil
	let applicationSecret = TestApplicationSecret
	let publicDirectory = ""
}
