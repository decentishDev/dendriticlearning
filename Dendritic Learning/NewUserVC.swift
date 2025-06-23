//
//  NewUserVC.swift
//  Dendritic Learning
//
//  Created by Matthew Lundeen on 6/17/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
import GoogleSignIn

class NewUserVC: UIViewController {
    
    let welcomeView = UIView()
    let infoView = UIView()
    let signUpOrIn = UIView()
    let signUp = UIView()
    let signIn = UIView()
    let success = UIView()
    
    var signUpName = UITextField()
    var signUpEmail = UITextField()
    var signUpUsername = UITextField()
    var signUpPassword = UITextField()
    var signUpPassword2 = UITextField()
    
    var signUpEmailError = UILabel()
    var signUpPasswordError = UILabel()
    var signUpPassword2Error = UILabel()
    
    var signInEmail = UITextField()
    var signInPassword = UITextField()
    
    var signInEmailError = UILabel()
    var signInPasswordError = UILabel()
    
    var nextButton = UIButton()
    var backButton = UIButton()
    
    var page = 0
    
    let db = Firestore.firestore()
    
    var keyboard: CGFloat = 0
    
    var scrollFrame = UIScrollView()

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
        
        let bgimage = UIImageView(image: UIImage(named: "dendriticbackground.svg")?.withRenderingMode(.alwaysTemplate))
        bgimage.tintColor = Colors.highlight
        bgimage.contentMode = .scaleAspectFill
        bgimage.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        bgimage.layer.opacity = 0.35
        view.addSubview(bgimage)

        scrollFrame.frame = view.frame
        view.addSubview(scrollFrame)
        scrollFrame.contentSize = view.frame.size
        
        welcomeView.frame = view.frame
        scrollFrame.addSubview(welcomeView)
        
        infoView.frame = CGRect(x: fullX, y: 0, width: fullX, height: fullY)
        scrollFrame.addSubview(infoView)

        signUpOrIn.frame = CGRect(x: fullX, y: 0, width: fullX, height: fullY)
        scrollFrame.addSubview(signUpOrIn)

        signUp.frame = CGRect(x: fullX, y: 0, width: fullX, height: fullY)
        scrollFrame.addSubview(signUp)

        signIn.frame = CGRect(x: fullX, y: 0, width: fullX, height: fullY)
        scrollFrame.addSubview(signIn)

        success.frame = CGRect(x: fullX, y: 0, width: fullX, height: fullY)
        scrollFrame.addSubview(success)

        
        let welcomeText = UILabel(frame: CGRect(x: 0, y: 50, width: fullX, height: fullY - 200))
        welcomeText.font = UIFont(name: "LilGrotesk-Black", size: 40)
        welcomeText.text = "Welcome to\nDendritic Learning."
        welcomeText.numberOfLines = 0
        welcomeText.textColor = Colors.text
        welcomeText.textAlignment = .center
        welcomeView.addSubview(welcomeText)
        
        let info1 = UILabel(frame: CGRect(x: 100, y: 50, width: fullX - 200, height: fullY - 200))
        info1.font = UIFont(name: "LilGrotesk-Regular", size: 30)
        //info1.text = "Dendritic is an innovative learning platform.\n\nThrough writing recognition, web sets, smart study modes, and simple integration of different types of content, our tools allow all students to learn in better ways."
        info1.text = "This is the first release version of Dendritic Learning, our innovative platform meant for learning in natural and efficient ways.\n\nWe are still in the early stages of development, so please let us know if you have any suggestions or feedback.\n\nMore features and bug fixes will be coming soon!"
        info1.numberOfLines = 0
        info1.textColor = Colors.text
        info1.textAlignment = .center
        infoView.addSubview(info1)
        
