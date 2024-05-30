//
//  ChatViewController.swift
//  TextIt
//
//  Created by Piyush Pandey on 14/05/24.
//

import InputBarAccessoryView
import MessageKit
import UIKit

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}

struct Sender: SenderType {
    var photoUrl: String
    var senderId: String
    var displayName: String
}

class ChatViewController: MessagesViewController {
    
    private let otherUserEmail: String
    private var conversationId: String?
    private var messages = [Message]()
    private var sender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: UserDefaultConstantKeys.email) as? String else {
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(email)
        
        return Sender(photoUrl: "",
                      senderId: safeEmail,
                      displayName: "Me")
    }
    
    public var isNewConversation: Bool = false
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MMM-yyyy 'at' HH:mm:ss z"
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    init(with email: String, id: String?) {
        self.otherUserEmail = email
        self.conversationId = id
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationId = conversationId {
            listenForMessages(id: conversationId, shouldScrollToBottom: true)
        }
    }
    
    private func listenForMessages(id: String, shouldScrollToBottom: Bool) {
        DatabaseManager.shared.getAllMessagesForConversation(with: id, completion: { [weak self] result in
            switch result {
            case .success(let messages):
                print("success in getting messages: \(messages)")
                guard !messages.isEmpty else {
                    print("messages are empty")
                    return
                }
                self?.messages = messages
                
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    
                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToLastItem()
                    }
                }
            case .failure(let error):
                print("failed to get messages: \(error)")
            }
        })
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let sender = self.sender,
              let messageId = generateMessageId() else { return }
        
        let message = Message(sender: sender,
                              messageId: messageId,
                              sentDate: Date(),
                              kind: .text(text))
        if isNewConversation {
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, 
                                                         name: self.title ?? "User",
                                                         firstMessage: message,
                                                         completion: { [weak self] success in
                guard let self else { return }
                if success {
                    // Message Sent
                    self.isNewConversation = false
                    let newConversationId = "conversation_\(message.messageId)"
                    self.conversationId = newConversationId
                    self.listenForMessages(id: newConversationId, shouldScrollToBottom: true)
                    self.messageInputBar.inputTextView.text = nil
                    print("message sent successfully")
                } else {
                    // Failed to Send
                    print("failed to send message")
                }
            })
        } else {
            guard let conversationId = conversationId, let name = self.title else {
                return
            }
            DatabaseManager.shared.sendMessage(to: conversationId,
                                               otherUserEmail: otherUserEmail,
                                               name: name,
                                               newMessage: message,
                                               completion: { [weak self] success in
                guard let self else { return }
                if success {
                    // Message Sent
                    self.messageInputBar.inputTextView.text = nil
                    print("message sent successfully")
                } else {
                    print("failed to send message")
                }
            })
        }
    }
    
    private func generateMessageId() -> String? {
        // Date + senderEmail + OtherUserEmail + randomInt
        guard let email = UserDefaults.standard.value(forKey: UserDefaultConstantKeys.email) as? String else { return nil }
        let dateString = Self.dateFormatter.string(from: Date())
        let newID = "\(otherUserEmail)_\(DatabaseManager.safeEmail(email))_\(dateString)"
        print("Message ID: \(newID)")
        return newID
    }
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    // To figure if chat bubble should be on right or left
    func currentSender() -> any MessageKit.SenderType {
        if let sender = sender {
            return sender
        }
        fatalError("Sender is nil, email should be cached")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> any MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
    
}
