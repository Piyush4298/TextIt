//
//  ProfilePageViewController.swift
//  TextIt
//
//  Created by Piyush Pandey on 02/04/24.
//

import FBSDKLoginKit
import FirebaseAuth
import GoogleSignIn
import SDWebImage
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.tableHeaderView = createTableHeader()
    }
    
    private func createTableHeader() -> UIView? {
        guard let email = UserDefaults.standard.value(forKey: UserDefaultConstantKeys.email) as? String else {
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(email)
        let imgPath = "images/" + safeEmail + Constants.profilePicExtension
        let headerView = UIImageView(frame: CGRect(x: 0,
                                        y: 0,
                                        width: self.view.width + 40,
                                        height: 300))
        headerView.contentMode = .scaleAspectFill
        headerView.image = UIImage(named: "profile_background")
        
        let outerView = UIView(frame: CGRect(x: (headerView.width - 150) / 2,
                                             y: 75,
                                             width: 150,
                                             height: 150))
        outerView.clipsToBounds = false
        outerView.layer.shadowColor = UIColor.black.cgColor
        outerView.layer.shadowOpacity = 1
        outerView.layer.shadowRadius = outerView.width / 2
        outerView.layer.shadowOffset = CGSize(width: 5, height: 5)
        
        outerView.layer.shadowPath = UIBezierPath(roundedRect: outerView.bounds, cornerRadius: outerView.width / 2).cgPath
        
        let imageView = UIImageView(frame: outerView.bounds)
        imageView.backgroundColor = .white
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 4
        imageView.layer.cornerRadius = imageView.width / 2
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        setImageFor(path: imgPath, in: imageView)
        headerView.addSubview(outerView)
        outerView.addSubview(imageView)
        applyMotionEffect(to: imageView, of: -20)
        applyMotionEffect(to: headerView, of: 10)
        return headerView
    }
    
    private func applyMotionEffect(to view: UIView, of magnitude: CGFloat) {
        let xMotion = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        xMotion.minimumRelativeValue = -magnitude
        xMotion.maximumRelativeValue = magnitude
        
        let yMotion = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        yMotion.minimumRelativeValue = -magnitude
        yMotion.maximumRelativeValue = magnitude
        
        let group = UIMotionEffectGroup()
        group.motionEffects = [xMotion, yMotion]
        view.addMotionEffect(group)
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
        DispatchQueue.main.async {
            imageView.sd_setImage(with: url)
        }
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
