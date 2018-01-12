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
    @IBOutlet weak var profileTableView: UITableView!
    var databaseRef : DatabaseReference?
    var storageRef: StorageReference?
    
    var fbName: String?
    var fbImage: UIImage?
    
    var name: String?
    var followerNum: String?
    var followingNum: String?
    var postNum: String?
    var profileImage: UIImage?
    
    var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        if let _ = FBSDKAccessToken.current() {
//            fetchFacebookProfile()
//        }
        
        setupRefreshControl()
        profileTableView.tableFooterView = UIView()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshControl.beginRefreshing()
        setupPage()
    }
    
    func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl.isEnabled = true
        refreshControl.tintColor = mainColor
        refreshControl.addTarget(self, action: #selector(refreshAction(_:)) , for: .valueChanged)
        profileTableView.addSubview(refreshControl)
    }
    
    @objc func refreshAction(_ sender: Any) {
        setupPage()
    }
    
    func setupPage() {
        
        if let user = Auth.auth().currentUser {
            // set database reference
            databaseRef = Database.database().reference()
            let userTable = databaseRef!.child("PublicUsers").child(user.uid)
            userTable.observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
                if let dict = snapshot.value as? [String : Any],
                    let name = dict["name"] as? String,
                    let followingCount = dict["followingCount"] as? Int,
                    let followerCount = dict["followerCount"] as? Int,
                    let postCount = dict["postCount"] as? Int
                {
                    self.name = name
                    self.followerNum = "\(followerCount)"
                    self.followingNum = "\(followingCount)"
                    self.postNum = "\(postCount)"
                    DispatchQueue.main.async {
                        self.profileTableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
                        self.refreshControl.endRefreshing()
                    }
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
    
    // TODO: Move this function to the FacebookDataFetcher class
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
        
    }
    
    // TODO: after implementing custom facebook login/logout, remove this piece if
    /*
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "email, first_name, last_name, picture.type(large)"]).start { (connection, result, error) in
    
                if error != nil {
                    print (error!)
                    return
                }
                let resultDict = result as! [String: Any]
                print(resultDict)
    //            if let email = resultDict["email"] as? String {
    //                self.emailLabel.text = email
    //            }
    
                if let picture = resultDict["picture"] as? [String: Any], let data = picture["data"] as? [String: Any], let url = data["url"] as? String, let imageURL = URL(string: url), let imageData = NSData(contentsOf: imageURL) as Data?{
                    self.fbImage = UIImage(data: imageData)
                }
    
                if let fn = resultDict["first_name"] as? String,
                    let ln = resultDict["last_name"] as? String{
                    self.fbName = "\(fn) \(ln)"
                }
            }
    */
    
    // TODO: replace with FirebaseCall method
    func getImage() {
        let userId = Auth.auth().currentUser?.uid
        FirebaseCall.sharedInstance().getProfileImage(ofUser: userId!) { (data, err) in
            if err == nil {
                self.profileImage = (data as! UIImage)
            } else {
                print(err!)
            
                if let facebookImage = self.fbImage {
                    self.profileImage = self.fbImage
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
        controller.name = name ?? ""
        controller.image = profileImage ?? UIImage()
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

// TODO: Consider call setupPage() in viewWillAppear to avoid using this this uneccessary delegate
extension ProfileViewController: EditProfileViewControllerDelegate {
    func didUpdate() {
        setupPage()
    }
}

extension ProfileViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = profileTableView.dequeueReusableCell(withIdentifier: "userProfileCell") as! ProfileTopviewCell
        
        cell.profileImageView.layer.cornerRadius = 44
        cell.profileImageView.clipsToBounds = true
        cell.editProfileButton.layer.borderColor = UIColor.lightGray.cgColor
        cell.editProfileButton.layer.borderWidth = 1
        cell.editProfileButton.layer.cornerRadius = 5
        
        cell.nameLabel.text = name ?? "Name"
        cell.postCountLabel.text = postNum ?? "0"
        cell.followerCountLabel.text = followerNum ?? "0"
        cell.followingCountLabel.text = followingNum ?? "0"
        
        cell.profileImageView.image = profileImage ?? #imageLiteral(resourceName: "user")
        
        return cell
    }
    
    
}
