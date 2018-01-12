//
//  AllUsersViewController.swift
//  Project1-Instagram
//
//  Created by LinChico on 1/8/18.
//  Copyright © 2018 RJTCOMPUQUEST. All rights reserved.
//

import UIKit
import FirebaseAuth
import TWMessageBarManager

class AllUsersViewController: UIViewController {
    @IBOutlet weak var usersTable: UITableView!
    
    var users : [PublicUser] = []
    var friendsUids : [String] = []
    
    var refreshControl : UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRefreshControl()
        setupPage()
    }
    
    func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl.isEnabled = true
        refreshControl.tintColor = .white
        refreshControl.addTarget(self, action: #selector(refreshAction(_:)) , for: .valueChanged)
        usersTable.addSubview(refreshControl)
        usersTable.sectionFooterHeight = 50
    }
    
    @objc func refreshAction(_ sender: Any) {
        setupPage()
    }
    
    func setupPage() {
        let uid = (Auth.auth().currentUser?.uid)!
        FirebaseCall.sharedInstance().getFriends(ofUser: uid) { (data, error) in
            if let friendUids = data as? [String: Any] {
                var uids : [String] = []
                for (friendUid, _) in friendUids {
                    uids.append(friendUid)
                }
                self.friendsUids = uids
            }
        }
        
        FirebaseCall.sharedInstance().getAllPublicUsersDict(completion: { (data, err) in
            let dict = data as! [String: Any]
            var tempUsers: [PublicUser] = []
            for (uid, userDict) in dict {
               
                if let userDict = userDict as? [String : Any],
                    let name = userDict["name"] as? String,
                let friends = userDict["friends"] as? [String: Any] {
                    var friendsUidArr : [String] = []
                    for (friend, _) in friends {
                        friendsUidArr.append(friend)
                    }
                    let publicUser = PublicUser(uid: uid, name: name, friends: friendsUidArr)
                    tempUsers.append(publicUser)
                }
            }
            self.users = tempUsers
            DispatchQueue.main.async {
                self.usersTable.reloadData()
                self.refreshControl.endRefreshing()
            }
        })
    }
    
    @objc func followUser(sender: UIButton) {
        let userTobeFollowed = users[sender.tag].uid
        print("following \(userTobeFollowed)")
        FirebaseCall.sharedInstance().followUnfollowUser(withId: userTobeFollowed, toFollow: true) { (_, error) in
            if let err = error { print("\n\(err)") }
        }
        friendsUids.append(userTobeFollowed)
        usersTable.reloadData()
        TWMessageBarManager.sharedInstance().hideAll()
        TWMessageBarManager.sharedInstance().showMessage(withTitle: "Success", description: "Friend added succefully!", type: .success, duration: 3.0, statusBarStyle: UIStatusBarStyle.default)
    }
    
}

extension AllUsersViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = usersTable.dequeueReusableCell(withIdentifier: "publicusercell") as! FriendUserCell
        let thisUser = users[indexPath.row]
        
        cell.nameLabel.text = thisUser.uid == Auth.auth().currentUser!.uid ? "You" : thisUser.name
        
        cell.cellContainerView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        cell.cellContainerView.layer.cornerRadius = 15
        cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.width / 2
        cell.profileImageView.clipsToBounds = true
        
        if thisUser.uid == Auth.auth().currentUser!.uid {
            cell.button.setImage(UIImage(), for: .normal)
        } else if friendsUids.contains(thisUser.uid) {
            let img = #imageLiteral(resourceName: "checked-checkbox")
            cell.button.setImage(img, for: .normal)
            cell.button.isEnabled = false
        } else {
            let img = #imageLiteral(resourceName: "add-new-filled")
            cell.button.setImage(img, for: .normal)
            cell.button.tag = indexPath.row
            cell.button.isEnabled = true
            cell.button.addTarget(self, action: #selector(followUser), for: .touchUpInside)
        }
        FirebaseCall.sharedInstance().getProfileImage(ofUser: thisUser.uid) { (image, err) in
            if err != nil {
                print(err!)
                return
            }
            cell.profileImageView.image = (image as! UIImage)
        }
        return cell
    }
    
    
}

