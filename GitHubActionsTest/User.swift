//
//  User.swift
//  GitHubActionsTest
//
//  Created by Cedomir Stankov on 12. 3. 2026..
//

import Foundation

struct User: Codable, Equatable {
    var id: Int
    var firstName: String
    var lastName: String
    var email: String
    var age: Int?
    var isActive: Bool = true
    var createdAt: Date? = nil
    var roles: [String] = []

    var fullName: String {
        return firstName + " " + lastName
    }

    var isAdult: Bool {
        guard let age = age else { return false }
        return age >= 18
    }

    func hasRole(_ role: String) -> Bool {
        return roles.contains(role)
    }

    mutating func deactivate() {
        isActive = false
    }

    mutating func addRole(_ role: String) {
        if !roles.contains(role) { roles.append(role) }
    }
}

class UserRepository {
    private var users: [User] = []
    private let queue = DispatchQueue(label: "com.app.userrepo", attributes: .concurrent)

    func add(_ user: User) {
        queue.async(flags: .barrier) { self.users.append(user) }
    }

    func find(byId id: Int) -> User? {
        return queue.sync { users.first { $0.id == id }}
    }

    func find(byEmail email: String) -> User? {
        queue.sync { users.first { $0.email.lowercased() == email.lowercased() }}
    }

    func update(_ user: User) -> Bool {
        queue.async(flags: .barrier) {
            if let index = self.users.firstIndex(where: { $0.id == user.id }) { self.users[index] = user }
        }
        return find(byId: user.id) != nil
    }

    func delete(byId id: Int) {
        queue.async(flags: .barrier) { self.users.removeAll { $0.id == id }
        }
    }

    func all() -> [User] {
        return queue.sync { users }
    }

    func count() -> Int {
        queue.sync { users.count }
    }

    func activeUsers() -> [User] {
        return queue.sync { users.filter { $0.isActive }}
    }

    func usersWithRole(_ role: String) -> [User] {
        queue.sync { users.filter { $0.roles.contains(role) }}
    }
}

enum UserValidationError: Error {
    case emptyFirstName
    case emptyLastName
    case invalidEmail
    case ageTooYoung(minimum: Int)
    case duplicateEmail
}

enum UserValidator {
    static func validate(_ user: User, existingEmails: [String] = []) -> Result<Void, UserValidationError> {
        if user.firstName.trimmingCharacters(in: .whitespaces).isEmpty { return .failure(.emptyFirstName) }
        if user.lastName.trimmingCharacters(in: .whitespaces).isEmpty { return .failure(.emptyLastName) }
        if !user.email.contains("@") || !user.email.contains(".") { return .failure(.invalidEmail) }
        if existingEmails.map({ $0.lowercased() }).contains(user.email.lowercased()) { return .failure(.duplicateEmail) }
        if let age = user.age, age < 13 { return .failure(.ageTooYoung(minimum: 13)) }
        return .success(())
    }
}
