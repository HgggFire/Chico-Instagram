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
extension UIView {
    
    // Example use: myView.addBorder(toSide: .Left, withColor: UIColor.redColor().CGColor, andThickness: 1.0)
    
    enum ViewSide {
        case Left, Right, Top, Bottom
    }
    
    func addBorder(toSide side: ViewSide, withColor color: CGColor, andThickness thickness: CGFloat) {
        
        let border = CALayer()
        border.backgroundColor = color
        
        switch side {
        case .Left: border.frame = CGRect(x: frame.minX, y: frame.minY, width: thickness, height: frame.height); break
        case .Right: border.frame = CGRect(x: frame.maxX, y: frame.minY, width: thickness, height: frame.height); break
        case .Top: border.frame = CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: thickness); break
        case .Bottom: border.frame = CGRect(x: frame.minX, y: frame.maxY, width: frame.width, height: thickness); break
        }
        
        layer.addSublayer(border)
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

}
