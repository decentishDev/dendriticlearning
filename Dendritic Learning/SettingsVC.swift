//
//  SettingsVC.swift
//  StudyApp
//
//  Created by Matthew Lundeen on 6/4/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class SettingsVC: UIViewController {

    let defaults = UserDefaults.standard
    
    let scrollView = UIScrollView()
    let stackView = UIStackView()
    
    var colorSegment = UISegmentedControl()
    
    var userData: [String: Any] = [:]
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.background
        if let uid = Auth.auth().currentUser?.uid {
            let dataRef = db.collection("users").document(uid)
            dataRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    self.userData = document.data()!
//                    self.updateColors()
//                    self.updateSets()
                    
                    DispatchQueue.main.async {
                        self.setup()
                    }
                } else {
                    print("Document does not exist")
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "newUserVC", sender: nil)
                    }
                }
            }
        }
        //setup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //setup()
    }
    
    func setup() {
        view.backgroundColor = Colors.background
        // Clear any existing views
        for subview in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        stackView.removeFromSuperview()
        for subview in view.subviews {
            subview.removeFromSuperview()
        }
        
        // Configure stackView and scrollView
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .leading
        scrollView.addSubview(stackView)
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 50),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -50),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 50),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -50),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -100)
        ])
        
        // Add other subviews
        let backButton = UIButton()
        backButton.setTitle("< Back", for: .normal)
        backButton.titleLabel!.font = UIFont(name: "LilGrotesk-Bold", size: 20)
        backButton.addTarget(self, action: #selector(self.backButton(sender:)), for: .touchUpInside)
        backButton.setTitleColor(Colors.highlight, for: .normal)
        stackView.addArrangedSubview(backButton)
        
        addBreakView(stackView, 15)
        
        let titleLabel = UILabel()
        titleLabel.text = "Settings"
        titleLabel.font = UIFont(name: "LilGrotesk-Black", size: 50)
        titleLabel.sizeToFit()
        titleLabel.textColor = Colors.text
        stackView.addArrangedSubview(titleLabel)
        
        addBreakView(stackView, 15)
        
        let colorLabel = UILabel()
        colorLabel.text = "Color theme"
        colorLabel.font = UIFont(name: "LilGrotesk-Regular", size: 30)
        colorLabel.sizeToFit()
        colorLabel.textColor = Colors.text
        stackView.addArrangedSubview(colorLabel)
        
        // Setup horizontal scroll view for color themes
        let colorScroll = UIScrollView()
        colorScroll.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(colorScroll)
        
        let colorStack = UIStackView()
        colorStack.axis = .horizontal
        colorStack.spacing = 10
        colorStack.alignment = .leading
        colorScroll.addSubview(colorStack)
        colorStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            colorScroll.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            colorScroll.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            colorScroll.heightAnchor.constraint(equalToConstant: 100),
            
            colorStack.topAnchor.constraint(equalTo: colorScroll.topAnchor),
            colorStack.bottomAnchor.constraint(equalTo: colorScroll.bottomAnchor),
            colorStack.leadingAnchor.constraint(equalTo: colorScroll.leadingAnchor),
            colorStack.trailingAnchor.constraint(equalTo: colorScroll.trailingAnchor)
        ])
        
        for (i, color) in Colors.themes.enumerated() {
            let button = UIButton()
            button.widthAnchor.constraint(equalToConstant: 200).isActive = true
            button.heightAnchor.constraint(equalToConstant: 100).isActive = true
            button.backgroundColor = color[2] as? UIColor
            button.setTitle(color[0] as? String, for: .normal)
            button.setTitleColor(color[5] as? UIColor, for: .normal)
            button.titleLabel!.font = UIFont(name: "LilGrotesk-Regular", size: 20)
            button.layer.cornerRadius = 10
            colorStack.addArrangedSubview(button)
            button.accessibilityIdentifier = String(i)
            button.addTarget(self, action: #selector(self.themeButton(sender:)), for: .touchUpInside)
        }
        
        addBreakView(stackView, 15)
        
        let pencilLabel = UILabel()
        pencilLabel.text = "Allows drawing with fingers"
        pencilLabel.font = UIFont(name: "LilGrotesk-Regular", size: 30)
        pencilLabel.frame = CGRect(x: 0, y: 0, width: view.frame.width - 100, height: 40)
        con(pencilLabel, view.frame.width - 100, 40)
        pencilLabel.textColor = Colors.text
        stackView.addArrangedSubview(pencilLabel)
        //pencilLabel.backgroundColor = .red
        pencilLabel.clipsToBounds = false
        pencilLabel.isUserInteractionEnabled = true
        
        let pencilSwitch = UISwitch(frame: CGRect(x: view.frame.width - 100 - 55, y: 5, width: 40, height: 40))
        pencilLabel.addSubview(pencilSwitch)
        pencilSwitch.isOn = defaults.value(forKey: "fingerDrawing")  as! Bool 
        pencilSwitch.addTarget(self, action: #selector(self.pencilSwitched(sender:)), for: .valueChanged)
        pencilSwitch.isUserInteractionEnabled = true
        //pencilSwitch.backgroundColor = .green
        addBreakView(stackView, 15)
        let accountLabel = UILabel()
        accountLabel.text = "Account options"
        accountLabel.font = UIFont(name: "LilGrotesk-Bold", size: 40)
        accountLabel.sizeToFit()
        accountLabel.textColor = Colors.text
        stackView.addArrangedSubview(accountLabel)
        
        let signOutButton = UIButton(frame: CGRect(x: 0, y: 0, width: ("Sign out" as NSString).size(withAttributes: [NSAttributedString.Key.font: UIFont(name: "LilGrotesk-Bold", size: 25)!]).width + 35, height: 50))
        con(signOutButton, ("Sign out" as NSString).size(withAttributes: [NSAttributedString.Key.font: UIFont(name: "LilGrotesk-Bold", size: 25)!]).width + 35, 50)
        signOutButton.backgroundColor = Colors.secondaryBackground
        signOutButton.layer.cornerRadius = 10
        signOutButton.setTitle("Sign out", for: .normal)
        signOutButton.setTitleColor(Colors.highlight, for: .normal)
        signOutButton.titleLabel!.font = UIFont(name: "LilGrotesk-Bold", size: 25)
        signOutButton.addTarget(self, action: #selector(self.signOut(sender:)), for: .touchUpInside)
        stackView.addArrangedSubview(signOutButton)
        let resetPasswordButton = UIButton(frame: CGRect(x: 0, y: 0, width: ("Reset password" as NSString).size(withAttributes: [NSAttributedString.Key.font: UIFont(name: "LilGrotesk-Bold", size: 25)!]).width + 35, height: 50))
        con(resetPasswordButton, ("Reset password" as NSString).size(withAttributes: [NSAttributedString.Key.font: UIFont(name: "LilGrotesk-Bold", size: 25)!]).width + 35, 50)
        resetPasswordButton.backgroundColor = Colors.secondaryBackground
        resetPasswordButton.layer.cornerRadius = 10
        resetPasswordButton.setTitle("Reset password", for: .normal)
        resetPasswordButton.setTitleColor(Colors.highlight, for: .normal)
        resetPasswordButton.titleLabel!.font = UIFont(name: "LilGrotesk-Bold", size: 25)
        resetPasswordButton.addTarget(self, action: #selector(self.resetPassword(sender:)), for: .touchUpInside)
        stackView.addArrangedSubview(resetPasswordButton)
        let deleteAccountButton = UIButton(frame: CGRect(x: 0, y: 0, width: ("Delete account" as NSString).size(withAttributes: [NSAttributedString.Key.font: UIFont(name: "LilGrotesk-Bold", size: 25)!]).width + 35, height: 50))
        con(deleteAccountButton, ("Delete account" as NSString).size(withAttributes: [NSAttributedString.Key.font: UIFont(name: "LilGrotesk-Bold", size: 25)!]).width + 35, 50)
        deleteAccountButton.backgroundColor = Colors.secondaryBackground
        deleteAccountButton.layer.cornerRadius = 10
        deleteAccountButton.setTitle("Delete account", for: .normal)
        deleteAccountButton.setTitleColor(Colors.highlight, for: .normal)
        deleteAccountButton.titleLabel!.font = UIFont(name: "LilGrotesk-Bold", size: 25)
        deleteAccountButton.addTarget(self, action: #selector(self.deleteAccount(sender:)), for: .touchUpInside)
        stackView.addArrangedSubview(deleteAccountButton)
        
    }

    @objc func themeButton(sender: UIButton){
        let i = Int(sender.accessibilityIdentifier!)!
        defaults.set(Colors.themes[i][0] as! String, forKey: "theme")
        var settings = userData["settings"] as? [String: Any]
        settings!["theme"] = Colors.themes[i][0] as! String
        userData["settings"] = settings
        Colors.background = Colors.themes[i][1] as! UIColor
        Colors.secondaryBackground = Colors.themes[i][2] as! UIColor
        Colors.darkHighlight = Colors.themes[i][3] as! UIColor
        Colors.highlight = Colors.themes[i][4] as! UIColor
        Colors.lightHighlight = Colors.themes[i][5] as! UIColor
        Colors.text = Colors.themes[i][6] as! UIColor
        setup()
        save()
    }
    @objc func signOut(sender: UIButton){
        let alertController = UIAlertController(title: nil, message: "Are you sure you want to sign out?", preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) {_ in
            do {
                try Auth.auth().signOut()
            } catch {
                print("Error signing out: \(error)")
            }
            self.performSegue(withIdentifier: "settingsVC_unwind", sender: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
 
    }
    
    @objc func resetPassword(sender: UIButton){
        Auth.auth().sendPasswordReset(withEmail: userData["email"] as! String)
        let endController = UIAlertController(title: "A link to reset your password has been sent to: " + (userData["email"] as! String), message: nil, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Confirm", style: .default, handler: nil)
        endController.addAction(confirmAction)
        self.present(endController, animated: true, completion: nil)
    }
    
    @objc func deleteAccount(sender: UIButton) {
        let alertController = UIAlertController(title: nil, message: "Are you sure you want to delete your account and all your sets? This is permanent and no data can be recovered.", preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            let alertControl = UIAlertController(title: "Enter your password to confirm this action.", message: nil, preferredStyle: .alert)
            alertControl.addTextField { (textField) in
                textField.placeholder = "Password"
                textField.isSecureTextEntry = true
                textField.textContentType = .password
            }
            let confirmAction = UIAlertAction(title: "Confirm", style: .destructive) { [weak alertControl] _ in
                if let textField = alertControl?.textFields?.first, let text = textField.text {
                    for i in self.view.subviews {
                        i.removeFromSuperview()
                    }
                    let loadingImage = createLoadingIcon()
                    loadingImage.center = self.view.center
                    self.view.addSubview(loadingImage)
                    
                    guard let user = Auth.auth().currentUser else { return }
                    let uid = user.uid
                    let db = Firestore.firestore()
                    let storage = Storage.storage()
                    
                    // Prompt user to reauthenticate
                    let credential = EmailAuthProvider.credential(withEmail: user.email!, password: text) // You need to get the password from the user
                    
                    user.reauthenticate(with: credential) { authResult, error in
                        if let error = error {
                            print("Reauthentication failed: \(error)")
                            return
                        }
                        
                        let userDocRef = db.collection("users").document(uid)
                        
                        db.runTransaction({ (transaction, errorPointer) -> Any? in
                            // Get user document
                            let userDocument: DocumentSnapshot
                            do {
                                try userDocument = transaction.getDocument(userDocRef)
                            } catch let error as NSError {
                                errorPointer?.pointee = error
                                return nil
                            }
                            
                            guard let likedSets = userDocument.data()?["likedSets"] as? [String],
                                  let createdSets = userDocument.data()?["createdSets"] as? [String] else {
                                return nil
                            }
                            
                            // Update likes for likedSets
                            for setID in likedSets {
                                let setDocRef = db.collection("sets").document(setID)
                                transaction.updateData(["likes": FieldValue.increment(Int64(-1))], forDocument: setDocRef)
                            }
                            
                            // Delete created sets
                            for setID in createdSets {
                                let setDocRef = db.collection("sets").document(setID)
                                transaction.deleteDocument(setDocRef)
                            }
                            
                            // Delete user document
                            transaction.deleteDocument(userDocRef)
                            
                            return nil
                        }) { (object, error) in
                            if let error = error {
                                print("Transaction failed: \(error)")
                            } else {
                                print("Transaction successfully committed!")
                                
                                // Delete user's folder from storage
                                let userFolderRef = storage.reference().child(uid)
                                userFolderRef.listAll { (result, error) in
                                    if let error = error {
                                        print("Error listing user folder: \(error)")
                                    } else {
                                        let dispatchGroup = DispatchGroup()
                                        
                                        for item in result!.items {
                                            dispatchGroup.enter()
                                            item.delete { error in
                                                if let error = error {
                                                    print("Error deleting item \(item): \(error)")
                                                } else {
                                                    print("Item \(item) deleted successfully.")
                                                }
                                                dispatchGroup.leave()
                                            }
                                        }
                                        
                                        dispatchGroup.notify(queue: .main) {
                                            print("All items deleted.")
                                            
                                            // Delete user account from authentication
                                            user.delete { error in
                                                if let error = error {
                                                    print("Error deleting user: \(error)")
                                                } else {
                                                    print("User deleted successfully.")
                                                    self.performSegue(withIdentifier: "settingsVC_unwind", sender: nil)
                                                    loadingImage.removeFromSuperview()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertControl.addAction(confirmAction)
            alertControl.addAction(cancelAction)
            self.present(alertControl, animated: true, completion: nil)
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }

    
    @objc func pencilSwitched(sender: UISwitch){
        defaults.setValue(sender.isOn, forKey: "fingerDrawing")
    }
    
    @objc func backButton(sender: UIButton){
        performSegue(withIdentifier: "settingsVC_unwind", sender: nil)
    }
    
    @IBAction func cancel (_ unwindSegue: UIStoryboardSegue){
        
    }
    
    func save(){
        db.collection("users").document(Auth.auth().currentUser!.uid).setData(userData, merge: true)
    }
}