        let signUpButton = UIButton(frame: CGRect(x: midX - 150, y: midY - 120, width: 300, height: 50))
        signUpButton.backgroundColor = Colors.secondaryBackground
        signUpButton.setTitle("Create a new account", for: .normal)
        signUpButton.setTitleColor(Colors.text, for: .normal)
        signUpButton.layer.cornerRadius = 10
        signUpButton.titleLabel!.font = UIFont(name: "LilGrotesk-Regular", size: 20)
        signUpButton.addTarget(self, action: #selector(signUp(_:)), for: .touchUpInside)
        signUpOrIn.addSubview(signUpButton)
        
        let signInButton = UIButton(frame: CGRect(x: midX - 150, y: midY - 50, width: 300, height: 50))
        signInButton.backgroundColor = Colors.secondaryBackground
        signInButton.setTitle("Sign in to an account", for: .normal)
        signInButton.setTitleColor(Colors.text, for: .normal)
        signInButton.layer.cornerRadius = 10
        signInButton.titleLabel!.font = UIFont(name: "LilGrotesk-Regular", size: 20)
        signInButton.addTarget(self, action: #selector(signIn(_:)), for: .touchUpInside)
        signUpOrIn.addSubview(signInButton)
        
//        let gSignInButton = GIDSignInButton()
//        gSignInButton.style = .wide
//        gSignInButton.colorScheme = .dark
//        gSignInButton.center = CGPoint(x: view.center.x, y: view.center.y + 100)
//        signUpOrIn.addSubview(gSignInButton)
//        gSignInButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(signInWithGoogle)))
        
//        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(signInWithGoogle))
//        gSignInButton.addGestureRecognizer(tapRecognizer)
        
        let gSignInView = UIView(frame: CGRect(x: midX - 120, y: midY + 90, width: 240, height: 50))
        gSignInView.backgroundColor = Colors.secondaryBackground
        gSignInView.layer.cornerRadius = 10
        gSignInView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(signInWithGoogle)))
        signUpOrIn.addSubview(gSignInView)
        
        let gLogo = UIImageView(frame: CGRect(x: 15, y: 15, width: 20, height: 20))
        gLogo.image = UIImage(named: "white-google-logo.png")
        gLogo.contentMode = .scaleAspectFit
        gSignInView.addSubview(gLogo)
        
        let gText = UILabel(frame: CGRect(x: 50, y: 0, width: 190, height: 50))
        gText.text = "Sign in with Google"
        gText.font = UIFont(name: "LilGrotesk-Bold", size: 20)
        gText.textAlignment = .left
        gText.textColor = Colors.text
        gSignInView.addSubview(gText)
        
        let signUpLabel = UILabel(frame: CGRect(x: 0, y: midY - 230 - 100, width: fullX, height: 50))
        signUpLabel.font = UIFont(name: "LilGrotesk-Regular", size: 30)
        signUpLabel.text = "Sign up"
        signUpLabel.textAlignment = .center
        signUpLabel.textColor = Colors.text
        signUp.addSubview(signUpLabel)
        
        signUpName = UITextField(frame: CGRect(x: midX - 200, y: midY - 160 - 80, width: 400, height: 40))
        signUpName.textContentType = .name
        
        let signUpNameLabel = UILabel(frame: CGRect(x: midX - 200, y: midY - 190 - 80, width: 400, height: 30))
        signUpNameLabel.text = "Name"
        
        signUpEmail = UITextField(frame: CGRect(x: midX - 200, y: midY - 90 - 60, width: 400, height: 40))
        signUpEmail.textContentType = .emailAddress
        
        let signUpEmailLabel = UILabel(frame: CGRect(x: midX - 200, y: midY - 120 - 60, width: 400, height: 30))
        signUpEmailLabel.text = "Email"
        
        signUpEmailError = UILabel(frame: CGRect(x: midX - 200, y: midY - 120 - 60, width: 400, height: 30))
        
        signUpUsername = UITextField(frame: CGRect(x: midX - 200, y: midY - 20 - 40, width: 400, height: 40))
        signUpUsername.textContentType = .username
        
        let signUpUsernameLabel = UILabel(frame: CGRect(x: midX - 200, y: midY - 50 - 40, width: 400, height: 30))
        signUpUsernameLabel.text = "Username"
        
        signUpPassword = UITextField(frame: CGRect(x: midX - 200, y: midY + 50 - 20, width: 400, height: 40))
        signUpPassword.textContentType = .password
        signUpPassword.isSecureTextEntry = true
        
        let signUpPasswordLabel = UILabel(frame: CGRect(x: midX - 200, y: midY + 20 - 20, width: 400, height: 30))
        signUpPasswordLabel.text = "Password"
        
        signUpPasswordError = UILabel(frame: CGRect(x: midX - 200, y: midY + 20 - 20, width: 400, height: 30))
        
        signUpPassword2 = UITextField(frame: CGRect(x: midX - 200, y: midY + 120, width: 400, height: 40))
        signUpPassword2.textContentType = .password
        signUpPassword2.isSecureTextEntry = true
        
        let signUpPassword2Label = UILabel(frame: CGRect(x: midX - 200, y: midY + 90, width: 400, height: 30))
        signUpPassword2Label.text = "Repeat password"
        
        signUpPassword2Error = UILabel(frame: CGRect(x: midX - 200, y: midY + 90, width: 400, height: 30))
        
