//
//  DatabaseManager.swift
//  TextIt
//
//  Created by Piyush Pandey on 05/05/24.
//

import CoreLocation
import Foundation
import FirebaseDatabase
import MessageKit

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
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: UserDefaultConstantKeys.email) as? String,
              let currentName = UserDefaults.standard.value(forKey: UserDefaultConstantKeys.fullName) as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard let self else { return }
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
                "name": name,
                "latest_message": [
                    "date": messageDate,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            let recipient_newConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": safeEmail,
                "name": currentName,
                "latest_message": [
                    "date": messageDate,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            // Update recipient conversaiton entry
            self.database.child("\(otherUserEmail)/\(Constants.COLLECTION_NAME_CONVERSATIONS)").observeSingleEvent(of: .value, with: { [weak self] snapshot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(otherUserEmail)/\(Constants.COLLECTION_NAME_CONVERSATIONS)").setValue(conversations)
                }
                else {
                    self?.database.child("\(otherUserEmail)/\(Constants.COLLECTION_NAME_CONVERSATIONS)").setValue([recipient_newConversationData])
                }
            })
            
            if var conversations = userNode[Constants.COLLECTION_NAME_CONVERSATIONS] as? [[String: Any]] {
                conversations.append(newConversationData)
                userNode[Constants.COLLECTION_NAME_CONVERSATIONS] = conversations
            } else {
                userNode[Constants.COLLECTION_NAME_CONVERSATIONS] = [newConversationData]
            }
            
            ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                guard error == nil else {
                    print("Error: \(error!)")
                    completion(false)
                    return
                }
                self?.finishCreatingConversation(conversationId: conversationId, 
                                                 name: name,
                                                 firstMessage: firstMessage,
                                                 completion: completion)
            })
        })
    }
    
    private func finishCreatingConversation(conversationId: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
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
            "is_read" : false,
            "name": name
        ]
        
        let value : [String: Any] = [
            Constants.COLLECTION_NAME_MESSAGES : [ messageObject ]
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
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
        database.child("\(email)/\(Constants.COLLECTION_NAME_CONVERSATIONS)").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else{
                completion(.failure(DatabaseErrors.failedToFetchConversations))
                return
            }
            
            let conversations: [Conversation] = value.compactMap({ dictionary in
                guard let conversationId = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String: Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool else {
                    return nil
                }
                
                let latestMessageObject = LatestMessage(date: date,
                                                         text: message,
                                                         isRead: isRead)
                return Conversation(id: conversationId,
                                    name: name,
                                    otherUserEmail: otherUserEmail,
                                    latestMessage: latestMessageObject)
            })
            
            completion(.success(conversations))
        })
    }
    
    /// Fetches all the messages for a particular conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        database.child("\(id)/\(Constants.COLLECTION_NAME_MESSAGES)").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else{
                completion(.failure(DatabaseErrors.failedToFetchMessages))
                return
            }
            
            let messages: [Message] = value.compactMap({ dictionary in
                guard let name = dictionary["name"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let messageID = dictionary["id"] as? String,
                      let content = dictionary["content"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let type = dictionary["type"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString) else {
                    return nil
                }
                var kind: MessageKind = .text(content)
                
                let sender = Sender(photoUrl: "",
                                    senderId: senderEmail,
                                    displayName: name)
    
                return Message(sender: sender,
                               messageId: messageID,
                               sentDate: date,
                               kind: kind)
            })
            
            completion(.success(messages))
        })
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
