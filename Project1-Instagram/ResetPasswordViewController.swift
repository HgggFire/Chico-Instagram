//
//  ResetPasswordViewController.swift
//  Project1-Instagram
//
//  Created by LinChico on 1/12/18.
//  Copyright © 2018 RJTCOMPUQUEST. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import TWMessageBarManager
import FirebaseAuth

class ResetPasswordViewController: UIViewController {
    @IBOutlet weak var emailView: UIView!
    
    @IBOutlet weak var sendLinkButton: UIButton!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var tabCollectionView: UICollectionView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var lockImageView: UIImageView!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var customFacebookLoginButton: WhiteCustomFacebookButton!
    
    let titles = ["Email", "Phone"]
    let helpTexts = ["Enter your username or email address and we'll send you a link to get back into your account", "Enter you phone number and we'll send you a password reset link to get back into your account."]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupPage()
        setupCollectionLayout()
        setupCustomFbButton(customFacebookLoginButton: customFacebookLoginButton)
        hideKeyboardWhenTappedAround()
    }
    
    func setupPage() {
        var images : [UIImage] = []
        for i in 0...15 {
            images.append(UIImage(named: String(format: "frame_%02d_delay-0.1s", i))!)
        }
        backgroundImageView.image = UIImage.animatedImage(with: images, duration: 1.8)
        
        
        
        lockImageView.image = UIImage(named: "lock")?.withRenderingMode(.alwaysTemplate)
        lockImageView.tintColor = UIColor.white
        
        let color = UIColor(white: 1, alpha: 0.2)
        emailTextField.backgroundColor = color
        emailTextField.attributedPlaceholder = NSAttributedString(string: "Email Address", attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
        bottomView.backgroundColor = color
        
        sendLinkButton.layer.borderColor = alphaWhite.cgColor
        sendLinkButton.layer.borderWidth = 1
        sendLinkButton.layer.cornerRadius = 5
    }
    
    func setupCollectionLayout() {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        layout.itemSize = CGSize(width: tabCollectionView.frame.width / 2, height: tabCollectionView.frame.height)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        tabCollectionView.collectionViewLayout = layout
        
        let indexPath = IndexPath(item: 0, section: 0)
        tabCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
        tabCollectionView.backgroundColor = UIColor.clear
    }
    
    @IBAction func facebookLoginAction(_ sender: Any) {
    }
    @IBAction func sendEmailAction(_ sender: Any) {
    }
    @IBAction func backToLoginAction(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
    }
    
}

extension ResetPasswordViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return titles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tabcell", for: indexPath) as! ResetMenubarCollectionViewCell
        cell.myLabel.text = titles[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        topLabel.text = helpTexts[indexPath.item]
        
//        if indexPath.item == 0 {
//            emailView.isHidden = false
//            phoneView.isHidden = true
//        } else {
//            emailView = true
//            phoneView.isHidden = false
//        }
    }
    
    
}
