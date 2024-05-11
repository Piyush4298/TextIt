//
//  LoginViewController.swift
//  TextIt
//
//  Created by Piyush Pandey on 02/04/24.
//

import FBSDKLoginKit
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import UIKit

class LoginViewController: UIViewController {
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "ic_messenger_logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var emailTextField: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .continue
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.gray.cgColor
        textField.placeholder = "Email Address..."
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        textField.leftViewMode = .always
        textField.backgroundColor = .white
        return textField
    }()
    
    private lazy var passwordTextField: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .done
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.gray.cgColor
        textField.placeholder = "Password..."
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        textField.leftViewMode = .always
        textField.backgroundColor = .white
        textField.isSecureTextEntry = true
        return textField
    }()
    
    private lazy var loginButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemGreen
        button.setTitle("Log In", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private lazy var fbLoginButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "facebook-app-logo"), for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.gray.cgColor
        button.layer.shadowColor = UIColor.gray.cgColor
        button.layer.shadowOpacity = 0.7
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 2
        button.layer.masksToBounds = false
        return button
    }()
    
    private lazy var googleSignInButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "googleLogo"), for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.gray.cgColor
        button.layer.shadowColor = UIColor.gray.cgColor
        button.layer.shadowOpacity = 0.7
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 2
        button.layer.masksToBounds = false
        return button
    }()
    
    private lazy var continueLabel: UILabel = {
        let label = UILabel()
        label.text = "Or Continue with..."
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 20)
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Log In"
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didTapRegister))
        // Do any additional setup after loading the view.
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        fbLoginButton.addTarget(self, action: #selector(facebookLoginButtonTapped), for: .touchUpInside)
        googleSignInButton.addTarget(self, action: #selector(googleSignInButtonTapped), for: .touchUpInside)
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailTextField)
        scrollView.addSubview(passwordTextField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(continueLabel)
        scrollView.addSubview(fbLoginButton)
        scrollView.addSubview(googleSignInButton)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width / 3
        imageView.frame = CGRect(x: (scrollView.width - size) / 2,
                                 y: 20,
                                 width: size,
                                 height: size)
        emailTextField.frame = CGRect(x: 30,
                                      y: imageView.bottom + 10,
                                      width: scrollView.width - 60,
                                      height: 52)
        passwordTextField.frame = CGRect(x: 30,
                                         y: emailTextField.bottom + 10,
                                         width: scrollView.width - 60,
                                         height: 52)
        loginButton.frame = CGRect(x: 30, 
                                   y: passwordTextField.bottom + 20,
                                   width: scrollView.width - 60,
                                   height: 44)
        
        continueLabel.frame = CGRect(x: 30,
                                     y: loginButton.bottom + 20,
                                     width: scrollView.width - 60,
                                     height: 40)
        
        fbLoginButton.frame = CGRect(x: (scrollView.width / 2) / 2 + 20,
                                     y: continueLabel.bottom + 20,
                                     width: 48,
                                     height: 48)
        
        googleSignInButton.frame = CGRect(x: fbLoginButton.right + 30,
                                          y: continueLabel.bottom + 20,
                                          width: 48,
                                          height: 48)
    }
    
    @objc private func loginButtonTapped() {
        dismissKeyboard()
        guard let email = emailTextField.text, let password = passwordTextField.text,
              !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            self.showSnackBar(message: "Please enter valid credentials to login")
            return
        }
        // MARK: Firebase Login
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: { [weak self] authResult, error in
            guard let self else { return }
            guard let result = authResult, error == nil else {
                self.showSnackBar(message: "Error logging in, please try again")
                return
            }
            let user = result.user
            print("Logged in user: \(user.email ?? "none")")
            self.dismiss(animated: true)
        })
    }
    
    @objc private func didTapRegister() {
        let registerVC = RegisterViewController()
        navigationController?.pushViewController(registerVC, animated: true)
    }
    
    @objc private func facebookLoginButtonTapped() {
        let loginManager = LoginManager()
        loginManager.logIn(permissions: ["public_profile", "email"], from: self) { [weak self] result, error in
            guard let self else {return}
            guard let token = result?.token?.tokenString, error == nil else {
                self.showSnackBar(message: "User failed to login using Facebook!")
                return
            }
            
            let facebookGraphRequest = GraphRequest(graphPath: "me",
                                                    parameters: ["fields": "email, name"],
                                                    tokenString: token,
                                                    version: nil,
                                                    httpMethod: .get)
            
            facebookGraphRequest.start(completion: { _, result, error in
                guard let result = result as? [String: Any], error == nil else {
                    print("Failed to make facebook graph request", error!)
                    return
                }
                
                guard let userName = result["name"] as? String,
                      let email = result["email"] as? String else {
                    print("Failed to fetch name and email from facebook")
                    return
                }
                
                let nameComponents = userName.components(separatedBy: " ")
                let firstName = nameComponents[0]
                let lastName = nameComponents[nameComponents.count - 1]
                
                DatabaseManager.shared.userExists(with: email, completion: { exists in
                    if !exists {
                        DatabaseManager.shared.insertUser(with: TextItUser(firstName: firstName,
                                                                           lastName: lastName,
                                                                           emailAddress: email))
                    }
                })
                
                let credentials = FacebookAuthProvider.credential(withAccessToken: token)
                
                FirebaseAuth.Auth.auth().signIn(with: credentials, completion: { [weak self] authResult, error in
                    guard let self else { return }
                    guard let result = authResult, error == nil else {
                        self.showSnackBar(message: "Facebook credential login failed!")
                        return
                    }
                    self.dismiss(animated: true)
                })
            })
        }
    }
    
    @objc private func googleSignInButtonTapped() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Start the sign-in flow
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] result, error in
            guard let self else { return }
            if let error = error {
                print("Error signing in with google, \(error)")
                return
            }
            
            guard let user = result?.user,
                  let firstName = user.profile?.givenName,
                  let lastName = user.profile?.familyName,
                  let email = user.profile?.email,
                  let idToken = user.idToken?.tokenString
            else {
                print("Can't fetch user id or token")
                return
            }
            
            DatabaseManager.shared.userExists(with: email, completion: { exists in
                if !exists {
                    DatabaseManager.shared.insertUser(with: TextItUser(firstName: firstName,
                                                                       lastName: lastName,
                                                                       emailAddress: email))
                }
            })
            
            let credentials = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)
            
            FirebaseAuth.Auth.auth().signIn(with: credentials, completion: { [weak self] authResult, error in
                guard let self else { return }
                guard let result = authResult, error == nil else {
                    self.showSnackBar(message: "Google credential login failed!")
                    return
                }
                self.dismiss(animated: true)
            })
            
        }
    }
    
    private func dismissKeyboard() {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            loginButtonTapped()
        }
        return true
    }
}
