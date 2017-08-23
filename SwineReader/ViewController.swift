import UIKit
import Swinject

public typealias ErrorClosure = ((Error?) -> Void)

class ViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		setup()
		setupDI()
	}
	func setup() {
		let user = MockUser()
		user.username = "test001"

		let avatar = MockAvatar(author: user)
		avatar.create()

		user.avatar = avatar
		user.create()

		print("User - \(user)")
		print("Avatar - \(avatar)")
		print("----")
	}
	func setupDI() {
		let container = DependencyContainer.setup()

		var newUser = container.resolve(User.self, argument: "test001")!

		let newAvatar = container.resolve(Avatar.self, argument: newUser)!
		newAvatar.create()

		newUser.avatar = newAvatar
		newUser.create()

		let queriedAvatar = container.resolve(Avatar.self)!
		queriedAvatar.show(uid: 42)

		let queriedUser = container.resolve(User.self)!
		queriedUser.show(uid: 42)

		print("newUser - \(newUser)")
		print("newAvatar - \(newAvatar)")
		print("queriedAvatar - \(queriedAvatar)")
		print("queriedUser - \(queriedUser)")
		print("queriedUser's avatar - \(String(describing: queriedUser.avatar))")
		print("----")
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
}

protocol Indexable {
	var uid: Int { get set }
	func isValid() -> Bool
}

extension Indexable {
	func isValid() -> Bool {
		return uid >= 0
	}
}

protocol Presentable: Indexable {
	func create(completion: ErrorClosure?)
	func show(uid: Int)
}

extension Presentable {
	func create(completion: ErrorClosure? = nil) {
		create(completion: completion)
	}
}

protocol Avatar: Presentable {
	var imageURL: String { get set }
	var author: User! { get set }
	
	init()
	init(author: User)
}

class MockAvatar: Avatar {
	var uid = -1
	var imageURL = "http://www.superarts.org/swine/default.png"
	var author: User!

	required init() {
	}
	required init(author: User) {
		self.author = author
	}

	func create(completion: ErrorClosure? = nil) {
		uid = 1
		if let closure = completion {
			closure(nil)
		}
	}
	func show(uid: Int) {
		self.uid = uid
		imageURL = String(format: "http://test.com/image%03d.png", uid)

		let user = DependencyContainer.container.resolve(User.self)!
		user.show(uid: 42)
		author = user
	}
}

protocol User: Presentable {
	var username: String! { get set }
	var avatar: Avatar? { get set }

	init()
	init(username: String)
}

class MockUser: User {
	var uid = -1
	var username: String!
	var avatar: Avatar?

	required init() {
	}
	required init(username: String) {
		self.username = username
	}

	func create(completion: ErrorClosure? = nil) {
		uid = 1
		if let closure = completion {
			closure(nil)
		}
	}
	func show(uid: Int) {
		self.uid = uid
		username = String(format: "test%03d", uid)

		let avatar = DependencyContainer.container.resolve(Avatar.self, argument: self as User)!
		avatar.create()
		self.avatar = avatar
	}
}

extension MockUser: CustomStringConvertible {
    var description: String {
		return "MockUser \(debugAddr(self)):\n\tID: \(uid)\n\tusername: \(username)\n\tavatar: \(String(describing: debugAddr(avatar as Any)))\n\tvalidity: \(isValid())\n"
    }
}

extension MockAvatar: CustomStringConvertible {
    var description: String {
        return "MockAvatar \(debugAddr(self)):\n\tID: \(uid)\n\timageURL: \(imageURL)\n\tauthor: \(debugAddr(author))\n\tvalidity: \(isValid())\n"
    }
}

func debugAddr(_ obj: Any) -> UnsafeMutableRawPointer {
	return Unmanaged<AnyObject>.passUnretained(obj as AnyObject).toOpaque()
}

protocol Post: Presentable {
	var title: String! { get set }
}

class DependencyContainer {
	static let container = Container()

	@discardableResult
	static func setup() -> Container {
		container.register(User.self) { _ in MockUser() }
		container.register(User.self) { _, username in MockUser(username: username) }
		container.register(Avatar.self) { _ in MockAvatar() }
		container.register(Avatar.self) { _, user in MockAvatar(author: user) }
		return container
	}
}