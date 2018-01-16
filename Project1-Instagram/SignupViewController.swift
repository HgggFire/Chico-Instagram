//
//  SignupViewController.swift
//  Project1-Instagram
//
//  Created by LinChico on 1/7/18.
//  Copyright © 2018 RJTCOMPUQUEST. All rights reserved.
//

import UIKit

class SignupViewController: UIViewController {

    @IBOutlet weak var customFbButton: WhiteCustomFacebookButton!
    @IBOutlet weak var bottomView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        bottomView.addBorder(toSide: .Top, withColor: UIColor.lightGray.cgColor, andThickness: 1)
        setupCustomFbButton(customFacebookLoginButton: customFbButton)
        customFbButton.layer.cornerRadius = 5
    }
    
    @IBAction func gotoLoginView(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
