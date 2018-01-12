//
//  ProfileViewController.swift
//  Project1-Instagram
//
//  Created by LinChico on 1/8/18.
//  Copyright © 2018 RJTCOMPUQUEST. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import TWMessageBarManager
import GoogleSignIn
import FBSDKLoginKit

class ProfileViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var followingNumberLabel: UILabel!
    @IBOutlet weak var followerNumLabel: UILabel!
    @IBOutlet weak var postNumLabel: UILabel!
    @IBOutlet weak var editProfileButton: UIButton!
    var databaseRef : DatabaseReference?
    var storageRef: StorageReference?
    
    var fbName: String?
    var fbImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let _ = FBSDKAccessToken.current() {
            fetchFacebookProfile()
        }
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupPage()
    }
    
    func setupPage() {
        imageView.layer.cornerRadius = 44
        imageView.clipsToBounds = true
        
        editProfileButton.layer.borderColor = UIColor.lightGray.cgColor
        editProfileButton.layer.borderWidth = 1
        editProfileButton.layer.cornerRadius = 5
        
        if let user = Auth.auth().currentUser {
            // set database reference
            databaseRef = Database.database().reference()
            let userTable = databaseRef!.child("Users").child(user.uid)
            userTable.observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
                if let dict = snapshot.value as? [String : Any],
                    let name = dict["name"] as? String {
                    self.nameLabel.text = name
                } else if let facebookName = self.fbName {
                    self.nameLabel.text = facebookName
                    userTable.updateChildValues(["name" : facebookName])
                } else {
                    TWMessageBarManager.sharedInstance().showMessage(withTitle: "Error", description: "Failed reading user information ", type: .error, duration: 4.0)
                }
            })
            
            // set storage reference
            storageRef = Storage.storage().reference()
            getImage()
            
        } else {
            TWMessageBarManager.sharedInstance().showMessage(withTitle: "Error", description: "Not logged in", type: .error, duration: 4.0)
            navigationController?.popToRootViewController(animated: true)
        }
    }
    
    func fetchFacebookProfile() {
        print("fetch facebook profile")
        let parameters = [FacebookDataFetcher.DataType.email, FacebookDataFetcher.DataType.firstName, FacebookDataFetcher.DataType.lastName, FacebookDataFetcher.DataType.largePicture]
        
        FacebookDataFetcher.sharedInstance().fetchFacebookData(parameters: parameters) { (data, err) in
            if err != nil {
                print(err!)
                return
            }
            let resultDict = data as! [String: Any]
            self.fbImage = FacebookDataFetcher.sharedInstance().getUIImageFromData(resultDict: resultDict)
            
            if let fn = resultDict["first_name"] as? String,
                let ln = resultDict["last_name"] as? String{
                self.fbName = "\(fn) \(ln)"
            }
        }
        
//        FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "email, first_name, last_name, picture.type(large)"]).start { (connection, result, error) in
//            
//            if error != nil {
//                print (error!)
//                return
//            }
//            let resultDict = result as! [String: Any]
//            print(resultDict)
////            if let email = resultDict["email"] as? String {
////                self.emailLabel.text = email
////            }
//            
//            if let picture = resultDict["picture"] as? [String: Any], let data = picture["data"] as? [String: Any], let url = data["url"] as? String, let imageURL = URL(string: url), let imageData = NSData(contentsOf: imageURL) as Data?{
//                self.fbImage = UIImage(data: imageData)
//            }
//            
//            if let fn = resultDict["first_name"] as? String,
//                let ln = resultDict["last_name"] as? String{
//                self.fbName = "\(fn) \(ln)"
//            }
//        }
    }
    
    func getImage() {
        let userId = Auth.auth().currentUser?.uid
        FirebaseCall.sharedInstance().getProfileImage(ofUser: userId!) { (data, err) in
            if err == nil {
                self.imageView.image = data as! UIImage
            } else {
                print(err!)
            
                if let facebookImage = self.fbImage {
                    self.imageView.image = self.fbImage
                    FirebaseCall.sharedInstance().uploadProfileImage(ofUser: userId!, with: facebookImage) { (data, err) in
                            if err != nil {
                                print(err!)
                        }
                    }
                }
            }
        }
    }
    

    @IBAction func editProfileAction(_ sender: Any) {
        let controller = storyboard?.instantiateViewController(withIdentifier: "editprofilevc") as! EditProfileViewController
        controller.name = nameLabel.text
        controller.image = imageView.image
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
    }
    

    @IBAction func settingsAction(_ sender: Any) {
    }
    
    @IBAction func logoutAction(_ sender: Any) {
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

extension ProfileViewController: EditProfileViewControllerDelegate {
    func didUpdate() {
        setupPage()
    }
}
