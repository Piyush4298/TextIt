//
//  ConversationsViewController.swift
//  TextIt
//
//  Created by Piyush Pandey on 02/04/24.
//

import FirebaseAuth
import UIKit

class ConversationsViewController: UIViewController {
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
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
        fetchConversations()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateUser()
    }
    
    private func fetchConversations() {
        tableView.isHidden = false
    }
    
    private func validateUser() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let loginVC = LoginViewController()
            let nav = UINavigationController(rootViewController: loginVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }
    
    @objc private func didTapComposeButton() {
        let newConversationsVC = NewConversationViewController()
        newConversationsVC.userDataCompletion = { [weak self] result in
            print("---> Result :\(result)")
            self?.createNewChatConversation(with: result)
        }
        let navVC = UINavigationController(rootViewController: newConversationsVC)
        present(navVC, animated: true)
    }
    
    private func createNewChatConversation(with userData: [String: String]) {
        guard let name = userData["name"],
              let email = userData["email"] else { return  }
        self.pushChatViewToNavigation(withTitle: name, and: email, isNewConversation: true)
    }
    
    private func pushChatViewToNavigation(withTitle name: String,
                                          and email: String,
                                          isNewConversation: Bool = false) {
        let chatVC = ChatViewController(with: email)
        chatVC.title = name
        chatVC.isNewConversation = isNewConversation
        chatVC.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(chatVC, animated: true)
    }
}

extension ConversationsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "Dummy text"
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.pushChatViewToNavigation(withTitle: "Piyush", and: "abc@gmail.com")
    }
    
}

