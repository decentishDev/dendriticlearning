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
    
    var loadingImage = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        for family in UIFont.familyNames {
//            print("family: \(family)")
//            for name in UIFont.fontNames(forFamilyName: family){
//                print("        Font: \(name)~")
//            }
//        }
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
        ])
        
        
        let topBar = createTopBar()
        stackView.addArrangedSubview(topBar)
        let breakView0 = UIView()
        breakView0.widthAnchor.constraint(equalToConstant: 30).isActive = true
        breakView0.heightAnchor.constraint(equalToConstant: 30).isActive = true
        stackView.addArrangedSubview(breakView0)
        
        loadingImage = createLoadingIcon()
        loadingImage.center = view.center
        view.addSubview(loadingImage)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setup()
        
    }
    
    func setup(){
        recentSets = []
        mySets = []
        
        // Clear existing views
        
        
        
        // Check for user settings and auth status
        if let fingerDrawing = defaults.value(forKey: "fingerDrawing") as? Bool, let uid = Auth.auth().currentUser?.uid {
            let dataRef = db.collection("users").document(uid)
            dataRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    self.userData = document.data()!
                    self.updateColors()
                    self.updateSets()
                    
                    DispatchQueue.main.async {
                        self.setupUI()
                        self.loadingImage.removeFromSuperview()
                    }
                } else {
                    print("Document does not exist")
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "newUserVC", sender: nil)
                        self.loadingImage.removeFromSuperview()
                    }
                }
            }
        } else {
            defaults.setValue(false, forKey: "fingerDrawing")
            defaults.setValue("dark", forKey: "theme")
            performSegue(withIdentifier: "newUserVC", sender: nil)
        }
    }

    func updateColors() {
        if let theme = (self.userData["settings"] as? [String: Any])?["theme"] {
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
    }

    func updateSets() {
        if let sets = self.userData["studiedSets"] {
            self.recentSets = sets as! [[String: Any]]
        }
        if let mySetIDs = self.userData["createdSets"] as? [String] {
            for set in self.recentSets {
                if mySetIDs.contains(set["setID"] as! String) {
                    self.mySets.append(set)
                }
            }
        }
        if let subscription = self.userData["subscription"] as? [String: Any] {
            if subscription["status"] as! String == "inactive" {
                self.defaults.set(false, forKey: "isPaid")
            }else{
                self.defaults.set(true, forKey: "isPaid")
            }
        }
    }

    func setupUI() {
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
        ])
        
        
        let topBar = createTopBar()
        stackView.addArrangedSubview(topBar)
        let breakView0 = UIView()
        breakView0.widthAnchor.constraint(equalToConstant: 30).isActive = true
        breakView0.heightAnchor.constraint(equalToConstant: 30).isActive = true
        stackView.addArrangedSubview(breakView0)
        
        loadingImage = createLoadingIcon()
        loadingImage.center = view.center
        view.addSubview(loadingImage)
        
        let recentLabel = createSectionLabel(text: "Recent sets")
        stackView.addArrangedSubview(recentLabel)
        addSets(to: stackView, from: recentSets)
        let breakView1 = UIView()
        breakView1.widthAnchor.constraint(equalToConstant: 30).isActive = true
        breakView1.heightAnchor.constraint(equalToConstant: 30).isActive = true
        stackView.addArrangedSubview(breakView1)
        
        let yourLabel = createSectionLabel(text: "Your sets")
        let newButton = UIButton()
        newButton.frame = CGRect(x: 250, y: 5, width: 40, height: 40)
        yourLabel.addSubview(newButton)
        newButton.setImage(UIImage(systemName: "plus.app.fill"), for: .normal)
        newButton.contentHorizontalAlignment = .fill
        newButton.contentVerticalAlignment = .fill
        newButton.imageView?.contentMode = .scaleAspectFit
        newButton.tintColor = Colors.highlight
        newButton.addTarget(self, action: #selector(newSet(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(yourLabel)
        addSets(to: stackView, from: mySets)
    }

    func createTopBar() -> UIView {
        let topBar = UIView()
        con(topBar, view.frame.width - 120, 50)
        
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
        
        let searchIcon = UIImageView()
        searchIcon.image = UIImage(systemName: "magnifyingglass")
        searchIcon.contentMode = .scaleAspectFit
        searchIcon.tintColor = Colors.highlight
        searchIcon.heightAnchor.constraint(equalToConstant: 50).isActive = true
        searchIcon.widthAnchor.constraint(equalToConstant: 50).isActive = true
        topBar.addSubview(searchIcon)
        searchIcon.trailingAnchor.constraint(equalTo: settingsIcon.leadingAnchor, constant: -15).isActive = true
        searchIcon.translatesAutoresizingMaskIntoConstraints = false
        
        let searchButton = UIButton()
        searchButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        searchButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        topBar.addSubview(searchButton)
        searchButton.trailingAnchor.constraint(equalTo: settingsIcon.leadingAnchor, constant: -15).isActive = true
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.addTarget(self, action: #selector(search(_:)), for: .touchUpInside)
        
        return topBar
    }

    func createSectionLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont(name: "LilGrotesk-Black", size: 50)
        con(label, 300, 50)
        label.textColor = Colors.text
        label.isUserInteractionEnabled = true
        return label
    }

    func addSets(to stackView: UIStackView, from sets: [[String: Any]]) {
        for i in 0...((sets.count - 1) / 3) {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 20
            row.alignment = .leading
            row.translatesAutoresizingMaskIntoConstraints = false
            stackView.addArrangedSubview(row)
            con(row, view.frame.width - 120, 100)
            for j in 3 * i...(3 * i) + 2 {
                if sets.count > j {
                    let setView = createSetView(set: sets[j])
                    row.addArrangedSubview(setView)
                } else {
                    let setView = UIView()
                    row.addArrangedSubview(setView)
                    NSLayoutConstraint.activate([
                        //setView.widthAnchor.constraint(equalToConstant: (view.frame.width - 160) / 3),
                        setView.heightAnchor.constraint(equalTo: row.heightAnchor),
                    ])
                }
            }
        }
    }

    func createSetView(set: [String: Any]) -> UIView {
        let setView = UIView()
        var image = UIImageView()
        if set["image"] as! String != "" {
            loadImage(url: set["image"] as? String, imageView: image)
            image.layer.cornerRadius = 10
            image.contentMode = .scaleAspectFill
            image.clipsToBounds = true
        } else {
            setView.backgroundColor = Colors.secondaryBackground
        }
        setView.addSubview(image)
        let setLabel = UILabel()
        setLabel.text = set["name"] as? String
        setView.addSubview(setLabel)
        image.translatesAutoresizingMaskIntoConstraints = false
        setView.translatesAutoresizingMaskIntoConstraints = false
        setLabel.translatesAutoresizingMaskIntoConstraints = false
        setLabel.textColor = Colors.text
        setLabel.textAlignment = .center
        setLabel.font = UIFont(name: "LilGrotesk-Regular", size: 25)
        setView.layer.cornerRadius = 10
        let setButton = UIButton()
        setButton.accessibilityIdentifier = "setButton"
        setButton.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        var t = "s"
        if set["type"] as! String == "web" {
            t = "w"
        }
        setButton.accessibilityIdentifier = t + (set["setID"] as! String)
        setButton.translatesAutoresizingMaskIntoConstraints = false
        setView.addSubview(setButton)
        con(setView, (view.frame.width - 180) / 3, 100)
        NSLayoutConstraint.activate([
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
        return setView
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
    
    @objc func search(_ sender: UIButton){
        destination = "search"
        performSegue(withIdentifier: "searchVC", sender: nil)
    }
    
    @objc func buttonTapped(_ sender: UIButton) {
        destinationSet = String(sender.accessibilityIdentifier!.dropFirst())
        if(String(sender.accessibilityIdentifier!.first!) == "s"){
            destination = "standard"
            performSegue(withIdentifier: "viewStandardSet", sender: self)
        }else{
            destination = "web"
            performSegue(withIdentifier: "viewWebSet", sender: self)
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
        newSet["keyWords"] = ["new", "set"]
        newSet["author"] = userData["username"]!
        newSet["authorID"] = Auth.auth().currentUser?.uid
        newSet["date"] = Timestamp(date: Date())
        newSet["version"] = Colors.version
        newSet["image"] = ""
        var studiedSet: [String: Any] = [:]
        studiedSet["name"] = "New Set"
        studiedSet["image"] = ""
        if(type == "Standard"){
            newSet["type"] = "standard"
            newSet["set"] = [[
                "termType": "t",
                "term": "Example term",
                "defType": "t",
                "def": "Example definition"
            ]]
            studiedSet["type"] = "standard"
            studiedSet["learn"] = [0]
            studiedSet["flashcards"] = [false]
            destination = "standard"
        }else if(type == "Web"){
            newSet["type"] = "web"
            newSet["set"] = [] as [[String: Any]]
            studiedSet["type"] = "web"
            destination = "web"
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
        self.destinationSet = ref.documentID
        studiedSet["setID"] = ref.documentID
        var newMy = userData["createdSets"] as! [String]
        newMy.append(ref.documentID)
        var newStudied = userData["studiedSets"] as! [[String: Any]]
        newStudied.append(studiedSet)
        db.collection("users").document(Auth.auth().currentUser!.uid).setData([
            "createdSets": newMy,
            "studiedSets": newStudied
        ], merge: true)
    }
    
    func newImport() {
        setup()
    }
}
