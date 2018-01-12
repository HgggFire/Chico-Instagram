//
//  FirstViewController.swift
//  Project1-Instagram
//
//  Created by LinChico on 1/5/18.
//  Copyright © 2018 RJTCOMPUQUEST. All rights reserved.
//

import UIKit
import TWMessageBarManager
import FirebaseAuth

class HomeFeedViewController: UIViewController {
    @IBOutlet weak var homeFeedTable: UITableView!
    var homeFeeds : [Feed] = []
    var refreshControl : UIRefreshControl!
    
    // MARK: - page loading
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupRefreshControl()
        refreshControl.beginRefreshing()
        loadPage()
        homeFeedTable.tableFooterView = UIView()
    }
    
    func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl.isEnabled = true
        refreshControl.tintColor = mainColor
        refreshControl.addTarget(self, action: #selector(refreshAction(_:)) , for: .valueChanged)
        homeFeedTable.addSubview(refreshControl)
    }
    
    
    func loadPage() {
        FirebaseCall.sharedInstance().getAllPosts { (data, err) in
            if err != nil {return}
            let dict = data as! [String: Any]
            var feeds: [Feed] = []
            for (id, postDict) in dict {
                if let pDict = postDict as? [String : Any],
                    let uid = pDict["uid"] as? String,
                    let timestamp = pDict["timestamp"] as? Double,
                    let likeCount = pDict["likeCount"] as? Int,
                    let description = pDict["description"] as? String
                {
                    let date = Date(timeIntervalSince1970: timestamp)
                    var isLiked = false
                    if let likedUsers = pDict["likedUsers"] as? [String: Any],
                        let _ = likedUsers[Auth.auth().currentUser!.uid] {
                        isLiked = true
                    }
                    
                    let feed = Feed(id: id, description: description, likeCount: likeCount, isLiked: isLiked, uid: uid, timestamp: date)
                    feeds.append(feed)
                }
            }
            self.homeFeeds = feeds.sorted() {$0.timestamp > $1.timestamp}
            DispatchQueue.main.async {
                self.homeFeedTable.reloadData()
                self.refreshControl.endRefreshing()
            }
            
        }
    }
    
    // MARK: - Events Actions
    @objc func refreshAction(_ sender: Any) {
        loadPage()
    }
    
    @IBAction func likeButtonAction(_ sender: UIButton) {
        if homeFeeds[sender.tag].isLiked {
            homeFeeds[sender.tag].likeCount -= 1
            homeFeeds[sender.tag].isLiked = false
            FirebaseCall.sharedInstance().dislikePost(withId: homeFeeds[sender.tag].id, completion: { (data, err) in })
        } else {
            homeFeeds[sender.tag].likeCount += 1
            homeFeeds[sender.tag].isLiked = true
            FirebaseCall.sharedInstance().likePost(withId: homeFeeds[sender.tag].id) { (data, err) in}
        }
        homeFeedTable.reloadRows(at: [IndexPath(row: sender.tag, section: 0)], with: .none)
    }
    
    @IBAction func commentButtonAction(_ sender: UIButton) {
        let controller = storyboard?.instantiateViewController(withIdentifier: "commentVC") as! CommentViewController
        controller.postId = homeFeeds[sender.tag].id
        navigationController?.pushViewController(controller, animated: true)
    }
    
    @IBAction func addFeedAction(_ sender: Any) {
        // Show options for the source picker only if the camera is available.
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            presentPhotoPicker(sourceType: .photoLibrary)
            return
        }
        
        let photoSourcePicker = UIAlertController()
        let takePhoto = UIAlertAction(title: "Take a Photo", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .camera)//important step for source type
        }
        let choosePhoto = UIAlertAction(title: "Choose from Gallery", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .photoLibrary)//important step for source type
        }
        
        photoSourcePicker.addAction(takePhoto)
        photoSourcePicker.addAction(choosePhoto)
        photoSourcePicker.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(photoSourcePicker, animated: true)
    }
    
}

// MARK: - Tableview Delegate
extension HomeFeedViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return homeFeeds.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = homeFeedTable.dequeueReusableCell(withIdentifier: "homefeedcell") as! HomeFeedCell
        let feed = homeFeeds[indexPath.row]
        cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.height / 2
        cell.profileImageView.clipsToBounds = true
        cell.descriptionLabel.text = feed.description
        cell.likeCountLabel.text = "\(feed.likeCount) likes"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm dd MMM yyyy"
        
        cell.timestampLabel.text = formatter.string(from: feed.timestamp)
        cell.postImageView.clipsToBounds = true
        cell.likeButton.tag = indexPath.row
        let likeButtonImage = feed.isLiked ? #imageLiteral(resourceName: "liked") : #imageLiteral(resourceName: "heart")
        cell.likeButton.setImage(likeButtonImage, for: .normal)
        
        cell.commentButton.tag = indexPath.row
        
        cell.postImageView.image = #imageLiteral(resourceName: "defaultImage")
        cell.profileImageView.image = #imageLiteral(resourceName: "user")
        FirebaseCall.sharedInstance().getUserName(of: feed.uid) { (name, err) in
            if err == nil {
                if let n = name as? String {
                    cell.nameLabel.text = n
                }
            } else {
                print()
                print(err!)
            }
        }
        
        FirebaseCall.sharedInstance().getProfileImage(ofUser: feed.uid) { (image, err) in
            if err != nil {
                print()
                print(err!)
                return
            }
            cell.profileImageView.image = (image as! UIImage)
        }
        
        FirebaseCall.sharedInstance().getPostImage(ofPost: feed.id) { (image, err) in
            if err != nil {
                print()
                print(err!)
                return
            }
            cell.postImageView.image = (image as! UIImage)
        }
        return cell
    }
}

// MARK: - CreatePost VC Delegate
extension HomeFeedViewController: CreatePostViewControllerDelegate {
    func didPost(image: UIImage, text: String) {
        FirebaseCall.sharedInstance().createOrDeletePost(withImage: image, description: text, toCreate: true) { (key, err) in
            if err == nil {
                self.loadPage()
                TWMessageBarManager.sharedInstance().hideAll()
                TWMessageBarManager.sharedInstance().showMessage(withTitle: "Success", description: "Post published succefully!", type: .success, duration: 3.0, statusBarStyle: UIStatusBarStyle.default)
            } else {
                print()
                print(err!)
                TWMessageBarManager.sharedInstance().hideAll()
                TWMessageBarManager.sharedInstance().showMessage(withTitle: "Error", description: "\(err!)", type: .error, duration: 3.0, statusBarStyle: UIStatusBarStyle.default)
            }
        }
    }
    
}

// MARK: - Image Picker
extension HomeFeedViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    //imagePickerController delegate methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        picker.dismiss(animated: true)
        
        // We always expect `imagePickerController(:didFinishPickingMediaWithInfo:)` to supply the original image.
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        let controller = storyboard?.instantiateViewController(withIdentifier: "createFeedVC") as! CreatePostViewController
        controller.image = image
        controller.delegate = self
        present(controller, animated: true, completion: nil)
    }
    
    //imagePickerController delegate methods
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        print("cancel")
    }
    
    func presentPhotoPicker(sourceType: UIImagePickerControllerSourceType) {
        let picker = UIImagePickerController()//init
        picker.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate//confirm to delegate that this class will implement delegate methods
        picker.sourceType = sourceType//important to tell UIImagePickerController, what source type camera or photo
        present(picker, animated: true)//not significant
    }
}