        for i in [signUpName, signUpNameLabel, signUpEmail, signUpEmailLabel, signUpUsername, signUpUsernameLabel, signUpPassword, signUpPasswordLabel, signUpPassword2, signUpPassword2Label]{
            if let c = i as? UILabel{
                c.font = UIFont(name: "LilGrotesk-Regular", size: 20)
                c.textColor = Colors.text
            }
            if let c = i as? UITextField{
                c.font = UIFont(name: "LilGrotesk-Regular", size: 20)
                c.backgroundColor = Colors.secondaryBackground
                c.layer.cornerRadius = 7
                let paddingView = UIView(frame: CGRectMake(0, 0, 10, c.frame.height))
                c.leftView = paddingView
                c.leftViewMode = .always
                c.textColor = Colors.text
            }
            signUp.addSubview(i)
        }
        
        for i in [signUpEmailError, signUpPasswordError, signUpPassword2Error]{
            if let c = i as? UILabel{
                c.font = UIFont(name: "LilGrotesk-Regular", size: 20)
                c.textColor = Colors.red
                c.textAlignment = .right
            }
            signUp.addSubview(i)
        }
        
        let signInLabel = UILabel(frame: CGRect(x: 0, y: midY - 230, width: fullX, height: 50))
        signInLabel.font = UIFont(name: "LilGrotesk-Regular", size: 30)
        signInLabel.text = "Sign in"
        signInLabel.textAlignment = .center
        signInLabel.textColor = Colors.text
        
        signIn.addSubview(signInLabel)
        signInEmail = UITextField(frame: CGRect(x: midX - 200, y: midY - 120, width: 400, height: 40))
        signInEmail.textContentType = .emailAddress
        
        let signInEmailLabel = UILabel(frame: CGRect(x: midX - 200, y: midY - 150, width: 400, height: 30))
        signInEmailLabel.text = "Email"
        
        signInEmailError = UILabel(frame: CGRect(x: midX - 200, y: midY - 150, width: 400, height: 30))
        
        signInPassword = UITextField(frame: CGRect(x: midX - 200, y: midY - 20, width: 400, height: 40))
        signInPassword.textContentType = .password
        signInPassword.isSecureTextEntry = true
        
        let signInPasswordLabel = UILabel(frame: CGRect(x: midX - 200, y: midY - 50, width: 400, height: 30))
        signInPasswordLabel.text = "Password"
        
        signInPasswordError = UILabel(frame: CGRect(x: midX - 200, y: midY - 50, width: 400, height: 30))
        
