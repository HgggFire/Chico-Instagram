//
//  Extensions.swift
//  Project1-Instagram
//
//  Created by LinChico on 1/13/18.
//  Copyright © 2018 RJTCOMPUQUEST. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FirebaseAuth
import FirebaseMessaging
import TWMessageBarManager
import GoogleSignIn

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

// add border to one side
extension CALayer {
    
    func addBorder(edge: UIRectEdge, color: UIColor, thickness: CGFloat) {
        
        let border = CALayer()
        
        switch edge {
        case UIRectEdge.top:
            border.frame = CGRect.init(x: 0, y: 0, width: frame.width, height: thickness)
            break
        case UIRectEdge.bottom:
            border.frame = CGRect.init(x: 0, y: frame.height - thickness, width: frame.width, height: thickness)
            break
        case UIRectEdge.left:
            border.frame = CGRect.init(x: 0, y: 0, width: thickness, height: frame.height)
            break
        case UIRectEdge.right:
            border.frame = CGRect.init(x: frame.width - thickness, y: 0, width: thickness, height: frame.height)
            break
        default:
            break
        }
        
        border.backgroundColor = color.cgColor;
        
        self.addSublayer(border)
    }
}

// custom facebook login button setup
extension UIViewController {
    func setupCustomFbButton(customFacebookLoginButton: CustomFacebookButton) {
        customFacebookLoginButton.isHighlighted = false
        customFacebookLoginButton.myTextLabel.text = "Continue with Facebook"
        if let _ = FBSDKAccessToken.current() {
            checkFacebookLoginAndSetName(customFacebookLoginButton: customFacebookLoginButton)
            customFacebookLoginButton.addTarget(self, action: #selector(loginFirebaseWithCurrentFbToken), for: .touchUpInside)
        } else {
            customFacebookLoginButton.addTarget(self, action: #selector(fbManagerLogin), for: .touchUpInside)
        }
    }
    
    // MARK: - Custom Facebook Login functions
    func checkFacebookLoginAndSetName(customFacebookLoginButton: CustomFacebookButton){
        let parameters = [FacebookDataFetcher.DataType.firstName, FacebookDataFetcher.DataType.lastName]
        
        FacebookDataFetcher.sharedInstance().fetchFacebookData(parameters: parameters) { (data, err) in
            if err != nil {
                print (err!)
                return
            }
            let resultDict = data as! [String: Any]
            if let fn = resultDict["first_name"] as? String,
                let ln = resultDict["last_name"] as? String {
                customFacebookLoginButton.myTextLabel.text = "Continue as \(fn) \(ln)"
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
    
    @objc func loginFirebaseWithCurrentFbToken() {
        let token = FBSDKAccessToken.current()!
        facebookLoginFirebase(with: token)
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
        
        Messaging.messaging().subscribe(toTopic: Auth.auth().currentUser!.uid)
        print("\n\nsubscribed to topic \(Auth.auth().currentUser!.uid)")
        let controller = storyboard?.instantiateViewController(withIdentifier: "tabvc") as! TabBarViewController
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func logout() {
        Messaging.messaging().unsubscribe(fromTopic: Auth.auth().currentUser!.uid)
        do {
            try Auth.auth().signOut()
            print("sign out succesfully")
            TWMessageBarManager.sharedInstance().showMessage(withTitle: "Success", description: "Successfully logged out", type: .info, duration: 3.0)
            navigationController?.popToRootViewController(animated: true)
            GIDSignIn.sharedInstance().signOut()
            tabBarController?.navigationController?.popToRootViewController(animated: true)
        } catch {
            TWMessageBarManager.sharedInstance().showMessage(withTitle: "Error", description: String(describing: error), type: .error, duration: 4.0)
            print(error)
        }
    }

}
