//
//  ChatViewController.swift
//  TextIt
//
//  Created by Piyush Pandey on 14/05/24.
//

import AVKit
import CoreLocation
import InputBarAccessoryView
import JGProgressHUD
import MessageKit
import SDWebImage
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

struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}

struct Location: LocationItem {
    var location: CLLocation
    var size: CGSize
}

class ChatViewController: MessagesViewController {
    
    private let otherUserEmail: String
    private var conversationId: String?
    private var senderPhotoURL: URL?
    private var otherUserPhotoURL: URL?
    private var messages = [Message]()
    private lazy var uploadingSpinner : JGProgressHUD = {
        let spinner = JGProgressHUD()
        spinner.textLabel.text = "Uploading.."
        return spinner
    }()
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
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationId = conversationId {
            listenForMessages(id: conversationId, shouldScrollToBottom: true)
        }
        setupInputButton()
    }
    
    private func setupInputButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 40, height: 40), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside { [weak self] _ in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentInputActionSheet() {
        messageInputBar.inputTextView.resignFirstResponder()
        let actionSheet = UIAlertController(title: "Attach Media",
                                            message: "What would you like to send?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.presentPhotoInputActionsheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self]  _ in
            self?.presentVideoInputActionsheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Location", style: .default, handler: { [weak self]  _ in
            self?.presentLocationPicker()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    private func presentLocationPicker() {
        let vc = LocationPickerViewController(coordinates: nil)
        vc.title = "Pick Location"
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.completion = { [weak self] selectedCoorindates in
            guard let self else { return }
            
            guard let messageId = self.generateMessageId(),
                  let conversationId = self.conversationId,
                  let name = self.title,
                  let selfSender = self.sender else {
                return
            }
            
            let longitude: Double = selectedCoorindates.longitude
            let latitude: Double = selectedCoorindates.latitude
            
            print("long=\(longitude) | lat= \(latitude)")
            
            let location = Location(location: CLLocation(latitude: latitude, longitude: longitude),
                                    size: .zero)
            
            let message = Message(sender: selfSender,
                                  messageId: messageId,
                                  sentDate: Date(),
                                  kind: .location(location))
            
            DatabaseManager.shared.sendMessage(to: conversationId,
                                               otherUserEmail: self.otherUserEmail,
                                               name: name,
                                               newMessage: message,
                                               completion: { success in
                if success {
                    print("sent location message")
                }
                else {
                    print("failed to send location message")
                }
            })
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func presentPhotoInputActionsheet() {
        let actionSheet = UIAlertController(title: "Attach Photo",
                                            message: "Where would you like to attach a photo from",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self.present(picker, animated: true)
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self.present(picker, animated: true)
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    private func presentVideoInputActionsheet() {
        let actionSheet = UIAlertController(title: "Attach Video",
                                            message: "Where would you like to attach a video from?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: { [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            self?.present(picker, animated: true)
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
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
        messageInputBar.inputTextView.text = nil
        if isNewConversation {
            DatabaseManager.shared.createNewConversation(with: otherUserEmail,
                                                         name: self.title ?? "User",
                                                         firstMessage: message,
                                                         completion: { [weak self] success in
                guard let self else { return }
                if success {
                    self.isNewConversation = false
                    let newConversationId = "conversation_\(message.messageId)"
                    self.conversationId = newConversationId
                    self.listenForMessages(id: newConversationId, shouldScrollToBottom: true)
                    print("message sent successfully")
                } else {
                    // Failed to Send
                    self.showSnackBar(message: "Failed to Send the message")
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
                    print("message sent successfully")
                } else {
                    // Failed to Send
                    self.showSnackBar(message: "Failed to Send the message")
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
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            imageView.sd_setImage(with: imageUrl, completed: nil)
        default:
            break
        }
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        let sender = message.sender
        
        if sender.senderId == self.sender?.senderId {
            if let currentUserImageURL = self.senderPhotoURL {
                avatarView.sd_setImage(with: currentUserImageURL, completed: nil)
            }
            else {
                guard let email = UserDefaults.standard.value(forKey: UserDefaultConstantKeys.email) as? String else { return }
                
                let safeEmail = DatabaseManager.safeEmail(email)
                let path = "images/\(safeEmail)\(Constants.profilePicExtension)"
                
                StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
                    switch result {
                    case .success(let url):
                        self?.senderPhotoURL = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                    case .failure(let error):
                        self?.showSnackBar(message: "Couldn't load avatar image")
                        print("\(error)")
                    }
                })
            }
        }
        else {
            if let otherUsrePHotoURL = self.otherUserPhotoURL {
                avatarView.sd_setImage(with: otherUsrePHotoURL, completed: nil)
            }
            else {
                let email = self.otherUserEmail
                
                let safeEmail = DatabaseManager.safeEmail(email)
                let path = "images/\(safeEmail)\(Constants.profilePicExtension)"
                
                StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
                    switch result {
                    case .success(let url):
                        self?.otherUserPhotoURL = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                    case .failure(let error):
                        self?.showSnackBar(message: "Couldn't load avatar image")
                        print("\(error)")
                    }
                })
            }
        }
        
    }
    
}

extension ChatViewController: MessageCellDelegate {
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        
        let message = messages[indexPath.section]
        switch message.kind {
        case .location(let locationData):
            let coordinates = locationData.location.coordinate
            let vc = LocationPickerViewController(coordinates: coordinates)
            
            vc.title = "Location"
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }

    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        let message = messages[indexPath.section]
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else { return}
            
            let photoVC = PhotoViewerViewController(with: imageUrl)
            self.navigationController?.pushViewController(photoVC, animated: true)
        case .video(let media):
            guard let videoUrl = media.url else { return }
            
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoUrl)
            present(vc, animated: true, completion: {
                vc.player?.play()
            })
        default:
            break
        }
    }
    
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let messageId = generateMessageId(),
              let conversationId = conversationId,
              let name = self.title,
              let selfSender = sender else {
            return
        }
        self.uploadingSpinner.show(in: self.view)
        if let image = info[.editedImage] as? UIImage, let imageData =  image.pngData() {
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
            StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName, completion: { [weak self] result in
                guard let self else { return }
                
                switch result {
                case .success(let urlString):
                    print("Uploaded Message Photo: \(urlString)")
                    
                    guard let url = URL(string: urlString),
                          let placeholder = UIImage(systemName: "plus") else {
                        return
                    }
                    
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: .zero)
                    
                    let message = Message(sender: selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .photo(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId,
                                                       otherUserEmail: self.otherUserEmail,
                                                       name: name,
                                                       newMessage: message,
                                                       completion: { success in
                        
                        if success {
                            self.messageInputBar.inputTextView.becomeFirstResponder()
                            self.uploadingSpinner.dismiss()
                            print("Sent photo message")
                        }
                        else {
                            print("Failed to send photo message")
                        }
                        
                    })
                    
                case .failure(let error):
                    print("Message photo upload error: \(error)")
                }
            })
        } else if let videoUrl = info[.mediaURL] as? URL {
            let fileName = "video_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
            
            StorageManager.shared.uploadMessageVideo(with: videoUrl, fileName: fileName, completion: { [weak self] result in
                guard let self else { return }
                
                switch result {
                case .success(let urlString):
                    print("Uploaded Message Video: \(urlString)")
                    
                    guard let url = URL(string: urlString),
                          let placeholder = UIImage(systemName: "plus") else {
                        return
                    }
                    
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: .zero)
                    
                    let message = Message(sender: selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .video(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId,
                                                       otherUserEmail: self.otherUserEmail,
                                                       name: name,
                                                       newMessage: message,
                                                       completion: { success in
                        if success {
                            self.messageInputBar.inputTextView.becomeFirstResponder()
                            self.uploadingSpinner.dismiss()
                            print("sent photo message")
                        }
                        else {
                            print("failed to send photo message")
                        }
                    })
                    
                case .failure(let error):
                    print("message photo upload error: \(error)")
                }
            })
        }
    }
}
