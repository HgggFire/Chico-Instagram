//
//  SignupEmailViewController2.swift
//  Project1-Instagram
//
//  Created by LinChico on 1/7/18.
//  Copyright © 2018 RJTCOMPUQUEST. All rights reserved.
//

import UIKit
import FirebaseAuth
import TWMessageBarManager

class SignupEmailViewController2: UIViewController {
    
    var email: String!

    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var pwdField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var bottomView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        hideKeyboardWhenTappedAround()
        signupButton.layer.cornerRadius = 5
        bottomView.layer.addBorder(edge: .top, color: .darkGray, thickness: 0.5)
    }

    @IBAction func signupAction(_ sender: Any) {
        let pwd = pwdField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = nameField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if name.count == 0 {
            TWMessageBarManager.sharedInstance().showMessage(withTitle: "Sign up Failed", description: "Name cannot be empty", type: .error, duration: 5.0)
            return
        }
        
        /* sign up */
        Auth.auth().createUser(withEmail: email, password: pwd) { (firebaseUser, error) in
            if error == nil {
                if let user = firebaseUser {
                    print(user.description)
                    FirebaseCall.shared().createUserProfile(ofUser: user.uid, name: name, email: user.email)
                    TWMessageBarManager.sharedInstance().showMessage(withTitle: "Success", description: "You have successfully signed up!", type: .success, duration: 3.0)
                    
                    // Go to home page
                    let controller = self.storyboard?.instantiateViewController(withIdentifier: "tabvc") as! TabBarViewController
                    self.navigationController?.pushViewController(controller, animated: true)
                }
            } else {
                TWMessageBarManager.sharedInstance().showMessage(withTitle: "Sign up Failed", description: error!.localizedDescription, type: .error, duration: 5.0)
                print(error!.localizedDescription)
            }
        }
    }
    
    @IBAction func gotoLoginView(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
    }
}

extension SignupEmailViewController2 : UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
