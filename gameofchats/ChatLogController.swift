
import UIKit
import Firebase
import FirebaseMessaging
import SwiftyJSON
import Alamofire
import MobileCoreServices
import JSQMessagesViewController
class ChatLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var user: User? {
        didSet {
            navigationItem.title = user?.name
            
            observeMessages()
        }
    }
    
    var messages = [Message]()
    
    func observeMessages() {
        guard let uid = FIRAuth.auth()?.currentUser?.uid, toId = user?.id else {
            return
        }
        
        let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(uid).child(toId)
        userMessagesRef.observeEventType(.ChildAdded, withBlock: { (snapshot) in
            
            let messageId = snapshot.key
            let messagesRef = FIRDatabase.database().reference().child("messages").child(messageId)
            messagesRef.observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                
                guard let dictionary = snapshot.value as? [String: AnyObject] else {
                    return
                }
                
                //                var verdad: Bool = true
                //
                //                vato.isFriendly = false
                //                ese.noEsFriendly = verdad
                
                self.messages.append(Message(dictionary: dictionary))
                dispatch_async(dispatch_get_main_queue(), {
                    self.collectionView?.reloadData()
                    //scroll to the last index
                    let indexPath = NSIndexPath(forItem: self.messages.count - 1, inSection: 0)
                    self.collectionView?.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
                })
                
                }, withCancelBlock: nil)
            
            }, withCancelBlock: nil)
    }
    
    lazy var inputTextField: UITextField = {
        var textField = UITextField()
        textField.placeholder = "Enter message..."
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        return textField
    }()
    
    let cellId = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let translateMessageToEnglishButton = UIBarButtonItem(title: "🇲🇽💯", style: .Plain, target: self, action: #selector(ChatLogController.translateToEnglish))
        // let preferred over var here
        navigationItem.rightBarButtonItem = translateMessageToEnglishButton

        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        //        collectionView?.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        collectionView?.alwaysBounceVertical = true
        collectionView?.backgroundColor = UIColor.blackColor()
        collectionView?.registerClass(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        
        collectionView?.keyboardDismissMode = .Interactive
        
        setupKeyboardObservers()
    }
    
    lazy var inputContainerView: UIView = {
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50)
        containerView.backgroundColor = UIColor.whiteColor()
        
        let uploadImageView = UIImageView()
        uploadImageView.userInteractionEnabled = true
        uploadImageView.image = UIImage(named: "upload_image_icon")
        uploadImageView.translatesAutoresizingMaskIntoConstraints = false
        uploadImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleUploadTap)))
        containerView.addSubview(uploadImageView)
        //x,y,w,h
        uploadImageView.leftAnchor.constraintEqualToAnchor(containerView.leftAnchor).active = true
        uploadImageView.centerYAnchor.constraintEqualToAnchor(containerView.centerYAnchor).active = true
        uploadImageView.widthAnchor.constraintEqualToConstant(44).active = true
        uploadImageView.heightAnchor.constraintEqualToConstant(44).active = true
        
        let sendButton = UIButton(type: .System)
        sendButton.setTitle("🇺🇸💯", forState: .Normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(handleSend), forControlEvents: .TouchUpInside)
        containerView.addSubview(sendButton)
        //x,y,w,h
        sendButton.rightAnchor.constraintEqualToAnchor(containerView.rightAnchor).active = true
        sendButton.centerYAnchor.constraintEqualToAnchor(containerView.centerYAnchor).active = true
        sendButton.widthAnchor.constraintEqualToConstant(80).active = true
        sendButton.heightAnchor.constraintEqualToAnchor(containerView.heightAnchor).active = true
        
        containerView.addSubview(self.inputTextField)
        //x,y,w,h
        self.inputTextField.leftAnchor.constraintEqualToAnchor(uploadImageView.rightAnchor, constant: 8).active = true
        self.inputTextField.centerYAnchor.constraintEqualToAnchor(containerView.centerYAnchor).active = true
        self.inputTextField.rightAnchor.constraintEqualToAnchor(sendButton.leftAnchor).active = true
        self.inputTextField.heightAnchor.constraintEqualToAnchor(containerView.heightAnchor).active = true
        
        let separatorLineView = UIView()
        separatorLineView.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(separatorLineView)
        //x,y,w,h
        separatorLineView.leftAnchor.constraintEqualToAnchor(containerView.leftAnchor).active = true
        separatorLineView.topAnchor.constraintEqualToAnchor(containerView.topAnchor).active = true
        separatorLineView.widthAnchor.constraintEqualToAnchor(containerView.widthAnchor).active = true
        separatorLineView.heightAnchor.constraintEqualToConstant(1).active = true
        
        return containerView
    }()
    
    func handleUploadTap() {
        let imagePickerController = UIImagePickerController()
        
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        
        presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            uploadToFirebaseStorageUsingImage(selectedImage)
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    private func uploadToFirebaseStorageUsingImage(image: UIImage) {
        let imageName = NSUUID().UUIDString
        let ref = FIRStorage.storage().reference().child("message_images").child(imageName)
        
        if let uploadData = UIImageJPEGRepresentation(image, 0.2) {
            ref.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                
                if error != nil {
                    print("Failed to upload image:", error)
                    return
                }
                
                if let imageUrl = metadata?.downloadURL()?.absoluteString {
                    self.sendMessageWithImageUrl(imageUrl, image: image)
                }
                
            })
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    override var inputAccessoryView: UIView? {
        get {
            return inputContainerView
        }
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    func setupKeyboardObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(handleKeyboardDidShow), name: UIKeyboardDidShowNotification, object: nil)
        
        //        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(handleKeyboardWillShow), name: UIKeyboardWillShowNotification, object: nil)
        //
        //        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(handleKeyboardWillHide), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func handleKeyboardDidShow() {
        if messages.count > 0 {
            let indexPath = NSIndexPath(forItem: messages.count - 1, inSection: 0)
            collectionView?.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func handleKeyboardWillShow(notification: NSNotification) {
        let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey]?.CGRectValue()
        let keyboardDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey]?.doubleValue
        
        containerViewBottomAnchor?.constant = -keyboardFrame!.height
        UIView.animateWithDuration(keyboardDuration!) {
            self.view.layoutIfNeeded()
        }
    }
    
    func handleKeyboardWillHide(notification: NSNotification) {
        let keyboardDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey]?.doubleValue
        
        containerViewBottomAnchor?.constant = 0
        UIView.animateWithDuration(keyboardDuration!) {
            self.view.layoutIfNeeded()
        }
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellId, forIndexPath: indexPath) as! ChatMessageCell
        
        let message = messages[indexPath.item]
        cell.textView.text = message.text
        
        setupCell(cell, message: message)
        
        if let text = message.text {
            cell.bubbleWidthAnchor?.constant = estimateFrameForText(text).width + 32
        } else if message.imageUrl != nil {
            //fall in here if its an image message
            cell.bubbleWidthAnchor?.constant = 200
        }
        
        return cell
    }
    
    private func setupCell(cell: ChatMessageCell, message: Message) {
        if let profileImageUrl = self.user?.profileImageUrl {
            cell.profileImageView.loadImageUsingCacheWithUrlString(profileImageUrl)
        }
        
        if message.fromId == FIRAuth.auth()?.currentUser?.uid {
            //outgoing blue
            cell.bubbleView.backgroundColor = ChatMessageCell.blueColor
            cell.textView.textColor = UIColor.whiteColor()
            cell.profileImageView.hidden = true
            
            cell.bubbleViewRightAnchor?.active = true
            cell.bubbleViewLeftAnchor?.active = false
            
        } else {
            //incoming gray
            cell.bubbleView.backgroundColor = UIColor.redColor()
            cell.textView.textColor = UIColor.whiteColor()
            cell.profileImageView.hidden = false
            
            cell.bubbleViewRightAnchor?.active = false
            cell.bubbleViewLeftAnchor?.active = true
        }
        
        if let messageImageUrl = message.imageUrl {
            cell.messageImageView.loadImageUsingCacheWithUrlString(messageImageUrl)
            cell.messageImageView.hidden = false
            cell.bubbleView.backgroundColor = UIColor.clearColor()
        } else {
            cell.messageImageView.hidden = true
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        var height: CGFloat = 80
        
        let message = messages[indexPath.item]
        if let text = message.text {
            height = estimateFrameForText(text).height + 20
        } else if let imageWidth = message.imageWidth?.floatValue, imageHeight = message.imageHeight?.floatValue {
            
            // h1 / w1 = h2 / w2
            // solve for h1
            // h1 = h2 / w2 * w1
            
            height = CGFloat(imageHeight / imageWidth * 200)
            
        }
        
        let width = UIScreen.mainScreen().bounds.width
        return CGSize(width: width, height: height)
    }
    
    private func estimateFrameForText(text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.UsesFontLeading.union(.UsesLineFragmentOrigin)
        return NSString(string: text).boundingRectWithSize(size, options: options, attributes: [NSFontAttributeName: UIFont.systemFontOfSize(16)], context: nil)
    }
    
    var containerViewBottomAnchor: NSLayoutConstraint?
    
    func handleSend() {
        let properties = ["text": inputTextField.text!]
        sendMessageWithProperties(properties)
        //here
    }
    
    private func sendMessageWithImageUrl(imageUrl: String, image: UIImage) {
        let properties: [String: AnyObject] = ["imageUrl": imageUrl, "imageWidth": image.size.width, "imageHeight": image.size.height]
        sendMessageWithProperties(properties)
    }
    
    private func sendMessageWithProperties(properties: [String: AnyObject]) {
        
            

//        let escape = ["á" : "a"]
//        let Eescape = ["é" : "e"]
        let  text = inputTextField.text
        if inputTextField.text == "up" || inputTextField.text == "Up" || inputTextField.text == "arriba" || inputTextField.text == "Arriba" || inputTextField.text == "high" || inputTextField.text == "High" {
            inputTextField.text = "⬆️"
        }
        if inputTextField.text == "Burger" || inputTextField.text == "burger"{
            inputTextField.text = "🍔"
        }
        
        if inputTextField.text == "sleep" || inputTextField.text == "Sleep" || inputTextField.text == "night" || inputTextField.text == "Night" {
            inputTextField.text = "😴💤"
        }
        if inputTextField.text == "100"{
            inputTextField.text = "💯"
        }

        let message = inputTextField.text?.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        
        // what does this line do?
        var messageForURL = ""
        //        does a for loop duhhhhhhh
        //         what does this line do?
        print("-------------------")
        print(text)
        for character in message!.characters {
            // what does this line do?
            if character == " " {
                // literally gives %20 cause that stands for a space in a url link
                // what does this line do?
                messageForURL += "%20"
                // what does this line do?
            }
                // what does this line do?
            else {
                //append means to add to the chars
                // what does this line do?
                messageForURL.append(character)
                // what does this line do?
            }
            //closes the for loop<>
            // |
            // what does this line do?
        }
        print("messageForURL: \(messageForURL)")
        
        let apiToContact = "https://www.googleapis.com/language/translate/v2?key=AIzaSyDDTV4qnVy3CK0CwtXLG0h1HYrtKmIWM8c&q=\(messageForURL)&source=es&target=en"
        
        print("apiToContact: \(apiToContact)")
        print("-------------------")
        var data = ""
        // This code will call the google translate api
        Alamofire.request(.GET, apiToContact).validate().responseJSON() { response in
            switch response.result {
                
            case .Success:
                if let value = response.result.value {
                    let json = JSON(value)
                    print(json)
                    
                    data = json["data"]["translations"][0]["translatedText"].stringValue
                    
                    print("Data is : " + data)
                    
                    let ref = FIRDatabase.database().reference().child("messages")
                    let childRef = ref.childByAutoId()
                    let toId = self.user!.id!
                    let fromId = FIRAuth.auth()!.currentUser!.uid
                    let timestamp: NSNumber = Int(NSDate().timeIntervalSince1970)
                    
                    var values: [String: AnyObject] = ["toId": toId, "fromId": fromId, "timestamp": timestamp, "text": data]
                    JSQSystemSoundPlayer.jsq_playMessageReceivedAlert()

                    
                    //append properties dictionary onto values somehow??
                    //key $0, value $1
//                    properties.forEach({values[$0] = $1})
                    
                    childRef.updateChildValues(values) { (error, ref) in
                        if error != nil {
                            print(error)
                            return
                            
                        }
                        
                        
                        self.inputTextField.text = nil
                        
                        let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(fromId).child(toId)
                        
                        
                        let messageId = childRef.key
                        userMessagesRef.updateChildValues([messageId: 1])
                        
                        let recipientUserMessagesRef = FIRDatabase.database().reference().child("user-messages").child(toId).child(fromId)
                        recipientUserMessagesRef.updateChildValues([messageId: 1])
                        //                translateEnglish()
                        
                    }

                }
            case .Failure:
                print("failed")
                
            }
        }
        
        
        
        
    }
    func translateToEnglish(){
        //emojifying code
//        if inputTextField.text == "up" || inputTextField.text == "Up" || inputTextField.text == "arriba" || inputTextField.text == "Arriba" || inputTextField.text == "high" || inputTextField.text == "High" {
//            inputTextField.text = "⬆️"
//        }
//        if inputTextField.text == "Burger" || inputTextField.text == "burger"{
//            inputTextField.text = "🍔"
//        }
//        
//        if inputTextField.text == "sleep"{
//            inputTextField.text = "😴💤"
//        }
        
        

        
        
        
        
    
        let  text = inputTextField.text
        if inputTextField.text == "up" || inputTextField.text == "Up" || inputTextField.text == "arriba" || inputTextField.text == "Arriba" || inputTextField.text == "high" || inputTextField.text == "High" {
            inputTextField.text = "⬆️"
        }
        if inputTextField.text == "Burger" || inputTextField.text == "burger"{
            inputTextField.text = "🍔"
        }
        
        if inputTextField.text == "sleep" || inputTextField.text == "Sleep" || inputTextField.text == "night" || inputTextField.text == "Night" {
            inputTextField.text = "😴💤"
        }
        if inputTextField.text == "100"{
        inputTextField.text = "💯"
        }

        let message = inputTextField.text?.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        
        // what does this line do?
        var messageForURL = ""
        //        does a for loop duhhhhhhh
        //         what does this line do?
        print(text)
        for character in message!.characters {
            // what does this line do?
            if character == " " {
                // literally gives %20 cause that stands for a space in a url link
                // what does this line do?
                messageForURL += "%20"
                // what does this line do?
            }
                // what does this line do?
            else {
                //append means to add to the chars
                // what does this line do?
                messageForURL.append(character)
                // what does this line do?
            }
            //closes the for loop<>
            // |
            // what does this line do?
        }
        

        print("messageForURL: \(messageForURL)")
        
        let apiToContact = "https://www.googleapis.com/language/translate/v2?key=AIzaSyDDTV4qnVy3CK0CwtXLG0h1HYrtKmIWM8c&q=\(messageForURL)&source=en&target=es"
        
        print("apiToContact: \(apiToContact)")
        print("-------------------")
        var data = ""
        // This code will call the google translate api
        Alamofire.request(.GET, apiToContact).validate().responseJSON() { response in
            switch response.result {
                
            case .Success:
                if let value = response.result.value {
                    let json = JSON(value)
                    print(json)
                    
                    data = json["data"]["translations"][0]["translatedText"].stringValue
                    
                    print("Data is : " + data)
                    
                    let ref = FIRDatabase.database().reference().child("messages")
                    let childRef = ref.childByAutoId()
                    let toId = self.user!.id!
                    let fromId = FIRAuth.auth()!.currentUser!.uid
                    let timestamp: NSNumber = Int(NSDate().timeIntervalSince1970)
                    
                    var values: [String: AnyObject] = ["toId": toId, "fromId": fromId, "timestamp": timestamp, "text": data]
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    
                    //append properties dictionary onto values somehow??
                    //key $0, value $1
//                    properties.forEach({values[$0] = $1})
                    
                    childRef.updateChildValues(values) { (error, ref) in
                        if error != nil {
                            print(error)
                            return
                            
                            
                        }
//                        func push(application: UIApplication, didRecievePushNotifications data: [String : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
//                            var values: [String : AnyObject] = ["text": data]
//                                 // Let FCM know about the message for analytics etc.
//                                  FIRMessaging.messaging().appDidReceiveMessage(data)
//                                  // handle your message
//                            
//                              }

                        
                        
                        self.inputTextField.text = nil
                        
                        let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(fromId).child(toId)
                        
                        
                        let messageId = childRef.key
                        userMessagesRef.updateChildValues([messageId: 1])
                        
                        let recipientUserMessagesRef = FIRDatabase.database().reference().child("user-messages").child(toId).child(fromId)
                        recipientUserMessagesRef.updateChildValues([messageId: 1])
                        //                translateEnglish()
                        
                    }
                    
                    
                }
            case .Failure:
                print("failed")
                
            }
        }
        
        
        
        
    }
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
               handleSend()
        return true
        
            
        }
        
    }







