//
//  WebSetVC.swift
//  StudyApp
//
//  Created by Matthew Lundeen on 4/13/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import GoogleMobileAds

class WebSetVC: UIViewController {

    let defaults = UserDefaults.standard
    
    let scrollView = UIScrollView()
    let stackView = UIStackView()
    
    var alreadyHasSet = false
    var set = ""
    var goToEditor = false
    
    var name: String = ""
    var date: String = ""
    var author: String = ""
    
    var image: String? = ""
    
    var setData: [String: Any] = [:]
    
    let db = Firestore.firestore()
    let storage = Storage.storage()
    
    var loadingImage = UIImageView()
    
    var bannerView: GADBannerView!
    
    var heartImage = UIImageView()
    var heartLabel = UILabel()
    
    var isLiked = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.background
        if goToEditor {
//            var newSet: [String: Any] = [:]
//            newSet["name"] = "New Set"
//            //newSet["author"] = userData["username"]!
//            newSet["authorID"] = Auth.auth().currentUser?.uid
//            //newSet["date"] = Timestamp(date: Date())
//            newSet["version"] = Colors.version
//            newSet["image"] = ""
//            newSet["type"] = "web"
//            newSet["set"] = [] as [[String: Any]]
//            defaults.set(newSet, forKey: "set")
            //UIView.setAnimationsEnabled(false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                self.performSegue(withIdentifier: "editWebSet", sender: self)
            }
            //UIView.setAnimationsEnabled(true)
        }
        
        //cards = data["set"] as! [[Any]]
        
        //setup()
        loadingImage = createLoadingIcon()
        loadingImage.center = view.center
        view.addSubview(loadingImage)
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if alreadyHasSet {
            alreadyHasSet = false
            setData = defaults.value(forKey: "set") as! [String : Any]
            if let name = self.setData["name"] as? String{
                self.name = name
            }
            if let image = self.setData["image"] as? String?{
                self.image = image
            }
            self.date = defaults.value(forKey: "date") as! String
            author = setData["author"] as! String
            self.setup()
            self.loadingImage.removeFromSuperview()
        }else{
            let dataRef = db.collection("sets").document(set)
            dataRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    self.setData = document.data()!
                    
                    if let name = self.setData["name"] as? String{
                        self.name = name
                    }
                    if let image = self.setData["image"] as? String?{
                        self.image = image
                    }
                    if let timestamp = self.setData["date"] as? Timestamp {
                        let date = timestamp.dateValue()
                        self.date = formatDate(date)
                    }
                    self.author = self.setData["author"] as! String
                    self.setup()
                    self.setData.removeValue(forKey: "date")
                    self.defaults.set(self.setData, forKey: "set")
                    self.loadingImage.removeFromSuperview()
                } else {
                    print("Document does not exist")
                }
            }
        }
    }
    
    func setup(){
        let storageRef = storage.reference()
        //        if(sets.count == set){
        //            performSegue(withIdentifier: "webSetVC_unwind", sender: nil)
        //        }else{
        
        for subview in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        stackView.removeFromSuperview()
        for subview in view.subviews {
            subview.removeFromSuperview()
        }
        if(image == ""){
            view.backgroundColor = Colors.background
        }else{
            let backgroundImage = UIImageView()
            loadImage(url: image!, imageView: backgroundImage)
            backgroundImage.contentMode = .scaleAspectFill
            view.addSubview(backgroundImage)
            tAMC(backgroundImage)
            NSLayoutConstraint.activate([
                backgroundImage.topAnchor.constraint(equalTo: view.topAnchor),
                backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        }
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.alignment = .leading
        scrollView.addSubview(stackView)
        view.addSubview(scrollView)
        tAMC([scrollView, stackView])
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
            
            let backButton = UIButton()
            backButton.setTitle("< Back", for: .normal)
            backButton.titleLabel!.font = UIFont(name: "LilGrotesk-Bold", size: 20)
            backButton.addTarget(self, action: #selector(self.backButton(sender:)), for: .touchUpInside)
            backButton.setTitleColor(Colors.highlight, for: .normal)
            stackView.addArrangedSubview(backButton)
            
        addBreakView(stackView, 15)
            
            let titleLabel = UILabel()
            titleLabel.text = name
            titleLabel.font = UIFont(name: "LilGrotesk-Black", size: 50)
            titleLabel.textColor = Colors.text
            titleLabel.sizeToFit()
            stackView.addArrangedSubview(titleLabel)

        addBreakView(stackView, 10)
            
        let authorLabel = UILabel()
        authorLabel.text = author
        authorLabel.font = UIFont(name: "LilGrotesk-Bold", size: 25)
        authorLabel.textColor = Colors.text
        authorLabel.sizeToFit()
        stackView.addArrangedSubview(authorLabel)
        
        
        
            let dateLabel = UILabel()
            dateLabel.text = "Last edited on " + date
            dateLabel.font = UIFont(name: "LilGrotesk-Light", size: 20)
            dateLabel.textColor = Colors.text
            dateLabel.sizeToFit()
            stackView.addArrangedSubview(dateLabel)
            
        addBreakView(stackView, 30)
        
        
        
        let copyButton = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 20))
        con(copyButton, 100, 20)
        copyButton.addTarget(self, action: #selector(self.copy(sender:)), for: .touchUpInside)
        //stackView.addArrangedSubview(copyButton)
        let copyImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        copyImage.tintColor = Colors.highlight
        copyImage.image = UIImage(systemName: "square.on.square.fill")
        copyImage.contentMode = .scaleAspectFit
        copyButton.addSubview(copyImage)
        let copyLabel = UILabel(frame: CGRect(x: 25, y: 0, width: 75, height: 20))
        copyLabel.textColor = Colors.highlight
        copyLabel.text = "Share"
        copyLabel.font = UIFont(name: "LilGrotesk-Regular", size: 25)
        copyButton.addSubview(copyLabel)
        //addBreakView(stackView, 30)
        
        let heartButton = UIButton(frame: CGRect(x: 0, y: 0, width: 300, height: 20))
        con(heartButton, 300, 20)
        heartButton.addTarget(self, action: #selector(self.like(sender:)), for: .touchUpInside)
        //stackView.addArrangedSubview(heartButton)
        heartLabel = UILabel(frame: CGRect(x: 25, y: 0, width: 275, height: 20))
        heartLabel.text = String(setData["likes"] as! Int)
        heartLabel.textColor = Colors.highlight
        heartLabel.font = UIFont(name: "LilGrotesk-Regular", size: 25)
        heartLabel.textAlignment = .left
        heartButton.addSubview(heartLabel)
        if(isLiked){
            heartImage = UIImageView(image: UIImage(systemName: "heart.fill"))
        }else{
            heartImage = UIImageView(image: UIImage(systemName: "heart"))
        }
        heartImage.contentMode = .scaleAspectFit
        heartImage.tintColor = Colors.highlight
        heartImage.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        heartButton.addSubview(heartImage)
        
        let horiView = UIStackView(arrangedSubviews: [copyButton, heartButton])
        horiView.axis = .horizontal
        horiView.spacing = 10
        stackView.addArrangedSubview(horiView)
        
        addBreakView(stackView, 40)
            
            let buttonsStackView = UIStackView()
        buttonsStackView.addArrangedSubview(createButton(withTitle: "View"))
        buttonsStackView.addArrangedSubview(createButton(withTitle: "Study"))
        if setData["authorID"] as! String == Auth.auth().currentUser!.uid {
            buttonsStackView.addArrangedSubview(createButton(withTitle: "Edit"))
        }
        buttonsStackView.addArrangedSubview(UIView())
            buttonsStackView.axis = .horizontal
            buttonsStackView.widthAnchor.constraint(equalToConstant: 400).isActive = true
            buttonsStackView.spacing = 20
            buttonsStackView.distribution = .fill
            stackView.addArrangedSubview(buttonsStackView)
        //}
//        let icon = UIImageView(image: UIImage(named: "DendriticLearningIcon-01.svg")?.withRenderingMode(.alwaysTemplate))
//        icon.tintColor = Colors.highlight
//        icon.contentMode = .scaleAspectFit
//        view.addSubview(icon)
//        icon.frame = CGRect(x: view.frame.width / 2.5, y: view.frame.height / 2.5, width: max(view.frame.width, view.frame.height), height: max(view.frame.width, view.frame.height))
//        icon.transform = icon.transform.rotated(by: -(.pi / 8))
        
        
        
        
        if(defaults.value(forKey: "isPaid") as! Bool != true){
            let bannerView = GADBannerView(adSize: GADAdSizeFromCGSize(CGSize(width: min(600, view.bounds.width), height: 100)))
            view.addSubview(bannerView)
            bannerView.delegate = self
            bannerView.adUnitID = "ca-app-pub-5124969442805102/7426291738"
            bannerView.rootViewController = self
            bannerView.load(GADRequest())
            
            tAMC(bannerView)
            NSLayoutConstraint.activate([
                bannerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                bannerView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
        }
    }
    
    func createButton(withTitle title: String) -> UIButton {
        let button = UIButton()
        button.setTitle(title, for: .normal)
        button.titleLabel!.font = UIFont(name: "LilGrotesk-Bold", size: 30)
        button.setTitleColor(Colors.text, for: .normal)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 70).isActive = true
        conW(button, (title as NSString).size(withAttributes: [NSAttributedString.Key.font: UIFont(name: "LilGrotesk-Bold", size: 30)!]).width + 40)
        button.layer.masksToBounds = true

        if(image == ""){
            button.backgroundColor = Colors.secondaryBackground
        }else{
            var blurEffect = UIBlurEffect(style: .systemThinMaterial)
            if(Colors.text == UIColor(red: 1, green: 1, blue: 1, alpha: 1.0)){
                blurEffect = UIBlurEffect(style: .systemThinMaterialDark)
            }else if(Colors.text == UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)){
                blurEffect = UIBlurEffect(style: .systemThinMaterialLight)
            }
            let blurredEffectView = UIVisualEffectView(effect: blurEffect)
            blurredEffectView.frame = button.bounds
            blurredEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            blurredEffectView.isUserInteractionEnabled = false
            button.insertSubview(blurredEffectView, at: 0)
        }

        return button
    }

    @objc func buttonTapped(_ sender: UIButton) {
        switch sender.titleLabel?.text {
        case "View":
            viewWeb()
        case "Study":
            studyWeb()
        case "Edit":
            editWeb()
        default:
            break
        }
    }

    @objc func viewWeb() {
        performSegue(withIdentifier: "webViewer", sender: self)
    }

    @objc func studyWeb() {
        performSegue(withIdentifier: "webStudy", sender: self)
    }

    @objc func editWeb() {
        performSegue(withIdentifier: "editWebSet", sender: self)
    }
    
    @objc func backButton(sender: UIButton){
        performSegue(withIdentifier: "webSetVC_unwind", sender: nil)
    }
    
    @objc func like(sender: UIButton){
        if isLiked {
            heartImage.image = UIImage(systemName: "heart")
            setData["likes"] = (setData["likes"] as! Int) - 1
            let dataRef = db.collection("users").document(Auth.auth().currentUser!.uid)
            dataRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    let userData = document.data()!
                    var newLiked = userData["likedSets"] as! [String]
                    newLiked.remove(at: newLiked.firstIndex(of: self.set)!)
                    self.db.collection("users").document(Auth.auth().currentUser!.uid).setData([
                        "likedSets": newLiked
                    ], merge: true)
                } else {
                    print("Document does not exist")
                }
            }
        }else{
            heartImage.image = UIImage(systemName: "heart.fill")
            setData["likes"] = (setData["likes"] as! Int) + 1
            let dataRef = db.collection("users").document(Auth.auth().currentUser!.uid)
            dataRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    let userData = document.data()!
                    var newLiked = userData["likedSets"] as! [String]
                    newLiked.append(self.set)
                    self.db.collection("users").document(Auth.auth().currentUser!.uid).setData([
                        "likedSets": newLiked
                    ], merge: true)
                } else {
                    print("Document does not exist")
                }
            }
        }
        heartLabel.text = String(setData["likes"] as! Int)
        
        isLiked = !isLiked
        var likeCount: [String: Any] = ["likes": setData["likes"]!]
        db.collection("sets").document(set).setData(likeCount, merge: true)
    }
    
    @objc func copy(sender: UIButton){
        UIPasteboard.general.string = set
            
        let alert = UIAlertController(title: "Copied!", message: "The set ID has been copied to your clipboard.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
//    @objc func export(sender: UIButton){
//        var cardsDictionary: [String: Any] = (defaults.object(forKey: "sets") as! [Dictionary<String, Any>])[set]
//        //cardsDictionary["images"] = (defaults.object(forKey: "images") as! [Data?])[set]
//        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: cardsDictionary, requiringSecureCoding: false) else {
//            print("Failed to archive data.")
//            return
//        }
//        
//        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
//        let timeString = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
//        let fileURL = temporaryDirectoryURL.appendingPathComponent(name).appendingPathExtension("dlset")
//        
//        do {
//            try data.write(to: fileURL)
//            
//            let documentPicker = UIDocumentPickerViewController(url: fileURL, in: .exportToService)
//            documentPicker.shouldShowFileExtensions = true
//            self.present(documentPicker, animated: true, completion: nil)
//        } catch {
//            print("Error exporting cards: \(error.localizedDescription)")
//        }
//    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        segue.destination.modalPresentationStyle = .fullScreen
        if let destination = segue.destination as? WebEditorVC{
            destination.set = set
        }
        if let destination = segue.destination as? WebStudyVC{
            destination.set = set
        }
        if let destination = segue.destination as? WebViewerVC{
            destination.set = set
        }
    }
    
    @IBAction func cancel (_ unwindSegue: UIStoryboardSegue){
        
    }
}

extension WebSetVC: GADBannerViewDelegate {
    
}
