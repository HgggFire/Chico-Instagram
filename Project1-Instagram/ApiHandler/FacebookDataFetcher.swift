//
//  FacebookDataFetcher.swift
//  Project1-Instagram
//
//  Created by LinChico on 1/8/18.
//  Copyright © 2018 RJTCOMPUQUEST. All rights reserved.
//

import FBSDKLoginKit

typealias CompletionHandler = (Any?, Error?) -> ()

class FacebookDataFetcher {
    private static let instance = FacebookDataFetcher()
    
    private init() {}
    
    enum DataType: String {
        case email = "email"
        case firstName = "first_name"
        case lastName = "last_name"
        case largePicture = "picture.type(large)"
    }
    
    
    static func sharedInstance() -> FacebookDataFetcher {
        return instance
    }
    
    func fetchFacebookData(parameters: [DataType], completion: @escaping CompletionHandler) {
        print("fetch facebook profile")
        var parameterStr = ""
        var data : [String: Any]?
        for i in 0..<parameters.count - 1 {
            parameterStr.append(parameters[i].rawValue + ", ")
        }
        parameterStr.append(parameters[parameters.count - 1].rawValue)
        
        FBSDKGraphRequest(graphPath: "me", parameters: ["fields": parameterStr]).start { (connection, result, error) in
            data = result as? [String: Any]
//            print(data)
            completion(data, error)
        }
    }
    
    func getUIImageFromData(resultDict: [String: Any]) -> UIImage? {
        var image : UIImage?
        if let picture = resultDict["picture"] as? [String: Any], let data = picture["data"] as? [String: Any], let url = data["url"] as? String, let imageURL = URL(string: url), let imageData = NSData(contentsOf: imageURL) as Data?{
            image = UIImage(data: imageData)
        }
        return image
    }
}
