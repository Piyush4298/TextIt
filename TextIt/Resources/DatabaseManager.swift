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
            guard snapshot.value as? [String: String] != nil else {
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
    
    /// Fetches list of all the users registered from the database.
    public func fetchUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
        database.child(Constants.COLLECTION_NAME_USER).observeSingleEvent(of: .value, with: { snapshot in
            guard let users = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseErrors.failedToFetchUsers))
                return
            }
            completion(.success(users))
        })
    }
}

// MARK: Chat / Conversation Management
extension DatabaseManager {
    
    /// Creates a new conversation with target user email and first message sent
    public func createNewConversation(with otherUserEmail: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: UserDefaultConstantKeys.email) as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: { snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("User not found")
                return
            }
            
            var message = ""
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let messageDate = ChatViewController.dateFormatter.string(from: firstMessage.sentDate)
            let conversationId = "conversation_\(firstMessage.messageId)"
            let newConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": otherUserEmail,
                "latest_message": [
                    "date": messageDate,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            if var conversations = userNode[Constants.COLLECTION_NAME_CONVERSATIONS] as? [[String: Any]] {
                conversations.append(newConversationData)
            }
            userNode[Constants.COLLECTION_NAME_CONVERSATIONS] = [newConversationData]
            ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                guard error == nil else {
                    print("Error: \(error!)")
                    completion(false)
                    return
                }
                self?.finishCreatingConversation(conversationId: conversationId,
                                                firstMessage: firstMessage,
                                                completion: completion)
            })
        })
    }
    
    private func finishCreatingConversation(conversationId: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: UserDefaultConstantKeys.email) as? String else {
            completion(false)
            return
        }
        var message = ""
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        let messageDate = ChatViewController.dateFormatter.string(from: firstMessage.sentDate)
        let messageObject: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": messageDate,
            "sender_email": DatabaseManager.safeEmail(currentEmail),
            "is_read" : false
        ]
        
        let value : [String: Any] = [
            "messages": [ messageObject ]
        ]
        database.child("\(conversationId)").setValue(value, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    /// Fetches all the conversations associated with the user email
    public func getAllConversations(for email: String, completion: @escaping (Result<String, Error>) -> Void) {
        
    }
    
    /// Fetched all the messages for a particular conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<String, Error>) -> Void) {
        
    }
    
    /// Sends a message with target conversation and message
    public func sendMessage(to conversation: String, message: Message, completion: @escaping (Bool) -> Void) {
        
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
