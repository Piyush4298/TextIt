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
    
    static func safeEmail(_ email: String) -> String {
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
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
    public func insertUser(with user: TextItUser, completion: @escaping ((Bool) -> Void)) {
        database.child(user.safeEmail).setValue([
            "firstName": user.firstName,
            "lastName": user.lastName
        ], withCompletionBlock: {[weak self] error, _ in
            guard let self else { return }
            if let error = error {
                completion(false)
                print("Failed to insert in Database.\(error)")
                return
            }
            self.database.child(Constants.COLLECTION_NAME_USER).observeSingleEvent(of: .value, with: { [weak self] snapshot in
                if var userCollection = snapshot.value as? [[String: String]] {
                    let newElement = [
                        "name": user.firstName + " " + user.lastName ,
                        "email": user.safeEmail,
                    ]
                    userCollection.append(newElement)
                    self?.database.child(Constants.COLLECTION_NAME_USER).setValue(userCollection, withCompletionBlock: { error, _ in
                        if let error = error {
                            completion(false)
                            print("Failed to insert users in Database.\(error)")
                            return
                        }
                        
                        completion(true)
                    })
                    
                } else {
                    let newCollection: [[String: String]] = [
                        [
                            "name": user.firstName + " " + user.lastName ,
                            "email": user.safeEmail,
                        ]
                    ]
                    self?.database.child(Constants.COLLECTION_NAME_USER).setValue(newCollection, withCompletionBlock: { error, _ in
                        if let error = error {
                            completion(false)
                            print("Failed to insert users in Database.\(error)")
                            return
                        }
                        
                        completion(true)
                    })
                }
            })
        })
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
    
    var profilePictureFileName: String {
        return "\(safeEmail)\(Constants.profilePicExtension)"
    }
}
