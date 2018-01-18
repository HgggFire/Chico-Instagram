//
//  ChatConversationViewController.swift
//  Project1-Instagram
//
//  Created by LinChico on 1/17/18.
//  Copyright © 2018 RJTCOMPUQUEST. All rights reserved.
//

//
//  ViewController.swift
//  D14_ChatView_textfield
//
//  Created by LinChico on 12/18/17.
//  Copyright © 2017 RJTCOMPUQUEST. All rights reserved.
//

import UIKit
import FirebaseAuth

class ChatConversationViewController: UIViewController {
    
    @IBOutlet weak var viewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var messageTextView: UIView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var messageTable: UITableView!
    @IBOutlet weak var chatTextField: UITextField!
    var messages : [Message] = []
    var selfUid: String!
    var toUid : String!
    var selfName: String?
    
    var refreshControl : UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        selfUid = Auth.auth().currentUser!.uid
        setupRefreshControl()
        setupPage()
        hideKeyboardWhenTappedOutsideMessageView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        tabBarController?.tabBar.isHidden = true
        loadPage()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    func setupPage() {
        bottomView.layer.addBorder(edge: .top, color: UIColor.lightGray, thickness: 0.5)
        bottomView.backgroundColor = UIColor(white: 0.9, alpha: 1)
        
        messageTextView.layer.cornerRadius = messageTextView.frame.height / 2
        messageTextView.clipsToBounds = true
        messageTextView.layer.borderColor = UIColor.darkGray.cgColor
        messageTextView.layer.borderWidth = 0.5
        
        sendButton.titleLabel?.textColor = mainColor
        
       FirebaseCall.sharedInstance().getUserName(of: toUid, completion: { (data, err) in
        if err == nil {
            self.navigationItem.title = data as? String
        }
        })
        FirebaseCall.sharedInstance().getUserName(of: selfUid, completion: { (data, err) in
            if err == nil {
                self.selfName = data as? String
            }
        })
        
        
    }
    
    func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl.isEnabled = true
        refreshControl.tintColor = mainColor
        refreshControl.addTarget(self, action: #selector(refreshAction(_:)) , for: .valueChanged)
        messageTable.addSubview(refreshControl)
        messageTable.sectionHeaderHeight = 50
        messageTable.sectionFooterHeight = 50
    }
    
    @objc func refreshAction(_ sender: Any) {
        loadPage()
    }
    
    func loadPage() {
        FirebaseCall.sharedInstance().getMessages(ofUser1: selfUid, user2: toUid) { (data, err) in
            if err != nil {
                print()
                print(err!)
                return
            }
            
            let dict = data as! [String: Any]
            var tempMessages: [Message] = []
            for (_, messageDict) in dict {
                if let mDict = messageDict as? [String : Any],
                    let senderId = mDict["senderId"] as? String,
                    let text = mDict["text"] as? String,
                    let timestamp = mDict["timestamp"] as? Double {
                    let date = Date(timeIntervalSince1970: timestamp)
                    
                    let message = Message(senderId: senderId, text: text, timestamp: date)
                    tempMessages.append(message)
                }
            }
            tempMessages = tempMessages.sorted() {$0.timestamp < $1.timestamp}
            DispatchQueue.main.async {
                self.messages = tempMessages
                self.messageTable.reloadData()
                self.refreshControl.endRefreshing()
                if self.messages.count > 0 {
                    let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                    self.messageTable.scrollToRow(at: indexPath, at: .bottom, animated: true)
                }
            }
        }
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let userinfo = notification.userInfo {
            if let keyboardSize = (userinfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                viewBottomConstraint.constant = keyboardSize.height
            }
            UIView.animate(withDuration: 0.1, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        viewBottomConstraint.constant = 0
        UIView.animate(withDuration: 0.1, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    @IBAction func submitAction(_ sender: UIButton) {
        if chatTextField.text!.count == 0 {return}
        let message = chatTextField.text!
        messages.append(Message(senderId: selfUid, text: message, timestamp: Date(timeIntervalSince1970: Date().timeIntervalSince1970)))
        FirebaseCall.sharedInstance().storeChatMessage(fromUser: selfUid, toUser: toUid, text: message)
        chatTextField.text = ""
        messageTable.reloadData()
        if message.count > 0 {
            let indexPath = IndexPath(row: messages.count - 1, section: 0)
            messageTable.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
        
        // send notification
        if let name = selfName {
            FirebaseCall.sharedInstance().notifyMessage(toUser: toUid, title: name, body: message)
        }
    }
    
    
    func hideKeyboardWhenTappedOutsideMessageView() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        messageTable.addGestureRecognizer(tap)
    }
}

extension ChatConversationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        submitAction(UIButton())
        return true
    }
}

extension ChatConversationViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        let cell : ChatCell!
        if (message.senderId == selfUid) {
            cell = messageTable.dequeueReusableCell(withIdentifier: "mycell") as! ChatCell
            
            cell.profileImage.image = profileImageDict[selfUid]
        } else {
            cell = messageTable.dequeueReusableCell(withIdentifier: "hiscell") as! ChatCell
            cell.profileImage.image = profileImageDict[toUid]
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        cell.timeLabel.text = formatter.string(from: message.timestamp)
        
        cell.messageLabel.text = message.text
        cell.profileImage.layer.cornerRadius = cell.profileImage.frame.width / 2
        cell.profileImage.clipsToBounds = true
        cell.labelContainerView.layer.cornerRadius = 5
        return cell
    }
    
}


