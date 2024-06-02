//
//  NewConversationViewController.swift
//  TextIt
//
//  Created by Piyush Pandey on 02/04/24.
//

import UIKit
import JGProgressHUD

struct SearchResult {
    let name: String
    let email: String
}

class NewConversationViewController: UIViewController {
    
    public var userDataCompletion: ( (SearchResult) -> (Void))?
    private let spinner = JGProgressHUD(style: .dark)
    
    private var users = [[String: String]]()
    private var results = [SearchResult]()
    private var hasFetched: Bool = false
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(NewConversationsTableViewCell.self,
                           forCellReuseIdentifier: NewConversationsTableViewCell.identifier)
        tableView.isHidden = true
        return tableView
    }()
    
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search for Users..."
        return searchBar
    }()
    
    private lazy var noResultsLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.text = "No Users found..."
        label.textAlignment = .center
        label.textColor = .black
        label.font = .systemFont(ofSize: 25, weight: .medium)
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        // Do any additional setup after loading the view.
        view.addSubview(noResultsLabel)
        view.addSubview(tableView)
        searchBar.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                            target: self,
                                                            action: #selector(dismissView))
        searchBar.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.frame = view.bounds
        noResultsLabel.frame = CGRect(x: view.width / 4,
                                      y: (view.height - 200) / 2,
                                      width: view.width / 2,
                                      height: 200)
    }
    
    @objc private func dismissView() {
        dismiss(animated: true)
    }
    
    private func searchUsers(query: String) {
        if hasFetched {
            filterUsers(with: query)
        } else {
            DatabaseManager.shared.fetchUsers(completion: { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let users):
                    self.users = users
                    self.hasFetched = true
                    self.filterUsers(with: query)
                case .failure(let error):
                    print("No users found. \(error)")
                }
            })
        }
    }
    
    private func filterUsers(with term: String) {
        guard let currentUserEmail = UserDefaults.standard.value(forKey: UserDefaultConstantKeys.email) as? String,
              hasFetched else { return }
        
        spinner.dismiss()
        let safeEmail = DatabaseManager.safeEmail(currentUserEmail)
        let filteredUsers: [SearchResult] = users.filter({
            guard let email = $0["email"], email != safeEmail else {
                return false
            }
            
            guard let name = $0["name"]?.lowercased() else {
                return false
            }
            
            return name.contains(term.lowercased())
        }).compactMap({
            
            guard let email = $0["email"],
                  let name = $0["name"] else {
                return nil
            }
            return SearchResult(name: name, email: email)
        })
        self.results = filteredUsers
        updateUI()
    }
    
    private func updateUI() {
        if results.isEmpty {
            self.noResultsLabel.isHidden = false
            self.tableView.isHidden = true
        } else {
            self.noResultsLabel.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
}

extension NewConversationViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let inputText = searchBar.text, !(inputText.replacingOccurrences(of: " ", with: "")).isEmpty else {
            return
        }
        searchBar.resignFirstResponder()
        results.removeAll()
        spinner.show(in: self.view)
        searchUsers(query: inputText)
    }
}

extension NewConversationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationsTableViewCell.identifier,
                                                 for: indexPath) as! NewConversationsTableViewCell
        let model = results[indexPath.row]
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let targetUserData = results[indexPath.row]
        dismiss(animated: true, completion: { [weak self] in
            guard let self else { return }
            self.userDataCompletion?(targetUserData)
        })
    }
}
