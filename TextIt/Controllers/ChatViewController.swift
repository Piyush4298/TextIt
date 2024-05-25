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
    private var messgaes = [Message]()
    private var sender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: UserDefaultConstantKeys.email) as? String else {
            return nil
        }
        return Sender(photoUrl: "", senderId: email, displayName: "Piyush")
    }
    
    public var isNewConversation: Bool = false
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    init(with email: String) {
        self.otherUserEmail = email
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
    }

}

extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let sender = self.sender,
              let messageId = generateMessageId() else { return }
        
        if isNewConversation {
            print("text says: \(text)")
            let message = Message(sender: sender, 
                                  messageId: messageId,
                                  sentDate: Date(),
                                  kind: .text(text))
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, firstMessage: message, completion: { [weak self] success in
                guard let self else { return }
                if success {
                    // Message sent
                } else {
                    //
                }
            })
        } else {
            
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
        return Sender(photoUrl: "", senderId: "1234", displayName: "Dummy Sender")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> any MessageKit.MessageType {
        return messgaes[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messgaes.count
    }
    
}
