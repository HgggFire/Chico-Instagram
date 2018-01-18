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
//    var followingUids : [String] = []
    
    var refreshControl : UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRefreshControl()
        setupPage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl.isEnabled = true
        refreshControl.tintColor = .white
        refreshControl.addTarget(self, action: #selector(refreshAction(_:)) , for: .valueChanged)
        usersTable.addSubview(refreshControl)
        usersTable.sectionFooterHeight = 50
    }
    
    
    func setupPage() {
        usersTable.tableFooterView = UIView()
        let uid = (Auth.auth().currentUser?.uid)!
//        FirebaseCall.sharedInstance().getFollowingUsers(ofUser: uid) { (data, error) in
//            if let followingUserId = data as? [String: Bool] {
//                var uids : [String] = []
//                for (friendUid, _) in followingUserId {
//                    uids.append(friendUid)
//                }
//                self.followingUids = uids
//            }
//        }
        
        FirebaseCall.sharedInstance().getAllPublicUsersDict(completion: { (data, err) in
            if err != nil {
                print()
                print(err!)
                return
            }
            let dict = data as! [String: Any]
            var tempUsers: [PublicUser] = []
            for (publicUserId, userDict) in dict {
               
                if let userDict = userDict as? [String : Any],
                    let name = userDict["name"] as? String {
                    var followers : [String: Bool]
                    followers = userDict["followers"] as? [String: Bool] ?? [:]
                    let followed = followers[uid] ?? false
                    let publicUser = PublicUser(uid: publicUserId, name: name, isFollowed: followed)
                    tempUsers.append(publicUser)
                }
            }
            self.users = tempUsers.sorted(by: {$0.name < $1.name})
            DispatchQueue.main.async {
                self.usersTable.reloadData()
                self.refreshControl.endRefreshing()
            }
        })
    }
    
    
    @objc func refreshAction(_ sender: Any) {
        setupPage()
    }
    
    @objc func followUser(sender: UIButton) {
        let userTobeFollowed = users[sender.tag].uid
        print("following \(userTobeFollowed)")
        FirebaseCall.sharedInstance().followUnfollowUser(withId: userTobeFollowed, toFollow: true) { (_, error) in
            if let err = error { print("\n\(err)") }
            
        }
        users[sender.tag].isFollowed = true
        //        followingUids.append(userTobeFollowed)
        usersTable.reloadRows(at: [IndexPath(row: sender.tag, section: 0)], with: .none)
        TWMessageBarManager.sharedInstance().hideAll()
        TWMessageBarManager.sharedInstance().showMessage(withTitle: "Success", description: "Followed succefully!", type: .success, duration: 3.0, statusBarStyle: UIStatusBarStyle.default)
    }
    
}

// MARK: - Tableview Delegate
extension AllUsersViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = usersTable.dequeueReusableCell(withIdentifier: "publicusercell") as! FriendUserCell
        let thisUser = users[indexPath.row]
        
        cell.nameLabel.text = thisUser.uid == Auth.auth().currentUser!.uid ? "You" : thisUser.name
        
        cell.cellContainerView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
//        cell.cellContainerView.layer.cornerRadius = 15
        cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.width / 2
        cell.profileImageView.clipsToBounds = true
        cell.profileImageView.image = #imageLiteral(resourceName: "user")
        if thisUser.uid == Auth.auth().currentUser!.uid {
            cell.button.setImage(UIImage(), for: .normal)
        } else if thisUser.isFollowed { // TODO: think: use thisUser.isFollowed or use followingUids.contains(thisUser.uid). Which one is more efficient?
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

