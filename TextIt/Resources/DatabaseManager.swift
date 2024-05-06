//
//  DatabaseManager.swift
//  TextIt
//
//  Created by Piyush Pandey on 05/05/24.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
}

// MARK: Account Management

extension DatabaseManager {
    
    /// Checks whether user with provided email already exists or not.
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    /// Inserts a new user to the database.
    public func insertUser(with user: TextItUser) {
        database.child(user.safeEmail).setValue([
            "firstName": user.firstName,
            "lastName": user.lastName
        ])
    }
}

struct TextItUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    //let profilePictureUrl: String
}
