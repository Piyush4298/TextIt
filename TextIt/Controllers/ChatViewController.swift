//
//  ChatViewController.swift
//  TextIt
//
//  Created by Piyush Pandey on 14/05/24.
//

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
    
    private var messgaes = [Message]()
    private let sender = Sender(photoUrl: "",
                                senderId: "1",
                                displayName: "Piyush")

    override func viewDidLoad() {
        super.viewDidLoad()
        
        messgaes.append(Message(sender: sender,
                                messageId: "1", 
                                sentDate: Date(),
                                kind: .text("Hello Bro! How r u? Hope you are doing fine, let's catch up sometime. What say? huh.")))

        // Do any additional setup after loading the view.
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }

}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    // To figure if chat bubble should be on right or left
    func currentSender() -> any MessageKit.SenderType {
        return sender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> any MessageKit.MessageType {
        return messgaes[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messgaes.count
    }
    
    
}
