//
//  SignupEmailViewController2.swift
//  Project1-Instagram
//
//  Created by LinChico on 1/7/18.
//  Copyright © 2018 RJTCOMPUQUEST. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import TWMessageBarManager

class SignupEmailViewController2: UIViewController {
    
    var email: String!

    @IBOutlet weak var pwdField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    
    var usersTableRef: DatabaseReference?
    var publicUsersTableRef: DatabaseReference?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        hideKeyboardWhenTappedAround()
        usersTableRef = Database.database().reference().child("Users")
        publicUsersTableRef = Database.database().reference().child("PublicUsers")
    }

    @IBAction func signupAction(_ sender: Any) {
        let pwd = pwdField.text!
        let name = nameField.text!
        
        if name.count == 0 {
            TWMessageBarManager.sharedInstance().showMessage(withTitle: "Sign up Failed", description: "Name cannot be empty", type: .error, duration: 5.0)
            return
        }
        
        /* sign up */
        Auth.auth().createUser(withEmail: email, password: pwd) { (firebaseUser, error) in
            if error == nil {
                if let user = firebaseUser {
                    print(user.description)
                    let userDict = ["name": name, "email": user.email]
                    self.usersTableRef?.child(user.uid).updateChildValues(userDict)
                
                    let puserDict = ["name": name, "followerCount": 0, "followingCount" : 0, "postCount": 0] as [String : Any]
                    self.publicUsersTableRef?.child(user.uid).updateChildValues(puserDict)
                    
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

}

extension SignupEmailViewController2 : UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
