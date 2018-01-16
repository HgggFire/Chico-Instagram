//
//  CreatePostViewController.swift
//  Project1-Instagram
//
//  Created by LinChico on 1/9/18.
//  Copyright © 2018 RJTCOMPUQUEST. All rights reserved.
//

import UIKit

protocol CreatePostViewControllerDelegate {
    func didPost(image: UIImage, text: String)
}

class CreatePostViewController: UIViewController {
    @IBOutlet weak var postImageView: UIImageView!
    
//    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var postTextView: UITextView!
    var image : UIImage!
    var delegate: CreatePostViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        hideKeyboardWhenTappedAround()
        postImageView.image = image
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.font: UIFont(name: "Savoye Let", size: 28.0)! ]
        

//        // view move up as keyboard shows
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
//    @objc func keyboardWillShow(_ notification: Notification) {
//        if let userinfo = notification.userInfo {
//            if let keyboardSize = (userinfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
//                bottomConstraint.constant = keyboardSize.height
//            }
//            UIView.animate(withDuration: 0.1, animations: {
//                self.view.layoutIfNeeded()
//            })
//        }
//    }
//
//    @objc func keyboardWillHide(_ notification: Notification) {
//        bottomConstraint.constant = 0
//        UIView.animate(withDuration: 0.1, animations: {
//            self.view.layoutIfNeeded()
//        })
//    }
    
    @IBAction func cancelPostAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func postAction(_ sender: Any) {
        delegate?.didPost(image: image, text: postTextView.text.trimmingCharacters(in: .whitespacesAndNewlines))
        dismiss(animated: true, completion: nil)
    }
    
}

