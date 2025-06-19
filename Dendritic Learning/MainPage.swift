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
    
    let defaults = UserDefaults.standard
    
    var scrollView = UIScrollView()
    var stackView = UIStackView()
    
    var destination = ""
    var destinationSet = ""
    
    var retrievedSetIDs: [String] = []
    var retrievedSets: [String: Any] = [:]
    var recentSets: [String] = []
    var likedSets: [String] = []
    var mySets: [String] = []
    
    var goToEditor = false
    
    let db = Firestore.firestore()
    
    var userData: [String: Any] = [:]
    
    var loadingImage = UIImageView()
    
    var previousSize: CGSize?
    
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
        tAMC(scrollView)
        tAMC(stackView)
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
        previousSize = view.bounds.size
        
        let topBar = createTopBar()
        stackView.addArrangedSubview(topBar)
        //addBreakView(stackView, 30)
        
        loadingImage = createLoadingIcon()
        loadingImage.center = view.center
        view.addSubview(loadingImage)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setup()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.setup()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if previousSize != view.bounds.size {
            previousSize = view.bounds.size
            setup()
        }
    }


    
    func setup() {
        if let fingerDrawing = defaults.value(forKey: "fingerDrawing") as? Bool, let uid = Auth.auth().currentUser?.uid {
            let dataRef = db.collection("users").document(uid)
            dataRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    self.retrievedSetIDs = []
                    self.retrievedSets = [:]
                    self.recentSets = []
                    self.likedSets = []
                    self.mySets = []
                    
                    self.userData = document.data()!
                    self.updateColors()
                    self.updateSets()
                    
                    if var studied = self.userData["studiedSets"] as? [[String: Any]] {
                        studied.sort { firstDoc, secondDoc in
                            guard let firstDate = firstDoc["date"] as? Timestamp,
                                  let secondDate = secondDoc["date"] as? Timestamp else {
                                return false
                            }
                            return firstDate.dateValue() > secondDate.dateValue()
                        }
                        for i in studied {
                            if let setID = i["setID"] as? String {
                                self.recentSets.append(setID)
                                self.retrievedSetIDs.append(setID)
                            }
                        }
                    }
                    
                    if var liked = self.userData["likedSets"] as? [String] {
                        liked.reverse()
                        self.likedSets = liked
                        for i in liked {
                            if self.retrievedSetIDs.firstIndex(of: i) == nil {
                                self.retrievedSetIDs.append(i)
                            }
                        }
                    }
                    
                    if var my = self.userData["createdSets"] as? [String] {
                        my.reverse()
                        self.mySets = my
                        for i in my {
                            if self.retrievedSetIDs.firstIndex(of: i) == nil {
                                self.retrievedSetIDs.append(i)
                            }
                        }
                    }
                    
                    if var classes = self.userData["classes"] as? [[String: Any]] {
                        self.defaults.setValue(classes, forKey: "classes")
                    }else{
                        let classes: [[String: Any]] = []
                        self.defaults.setValue(classes, forKey: "classes")
                    }
                    
                    self.getSets { error in
                        if let error = error {
                            print("Error fetching documents: \(error)")
                        } else {
                            self.loadingImage.removeFromSuperview()
                            self.filterSets()
                            self.setupUI()
                        }
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

    func getSets(completion: @escaping (Error?) -> Void) {
        let dispatchGroup = DispatchGroup()
        for docName in retrievedSetIDs {
            dispatchGroup.enter()
            db.collection("sets").document(docName).getDocument { (document, error) in
                if let error = error {
                    completion(error)
                    dispatchGroup.leave()
                    return
                }
                
                if let document = document, document.exists, let docData = document.data() {
                    self.retrievedSets[docName] = docData
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(nil)
        }
    }

    func filterSets() {
        var deleted = 0
        for i in 0 ..< self.recentSets.count {
            let index = i - deleted
            if !(self.retrievedSets.contains { $0.key == self.recentSets[index] }) {
                self.recentSets.remove(at: index)
                deleted += 1
            }
        }
        
        deleted = 0
        for i in 0 ..< self.likedSets.count {
            let index = i - deleted
            if !(self.retrievedSets.contains { $0.key == self.likedSets[index] }) {
                self.likedSets.remove(at: index)
                deleted += 1
            }
        }
        
        deleted = 0
        for i in 0 ..< self.mySets.count {
            let index = i - deleted
            if !(self.retrievedSets.contains { $0.key == self.mySets[index] }) {
                self.mySets.remove(at: index)
                deleted += 1
            }
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
//        if let sets = self.userData["studiedSets"] {
//            self.recentSets = sets as! [[String: Any]]
//        }
//        if let mySetIDs = self.userData["createdSets"] as? [String] {
//            for set in self.recentSets {
//                if mySetIDs.contains(set["setID"] as! String) {
//                    self.mySets.append(set)
//                }
//            }
//        }
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
        
        scrollView = UIScrollView()
        stackView = UIStackView()
        view.backgroundColor = Colors.background
        
        let bgimage = UIImageView(image: UIImage(named: "dendriticbackground.svg")?.withRenderingMode(.alwaysTemplate))
        bgimage.tintColor = Colors.highlight
        bgimage.contentMode = .scaleAspectFill
        bgimage.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        bgimage.layer.opacity = 0.35
        view.addSubview(bgimage)
        
        
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .leading
        scrollView.addSubview(stackView)
        view.addSubview(scrollView)
        tAMC(scrollView)
        tAMC(stackView)
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
        //scrollView.bounds = scrollView.frame
        
        scrollView.contentInset = .zero
        
        let topBar = createTopBar()
        stackView.addArrangedSubview(topBar)
        addBreakView(stackView, 30)
        
//        loadingImage = createLoadingIcon()
//        loadingImage.center = view.center
//        view.addSubview(loadingImage)
        
        let recentLabel = createSectionLabel(text: "Recently studied")
        stackView.addArrangedSubview(recentLabel)
        if(recentSets.count > 0){
            addSets(to: stackView, from: recentSets)
        }else{
            let noSets = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width - 120, height: 100))
            con(noSets, view.frame.width - 120, 100)
            noSets.text = "No sets studied yet"
            noSets.textAlignment = .center
            noSets.font = UIFont(name: "LilGrotesk-Regular", size: 30)
            noSets.textColor = Colors.text.withAlphaComponent(0.7)
            noSets.backgroundColor = Colors.secondaryBackground
            noSets.layer.cornerRadius = 10
            noSets.clipsToBounds = true
            stackView.addArrangedSubview(noSets)
        }
        addBreakView(stackView, 30)
        
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
        if(mySets.count > 0){
            addSets(to: stackView, from: mySets)
        }else{
            let noSets = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width - 120, height: 100))
            con(noSets, view.frame.width - 120, 100)
            noSets.text = "You haven't created any sets yet"
            noSets.textAlignment = .center
            noSets.font = UIFont(name: "LilGrotesk-Regular", size: 30)
            noSets.textColor = Colors.text.withAlphaComponent(0.7)
            noSets.backgroundColor = Colors.secondaryBackground
            noSets.layer.cornerRadius = 10
            noSets.clipsToBounds = true
            stackView.addArrangedSubview(noSets)
        }
        addBreakView(stackView, 30)
        let likedLabel = createSectionLabel(text: "Liked sets")
        stackView.addArrangedSubview(likedLabel)
        if(likedSets.count > 0){
            addSets(to: stackView, from: likedSets)
        }else{
            let noSets = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width - 120, height: 100))
            con(noSets, view.frame.width - 120, 100)
            noSets.text = "You haven't liked any sets yet"
            noSets.textAlignment = .center
            noSets.font = UIFont(name: "LilGrotesk-Regular", size: 30)
            noSets.textColor = Colors.text.withAlphaComponent(0.7)
            noSets.backgroundColor = Colors.secondaryBackground
            noSets.layer.cornerRadius = 10
            noSets.clipsToBounds = true
            stackView.addArrangedSubview(noSets)
        }
        //addBreakView(stackView, 30)
        
        
        //print(stackView.arrangedSubviews)
    }

    func createTopBar() -> UIView {
        let topBar = UIView()
        con(topBar, view.frame.width - 120, 50)
        
        let icon = UIImageView(image: UIImage(named: "DendriticLearningIconBold1.svg")?.withRenderingMode(.alwaysTemplate))
        icon.tintColor = Colors.highlight
        icon.contentMode = .scaleAspectFit
        topBar.addSubview(icon)
        con(icon, 50, 50)
        icon.leadingAnchor.constraint(equalTo: topBar.leadingAnchor).isActive = true
        
        let titleLabel = UILabel()
        //titleLabel.text = "Dendritic Learning"
        titleLabel.textColor = Colors.text
        titleLabel.font = UIFont(name: "LilGrotesk-Black", size: 30)
        topBar.addSubview(titleLabel)
        con(titleLabel, 400, 50)
        titleLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 10).isActive = true
        
        if (previousSize?.width)! > 600 {
            titleLabel.text = "Dendritic Learning"
        }
        
        let settingsIcon = UIImageView()
        settingsIcon.image = UIImage(systemName: "gear")
        settingsIcon.contentMode = .scaleAspectFit
        settingsIcon.tintColor = Colors.highlight
        con(settingsIcon, 50, 50)
        topBar.addSubview(settingsIcon)
        settingsIcon.trailingAnchor.constraint(equalTo: topBar.trailingAnchor).isActive = true
        
        let settingsButton = UIButton()
        con(settingsButton, 50, 50)
        topBar.addSubview(settingsButton)
        settingsButton.trailingAnchor.constraint(equalTo: topBar.trailingAnchor).isActive = true
        settingsButton.addTarget(self, action: #selector(settings(_:)), for: .touchUpInside)
        
        let searchIcon = UIImageView()
        searchIcon.image = UIImage(systemName: "magnifyingglass")
        searchIcon.contentMode = .scaleAspectFit
        searchIcon.tintColor = Colors.highlight
        con(searchIcon, 50, 50)
        topBar.addSubview(searchIcon)
        searchIcon.trailingAnchor.constraint(equalTo: settingsIcon.leadingAnchor, constant: -15).isActive = true
        tAMC(searchIcon)
        
        let searchButton = UIButton()
        con(searchButton, 50, 50)
        topBar.addSubview(searchButton)
        searchButton.trailingAnchor.constraint(equalTo: settingsIcon.leadingAnchor, constant: -15).isActive = true
        searchButton.addTarget(self, action: #selector(search(_:)), for: .touchUpInside)
        
        let classIcon = UIImageView()
        classIcon.image = UIImage(systemName: "graduationcap")
        classIcon.contentMode = .scaleAspectFit
        classIcon.tintColor = Colors.highlight.withAlphaComponent(0.5)
        con(classIcon, 50, 50)
        topBar.addSubview(classIcon)
        classIcon.trailingAnchor.constraint(equalTo: searchIcon.leadingAnchor, constant: -15).isActive = true
        
        let classButton = UIButton()
        con(classButton, 50, 50)
        topBar.addSubview(classButton)
        classButton.trailingAnchor.constraint(equalTo: searchIcon.leadingAnchor, constant: -15).isActive = true
        classButton.addTarget(self, action: #selector(classes(_:)), for: .touchUpInside)
        classButton.isEnabled = false
        
        tAMC([icon, titleLabel, settingsIcon, settingsButton, searchIcon, searchButton, classIcon, classButton])
        return topBar
    }

    func createSectionLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont(name: "LilGrotesk-Black", size: 50)
        con(label, view.frame.width - 120, 50)
        label.textColor = Colors.text
        label.isUserInteractionEnabled = true
        return label
    }

    func addSets(to stackView: UIStackView, from setIDs: [String]) {
        var sets: [[String: Any]] = []
        for i in setIDs {
            sets.append(retrievedSets[i] as! [String: Any])
        }
        
        let minimumWidth: CGFloat = 300
        let rowCount = Int(max((previousSize!.width - 100) / minimumWidth, 1))
        
        for i in 0...((sets.count - 1) / rowCount) {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 20
            row.alignment = .leading
            row.distribution = .fillEqually
            tAMC(row)
            stackView.addArrangedSubview(row)
            
            conW(row, view.frame.width - 120)
            for j in rowCount * i...(rowCount * i) + rowCount - 1 {
                if sets.count > j {
                    let setView = createSetView(set: sets[j], id: setIDs[j])
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

    func createSetView(set: [String: Any], id: String) -> UIView {
        let container = UIButton()
        container.backgroundColor = Colors.secondaryBackground
        container.layer.cornerRadius = 10
        container.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)

        var typePrefix = "s"
        if set["type"] as? String == "web" {
            typePrefix = "w"
        }
        container.accessibilityIdentifier = typePrefix + id

        let titleLabel = UILabel()
        titleLabel.text = set["name"] as? String
        titleLabel.textColor = Colors.text
        titleLabel.font = UIFont(name: "LilGrotesk-Medium", size: 30)
        titleLabel.numberOfLines = 0

        let creatorLabel = UILabel()
        creatorLabel.text = set["author"] as? String
        creatorLabel.textColor = Colors.text
        creatorLabel.font = UIFont(name: "LilGrotesk-Regular", size: 22)

        let likeCount = set["likes"] as? Int ?? 0
        let heartLabel = UILabel()
        heartLabel.text = "\(likeCount)"
        heartLabel.textColor = Colors.highlight
        heartLabel.font = UIFont(name: "LilGrotesk-Regular", size: 20)
        heartLabel.textAlignment = .right

        let heartImageName = likedSets.contains(id) ? "heart.fill" : "heart"
        let heartImage = UIImageView(image: UIImage(systemName: heartImageName))
        heartImage.contentMode = .scaleAspectFit
        heartImage.tintColor = Colors.highlight

        let heartStack = UIStackView(arrangedSubviews: [heartLabel, heartImage])
        heartStack.axis = .horizontal
        heartStack.spacing = 4
        heartStack.alignment = .center

        let bottomRow = UIStackView(arrangedSubviews: [creatorLabel, heartStack])
        bottomRow.axis = .horizontal
        bottomRow.spacing = 8
        bottomRow.alignment = .center
        bottomRow.distribution = .equalSpacing

        let stack = UIStackView(arrangedSubviews: [titleLabel, bottomRow])
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .fill

        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -12),
            heartImage.widthAnchor.constraint(equalToConstant: 15),
            heartImage.heightAnchor.constraint(equalToConstant: 15)
        ])
        
        tAMC([container, titleLabel, creatorLabel, heartLabel, heartImage, heartStack, bottomRow, stack])
        
        for i in container.subviews {
            i.isUserInteractionEnabled = false
        }

        return container
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
    
    @objc func classes(_ sender: UIButton){
        destination = "classes"
        performSegue(withIdentifier: "classesVC", sender: nil)
    }
    
    @objc func buttonTapped(_ sender: UIButton) {
        destinationSet = String(sender.accessibilityIdentifier!.dropFirst())
        if var t = retrievedSets[destinationSet] as? [String: Any] {
            if let timestamp = t["date"] as? Timestamp {
                let date = timestamp.dateValue()
                self.defaults.setValue(formatDate(date), forKey: "date")
            }
            t.removeValue(forKey: "date")
            defaults.set(t, forKey: "set")
            if(String(sender.accessibilityIdentifier!.first!) == "s"){
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
            if(likedSets.firstIndex(of: destinationSet) != nil){
                vc.isLiked = true
            }
            vc.set = destinationSet
            vc.alreadyHasSet = true
        }else{
            guard let vc = segue.destination as? WebSetVC else {return}
            if(goToEditor){
                vc.goToEditor = true
            }
            if(likedSets.firstIndex(of: destinationSet) != nil){
                vc.isLiked = true
            }
            vc.set = destinationSet
            vc.alreadyHasSet = true
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
        newSet["likes"] = 0
        //var studiedSet: [String: Any] = [:]
        //studiedSet["name"] = "New Set"
        //studiedSet["image"] = ""
        if(type == "Standard"){
            newSet["type"] = "standard"
            newSet["set"] = [[
                "termType": "t",
                "term": "Example term",
                "defType": "t",
                "def": "Example definition"
            ]]
            //studiedSet["type"] = "standard"
            //studiedSet["learn"] = [0]
            //studiedSet["flashcards"] = [false]
            destination = "standard"
        }else if(type == "Web"){
            newSet["type"] = "web"
            newSet["set"] = [] as [[String: Any]]
            //studiedSet["type"] = "web"
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
        //studiedSet["setID"] = ref.documentID
        var newMy = userData["createdSets"] as! [String]
        newMy.append(ref.documentID)
        //var newStudied = userData["studiedSets"] as! [[String: Any]]
        //newStudied.append(studiedSet)
        db.collection("users").document(Auth.auth().currentUser!.uid).setData([
            "createdSets": newMy//,
            //"studiedSets": newStudied
        ], merge: true)
        
        newSet.removeValue(forKey: "date")
        defaults.setValue(newSet, forKey: "set")
    }
    
    func newImport() {
        setup()
    }
}
