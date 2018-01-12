//
//  PublicUser.swift
//  Project1-Instagram
//
//  Created by LinChico on 1/8/18.
//  Copyright © 2018 RJTCOMPUQUEST. All rights reserved.
//
import UIKit
struct PublicUser {
    let uid : String
    let name : String
    var isFollowed: Bool
}

struct FollowedUser {
    let uid: String
    let name: String
}

struct Comment {
    let id: String
    let description: String
    var likeCount: Int
    var isLiked: Bool
    let uid: String
    let timestamp: Date
    let postId: String
}

struct Feed {
    let id: String
    let description: String
    var likeCount: Int
    var isLiked: Bool
    let uid: String
    let timestamp: Date
}
