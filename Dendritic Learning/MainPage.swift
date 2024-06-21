//
//  MainPage.swift
//  StudyApp
//
//  Created by Tirth D. Patel on 4/16/24.
//
import UIKit
import FirebaseAuth
import FirebaseFirestore
import Firebase

class MainPage: UIViewController, NewSetDelegate {
//    var isDarkMode = false // State variable to track dark mode
    
    //let buttonSize: CGFloat = 170 // Adjust button size here
    
    let defaults = UserDefaults.standard
    
    let scrollView = UIScrollView()
    let stackView = UIStackView()
    
    var destination = ""
    var destinationSet = ""
    
    var recentSets: [[String: Any]] = []
    var mySets: [[String: Any]] = []
    
    var goToEditor = false
    
    let db = Firestore.firestore()
    
    var userData: [String: Any] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        for family in UIFont.familyNames {
//            print("family: \(family)")
//            for name in UIFont.fontNames(forFamilyName: family){
//                print("        Font: \(name)~")
//            }
//        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setup()
    }
    
    func setup(){
        recentSets = []
        mySets = []
        if let data = defaults.value(forKey: "sets") as? [Dictionary<String, Any>]{
            if let uid = Auth.auth().currentUser?.uid{
                let dataRef = db.collection("users").document(uid)
                dataRef.getDocument { (document, error) in
                    if let document = document, document.exists {
                        self.userData = document.data()!
                        if let theme = (self.userData["settings"] as? [String: Any])!["theme"]{
                            for j in Colors.themes {
                                if j[0] as! String == theme as! String {
                                    Colors.background = j[1] as! UIColor
                                    Colors.secondaryBackground = j[2] as! UIColor
                                    Colors.darkHighlight = j[3] as! UIColor
                                    Colors.highlight = j[4] as! UIColor
                                    Colors.lightHighlight = j[5] as! UIColor
                                    Colors.text = j[6] as! UIColor
                                }
                            }
                        }
                        
                         
                        if let sets = self.userData["studiedSets"]{
                            self.recentSets = sets as! [[String: Any]]
                        }
                        let mySetIDs = self.userData["createdSets"] as! [String]
                        for i in self.recentSets {
                            if(mySetIDs.firstIndex(of: i["setID"] as! String) != nil){
                                self.mySets.append(i)
                            }
                        }
                        
                        if let subscription = self.userData["subscription"] as? [String: Any] {
                            if subscription["status"] as! String == "inactive" {
                                self.defaults.set(false, forKey: "isPaid")
                            }
                        }
                    } else {
                        print("Document does not exist")
                    }
                }
            }
//            for (index, i) in data.enumerated() {
//                sets.append([i["name"] as! String, i["type"] as! String, (defaults.value(forKey: "images") as! [Data?])[index]])
//            }
        }else{
            defaults.setValue(false, forKey: "fingerDrawing")
            
            performSegue(withIdentifier: "newUserVC", sender: nil)
        }
        
        for subview in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        stackView.removeFromSuperview()
        for subview in view.subviews {
            subview.removeFromSuperview()
        }
        
        view.backgroundColor = Colors.background
        
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .leading
        scrollView.addSubview(stackView)
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 60),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -60),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 60),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -60),
//            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -100)
        ])
        
        let topBar = UIView()
        topBar.heightAnchor.constraint(equalToConstant: 50).isActive = true
        stackView.addArrangedSubview(topBar)
        topBar.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
        let icon = UIImageView(image: UIImage(named: "DendriticLearningIcon-01.svg")?.withRenderingMode(.alwaysTemplate))
        icon.tintColor = Colors.highlight
        icon.contentMode = .scaleAspectFit
        topBar.addSubview(icon)
        con(icon, 50, 50)
        icon.leadingAnchor.constraint(equalTo: topBar.leadingAnchor).isActive = true
        icon.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "Dendritic Learning"
        titleLabel.textColor = Colors.text
        titleLabel.font = UIFont(name: "LilGrotesk-Black", size: 30)
        topBar.addSubview(titleLabel)
        titleLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        titleLabel.widthAnchor.constraint(equalToConstant: 400).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 10).isActive = true
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let settingsIcon = UIImageView()
        settingsIcon.image = UIImage(systemName: "gear")
        settingsIcon.contentMode = .scaleAspectFit
        settingsIcon.tintColor = Colors.highlight
        settingsIcon.heightAnchor.constraint(equalToConstant: 50).isActive = true
        settingsIcon.widthAnchor.constraint(equalToConstant: 50).isActive = true
        topBar.addSubview(settingsIcon)
        settingsIcon.trailingAnchor.constraint(equalTo: topBar.trailingAnchor).isActive = true
        settingsIcon.translatesAutoresizingMaskIntoConstraints = false
        
        let settingsButton = UIButton()
        settingsButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        settingsButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        topBar.addSubview(settingsButton)
        settingsButton.trailingAnchor.constraint(equalTo: topBar.trailingAnchor).isActive = true
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.addTarget(self, action: #selector(settings(_:)), for: .touchUpInside)
        
        let breakView0 = UIView()
        breakView0.widthAnchor.constraint(equalToConstant: 30).isActive = true
        breakView0.heightAnchor.constraint(equalToConstant: 30).isActive = true
        stackView.addArrangedSubview(breakView0)
        
        let recentLabel = UILabel()
        recentLabel.text = "Recent sets"
        recentLabel.font = UIFont(name: "LilGrotesk-Black", size: 50)
        con(recentLabel, 300, 50)
        recentLabel.textColor = Colors.text
        recentLabel.isUserInteractionEnabled = true
        stackView.addArrangedSubview(recentLabel)
        let newButton = UIButton()
        newButton.frame = CGRect(x: 250, y: 5, width: 40, height: 40)
        recentLabel.addSubview(newButton)
        newButton.setImage(UIImage(systemName: "plus.app.fill"), for: .normal)
        newButton.contentHorizontalAlignment = .fill
        newButton.contentVerticalAlignment = .fill
        newButton.imageView?.contentMode = .scaleAspectFit
        newButton.tintColor = Colors.highlight
        newButton.addTarget(self, action: #selector(newSet(_:)), for: .touchUpInside)
        if(recentSets.count > 0){
            for i in 0...((recentSets.count - 1)/3) {
                let row = UIStackView()
                row.axis = .horizontal
                row.spacing = 20
                row.alignment = .leading
                row.translatesAutoresizingMaskIntoConstraints = false
                stackView.addArrangedSubview(row)
                NSLayoutConstraint.activate([
                    row.widthAnchor.constraint(equalTo: stackView.widthAnchor),
                    row.heightAnchor.constraint(equalToConstant: 100)
                ])
                for j in 3*i...(3*i) + 2 {
                    if(recentSets.count > j){
                        let setView = UIView()
                        row.addArrangedSubview(setView)
                        var image = UIImageView()
                        if recentSets[j]["image"] as? Data != nil && recentSets[j]["image"] as? Data != Colors.placeholderI {
                            image = UIImageView(image: UIImage(data: recentSets[j]["image"] as! Data))
                            image.layer.cornerRadius = 10
                            image.contentMode = .scaleAspectFill
                            image.clipsToBounds = true
                        }else{
                            setView.backgroundColor = Colors.secondaryBackground
                        }
                        setView.addSubview(image)
                        let setLabel = UILabel()
                        setLabel.text = recentSets[j]["name"] as? String
                        setView.addSubview(setLabel)
                        image.translatesAutoresizingMaskIntoConstraints = false
                        setView.translatesAutoresizingMaskIntoConstraints = false
                        setLabel.translatesAutoresizingMaskIntoConstraints = false
                        setLabel.textColor = Colors.text
                        setLabel.textAlignment = .center
                        setLabel.font = UIFont(name: "LilGrotesk-Regular", size: 25)
                        setView.layer.cornerRadius = 10
                        let setButton = UIButton()
                        setButton.accessibilityIdentifier = "r" + String(j)
                        setButton.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
                        setButton.translatesAutoresizingMaskIntoConstraints = false
                        setView.addSubview(setButton)
                        NSLayoutConstraint.activate([
                            setView.widthAnchor.constraint(equalToConstant: (view.frame.width - 160)/3),
                            setView.heightAnchor.constraint(equalTo: row.heightAnchor),
                            setLabel.topAnchor.constraint(equalTo: setView.topAnchor),
                            setLabel.bottomAnchor.constraint(equalTo: setView.bottomAnchor),
                            setLabel.leadingAnchor.constraint(equalTo: setView.leadingAnchor),
                            setLabel.trailingAnchor.constraint(equalTo: setView.trailingAnchor),
                            setButton.topAnchor.constraint(equalTo: setView.topAnchor),
                            setButton.bottomAnchor.constraint(equalTo: setView.bottomAnchor),
                            setButton.leadingAnchor.constraint(equalTo: setView.leadingAnchor),
                            setButton.trailingAnchor.constraint(equalTo: setView.trailingAnchor),
                            image.topAnchor.constraint(equalTo: setView.topAnchor),
                            image.bottomAnchor.constraint(equalTo: setView.bottomAnchor),
                            image.leadingAnchor.constraint(equalTo: setView.leadingAnchor),
                            image.trailingAnchor.constraint(equalTo: setView.trailingAnchor),
                        ])
                    }else{
                        let setView = UIView()
                        row.addArrangedSubview(setView)
                        NSLayoutConstraint.activate([
                            setView.widthAnchor.constraint(equalToConstant: (view.frame.width - 160)/3),
                            setView.heightAnchor.constraint(equalTo: row.heightAnchor),
                        ])
                    }
                }
            }
        }
        let yourLabel = UILabel()
        yourLabel.text = "Your sets"
        yourLabel.font = UIFont(name: "LilGrotesk-Black", size: 50)
        con(yourLabel, 300, 50)
        yourLabel.textColor = Colors.text
        yourLabel.isUserInteractionEnabled = true
        stackView.addArrangedSubview(yourLabel)
//        let newButton = UIButton()
//        newButton.frame = CGRect(x: 250, y: 5, width: 40, height: 40)
//        recentLabel.addSubview(newButton)
//        newButton.setImage(UIImage(systemName: "plus.app.fill"), for: .normal)
//        newButton.contentHorizontalAlignment = .fill
//        newButton.contentVerticalAlignment = .fill
//        newButton.imageView?.contentMode = .scaleAspectFit
//        newButton.tintColor = Colors.highlight
//        newButton.addTarget(self, action: #selector(newSet(_:)), for: .touchUpInside)
        if(mySets.count > 0){
            for i in 0...((mySets.count - 1)/3) {
                let row = UIStackView()
                row.axis = .horizontal
                row.spacing = 20
                row.alignment = .leading
                row.translatesAutoresizingMaskIntoConstraints = false
                stackView.addArrangedSubview(row)
                NSLayoutConstraint.activate([
                    row.widthAnchor.constraint(equalTo: stackView.widthAnchor),
                    row.heightAnchor.constraint(equalToConstant: 100)
                ])
                for j in 3*i...(3*i) + 2 {
                    if(mySets.count > j){
                        let setView = UIView()
                        row.addArrangedSubview(setView)
                        var image = UIImageView()
                        if mySets[j]["image"] as? Data != nil && mySets[j]["image"] as? Data != Colors.placeholderI  {
                            image = UIImageView(image: UIImage(data: mySets[j]["image"] as! Data))
                            image.layer.cornerRadius = 10
                            image.contentMode = .scaleAspectFill
                            image.clipsToBounds = true
                        }else{
                            setView.backgroundColor = Colors.secondaryBackground
                        }
                        setView.addSubview(image)
                        let setLabel = UILabel()
                        setLabel.text = mySets[j]["name"] as? String
                        setView.addSubview(setLabel)
                        image.translatesAutoresizingMaskIntoConstraints = false
                        setView.translatesAutoresizingMaskIntoConstraints = false
                        setLabel.translatesAutoresizingMaskIntoConstraints = false
                        setLabel.textColor = Colors.text
                        setLabel.textAlignment = .center
                        setLabel.font = UIFont(name: "LilGrotesk-Regular", size: 25)
                        setView.layer.cornerRadius = 10
                        let setButton = UIButton()
                        setButton.accessibilityIdentifier = "m" + String(j)
                        setButton.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
                        setButton.translatesAutoresizingMaskIntoConstraints = false
                        setView.addSubview(setButton)
                        NSLayoutConstraint.activate([
                            setView.widthAnchor.constraint(equalToConstant: (view.frame.width - 160)/3),
                            setView.heightAnchor.constraint(equalTo: row.heightAnchor),
                            setLabel.topAnchor.constraint(equalTo: setView.topAnchor),
                            setLabel.bottomAnchor.constraint(equalTo: setView.bottomAnchor),
                            setLabel.leadingAnchor.constraint(equalTo: setView.leadingAnchor),
                            setLabel.trailingAnchor.constraint(equalTo: setView.trailingAnchor),
                            setButton.topAnchor.constraint(equalTo: setView.topAnchor),
                            setButton.bottomAnchor.constraint(equalTo: setView.bottomAnchor),
                            setButton.leadingAnchor.constraint(equalTo: setView.leadingAnchor),
                            setButton.trailingAnchor.constraint(equalTo: setView.trailingAnchor),
                            image.topAnchor.constraint(equalTo: setView.topAnchor),
                            image.bottomAnchor.constraint(equalTo: setView.bottomAnchor),
                            image.leadingAnchor.constraint(equalTo: setView.leadingAnchor),
                            image.trailingAnchor.constraint(equalTo: setView.trailingAnchor),
                        ])
                    }else{
                        let setView = UIView()
                        row.addArrangedSubview(setView)
                        NSLayoutConstraint.activate([
                            setView.widthAnchor.constraint(equalToConstant: (view.frame.width - 160)/3),
                            setView.heightAnchor.constraint(equalTo: row.heightAnchor),
                        ])
                    }
                }
            }
        }
    }
    
    @objc func newSet(_ sender: UIButton){
        let popupVC = NewSetVC()
        popupVC.delegate = self
        popupVC.modalPresentationStyle = .overCurrentContext
        popupVC.modalTransitionStyle = .crossDissolve
        present(popupVC, animated: true, completion: nil)
    }
    
    @objc func settings(_ sender: UIButton){
        destination = "settings"
        performSegue(withIdentifier: "settingsVC", sender: nil)
    }
    
    @objc func buttonTapped(_ sender: UIButton) {
        
        if(String(sender.accessibilityIdentifier!.first!) == "r"){
            destinationSet = recentSets[Int(sender.accessibilityIdentifier!.dropFirst())!]["setID"] as! String
            if(recentSets[Int(sender.accessibilityIdentifier!.dropFirst())!]["type"] as! String == "standard"){
                destination = "standard"
                performSegue(withIdentifier: "viewStandardSet", sender: self)
            }else{
                destination = "web"
                performSegue(withIdentifier: "viewWebSet", sender: self)
            }
        }else{
            destinationSet = mySets[Int(sender.accessibilityIdentifier!.dropFirst())!]["setID"] as! String
            if(mySets[Int(sender.accessibilityIdentifier!.dropFirst())!]["type"] as! String == "standard"){
                destination = "standard"
                performSegue(withIdentifier: "viewStandardSet", sender: self)
            }else{
                destination = "web"
                performSegue(withIdentifier: "viewWebSet", sender: self)
            }
        }
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        segue.destination.modalPresentationStyle = .fullScreen
        if(destination == "settings"){
            //guard let vc = segue.destination as? SettingsVC else {return}
            //idk
        }else if(destination == "newUser"){
            //guard let vc = segue.destination as? NewUserVC else {return}
        }else if(destination == "standard"){
            guard let vc = segue.destination as? StandardSetVC else {return}
            if(goToEditor){
                vc.goToEditor = true
            }
            vc.set = destinationSet
        }else{
            guard let vc = segue.destination as? WebSetVC else {return}
            if(goToEditor){
                vc.goToEditor = true
            }
            vc.set = destinationSet
        }
        goToEditor = false
    }
    
    @IBAction func cancel (_ unwindSegue: UIStoryboardSegue){
        
    }
    
    func newSetType(type: String){
        goToEditor = true
        var newSet: [String: Any] = [:]
        newSet["name"] = "New Set"
        newSet["author"] = userData["username"]!
        newSet["authorID"] = Auth.auth().currentUser?.uid
        newSet["date"] = Timestamp()
        newSet["version"] = Colors.version
        newSet["image"] = nil
        var studiedSet: [String: Any] = [:]
        studiedSet["name"] = "New Set"
        studiedSet["image" ] = nil
        if(type == "Standard"){
            newSet["type"] = "standard"
            newSet["set"] = [["t", "Example term", "t", "Example definition"]]
            studiedSet["type"] = "standard"
            studiedSet["learn"] = [0]
            studiedSet["flashcards"] = [false]
        }else if(type == "Web"){
            newSet["type"] = "web"
            newSet["set"] = []
            studiedSet["type"] = "web"
        }
        
        let ref = db.collection("sets").addDocument(data: newSet) { error in
            if let error = error {
                print("Error adding document: \(error)")
                return
            } else {
                if(type == "Standard"){
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                        self.performSegue(withIdentifier: "viewStandardSet", sender: self)
                    }
                }else{
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                        self.performSegue(withIdentifier: "viewWebSet", sender: self)
                    }
                }
            }
        }
        self.destination = ref.documentID
        studiedSet["setID"] = ref.documentID
        var newMy = userData["mySets"] as! [String]
        newMy.append(ref.documentID)
        var newStudied = userData["studiedSets"] as! [[String: Any]]
        
        db.collection("users").document(Auth.auth().currentUser!.uid).setData([
            "mySets": newMy,
            "studiedSets": newStudied
        ], merge: true)
    }
    
    func newImport() {
        setup()
    }
}
