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

protocol EditProfileViewControllerDelegate {
    func didUpdate()
}

class EditProfileViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
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
        imageView.layer.cornerRadius = 60
        imageView.clipsToBounds = true
        imageView.image = image
        nameField.text = name
        
        dbRef = Database.database().reference()
        storageRef = Storage.storage().reference()
    }

    @IBAction func changePhotoAction(_ sender: Any) {
        // Show options for the source picker only if the camera is available.
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            presentPhotoPicker(sourceType: .photoLibrary)
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
        
        present(photoSourcePicker, animated: true)
    }
    
    func presentPhotoPicker(sourceType: UIImagePickerControllerSourceType) {
        let picker = UIImagePickerController()//init
        picker.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate//confirm to delegate that this class will implement delegate methods
        picker.sourceType = sourceType//important to tell UIImagePickerController, what source type camera or photo
        present(picker, animated: true)//not significant
    }
    
    func uploadImage() {
        if let img = imageView.image {
            let uid = Auth.auth().currentUser?.uid
            FirebaseCall.sharedInstance().uploadProfileImage(ofUser: uid!, with: img, completion: { (meta, error) in
                if (error != nil) {
                    print("\nUpload Profile Image Error: \(error!)")
                } else {
                    print("uploaded succesfully")
                    self.delegate?.didUpdate()
                }
            })
        }
    }

    @IBAction func doneAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
        
        if let user = Auth.auth().currentUser {
            // set database reference
            dbRef = Database.database().reference()
            let userTable = dbRef!.child("Users").child(user.uid)
            userTable.updateChildValues(["name": nameField.text])
            
            // set storage reference
            storageRef = Storage.storage().reference()
            
        } else {
            TWMessageBarManager.sharedInstance().showMessage(withTitle: "Error", description: "Not logged in", type: .error, duration: 4.0)
            navigationController?.popToRootViewController(animated: true)
        }
        delegate?.didUpdate()
        TWMessageBarManager.sharedInstance().hideAll()
        TWMessageBarManager.sharedInstance().showMessage(withTitle: "Success", description: "Profile edited succefully!", type: .success, duration: 3.0, statusBarStyle: UIStatusBarStyle.default)
    }
}

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    //imagePickerController delegate methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        picker.dismiss(animated: true)
        
        // We always expect `imagePickerController(:didFinishPickingMediaWithInfo:)` to supply the original image.
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        imageView.image = image
        uploadImage()
    }
    
    //imagePickerController delegate methods
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        print("cancel")
    }
}

