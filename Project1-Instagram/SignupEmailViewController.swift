//
//  SignupEmailViewController.swift
//  Project1-Instagram
//
//  Created by LinChico on 1/7/18.
//  Copyright © 2018 RJTCOMPUQUEST. All rights reserved.
//

import UIKit

class SignupEmailViewController: UIViewController {
    @IBOutlet weak var centerView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var emailAddressView: UIView!
    @IBOutlet weak var  emailTextfield : UITextField!
    
    @IBOutlet weak var phoneView: UIView!
    
    @IBOutlet weak var bottomView: UIView!
    let titles = ["Email address", "Phone"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        hideKeyboardWhenTappedAround()
        setupCollectionLayout()
        nextButton.layer.cornerRadius = 5
        bottomView.addBorder(toSide: .Top, withColor: UIColor.lightGray.cgColor, andThickness: 1)
    }
    
    func setupCollectionLayout() {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        layout.itemSize = CGSize(width: collectionView.frame.width / 2, height: collectionView.frame.height)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView.collectionViewLayout = layout
        
        let indexPath = IndexPath(item: 0, section: 0)
        collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
        collectionView.backgroundColor = UIColor.clear
    }

    
    @IBAction func gotoLoginView(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func emailNextButtonAction(_ sender: Any) {
        let controller = storyboard?.instantiateViewController(withIdentifier: "signupemailvc2") as! SignupEmailViewController2
        controller.email = emailTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        navigationController?.pushViewController(controller, animated: true)
    }
}

// MARK: - ConllectionView Delegate
extension SignupEmailViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return titles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tabcell", for: indexPath) as! MenubarCollectionViewCell
        cell.myLabel.text = titles[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            emailAddressView.isHidden = false
            phoneView.isHidden = true
        } else {
            emailAddressView.isHidden = true
            phoneView.isHidden = false
        }
    }
    
}

// MARK: - TextField delegate
extension SignupEmailViewController : UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
