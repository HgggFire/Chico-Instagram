//
//  FriendsViewController.swift
//  Project1-Instagram
//
//  Created by LinChico on 1/8/18.
//  Copyright © 2018 RJTCOMPUQUEST. All rights reserved.
//

import UIKit
import FirebaseAuth
import TWMessageBarManager

class FollowingViewController: UIViewController {
    
    var followingUsers : [FriendUser] = []
    @IBOutlet weak var friendsTable: UITableView!
    var refreshControl : UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRefreshControl()
        
        self.refreshControl.beginRefreshing()
        setupPage()
    }
    
    func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl.isEnabled = true
        refreshControl.tintColor = .white
        refreshControl.addTarget(self, action: #selector(refreshAction(_:)) , for: .valueChanged)
        friendsTable.addSubview(refreshControl)
        friendsTable.sectionHeaderHeight = 50
        friendsTable.sectionFooterHeight = 50
    }
    
    @objc func refreshAction(_ sender: Any) {
        setupPage()
    }
    
    func setupPage() {
        let uid = (Auth.auth().currentUser?.uid)!
        FirebaseCall.sharedInstance().getFriends(ofUser: uid) { (data, error) in
            if let friendUids = data as? [String: Any] {
                var friendList: [FriendUser] = []
                let count = friendUids.count
                for (friendUid, _) in friendUids {
                    FirebaseCall.sharedInstance().getPublicUserDict(ofUser: friendUid, completion: { (data, err) in
                        let dict = data as! [String: Any]
                        let name = dict["name"] as! String
                        let friendUser = FriendUser(uid: friendUid, name: name)
                        friendList.append(friendUser)
                        if (friendList.count == count) {
                            self.followingUsers = friendList
                            DispatchQueue.main.async {
                                self.refreshControl.endRefreshing()
                                self.friendsTable.reloadData()
                            }
                            
                        }
                    })
                }
            }
        }
        
    }
    
    @objc func unfollowUser(sender: UIButton) {
        let userTobeUnfollowed = followingUsers[sender.tag].uid
        print("deleting friend \(userTobeUnfollowed) from \(Auth.auth().currentUser!.uid)")
        FirebaseCall.sharedInstance().followUnfollowUser(withId: userTobeUnfollowed, toFollow: false) { (_, error) in
            if let err = error {
                print("\n\(err)")
                TWMessageBarManager.sharedInstance().hideAll()
                TWMessageBarManager.sharedInstance().showMessage(withTitle: "Failed", description: "Something wrong happened while unfollowing!", type: TWMessageBarMessageType.error, duration: 3.0, statusBarStyle: UIStatusBarStyle.default)
            } else {
                self.followingUsers.remove(at: sender.tag)
                DispatchQueue.main.async {
                    self.friendsTable.reloadData()
                }
                TWMessageBarManager.sharedInstance().hideAll()
                TWMessageBarManager.sharedInstance().showMessage(withTitle: "Success", description: "Unfollowed user succesfully!", type: .success, duration: 3.0, statusBarStyle: UIStatusBarStyle.default)
            }
        }
    }

}

extension FollowingViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return followingUsers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = friendsTable.dequeueReusableCell(withIdentifier: "friendcell") as! FriendUserCell
        let thisUser = followingUsers[indexPath.row]
        cell.nameLabel.text = thisUser.name
        cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.width / 2
        cell.profileImageView.clipsToBounds = true
        cell.cellContainerView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        cell.cellContainerView.layer.cornerRadius = 15
        cell.button.setImage(#imageLiteral(resourceName: "delete-filled"), for: .normal)
        cell.button.tag = indexPath.row
        cell.button.addTarget(self, action: #selector(unfollowUser), for: .touchUpInside)
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
