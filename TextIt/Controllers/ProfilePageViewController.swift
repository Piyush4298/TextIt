//
//  ProfilePageViewController.swift
//  TextIt
//
//  Created by Piyush Pandey on 02/04/24.
//

import FBSDKLoginKit
import FirebaseAuth
import GoogleSignIn
import UIKit

class ProfilePageViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var data = ["Log Out"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = createTableHeader()
    }
    
    private func createTableHeader() -> UIView? {
        guard let email = UserDefaults.standard.value(forKey: UserDefaultConstantKeys.email) as? String else {
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(email)
        let imgPath = "images/" + safeEmail + Constants.profilePicExtension
        let headerView = UIView(frame: CGRect(x: 0,
                                        y: 0,
                                        width: self.view.width,
                                        height: 300))
        headerView.backgroundColor = .link
        let imageView = UIImageView(frame: CGRect(x: (headerView.width - 150) / 2,
                                                  y: 75,
                                                  width: 150,
                                                  height: 150))
        imageView.backgroundColor = .white
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.cornerRadius = imageView.width / 2
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        setImageFor(path: imgPath, in: imageView)
        headerView.addSubview(imageView)
        return headerView
    }
    
    private func setImageFor(path: String, in imageView: UIImageView) {
        StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
            switch result {
            case .success(let url):
                self?.downloadAndSetImage(for: imageView, with: url)
            case .failure(_):
                self?.showSnackBar(message: "Could not find image for user")
                print("Failed to get download URL")
            }
        })
    }
    
    private func downloadAndSetImage(for imageView: UIImageView, with url: URL) {
        URLSession.shared.dataTask(with: url, completionHandler: { data, _, error in
            guard let data = data, error == nil else {
                return
            }
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                imageView.image = image
            }
        }).resume()
    }
}

extension ProfilePageViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        cell.textLabel?.textColor = .red
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let actionSheet = UIAlertController(title: "Do you really want to Logout",
                                            message: "Select an option to proceed",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Log Out",
                                            style: .default,
                                            handler: { [weak self] _ in
            guard let self else { return }
            // Faceook logout
            FBSDKLoginKit.LoginManager().logOut()
            
            // Google logout
            GIDSignIn.sharedInstance.signOut()
            
            do {
                try FirebaseAuth.Auth.auth().signOut()
                
                let loginVC = LoginViewController()
                let navVC = UINavigationController(rootViewController: loginVC)
                navVC.modalPresentationStyle = .fullScreen
                present(navVC, animated: true)
            } catch {
                self.showSnackBar(message: "Failed to Logout!")
            }
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel",
                                            style: .cancel,
                                            handler: nil))
        present(actionSheet, animated: true)
    }
    
}
