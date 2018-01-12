//
//  CommentViewController.swift
//  Project1-Instagram
//
//  Created by LinChico on 1/12/18.
//  Copyright © 2018 RJTCOMPUQUEST. All rights reserved.
//

import UIKit
import FirebaseAuth
import TWMessageBarManager

class CommentViewController: UIViewController {
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var commentTable: UITableView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var commentTextField: UITextField!
    
    var comments: [Comment] = []
    var refreshControl : UIRefreshControl!
    var postId: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRefreshControl()
        print(postId)
        self.refreshControl.beginRefreshing()
        commentTable.tableFooterView = UIView()
        setupPage()
//        hideKeyboardWhenTappedAround()
        // view move up as keyboard shows
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        tabBarController?.tabBar.isHidden = false
        super.viewWillDisappear(animated)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let userinfo = notification.userInfo {
            if let keyboardSize = (userinfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                bottomConstraint.constant = -keyboardSize.height
                print(keyboardSize.height)
                print(bottomConstraint.constant)
                print(bottomView.frame.maxY)
            }
            UIView.animate(withDuration: 0.1, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        bottomConstraint.constant = 0
        UIView.animate(withDuration: 0.1, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl.isEnabled = true
        refreshControl.tintColor = .white
        refreshControl.addTarget(self, action: #selector(refreshAction(_:)) , for: .valueChanged)
        commentTable.addSubview(refreshControl)
        commentTable.sectionHeaderHeight = 50
        commentTable.sectionFooterHeight = 50
    }
    
    @objc func refreshAction(_ sender: Any) {
        loadPage()
    }
    
    func setupPage() {
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.clipsToBounds = true
        
        tabBarController?.hidesBottomBarWhenPushed = true
        
        bottomView.layer.borderColor = UIColor.darkGray.cgColor
        bottomView.layer.borderWidth = 0.5
        loadPage()
    }
    
    func loadPage() {
        
        let uid = (Auth.auth().currentUser?.uid)!
        FirebaseCall.sharedInstance().getProfileImage(ofUser: uid) { (data, err) in
            if err == nil {
                self.profileImageView.image = (data as! UIImage)
            }
        }
        
        FirebaseCall.sharedInstance().getAllComments(ofPost: postId) { (data, err) in
            if err != nil {
                print()
                print(err!)
                return
            }
            
            let dict = data as! [String: Any]
            var tempComments: [Comment] = []
            for (id, commentDict) in dict {
                if let cDict = commentDict as? [String : Any],
                    let uid = cDict["uid"] as? String,
                    let timestamp = cDict["timestamp"] as? Double,
                    let description = cDict["description"] as? String,
                    let postId = cDict["postId"] as? String
                {
                    let likeCount = cDict["likeCount"] as? Int ?? 0
                    let date = Date(timeIntervalSince1970: timestamp)
                    var isLiked = false
                    if let likedUsers = cDict["likedUsers"] as? [String: Any],
                        let _ = likedUsers[Auth.auth().currentUser!.uid] {
                        isLiked = true
                    }
                    
                    let comment = Comment(id: id, description: description, likeCount: likeCount, isLiked: isLiked, uid: uid, timestamp: date, postId: postId)
                    tempComments.append(comment)
                }
            }
            self.comments = tempComments.sorted() {$0.timestamp < $1.timestamp}
            DispatchQueue.main.async {
                self.commentTable.reloadData()
                self.refreshControl.endRefreshing()
                if self.comments.count > 0 {
                    let indexPath = IndexPath(row: self.comments.count - 1, section: 0)
                    self.commentTable.scrollToRow(at: indexPath, at: UITableViewScrollPosition.bottom, animated: true)
                }
            }
            
        }
        
    }
    
    @IBAction func likeCommentAction(_ sender: UIButton) {
    }
    
    @IBAction func replyCommentAction(_ sender: UIButton) {
    }
    
    @IBAction func postButtonAction(_ sender: UIButton) {
        let commentText = commentTextField.text
        FirebaseCall.sharedInstance().createOrDeleteComment(toPost: postId, description: commentText!, toCreate: true) { (data, err) in
            if err != nil {
                print()
                print(err!)
            } else {
                self.loadPage()
            }
        }
        TWMessageBarManager.sharedInstance().hideAll(animated: true)
        TWMessageBarManager.sharedInstance().showMessage(withTitle: "Success", description: "You have posted a comment succesfully!", type: .success)
        commentTextField.text = ""
        
    }
    
}

extension CommentViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = commentTable.dequeueReusableCell(withIdentifier: "commentCell") as! CommentCell
        let comment = comments[indexPath.row]
        
        cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.width / 2
        cell.profileImageView.clipsToBounds = true
        cell.commentLabel.text = comment.description
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        cell.timeLabel.text = formatter.string(from: comment.timestamp)
        
        let likeButtonImage = comment.isLiked ? #imageLiteral(resourceName: "liked") : #imageLiteral(resourceName: "heart")
        cell.likeButton.setImage(likeButtonImage, for: .normal)
        cell.likeButton.tag = indexPath.row
        cell.profileImageView.image = #imageLiteral(resourceName: "user")
        
        FirebaseCall.sharedInstance().getUserName(of: comment.uid) { (name, err) in
            if err == nil {
                if let n = name as? String {
                    cell.commentLabel.text = "\(n): \(comment.description)"
                }
            } else {
                print()
                print(err!)
            }
        }
        
        FirebaseCall.sharedInstance().getProfileImage(ofUser: comment.uid) { (image, err) in
            if err != nil {
                print()
                print(err!)
                return
            }
            cell.profileImageView.image = (image as! UIImage)
        }
        
        return cell
    }
    
    
}
