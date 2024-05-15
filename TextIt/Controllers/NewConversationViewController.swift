//
//  NewConversationViewController.swift
//  TextIt
//
//  Created by Piyush Pandey on 02/04/24.
//

import UIKit

class NewConversationViewController: UIViewController {
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
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
        searchBar.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                            target: self,
                                                            action: #selector(dismissView))
        searchBar.becomeFirstResponder()
    }
    
    @objc private func dismissView() {
        dismiss(animated: true)
    }
    
}

extension NewConversationViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
    }
}

extension NewConversationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        return cell
    }
    
    
}
