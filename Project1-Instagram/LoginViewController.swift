//
//  LoginViewController.swift
//  Project1-Instagram
//
//  Created by LinChico on 1/7/18.
//  Copyright © 2018 RJTCOMPUQUEST. All rights reserved.
//

import UIKit
import FirebaseAuth
import TWMessageBarManager
import GoogleSignIn
import FBSDKLoginKit

class LoginViewController: UIViewController, GIDSignInUIDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var googleSigninButton: GIDSignInButton!
    
    @IBOutlet weak var customFbButton: CustomFacebookButton!
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
            checkFacebookLoginAndSetName()
            customFbButton.addTarget(self, action: #selector(loginFirebaseWithCurrentFbToken), for: .touchUpInside)
        } else {
            customFbButton.addTarget(self, action: #selector(fbManagerLogin), for: .touchUpInside)
        }
    }
    
    @objc func loginFirebaseWithCurrentFbToken() {
        let token = FBSDKAccessToken.current()!
        facebookLoginFirebase(with: token)
    }
    
    func checkFacebookLoginAndSetName(){
        let parameters = [FacebookDataFetcher.DataType.firstName, FacebookDataFetcher.DataType.lastName]
        
        FacebookDataFetcher.sharedInstance().fetchFacebookData(parameters: parameters) { (data, err) in
            if err != nil {
                print (err!)
                return
            }
            let resultDict = data as! [String: Any]
            if let fn = resultDict["first_name"] as? String,
                let ln = resultDict["last_name"] as? String{
                self.customFbButton.myTextLabel.text = "Continue as \(fn) \(ln)"
            }
        }
    }
    
    @objc func fbManagerLogin() {
        FBSDKLoginManager().logIn(withReadPermissions: ["email"], from: self) { (result, err) in
            if err == nil {
                TWMessageBarManager.sharedInstance().hideAll()
                TWMessageBarManager.sharedInstance().showMessage(withTitle: "Success", description: "You have logged in with Facebook succefully!", type: .info, duration: 3.0, statusBarStyle: UIStatusBarStyle.default)
                self.facebookLoginFirebase(with: FBSDKAccessToken.current())
            } else {
                TWMessageBarManager.sharedInstance().hideAll()
                TWMessageBarManager.sharedInstance().showMessage(withTitle: "Sign in failed", description: err!.localizedDescription, type: TWMessageBarMessageType.error, duration: 5.0, statusBarStyle: UIStatusBarStyle.default)
                print("FB ERROR: \(err!)")
            }
        }
    }
    func facebookLoginFirebase(with token: FBSDKAccessToken) {
        let credential = FacebookAuthProvider.credential(withAccessToken: token.tokenString)
        Auth.auth().signIn(with: credential) { (user, error) in
            if error == nil {
                TWMessageBarManager.sharedInstance().hideAll()
                TWMessageBarManager.sharedInstance().showMessage(withTitle: "Success", description: "You have logged in with Facebook succefully!", type: .info, duration: 3.0, statusBarStyle: UIStatusBarStyle.default)
                print("successfully logged in with Facebook")
                self.gotoHomepage()
            } else {
                TWMessageBarManager.sharedInstance().hideAll()
                TWMessageBarManager.sharedInstance().showMessage(withTitle: "Facebook Sign in failed", description: error!.localizedDescription, type: TWMessageBarMessageType.error, duration: 5.0, statusBarStyle: UIStatusBarStyle.default)
                print("FB ERROR: \(error!)")
            }
        }
    }
    
    func gotoHomepage() {
        let controller = storyboard?.instantiateViewController(withIdentifier: "tabvc") as! TabBarViewController
        navigationController?.pushViewController(controller, animated: true)
    }

    @IBAction func loginAction(_ sender: Any) {
        Auth.auth().signIn(withEmail: usernameField.text!, password: pwdField.text!) { (user, error) in
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
    
    //    func setupFacebookLogin() {
    //        let fbLoginBtn = FBSDKLoginButton.init()
    //        fbLoginBtn.frame = CGRect(x: view.frame.width * 0.1, y: googleSigninButton.center.y + 50, width: view.frame.width * 0.8, height: 45)
    //        fbLoginBtn.delegate = self
    //        fbLoginBtn.readPermissions = ["email"]
    ////        view.addSubview(fbLoginBtn)
    //
    //    }
    
}

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
                let controller = self.storyboard?.instantiateViewController(withIdentifier: "tabvc") as! TabBarViewController
                self.navigationController?.pushViewController(controller, animated: true)
            } else {
                print(error!)
            }
        }
    }
}

extension LoginViewController : UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// Put this piece of code anywhere you like
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

//extension LoginViewController: FBSDKLoginButtonDelegate {
//    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
//        print("did complete with")
//        if error == nil {
//            TWMessageBarManager.sharedInstance().showMessage(withTitle: "Success", description: "You have logged in with Facebook succefully!", type: .info, duration: 3.0, statusBarStyle: UIStatusBarStyle.default)
//            facebookLoginFirebase(with: FBSDKAccessToken.current())
//        } else {
//            TWMessageBarManager.sharedInstance().showMessage(withTitle: "Sign in failed", description: error!.localizedDescription, type: TWMessageBarMessageType.error, duration: 5.0, statusBarStyle: UIStatusBarStyle.default)
//            print("FB ERROR: \(error!)")
//        }
//    }
//
//    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
//        print("did log out")
//        TWMessageBarManager.sharedInstance().showMessage(withTitle: "Logout", description: "Facebook Logged out", type: .info, duration: 3.0, statusBarStyle: UIStatusBarStyle.default)
//    }
//
//    func loginButtonWillLogin(_ loginButton: FBSDKLoginButton!) -> Bool {
//        print("will log in")
//        TWMessageBarManager.sharedInstance().showMessage(withTitle: "FB Will Login", description: "Y", type: .info, duration: 3.0, statusBarStyle: UIStatusBarStyle.default)
//        return true
//    }
//}