        let resetPasswordButton = UIButton(frame: CGRect(x: midX - 200, y: midY + 20, width: 400, height: 30))
        resetPasswordButton.setTitle("Forgot password?", for: .normal)
        resetPasswordButton.setTitleColor(Colors.highlight, for: .normal)
        resetPasswordButton.titleLabel!.font = UIFont(name: "LilGrotesk-Regular", size: 16)
        resetPasswordButton.titleLabel!.textAlignment = .left
        resetPasswordButton.contentHorizontalAlignment = .left
        resetPasswordButton.addTarget(self, action: #selector(resetButtonPressed(_:)), for: .touchUpInside)
        
        signIn.addSubview(resetPasswordButton)
        
        for i in [signInEmail, signInEmailLabel, signInPassword, signInPasswordLabel]{
            if let c = i as? UILabel{
                c.font = UIFont(name: "LilGrotesk-Regular", size: 20)
                c.textColor = Colors.text
            }
            if let c = i as? UITextField{
                c.font = UIFont(name: "LilGrotesk-Regular", size: 20)
                c.textColor = Colors.text
                c.backgroundColor = Colors.secondaryBackground
                c.layer.cornerRadius = 7
                let paddingView = UIView(frame: CGRectMake(0, 0, 10, c.frame.height))
                c.leftView = paddingView
                c.leftViewMode = .always
            }
            signIn.addSubview(i)
        }
        
        for i in [signInEmailError, signInPasswordError]{
            if let c = i as? UILabel{
                c.font = UIFont(name: "LilGrotesk-Regular", size: 20)
                c.textColor = Colors.red
                c.textAlignment = .right
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
        
        nextButton = UIButton(frame: CGRect(x: midX + 10, y: fullY - 200 + 50, width: 150, height: 50))
        nextButton.backgroundColor = Colors.secondaryBackground
        nextButton.setTitle("Next >", for: .normal)
        nextButton.setTitleColor(Colors.text, for: .normal)
        nextButton.layer.cornerRadius = 10
        nextButton.titleLabel!.font = UIFont(name: "LilGrotesk-Regular", size: 20)
        nextButton.addTarget(self, action: #selector(nextButtonPressed(_:)) , for: .touchUpInside)
        scrollFrame.addSubview(nextButton)
        backButton = UIButton(frame: CGRect(x: midX - 160, y: fullY - 200 + 50, width: 150, height: 50))
        backButton.backgroundColor = Colors.secondaryBackground
        backButton.setTitle("< Back", for: .normal)
        backButton.setTitleColor(Colors.text, for: .normal)
        backButton.layer.cornerRadius = 10
        backButton.titleLabel!.font = UIFont(name: "LilGrotesk-Regular", size: 20)
        backButton.addTarget(self, action: #selector(backButtonPressed(_:)), for: .touchUpInside)
        backButton.isEnabled = false
        backButton.alpha = 0.5
        scrollFrame.addSubview(backButton)
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
        view.endEditing(true)
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
            let email = signInEmail.text
            let password = signInPassword.text
            if(email != nil && isValidEmail(email!)){
                signInEmailError.text = ""
                if(password != nil && isValidPassword(password!)){
                    signInPasswordError.text = ""
                    backButton.isEnabled = false
                    nextButton.isEnabled = false
                    Auth.auth().signIn(withEmail: signInEmail.text!, password: signInPassword.text!) { authResult, error in
                        if let error = error {
                            self.signInPasswordError.text = "Incorrect password"
                            self.backButton.isEnabled = true
                            self.nextButton.isEnabled = true
                        }else{
                            self.signInPasswordError.text = ""
                            UIView.animate(withDuration: 0.5, animations: {
                                self.signIn.frame = CGRect(x: -fullX, y: 0, width: fullX, height: fullY)
                                self.success.frame = CGRect(x: 0, y: 0, width: fullX, height: fullY)
                                self.backButton.alpha = 0.5
                            })
                            self.nextButton.isEnabled = true
                            self.page+=1
                            
                        }
                    }
                }else{
                    signInPasswordError.text = "Invalid password"
                }
            }else{
                signInEmailError.text = "Invalid email"
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
        view.endEditing(true)
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
        scrollFrame.contentSize = CGSize(width: fullX, height: fullY)
        scrollFrame.frame = CGRect(x: 0, y: 0, width: fullX, height: fullY - keyboard)
        //scrollFrame.backgroundColor = .red
//        welcomeView.frame = CGRect(x: 0, y: 0, width: fullX, height: fullY - keyboard)
//        infoView.frame = CGRect(x: infoView.frame.minX, y: 0, width: fullX, height: fullY - keyboard)
//        signUpOrIn.frame = CGRect(x: signUpOrIn.frame.minX, y: 0, width: fullX, height: fullY - keyboard)
//        signUp.frame = CGRect(x: signUp.frame.minX, y: 0, width: fullX, height: fullY - keyboard)
//        signIn.frame = CGRect(x: signIn.frame.minX, y: 0, width: fullX, height: fullY - keyboard - 100)
//        success.frame = CGRect(x: success.frame.minX, y: 0, width: fullX, height: fullY - keyboard)
    }
    
    @objc func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: self) { result, error in
            if let error = error {
                print("Google Sign-In failed: \(error.localizedDescription)")
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                print("Failed to retrieve tokens.")
                return
            }
            
            let accessToken = user.accessToken.tokenString

            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase Auth failed: \(error.localizedDescription)")
                    return
                }

                guard let authResult = authResult else { return }

                let isNew = authResult.additionalUserInfo?.isNewUser ?? false
                let email = authResult.user.email ?? ""
                let username = email.components(separatedBy: "@").first ?? "user"

                if isNew {
                    self.db.collection("users").document(authResult.user.uid).setData([
                        "name": authResult.user.displayName ?? "",
                        "username": username,
                        "email": email,
                        "subscription": ["status": "inactive"],
                        "transactions": [],
                        "createdSets": [],
                        "studiedSets": [],
                        "likedSets": [],
                        "settings": ["theme": "Dark"]
                    ]) { err in
                        if let err = err {
                            print("Firestore error: \(err)")
                        } else {
                            print("New user created")
                        }
                    }
                } else {
                    print("Welcome back!")
                }
                
                self.backButton.isEnabled = false
                self.nextButton.isEnabled = true
                self.page = 5
                
                let fullX = self.view.frame.width
                let fullY = self.view.frame.height
                
                UIView.animate(withDuration: 0.5, animations: {
                    self.signUpOrIn.frame = CGRect(x: -fullX, y: 0, width: fullX, height: fullY)
                    self.success.frame = CGRect(x: 0, y: 0, width: fullX, height: fullY)
                    self.backButton.alpha = 0.5
                    self.nextButton.alpha = 1
                })
                
            }
        }
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
