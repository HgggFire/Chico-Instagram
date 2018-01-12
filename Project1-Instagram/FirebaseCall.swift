//
//  FirebaseCall.swift
//  Project1-Instagram
//
//  Created by LinChico on 1/9/18.
//  Copyright © 2018 RJTCOMPUQUEST. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

class FirebaseCall {
    static private let instance = FirebaseCall()
    
    var databaseRef : DatabaseReference!
    var storageRef: StorageReference!
    
    var profileImageDict : [String: UIImage] = [:]
    var postImageDict : [String: UIImage] = [:]
    var userNameDict : [String: String] = [:]
    
    private init () {
        databaseRef = Database.database().reference()
        storageRef = Storage.storage().reference()
    }
    
    enum FirebaseCallError: Error {
        case userAlreadyLikedPost
        case userDidNotLikePost
        case pathNotFoundInDatabase
        case noUserLoggedIn
        case alreadyFollowed
        case alreadyFollowing
        case wasNotFollowed
        case wasNotFollowing
    }
    
    static func sharedInstance() -> FirebaseCall {
        return instance
    }
    
    func getFriends(ofUser userId: String, completion: @escaping CompletionHandler) {
        let friendsRef = databaseRef.child("PublicUsers").child(userId).child("friends")
        friendsRef.observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            if let friends = snapshot.value as? [String: Any] {
                completion(friends, nil)
            }
        })
    }
    
    func getPublicUserDict(ofUser userId: String, completion: @escaping CompletionHandler) {
        let friendsRef = databaseRef.child("PublicUsers").child(userId)
        friendsRef.observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            if let dict = snapshot.value as? [String: Any] {
                completion(dict, nil)
            }
        })
    }
    
    func getAllPublicUsersDict(completion: @escaping CompletionHandler) {
        let allUsersRef = databaseRef.child("PublicUsers")
        allUsersRef.observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            if let dict = snapshot.value as? [String: Any] {
                completion(dict, nil)
            }
        })
    }
    
    
    
    func followUnfollowUser(withId user: String, toFollow: Bool, completion: @escaping CompletionHandler) {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            completion(nil, FirebaseCallError.noUserLoggedIn)
            return
        }
       // add current user to target user's followers list & increment the follower count
        databaseRef.child("PublicUsers").child(user).runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            if var userDict = currentData.value as? [String : Any] {
                var followers: Dictionary<String, Bool>
                followers = userDict["followers"] as? [String : Bool] ?? [:]
                var followerCount = userDict["followerCount"] as? Int ?? 0
                if let _ = followers[currentUid] {
                    if toFollow {
                        completion(nil, FirebaseCallError.alreadyFollowed)
                        return TransactionResult.abort()
                    } else {
                        followers.removeValue(forKey: currentUid)
                        followerCount -= 1
                    }
                } else {
                    if toFollow {
                        followerCount += 1
                        followers[currentUid] = true
                    } else {
                        completion(nil, FirebaseCallError.wasNotFollowed)
                        return TransactionResult.abort()
                    }
                }
                
                userDict["followerCount"] = followerCount as Any?
                userDict["followers"] = followers as Any?
                
                // Set value and report transaction success
                currentData.value = userDict
                completion(nil, nil)
                return TransactionResult.success(withValue: currentData)
            }
            completion(nil, FirebaseCallError.pathNotFoundInDatabase)
            return TransactionResult.success(withValue: currentData)
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
                completion(nil, error)
            }
        }
        
       
       // add target user to current user's following list
        databaseRef.child("PublicUsers").child(currentUid).runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            if var userDict = currentData.value as? [String : Any] {
                var followings: Dictionary<String, Bool>
                followings = userDict["followings"] as? [String : Bool] ?? [:]
                var followingCount = userDict["followingCount"] as? Int ?? 0
                if let _ = followings[user] {
                    if toFollow {
                        completion(nil, FirebaseCallError.alreadyFollowing)
                        return TransactionResult.abort()
                    } else { // remove from following list
                        followings.removeValue(forKey: user)
                        followingCount -= 1
                    }
                } else {
                    if toFollow { // add to following list
                        followingCount += 1
                        followings[user] = true
                    } else {
                        completion(nil, FirebaseCallError.wasNotFollowing)
                        return TransactionResult.abort()
                    }
                }
                userDict["followingCount"] = followingCount as Any?
                userDict["followings"] = followings as Any?
                
                // Set value and report transaction success
                currentData.value = userDict
                completion(nil, nil)
                return TransactionResult.success(withValue: currentData)
            }
            completion(nil, FirebaseCallError.pathNotFoundInDatabase)
            return TransactionResult.success(withValue: currentData)
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
                completion(nil, error)
            }
        }
    }
    
    func getUserName(of uid: String, completion: @escaping CompletionHandler) {
        if let name = userNameDict[uid] {
            completion(name, nil)
        } else {
            databaseRef.child("Users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
                // Get user value
                if let value = snapshot.value as? [String: Any],
                    let name = value["name"] as? String  {
                    self.userNameDict[uid] = name
                    completion(name, nil)
                }
                // ...
            }) { (error) in
                print(error.localizedDescription)
                completion(nil, error)
            }
        }
    }
    
    func getImage(inDatabase database: String, ofId id: String, completion: @escaping CompletionHandler) {
        let imageName = "\(database)/\(id).jpeg"
        let childRef = storageRef?.child(imageName)
        childRef?.getMetadata(completion: { (metadata, error) in
            if error != nil {
                completion(metadata, error)
            } else {
                if let url = metadata?.downloadURL()?.absoluteURL {
                    let image = self.downloadImageWithURL(url: url)
                    completion(image, nil)
                }
            }
        })
    }
    
    func getProfileImage(ofUser userId: String, completion: @escaping CompletionHandler) {
        if let image = profileImageDict[userId] {
            completion(image, nil)
        } else {
            getImage(inDatabase: "UserImage", ofId: userId) { (data, err) in
                if err == nil {
                    self.profileImageDict[userId] = data as? UIImage
                }
                completion(data, err)
            }
        }
    }
    
    func getPostImage(ofPost postId: String, completion: @escaping CompletionHandler) {
        if let image = postImageDict[postId] {
            completion(image, nil)
        } else {
            getImage(inDatabase: "PostImage", ofId: postId) { (data, err) in
                if err == nil {
                    self.postImageDict[postId] = data as? UIImage
                }
                completion(data, err)
            }
        }
    }
    
    func uploadImage(ofId userId: String, with img: UIImage, to database: String, completion: @escaping CompletionHandler) {
        let data = UIImageJPEGRepresentation(img, 0.8)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        let imageName = "\(database)/\(userId).jpeg"
        let childRef = storageRef?.child(imageName)
        childRef?.putData(data!, metadata: metadata, completion: { (meta, error) in
            completion(meta, error)
        })
    }
    
    func uploadProfileImage(ofUser userId: String, with img: UIImage, completion: @escaping CompletionHandler) {
        uploadImage(ofId: userId, with: img, to: "UserImage") { (meta, error) in
            completion(meta, error)
        }
    }
    
    func uploadPostImage(ofId postId: String, with img: UIImage, completion: @escaping CompletionHandler) {
        uploadImage(ofId: postId, with: img, to: "PostImage") { (meta, error) in
            completion(meta, error)
        }
    }
    
    func createPost(withImage image: UIImage, description: String, completion: @escaping CompletionHandler) {
        let key = databaseRef.child("Posts").childByAutoId().key
        let timestamp = (Date().timeIntervalSince1970)
        let userId = Auth.auth().currentUser?.uid
        let postDict = ["timestamp": timestamp, "likeCount": 0, "uid": userId!, "description": description, "likedUsers": false] as [String : Any]
        databaseRef.child("Posts").child(key).updateChildValues(postDict)
        uploadPostImage(ofId: key, with: image) { (data, err) in
            if err == nil {
                completion(key, nil)
            } else {
                completion(data, err)
            }
        }
    }
    
    func likePost(withId postId: String, completion: @escaping CompletionHandler) {
        let userId = (Auth.auth().currentUser?.uid)!
        let postRef = databaseRef.child("Posts").child(postId)
        postRef.observeSingleEvent(of: .value) { (snapshot) in
            if let postDict = snapshot.value as? [String: Any],
                let likeCount = postDict["likeCount"] as? Int
            {
                if let likedUsers = postDict["likedUsers"] as? [String: Any],
                    let _ = likedUsers[userId]{
                    completion(nil, FirebaseCallError.userAlreadyLikedPost)
                } else {
                    postRef.child("likedUsers").child(userId).setValue(userId)
                    postRef.child("likeCount").setValue(likeCount + 1)
                    completion(nil, nil)
                }
            } else {
                completion(nil, FirebaseCallError.pathNotFoundInDatabase)
            }
        }
    }
    
    func dislikePost(withId postId: String, completion: @escaping CompletionHandler) {
        let userId = (Auth.auth().currentUser?.uid)!
        let postRef = databaseRef.child("Posts").child(postId)
        postRef.observeSingleEvent(of: .value) { (snapshot) in
            if let postDict = snapshot.value as? [String: Any],
                let likeCount = postDict["likeCount"] as? Int,
                let likedUsers = postDict["likedUsers"] as? [String: Any]
            {
                if let _ = likedUsers[userId] {
                    postRef.child("likedUsers").child(userId).removeValue()
                    postRef.child("likeCount").setValue(likeCount - 1)
                    completion(nil, nil)
                } else {
                    completion(nil, FirebaseCallError.userDidNotLikePost)
                }
                
            } else {
                completion(nil, FirebaseCallError.pathNotFoundInDatabase)
            }
        }
    }
    
    func getAllPosts(completion: @escaping CompletionHandler) {
        let ref = databaseRef.child("Posts")
        ref.observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            if let dict = snapshot.value as? [String: Any] {
                completion(dict, nil)
            }
        })
    }
    
    func downloadImageWithURL(url: URL) -> UIImage! {
        do {
            let data = try NSData(contentsOf: url, options: NSData.ReadingOptions())
            return UIImage(data: data as Data)
        } catch {
            print(error)
        }
        return UIImage()
    }
    
}
