//
//  LoginViewController.swift
//  Project1-Instagram
//
//  Created by LinChico on 1/7/18.
//  Copyright © 2018 RJTCOMPUQUEST. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseMessaging
import TWMessageBarManager
import GoogleSignIn
import FBSDKLoginKit

class LoginViewController: UIViewController, GIDSignInUIDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var googleSigninButton: GIDSignInButton!
    @IBOutlet weak var customFbButton: CustomFacebookButton!
    
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var pwdField: UITextField!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var separaterLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        hideKeyboardWhenTappedAround()
        setup()
        setupGoogleLogin()
//        setupFacebookLogin()
        setupCustomFbButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide the navigation bar on the this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    
    func setup() {
        if let user = Auth.auth().currentUser {
            print(user.description)
            gotoHomepage()
        }
        loginButton.layer.cornerRadius = 5
        bottomView.addBorder(toSide: .Top, withColor: UIColor.black.cgColor, andThickness: 2)
        bottomView.addBorder(toSide: .Bottom, withColor: UIColor.black.cgColor, andThickness: 2)
        bottomView.addBorder(toSide: .Left, withColor: UIColor.black.cgColor, andThickness: 2)
        bottomView.addBorder(toSide: .Right, withColor: UIColor.black.cgColor, andThickness: 2)
        
        googleSigninButton.style = .wide
        googleSigninButton.layer.cornerRadius = 5
        googleSigninButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        googleSigninButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
    }
    
    
    func setupGoogleLogin() {
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
    }
    
    func setupCustomFbButton() {
        customFbButton.center = CGPoint(x: googleSigninButton.center.x, y: googleSigninButton.center.y + 50)
        customFbButton.isHighlighted = false
        customFbButton.myTextLabel.text = "Continue with Facebook"
        if let _ = FBSDKAccessToken.current() {
            checkFacebookLoginAndSetName(customFacebookLoginButton: customFbButton)
            customFbButton.addTarget(self, action: #selector(loginFirebaseWithCurrentFbToken), for: .touchUpInside)
        } else {
            customFbButton.addTarget(self, action: #selector(fbManagerLogin), for: .touchUpInside)
        }
    }
    
    @IBAction func loginAction(_ sender: Any) {
        Auth.auth().signIn(withEmail: usernameField.text!.trimmingCharacters(in: .whitespacesAndNewlines), password: pwdField.text!.trimmingCharacters(in: .whitespacesAndNewlines)) { (user, error) in
            if error == nil {TWMessageBarManager.sharedInstance().showMessage(withTitle: "Successful", description: "You have logged in succefully!", type: TWMessageBarMessageType.success, duration: 3.0, statusBarStyle: UIStatusBarStyle.default)
                print("successfully logged in")
                
                self.gotoHomepage()
            } else {
                TWMessageBarManager.sharedInstance().showMessage(withTitle: "Sign in failed", description: error!.localizedDescription, type: TWMessageBarMessageType.error, duration: 5.0, statusBarStyle: UIStatusBarStyle.default)
                print(error!.localizedDescription)
                print(error!)
            }
        }
    }
    
}

// MARK: - Google Sign in
extension LoginViewController: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
//        print("google signed in with \(user.description)")
        if error != nil {
            print("Error: \(error)")
            return
        }
        
        guard let authentication = user.authentication else {return}
        
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        Auth.auth().signIn(with: credential) { (user, error) in
            if error == nil {
                print("signed in with google")
                self.gotoHomepage()
            } else {
                print(error!)
            }
        }
    }
}

// MARK: - Textfield Delegate
extension LoginViewController : UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
