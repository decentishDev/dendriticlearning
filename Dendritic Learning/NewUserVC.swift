//
//  NewUserVC.swift
//  Dendritic Learning
//
//  Created by Matthew Lundeen on 6/17/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class NewUserVC: UIViewController {
    
    let welcomeView = UIScrollView()
    let infoView = UIScrollView()
    let signUpOrIn = UIScrollView()
    let signUp = UIScrollView()
    let signIn = UIScrollView()
    let success = UIScrollView()
    
    var signUpName = UITextField()
    var signUpEmail = UITextField()
    var signUpUsername = UITextField()
    var signUpPassword = UITextField()
    var signUpPassword2 = UITextField()
    
    var signInEmail = UITextField()
    var signInPassword = UITextField()
    
    var nextButton = UIButton()
    var backButton = UIButton()
    
    var page = 0
    
    let db = Firestore.firestore()
    
    var keyboard: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        setup()
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(dismissIt(_:)))
        view.addGestureRecognizer(gesture)
    }
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    func setup(){
        let midX = view.frame.width / 2
        let midY = view.frame.height / 2
        let fullX = view.frame.width
        let fullY = view.frame.height
        
        view.backgroundColor = Colors.background

        welcomeView.frame = view.frame
        view.addSubview(welcomeView)
        welcomeView.contentSize = view.frame.size
        infoView.frame = CGRect(x: fullX, y: 0, width: fullX, height: fullY)
        view.addSubview(infoView)
        infoView.contentSize = view.frame.size
        signUpOrIn.frame = CGRect(x: fullX, y: 0, width: fullX, height: fullY)
        view.addSubview(signUpOrIn)
        signUpOrIn.contentSize = view.frame.size
        signUp.frame = CGRect(x: fullX, y: 0, width: fullX, height: fullY)
        view.addSubview(signUp)
        signUp.contentSize = view.frame.size
        signIn.frame = CGRect(x: fullX, y: 0, width: fullX, height: fullY)
        view.addSubview(signIn)
        signIn.contentSize = view.frame.size
        success.frame = CGRect(x: fullX, y: 0, width: fullX, height: fullY)
        view.addSubview(success)
        success.contentSize = view.frame.size
        
        let welcomeText = UILabel(frame: CGRect(x: 0, y: 0, width: fullX, height: fullY - 200))
        welcomeText.font = UIFont(name: "LilGrotesk-Black", size: 40)
        welcomeText.text = "Welcome to\nDendritic Learning."
        welcomeText.numberOfLines = 0
        welcomeText.textColor = Colors.text
        welcomeText.textAlignment = .center
        welcomeView.addSubview(welcomeText)
        
        let info1 = UILabel(frame: CGRect(x: 100, y: 0, width: fullX - 200, height: fullY - 200))
        info1.font = UIFont(name: "LilGrotesk-Regular", size: 30)
        info1.text = "Dendritic is an innovative learning platform.\n\nThrough writing recognition, web sets, smart study modes, and simple integration of different types of content, our tools allow all students to learn in better ways."
        info1.numberOfLines = 0
        info1.textColor = Colors.text
        info1.textAlignment = .center
        infoView.addSubview(info1)
        
        let signUpButton = UIButton(frame: CGRect(x: midX - 150, y: midY - 70, width: 300, height: 50))
        signUpButton.backgroundColor = Colors.secondaryBackground
        signUpButton.setTitle("Create a new account", for: .normal)
        signUpButton.setTitleColor(Colors.text, for: .normal)
        signUpButton.layer.cornerRadius = 10
        signUpButton.titleLabel!.font = UIFont(name: "LilGrotesk-Regular", size: 20)
        signUpButton.addTarget(self, action: #selector(signUp(_:)), for: .touchUpInside)
        signUpOrIn.addSubview(signUpButton)
        
        let signInButton = UIButton(frame: CGRect(x: midX - 150, y: midY, width: 300, height: 50))
        signInButton.backgroundColor = Colors.secondaryBackground
        signInButton.setTitle("Sign in to an account", for: .normal)
        signInButton.setTitleColor(Colors.text, for: .normal)
        signInButton.layer.cornerRadius = 10
        signInButton.titleLabel!.font = UIFont(name: "LilGrotesk-Regular", size: 20)
        signInButton.addTarget(self, action: #selector(signIn(_:)), for: .touchUpInside)
        signUpOrIn.addSubview(signInButton)
        
        let signUpLabel = UILabel(frame: CGRect(x: 0, y: midY - 230, width: fullX, height: 50))
        signUpLabel.font = UIFont(name: "LilGrotesk-Regular", size: 30)
        signUpLabel.text = "Sign up"
        signUpLabel.textAlignment = .center
        signUp.addSubview(signUpLabel)
        signUpName = UITextField(frame: CGRect(x: midX - 200, y: midY - 160, width: 400, height: 30))
        signUpName.textContentType = .name
        let signUpNameLabel = UILabel(frame: CGRect(x: midX - 200, y: midY - 190, width: 400, height: 30))
        signUpNameLabel.text = "Name"
        signUpEmail = UITextField(frame: CGRect(x: midX - 200, y: midY - 90, width: 400, height: 30))
        signUpEmail.textContentType = .emailAddress
        let signUpEmailLabel = UILabel(frame: CGRect(x: midX - 200, y: midY - 120, width: 400, height: 30))
        signUpEmailLabel.text = "Email"
        signUpUsername = UITextField(frame: CGRect(x: midX - 200, y: midY - 20, width: 400, height: 30))
        signUpUsername.textContentType = .username
        let signUpUsernameLabel = UILabel(frame: CGRect(x: midX - 200, y: midY - 50, width: 400, height: 30))
        signUpUsernameLabel.text = "Username"
        signUpPassword = UITextField(frame: CGRect(x: midX - 200, y: midY + 50, width: 400, height: 30))
        signUpPassword.textContentType = .password
        signUpPassword.isSecureTextEntry = true
        let signUpPasswordLabel = UILabel(frame: CGRect(x: midX - 200, y: midY + 20, width: 400, height: 30))
        signUpPasswordLabel.text = "Password"
        signUpPassword2 = UITextField(frame: CGRect(x: midX - 200, y: midY + 120, width: 400, height: 30))
        signUpPassword2.textContentType = .password
        signUpPassword2.isSecureTextEntry = true
        let signUpPassword2Label = UILabel(frame: CGRect(x: midX - 200, y: midY + 90, width: 400, height: 30))
        signUpPassword2Label.text = "Repeat password"
        
        for i in [signUpName, signUpNameLabel, signUpEmail, signUpEmailLabel, signUpUsername, signUpUsernameLabel, signUpPassword, signUpPasswordLabel, signUpPassword2, signUpPassword2Label]{
            if let c = i as? UILabel{
                c.font = UIFont(name: "LilGrotesk-Regular", size: 20)
            }
            if let c = i as? UITextField{
                c.font = UIFont(name: "LilGrotesk-Regular", size: 20)
                c.backgroundColor = Colors.secondaryBackground
                c.layer.cornerRadius = 7
                let paddingView = UIView(frame: CGRectMake(0, 0, 6, c.frame.height))
                c.leftView = paddingView
                c.leftViewMode = .always
            }
            signUp.addSubview(i)
        }
        
        let signInLabel = UILabel(frame: CGRect(x: 0, y: midY - 230, width: fullX, height: 50))
        signInLabel.font = UIFont(name: "LilGrotesk-Regular", size: 30)
        signInLabel.text = "Sign in"
        signInLabel.textAlignment = .center
        signIn.addSubview(signInLabel)
        signInEmail = UITextField(frame: CGRect(x: midX - 200, y: midY - 70, width: 400, height: 30))
        signInEmail.textContentType = .emailAddress
        let signInEmailLabel = UILabel(frame: CGRect(x: midX - 200, y: midY - 100, width: 400, height: 30))
        signInEmailLabel.text = "Email"
        signInPassword = UITextField(frame: CGRect(x: midX - 200, y: midY + 30, width: 400, height: 30))
        signInPassword.textContentType = .password
        signInPassword.isSecureTextEntry = true
        let signInPasswordLabel = UILabel(frame: CGRect(x: midX - 200, y: midY, width: 400, height: 30))
        signInPasswordLabel.text = "Password"
        let resetPasswordButton = UIButton(frame: CGRect(x: midX - 200, y: midY + 60, width: 400, height: 30))
        resetPasswordButton.setTitle("Reset password", for: .normal)
        resetPasswordButton.setTitleColor(Colors.highlight, for: .normal)
        resetPasswordButton.titleLabel!.font = UIFont(name: "LilGrotesk-Regular", size: 16)
        resetPasswordButton.titleLabel!.textAlignment = .left
        resetPasswordButton.addTarget(self, action: #selector(resetButtonPressed(_:)), for: .touchUpInside)
        signIn.addSubview(resetPasswordButton)
        for i in [signInEmail, signInEmailLabel, signInPassword, signInPasswordLabel]{
            if let c = i as? UILabel{
                c.font = UIFont(name: "LilGrotesk-Regular", size: 20)
            }
            if let c = i as? UITextField{
                c.font = UIFont(name: "LilGrotesk-Regular", size: 20)
                c.backgroundColor = Colors.secondaryBackground
                c.layer.cornerRadius = 7
                let paddingView = UIView(frame: CGRectMake(0, 0, 6, c.frame.height))
                c.leftView = paddingView
                c.leftViewMode = .always
            }
            signIn.addSubview(i)
        }
        
        let successLabel = UILabel(frame: CGRect(x: 0, y: 0, width: fullX, height: fullY - 200))
        successLabel.font = UIFont(name: "LilGrotesk-Black", size: 40)
        successLabel.text = "Success!\n\nWelcome to\nDendritic Learning."
        successLabel.numberOfLines = 0
        successLabel.textColor = Colors.text
        successLabel.textAlignment = .center
        success.addSubview(successLabel)
        
        nextButton = UIButton(frame: CGRect(x: midX + 10, y: fullY - 200, width: 150, height: 50))
        nextButton.backgroundColor = Colors.secondaryBackground
        nextButton.setTitle("Next >", for: .normal)
        nextButton.setTitleColor(Colors.text, for: .normal)
        nextButton.layer.cornerRadius = 10
        nextButton.titleLabel!.font = UIFont(name: "LilGrotesk-Regular", size: 20)
        nextButton.addTarget(self, action: #selector(nextButtonPressed(_:)) , for: .touchUpInside)
        view.addSubview(nextButton)
        backButton = UIButton(frame: CGRect(x: midX - 160, y: fullY - 200, width: 150, height: 50))
        backButton.backgroundColor = Colors.secondaryBackground
        backButton.setTitle("< Back", for: .normal)
        backButton.setTitleColor(Colors.text, for: .normal)
        backButton.layer.cornerRadius = 10
        backButton.titleLabel!.font = UIFont(name: "LilGrotesk-Regular", size: 20)
        backButton.addTarget(self, action: #selector(backButtonPressed(_:)), for: .touchUpInside)
        backButton.isEnabled = false
        backButton.alpha = 0.5
        view.addSubview(backButton)
    }
    
    @objc func signUp(_ sender: UIButton){
        let fullX = view.frame.width
        let fullY = view.frame.height
        UIView.animate(withDuration: 0.5, animations: {
            self.signUpOrIn.frame = CGRect(x: -fullX, y: 0, width: fullX, height: fullY)
            self.signUp.frame = CGRect(x: 0, y: 0, width: fullX, height: fullY)
            self.nextButton.alpha = 1
        })
        page+=1
        nextButton.isEnabled = true
    }
    
    @objc func signIn(_ sender: UIButton){
        let fullX = view.frame.width
        let fullY = view.frame.height
        UIView.animate(withDuration: 0.5, animations: {
            self.signUpOrIn.frame = CGRect(x: -fullX, y: 0, width: fullX, height: fullY)
            self.signIn.frame = CGRect(x: 0, y: 0, width: fullX, height: fullY)
            self.nextButton.alpha = 1
        })
        page+=2
        nextButton.isEnabled = true
    }
    
    @objc func nextButtonPressed(_ sender: UIButton){
        let midX = view.frame.width / 2
        let midY = view.frame.height / 2
        let fullX = view.frame.width
        let fullY = view.frame.height
        
        switch page {
        case 0:
            self.backButton.isEnabled = true
            UIView.animate(withDuration: 0.5, animations: {
                self.welcomeView.frame = CGRect(x: -fullX, y: 0, width: fullX, height: fullY)
                self.infoView.frame = CGRect(x: 0, y: 0, width: fullX, height: fullY)
                self.backButton.alpha = 1
            })
            page+=1
        case 1:
            
            UIView.animate(withDuration: 0.5, animations: {
                self.infoView.frame = CGRect(x: -fullX, y: 0, width: fullX, height: fullY)
                self.signUpOrIn.frame = CGRect(x: 0, y: 0, width: fullX, height: fullY)
                self.nextButton.alpha = 0.5
            })
            nextButton.isEnabled = false
            page+=1
//        case 2:
//            UIView.animate(withDuration: 0.5, animations: {
//                self.signUpOrIn.frame = CGRect(x: -fullX, y: 0, width: fullX, height: fullY)
//                self.sign.frame = CGRect(x: 0, y: 0, width: fullX, height: fullY)
//            })
        case 3:
            let email = signUpEmail.text
            let password = signUpPassword.text
            if(email != nil && isValidEmail(email!)){
                if(password != nil && isValidPassword(password!)){
                    backButton.isEnabled = false
                    nextButton.isEnabled = false
                    Auth.auth().createUser(withEmail: signUpEmail.text!, password: signUpPassword.text!) { authResult, error in
                        if let error = error {
                            print("Error: \(error.localizedDescription)")
                            self.backButton.isEnabled = true
                            self.nextButton.isEnabled = true
                        }else if let authResult = authResult{
                            print("User signed up successfully")
                            UIView.animate(withDuration: 0.5, animations: {
                                self.signUp.frame = CGRect(x: -fullX, y: 0, width: fullX, height: fullY)
                                self.success.frame = CGRect(x: 0, y: 0, width: fullX, height: fullY)
                                self.backButton.alpha = 0.5
                            })
                            self.page+=2
                            self.nextButton.isEnabled = true
                            self.db.collection("users").document(authResult.user.uid).setData([
                                "name": self.signUpName.text!,
                                "username": self.signUpUsername.text!,
                                "email": self.signUpEmail.text!,
                                "subscription": [
                                    "status": "inactive",
                                ],
                                "transactions": [],
                                "createdSets": [],
                                "studiedSets": [],
                                "likedSets": [],
                                "settings": [
                                    "theme": "Dark"
                                ]
                                
                            ]) { err in
                                if let err = err {
                                    print("Error adding document: \(err)")
                                } else {
                                    print("Document added")
                                }
                            }
                        }
                    }
                }
            }
        case 4:
            print("ok")
            let email = signInEmail.text
            let password = signInPassword.text
            if(email != nil && isValidEmail(email!)){
                print("ok")
                if(password != nil && isValidPassword(password!)){
                    print("ok")
                    backButton.isEnabled = false
                    nextButton.isEnabled = false
                    Auth.auth().signIn(withEmail: signInEmail.text!, password: signInPassword.text!) { authResult, error in
                        if let error = error {
                            print("Error: \(error.localizedDescription)")
                            self.backButton.isEnabled = true
                            self.nextButton.isEnabled = true
                        }else{
                            print("User signed in successfully")
                            UIView.animate(withDuration: 0.5, animations: {
                                self.signIn.frame = CGRect(x: -fullX, y: 0, width: fullX, height: fullY)
                                self.success.frame = CGRect(x: 0, y: 0, width: fullX, height: fullY)
                                self.backButton.alpha = 0.5
                            })
                            self.nextButton.isEnabled = true
                            self.page+=1
                            
                        }
                    }
                }
            }
        case 5:
            performSegue(withIdentifier: "newUser_unwind", sender: nil)
        default:
            break
        }
        
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Z0-9a-z.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPredicate.evaluate(with: email)
    }
    
    func isValidPassword(_ password: String) -> Bool {
        let passwordRegEx = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{8,}$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegEx)
        return passwordPredicate.evaluate(with: password)
    }
    
    @objc func backButtonPressed(_ sender: UIButton){
        let midX = view.frame.width / 2
        let midY = view.frame.height / 2
        let fullX = view.frame.width
        let fullY = view.frame.height
        
        switch page {
        case 1:
            self.backButton.isEnabled = false
            UIView.animate(withDuration: 0.5, animations: {
                self.infoView.frame = CGRect(x: fullX, y: 0, width: fullX, height: fullY)
                self.welcomeView.frame = CGRect(x: 0, y: 0, width: fullX, height: fullY)
                self.backButton.alpha = 0.5
            })
            page-=1
        case 2:
            UIView.animate(withDuration: 0.5, animations: {
                self.signUpOrIn.frame = CGRect(x: fullX, y: 0, width: fullX, height: fullY)
                self.infoView.frame = CGRect(x: 0, y: 0, width: fullX, height: fullY)
                self.nextButton.alpha = 1
            })
            nextButton.isEnabled = true
            page-=1
        case 3:
            UIView.animate(withDuration: 0.5, animations: {
                self.signUp.frame = CGRect(x: fullX, y: 0, width: fullX, height: fullY)
                self.signUpOrIn.frame = CGRect(x: 0, y: 0, width: fullX, height: fullY)
                self.nextButton.alpha = 0.5
            })
            nextButton.isEnabled = false
            page-=1
        case 4:
            UIView.animate(withDuration: 0.5, animations: {
                self.signIn.frame = CGRect(x: fullX, y: 0, width: fullX, height: fullY)
                self.signUpOrIn.frame = CGRect(x: 0, y: 0, width: fullX, height: fullY)
                self.nextButton.alpha = 0.5
            })
            page-=2
            nextButton.isEnabled = false
        default:
            break
        }
    }
    
    @objc func resetButtonPressed(_ sender: UIButton){
        let alertController = UIAlertController(title: "Enter the account email:", message: nil, preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.placeholder = "example@domain.com"
        }
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { [weak alertController] _ in
            if let textField = alertController?.textFields?.first, let text = textField.text {
                Auth.auth().sendPasswordReset(withEmail: text)
                let endController = UIAlertController(title: "A link to reset your password has been sent to: " + text, message: nil, preferredStyle: .alert)
                let confirmAction = UIAlertAction(title: "Confirm", style: .default, handler: nil)
                endController.addAction(confirmAction)
                self.present(endController, animated: true, completion: nil)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func dismissIt(_ sender: UITapGestureRecognizer){
        view.endEditing(true)
    }
    
    @IBAction func cancel (_ unwindSegue: UIStoryboardSegue){
    }
    func reformat(){
        let fullX = view.frame.width
        let fullY = view.frame.width
        welcomeView.frame = CGRect(x: welcomeView.frame.minX, y: 0, width: fullX, height: fullY - keyboard)
        infoView.frame = CGRect(x: infoView.frame.minX, y: 0, width: fullX, height: fullY - keyboard)
        signUpOrIn.frame = CGRect(x: signUpOrIn.frame.minX, y: 0, width: fullX, height: fullY - keyboard)
        signUp.frame = CGRect(x: signUp.frame.minX, y: 0, width: fullX, height: fullY - keyboard)
        signIn.frame = CGRect(x: signIn.frame.minX, y: 0, width: fullX, height: fullY - keyboard - 100)
        success.frame = CGRect(x: success.frame.minX, y: 0, width: fullX, height: fullY - keyboard)
    }
}
extension NewUserVC {
    
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        
        let keyboardHeight = keyboardFrame.height
        keyboard = keyboardHeight
        reformat()
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        keyboard = 0
        reformat()
    }
}
