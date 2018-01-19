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
    
    var followingUsers : [FollowedUser] = []
    @IBOutlet weak var followingTable: UITableView!
    var refreshControl : UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRefreshControl()
        
        self.refreshControl.beginRefreshing()
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
        followingTable.addSubview(refreshControl)
        followingTable.sectionHeaderHeight = 50
        followingTable.sectionFooterHeight = 50
    }
    
    @objc func refreshAction(_ sender: Any) {
        setupPage()
    }
    
    func setupPage() {
        let uid = (Auth.auth().currentUser?.uid)!
        followingTable.tableFooterView = UIView()
        FirebaseCall.sharedInstance().getFollowingUsers(ofUser: uid) { (data, error) in
            if let followingUids = data as? [String: Bool] {
                var followingList: [FollowedUser] = []
                let count = followingUids.count
                for (thisUid, _) in followingUids {
                    FirebaseCall.sharedInstance().getPublicUserDict(ofUser: thisUid, completion: { (data, err) in
                        let followedUserDict = data as! [String: Any]
                        let name = followedUserDict["name"] as! String
                        let followedUser = FollowedUser(uid: thisUid, name: name)
                        followingList.append(followedUser)
                        if (followingList.count == count) {
                            self.followingUsers = followingList.sorted() {
                                $0.name < $1.name
                            }
                            DispatchQueue.main.async {
                                self.refreshControl.endRefreshing()
                                self.followingTable.reloadData()
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
            }
        }
        followingUsers.remove(at: sender.tag)
        followingTable.reloadData()
        TWMessageBarManager.sharedInstance().hideAll()
        TWMessageBarManager.sharedInstance().showMessage(withTitle: "Success", description: "Unfollowed user succesfully!", type: .success, duration: 3.0, statusBarStyle: UIStatusBarStyle.default)
    }

}

// MARK: - Tableview Delegate
extension FollowingViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return followingUsers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = followingTable.dequeueReusableCell(withIdentifier: "friendcell") as! FriendUserCell
        let thisUser = followingUsers[indexPath.row]
        cell.nameLabel.text = thisUser.name
        cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.width / 2
        cell.profileImageView.clipsToBounds = true
        cell.profileImageView.image = #imageLiteral(resourceName: "user")
        cell.cellContainerView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let id = followingUsers[indexPath.row].uid
        let controller = storyboard?.instantiateViewController(withIdentifier: "conversationVC") as! ChatConversationViewController
        controller.toUid = id
        navigationController?.pushViewController(controller, animated: true)
    }
    
    
}
