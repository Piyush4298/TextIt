//
//  ConversationsViewController.swift
//  TextIt
//
//  Created by Piyush Pandey on 02/04/24.
//

import FirebaseAuth
import UIKit

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
    let messageType: String
}

class ConversationsViewController: UIViewController {
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(ConversationTableViewCell.self,
                           forCellReuseIdentifier: ConversationTableViewCell.identifier)
        tableView.isHidden = true
        return tableView
    }()
    
    private lazy var noConversationLabel: UILabel = {
        let label = UILabel()
        label.text = "No Conversations!"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.textColor = .darkGray
        label.isHidden = true
        return label
    }()
    
    private var conversations = [Conversation]()
    private var loginObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose,
                                                            target: self,
                                                            action: #selector(didTapComposeButton))
        view.addSubview(tableView)
        view.addSubview(noConversationLabel)
        tableView.delegate = self
        tableView.dataSource = self
        startListeningForConversations()
        loginObserver = NotificationCenter.default.addObserver(forName: .didLoginNotification,
                                                               object: nil,
                                                               queue: .main,
                                                               using: { [weak self] _ in
            guard let self else { return }
            self.tabBarController?.selectedIndex = 0
            self.startListeningForConversations()
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noConversationLabel.frame = CGRect(x: 10,
                                           y: (view.height-100)/2,
                                           width: view.width-20,
                                           height: 100)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateUser()
    }
    
    private func validateUser() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let loginVC = LoginViewController()
            let nav = UINavigationController(rootViewController: loginVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }
    
    private func startListeningForConversations() {
        guard let email = UserDefaults.standard.value(forKey: UserDefaultConstantKeys.email) as? String else {
            return
        }
        print("starting conversation fetch...")
        
        let safeEmail = DatabaseManager.safeEmail(email)
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        DatabaseManager.shared.getAllConversations(for: safeEmail, completion: { [weak self] result in
            switch result {
            case .success(let conversations):
                print("successfully got conversation models")
                guard !conversations.isEmpty else {
                    self?.tableView.isHidden = true
                    self?.noConversationLabel.isHidden = false
                    return
                }
                self?.noConversationLabel.isHidden = true
                self?.tableView.isHidden = false
                self?.conversations = conversations
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                    self?.animateTableView()
                }
            case .failure(let error):
                self?.tableView.isHidden = true
                self?.noConversationLabel.isHidden = false
                print("failed to get convos: \(error)")
            }
        })
    }
    
    @objc private func didTapComposeButton() {
        let newConversationsVC = NewConversationViewController()
        newConversationsVC.userDataCompletion = { [weak self] result in
            guard let self else { return }
            
            let currentConversations = self.conversations
            
            if let targetConversation = currentConversations.first(where: {
                $0.otherUserEmail == DatabaseManager.safeEmail(result.email)
            }) {
                self.pushChatViewToNavigation(withTitle: targetConversation.name,
                                              mail: targetConversation.otherUserEmail,
                                              id: targetConversation.id)
            }
            else {
                self.createNewChatConversation(with: result)
            }
        }
        let navVC = UINavigationController(rootViewController: newConversationsVC)
        present(navVC, animated: true)
    }
    
    private func createNewChatConversation(with userData: SearchResult) {
        let name = userData.name
        let email = DatabaseManager.safeEmail(userData.email)

        DatabaseManager.shared.conversationExists(with: email, completion: { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let conversationId):
                self.pushChatViewToNavigation(withTitle: name,
                                              mail: email,
                                              id: conversationId)
            case .failure(_):
                self.pushChatViewToNavigation(withTitle: name,
                                              mail: email,
                                              id: nil ,
                                              isNewConversation: true)
            }
        })
        self.pushChatViewToNavigation(withTitle: name, mail: email, id: nil , isNewConversation: true)
    }
    
    private func pushChatViewToNavigation(withTitle name: String,
                                          mail email: String,
                                          id conversationId: String?,
                                          isNewConversation: Bool = false) {
        let chatVC = ChatViewController(with: email, id: conversationId)
        chatVC.title = name
        chatVC.isNewConversation = isNewConversation
        chatVC.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(chatVC, animated: true)
    }
    
    private func animateTableView() {
        let cells = tableView.visibleCells
        
        let tableViewHeight = tableView.bounds.size.height
        
        for cell in cells {
            cell.transform = CGAffineTransform(translationX: 0, y: tableViewHeight)
        }
        var delayCounter: Double = 0.0
        for cell in cells {
            UIView.animate(withDuration: 0.5,
                           delay: delayCounter * 0.05,
                           usingSpringWithDamping: 0.8,
                           initialSpringVelocity: 0,
                           options: .curveEaseInOut, 
                           animations: {
                cell.transform = CGAffineTransform.identity
            }, completion: nil)
            delayCounter += 1
        }
    }
}

extension ConversationsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier,
                                                    for: indexPath) as? ConversationTableViewCell {
            let conversationModel = conversations[indexPath.row]
            cell.configure(with: conversationModel)
            return cell
        }
        // Ideally shouldn't be called
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let conversationModel = conversations[indexPath.row]
        self.pushChatViewToNavigation(withTitle: conversationModel.name,
                                      mail: conversationModel.otherUserEmail,
                                      id: conversationModel.id)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let conversationId = conversations[indexPath.row].id
            tableView.beginUpdates()
            self.conversations.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            DatabaseManager.shared.deleteConversation(conversationId: conversationId, completion: { success in
                if !success {
                    
                }
            })
            tableView.endUpdates()
        }
    }
    
}

