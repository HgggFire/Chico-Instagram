//
//  EditProfileViewController.swift
//  Project1-Instagram
//
//  Created by LinChico on 1/8/18.
//  Copyright © 2018 RJTCOMPUQUEST. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase
import TWMessageBarManager
import Photos

protocol EditProfileViewControllerDelegate {
    func didUpdate()
}

class EditProfileViewController: UIViewController {

    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var nameField: UITextField!
    var image : UIImage!
    var name: String!
    var delegate: EditProfileViewControllerDelegate?
    
    var storageRef: StorageReference?
    var dbRef: DatabaseReference?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        hideKeyboardWhenTappedAround()
        setupPage()
    }
    
    
    func setupPage() {
        myImageView.layer.cornerRadius = 60
        myImageView.clipsToBounds = true
        myImageView.image = image
        nameField.text = name
        
        dbRef = Database.database().reference()
        storageRef = Storage.storage().reference()
    }

    @IBAction func changePhotoAction(_ sender: Any) {
        // Show options for the source picker only if the camera is available.
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            self.presentPhotoPicker(sourceType: .photoLibrary)
            return
        }
        
        let photoSourcePicker = UIAlertController()
        let takePhoto = UIAlertAction(title: "Take a photo", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .camera)//important step for source type
        }
        let choosePhoto = UIAlertAction(title: "Choose from gallery", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .photoLibrary)//important step for source type
        }
        
        photoSourcePicker.addAction(takePhoto)
        photoSourcePicker.addAction(choosePhoto)
        photoSourcePicker.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(photoSourcePicker, animated: true)
        
    }
    
    func presentPhotoPicker(sourceType: UIImagePickerControllerSourceType) {
        let picker = UIImagePickerController()//init
        picker.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate//confirm to delegate that this class will implement delegate methods
        picker.sourceType = sourceType//important to tell UIImagePickerController, what source type camera or photo
        present(picker, animated: true)//not significant
    }
    
    func uploadImage() {
        if let img = myImageView.image,
            let uid = Auth.auth().currentUser?.uid {
            profileImageDict[uid] = img
            FirebaseCall.shared().uploadProfileImage(ofUser: uid, with: img, completion: { (meta, error) in
                if (error != nil) {
                    print("\nUpload Profile Image Error: \(error!)")
                } else {
                    print("uploaded succesfully")
                    self.delegate?.didUpdate()
                }
            })
        }
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func doneAction(_ sender: Any) {
        
        guard let user = Auth.auth().currentUser else {
            TWMessageBarManager.sharedInstance().showMessage(withTitle: "Error", description: "Not logged in", type: .error, duration: 4.0)
            return
        }
        guard let newName = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            TWMessageBarManager.sharedInstance().showMessage(withTitle: "Error", description: "Name not valid", type: .error, duration: 4.0)
            return
        }
        
        if newName.count == 0 {
            TWMessageBarManager.sharedInstance().showMessage(withTitle: "Error", description: "Name cannot be empty", type: .error, duration: 4.0)
            return
        }
        
        userNameDict[user.uid] = newName
        delegate?.didUpdate()
        FirebaseCall.shared().updateUserName(ofUser: user.uid, name: newName)
        
        uploadImage()
        
        TWMessageBarManager.sharedInstance().hideAll()
        TWMessageBarManager.sharedInstance().showMessage(withTitle: "Success", description: "Profile edited succefully!", type: .success, duration: 3.0, statusBarStyle: UIStatusBarStyle.default)
        
        navigationController?.popViewController(animated: true)
    }
}

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    //imagePickerController delegate methods
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        picker.dismiss(animated: true)
        
        // We always expect `imagePickerController(:didFinishPickingMediaWithInfo:)` to supply the original image.
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        myImageView.image = image
    }
    
    //imagePickerController delegate methods
    @objc func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        print("cancel")
    }
}

