//
//  StandardSetVC.swift
//  StudyApp
//
//  Created by Matthew J. Lundeen on 4/9/24.
//

import UIKit
import PencilKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import GoogleMobileAds

class StandardSetVC: UIViewController, GADBannerViewDelegate {

    let defaults = UserDefaults.standard
    
    let scrollView = UIScrollView()
    let stackView = UIStackView()
    
    var alreadyHasSet = false
    var set = "" // passed through mainpage
    var cards: [[String: Any?]] = [] //t: text, d: drawing, s: speech - maybe
    var name: String = ""
    var date: String = ""
    var author: String = ""
    
    var setData: [String: Any] = [:]
    
    var image: String = ""
    
    var goToEditor = false
    
    let db = Firestore.firestore()
    let storage = Storage.storage()
    
    var loadingImage = UIImageView()
    
    var bannerViews: [GADBannerView] = []
    
    var heartImage = UIImageView()
    var heartLabel = UILabel()
    
    var isLiked = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(set)
        print(alreadyHasSet)
        //print(goToEditor)
        view.backgroundColor = Colors.background
        if goToEditor {
//            var newSet: [String: Any] = [:]
//            newSet["name"] = "New Set"
//            //newSet["author"] = userData["username"]!
//            newSet["authorID"] = Auth.auth().currentUser?.uid
//            //newSet["date"] = Timestamp(date: Date())
//            newSet["version"] = Colors.version
//            newSet["image"] = ""
//            newSet["type"] = "standard"
//            newSet["set"] = [[
//                "termType": "t",
//                "term": "Example term",
//                "defType": "t",
//                "def": "Example definition"
//            ]]
//            defaults.set(newSet, forKey: "set")
            //UIView.setAnimationsEnabled(false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                self.performSegue(withIdentifier: "standardEditor", sender: self)
            }
            //print("whyyyyy")
            editSet()
            //UIView.setAnimationsEnabled(true)
        }
        
        loadingImage = createLoadingIcon()
        loadingImage.center = view.center
        view.addSubview(loadingImage)
//        print(data)
//        print("//////////////////////////////////////////////")
//        print(cards)
        
        //setup()
    }
    override func viewDidAppear(_ animated: Bool) {
        view.backgroundColor = Colors.background
        setup()
    }
    
    func setup() {
        fetchSetData { [weak self] in
            self?.setupUI()
        }
    }

    private func fetchSetData(completion: @escaping () -> Void) {
        if alreadyHasSet {
            alreadyHasSet = false
            setData = defaults.value(forKey: "set") as! [String : Any]
            cards = setData["set"] as! [[String: Any?]]
            name = setData["name"] as? String ?? ""
            author = setData["author"] as! String
            image = (setData["image"] as? String)!
            self.date = defaults.value(forKey: "date") as! String
            loadingImage.removeFromSuperview()
            completion()
        }else{
            let dataRef = db.collection("sets").document(set)
            dataRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    self.setData = document.data()!
                    self.cards = self.setData["set"] as! [[String: Any?]]
                    self.name = self.setData["name"] as? String ?? ""
                    self.image = (self.setData["image"] as? String)!
                    self.author = self.setData["author"] as! String
                    if let timestamp = self.setData["date"] as? Timestamp {
                        let date = timestamp.dateValue()
                        self.date = formatDate(date)
                    }
                    self.setData.removeValue(forKey: "date")
                    self.defaults.set(self.setData, forKey: "set")
                    self.loadingImage.removeFromSuperview()
                    completion()
                } else {
                    print("Document does not exist")
                }
            }
        }
    }

    private func setupUI() {
        clearExistingViews()
        
        if image != "" {
            setBackgroundImage()
        }
        
        setupStackView()
        setupTopSection()
        setupButtons()
        setupTermsSection()
    }

    private func clearExistingViews() {
        for subview in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        stackView.removeFromSuperview()
        
        for subview in view.subviews {
            subview.removeFromSuperview()
        }
    }

    private func setBackgroundImage() {
        let backgroundImage = UIImageView()
        backgroundImage.contentMode = .scaleAspectFill
        view.addSubview(backgroundImage)
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundImage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        loadImage(url: image, imageView: backgroundImage)
    }

    private func setupStackView() {
        stackView.axis = .vertical
        stackView.spacing = 0
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
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 50),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -50),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 50),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -50),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -100)
        ])
    }

    private func setupTopSection() {
        let backButton = createButton(title: "< Back", font: UIFont(name: "LilGrotesk-Bold", size: 20), action: #selector(self.backButton(sender:)))
        stackView.addArrangedSubview(backButton)
        
        addBreakView(stackView, 15)
        
        let titleLabel = createLabel(text: name, font: UIFont(name: "LilGrotesk-Black", size: 50))
        stackView.addArrangedSubview(titleLabel)
        
        addBreakView(stackView, 10)
        
        let authorLabel = createLabel(text: author, font: UIFont(name: "LilGrotesk-Bold", size: 25))
        stackView.addArrangedSubview(authorLabel)
        
        let dateLabel = createLabel(text: "Last edited on " + date, font: UIFont(name: "LilGrotesk-Light", size: 20))
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
    }

    private func setupButtons() {
        let buttonsStackView = UIStackView()
        buttonsStackView.addArrangedSubview(createButton(withTitle: "Learn"))
        buttonsStackView.addArrangedSubview(createButton(withTitle: "Flashcards"))
        if setData["authorID"] as! String == Auth.auth().currentUser!.uid {
            buttonsStackView.addArrangedSubview(createButton(withTitle: "Edit"))
        }
        buttonsStackView.addArrangedSubview(UIView())
        buttonsStackView.axis = .horizontal
        buttonsStackView.spacing = 20
        buttonsStackView.distribution = .fill
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonsStackView.widthAnchor.constraint(equalToConstant: 600).isActive = true
        stackView.addArrangedSubview(buttonsStackView)
        
        addBreakView(stackView, 100)
    }

    private func setupTermsSection() {
        let termsLabel = createLabel(text: "Terms", font: UIFont(name: "LilGrotesk-Bold", size: 30))
        stackView.addArrangedSubview(termsLabel)
        
        addBreakView(stackView, 10)
        
        let allTermsStackView = UIStackView()
        allTermsStackView.axis = .vertical
        allTermsStackView.spacing = 10
        allTermsStackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(allTermsStackView)
        
        NSLayoutConstraint.activate([
            allTermsStackView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            allTermsStackView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
        ])
        var paid: Bool? = defaults.value(forKey: "isPaid") as? Bool
        var c = 0
        for card in cards {
            if c == 6 && paid == false{
                c = 0
                let containerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width - 100, height: 150))
                containerView.translatesAutoresizingMaskIntoConstraints = false
                con(containerView, view.frame.width - 100, 150)
                allTermsStackView.addArrangedSubview(containerView)
                let bannerView = GADBannerView(adSize: GADCurrentOrientationInlineAdaptiveBannerAdSizeWithWidth(min(view.frame.height, view.frame.width) - 200))
                bannerView.isAutoloadEnabled = true
                bannerView.delegate = self
                bannerView.adUnitID = "ca-app-pub-3940256099942544/2435281174"
                bannerView.rootViewController = self
                bannerView.translatesAutoresizingMaskIntoConstraints = false
//                NSLayoutConstraint.activate([
//                    bannerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
//                    bannerView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
//                ])
                
                //conH(bannerView, GADCurrentOrientationInlineAdaptiveBannerAdSizeWithWidth(min(view.frame.height, view.frame.width) - 100).size.height)
                con(bannerView, view.frame.width - 200, 100)
                bannerView.load(GADRequest())
                
                containerView.addSubview(bannerView)
                NSLayoutConstraint.activate([
                    bannerView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                    bannerView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
                ])
            }
            let termDefinitionStackView = createTermDefinitionStackView(for: card)
            allTermsStackView.addArrangedSubview(termDefinitionStackView)
            c+=1
        }
    }

    private func createLabel(text: String, font: UIFont?) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.sizeToFit()
        label.textColor = Colors.text
        return label
    }

    private func createButton(title: String, font: UIFont?, action: Selector) -> UIButton {
        let button = UIButton()
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = font
        button.addTarget(self, action: action, for: .touchUpInside)
        button.setTitleColor(Colors.highlight, for: .normal)
        return button
    }

    private func createTermDefinitionStackView(for card: [String: Any?]) -> UIStackView {
        let termDefinitionStackView = UIStackView()
        termDefinitionStackView.translatesAutoresizingMaskIntoConstraints = false
        termDefinitionStackView.isLayoutMarginsRelativeArrangement = true
        termDefinitionStackView.layoutMargins = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        termDefinitionStackView.axis = .horizontal
        termDefinitionStackView.spacing = 15
        conW(termDefinitionStackView, view.frame.width - 100)
        
        // Term and definition setup based on card data
        setupTermAndDefinition(for: card, in: termDefinitionStackView)
        
        if(image == ""){
            termDefinitionStackView.backgroundColor = Colors.secondaryBackground
            termDefinitionStackView.layer.cornerRadius = 10
        }else{
            var blurEffect = UIBlurEffect(style: .systemThinMaterial)
            if(Colors.text == UIColor(red: 1, green: 1, blue: 1, alpha: 1.0)){
                blurEffect = UIBlurEffect(style: .systemThinMaterialDark)
            }else if(Colors.text == UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)){
                blurEffect = UIBlurEffect(style: .systemThinMaterialLight)
            }
            let blurredEffectView = UIVisualEffectView(effect: blurEffect)
            blurredEffectView.frame = termDefinitionStackView.frame
            blurredEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            blurredEffectView.layer.cornerRadius = 10
            blurredEffectView.clipsToBounds = true
            termDefinitionStackView.insertSubview(blurredEffectView, at: 0)
        }
        
        return termDefinitionStackView
    }

    private func setupTermAndDefinition(for card: [String: Any?], in stackView: UIStackView) {
        let term = card["term"] as? String
        let definition = card["def"] as? String
        if(card["termType"] as! String == "t"){
            let termView = UILabel(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            termView.text = term
            termView.font = UIFont(name: "LilGrotesk-Regular", size: 20)
            termView.translatesAutoresizingMaskIntoConstraints = false
            termView.backgroundColor = .clear
            termView.numberOfLines = 0
            termView.textColor = Colors.text
            termView.widthAnchor.constraint(equalToConstant: (view.frame.width - 156)/2).isActive = true
            stackView.addArrangedSubview(termView)
            //termView.backgroundColor = .green
        }else if(card["termType"] as! String == "i"){
            let termImage = UIButton(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            termImage.translatesAutoresizingMaskIntoConstraints = false
            //termImage.setImage(UIImage(named: "color1.png"), for: .normal)
            termImage.widthAnchor.constraint(equalToConstant: (view.frame.width - 156)/2).isActive = true
            termImage.heightAnchor.constraint(equalToConstant: (view.frame.width - 156)/3).isActive = true
            termImage.imageView?.contentMode = .scaleAspectFit
            loadButtonImage(url: card["term"] as? String, imageView: termImage)
            stackView.addArrangedSubview(termImage)
            //termImage.backgroundColor = .blue
        }else{
            let drawingsuperview = UIView(frame: CGRect(x: 0, y: 0, width: (view.frame.width - 156)/2, height: (view.frame.width - 156)/3))
            drawingsuperview.widthAnchor.constraint(equalToConstant: (view.frame.width - 156)/2).isActive = true
            drawingsuperview.heightAnchor.constraint(equalToConstant: (view.frame.width - 156)/3).isActive = true
            let termDrawing = PKCanvasView(frame: CGRect(x: 0, y: 0, width: view.frame.width - 156, height: 2*(view.frame.width - 156)/3))
            termDrawing.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            drawingsuperview.addSubview(termDrawing)
            termDrawing.anchorPoint = drawingsuperview.anchorPoint
            drawingsuperview.translatesAutoresizingMaskIntoConstraints = false
            termDrawing.isUserInteractionEnabled = false
            termDrawing.translatesAutoresizingMaskIntoConstraints = false
            termDrawing.tool = Colors.pen
            termDrawing.overrideUserInterfaceStyle = .light
            loadDrawing(url: card["term"] as? String, canvas: termDrawing)
            termDrawing.anchorPoint = CGPoint(x: 1, y: 1)
            termDrawing.backgroundColor = .clear
            termDrawing.layer.cornerRadius = 10
            stackView.addArrangedSubview(drawingsuperview)
            //centerDrawing(termDrawing)
            //termDrawing.backgroundColor = .red
        }
        
        let breakView = UIView()
        breakView.backgroundColor = Colors.text.withAlphaComponent(0.5)
        breakView.widthAnchor.constraint(equalToConstant: 1).isActive = true
        breakView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(breakView)
        //breakView.heightAnchor.constraint(equalTo: termDefinitionStackView.heightAnchor, multiplier: 0.5).isActive = true
        
        if(card["defType"] as! String == "t" || card["defType"] as! String == "d-r"){
            let definitionView = UILabel(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            definitionView.numberOfLines = 0
            definitionView.text = definition
            definitionView.textColor = Colors.text
            definitionView.font = UIFont(name: "LilGrotesk-Regular", size: 20)
            definitionView.translatesAutoresizingMaskIntoConstraints = false
            definitionView.backgroundColor = .clear
            stackView.addArrangedSubview(definitionView)
            //definitionView.backgroundColor = .blue
        }else if card["defType"] as! String == "d"{
            let drawingsuperview = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: (view.frame.width - 156)/3))
            drawingsuperview.translatesAutoresizingMaskIntoConstraints = false
            drawingsuperview.widthAnchor.constraint(equalToConstant: (view.frame.width - 156)/2).isActive = true
            drawingsuperview.heightAnchor.constraint(equalToConstant: (view.frame.width - 156)/3).isActive = true
            let definitionDrawing = PKCanvasView(frame: CGRect(x: 0, y: 0, width: view.frame.width - 156, height: 2*(view.frame.width - 156)/3))
            definitionDrawing.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            definitionDrawing.layer.cornerRadius = 10
            definitionDrawing.isUserInteractionEnabled = false
            definitionDrawing.tool = Colors.pen
            definitionDrawing.overrideUserInterfaceStyle = .light
            loadDrawing(url: card["def"] as? String, canvas: definitionDrawing)
            definitionDrawing.translatesAutoresizingMaskIntoConstraints = false
            
            drawingsuperview.addSubview(definitionDrawing)
            definitionDrawing.anchorPoint = CGPoint(x: 1, y: 1)
            definitionDrawing.backgroundColor = .clear
            //definitionDrawing.backgroundColor = .red
            stackView.addArrangedSubview(drawingsuperview)
            
            //centerDrawing(definitionDrawing)
        }
    }
    
    func createButton(withTitle title: String) -> UIButton {
        let button = UIButton()
        button.setTitle(title, for: .normal)
        button.titleLabel!.font = UIFont(name: "LilGrotesk-Bold", size: 30)
        button.layer.cornerRadius = 10
        button.setTitleColor(Colors.text, for: .normal)
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
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
        case "Learn":
            startLearn()
        case "Flashcards":
            startFlashcards()
        case "Test":
            startTest()
        case "Edit":
            editSet()
        default:
            break
        }
    }

    @objc func startLearn() {
        performSegue(withIdentifier: "standardLearnVC", sender: nil)
    }

    @objc func startFlashcards() {
        performSegue(withIdentifier: "flashcards", sender: nil)
    }

    @objc func startTest() {
        //print("test")
    }
    
    @objc func editSet() {
        performSegue(withIdentifier: "standardEditor", sender: nil)
    }
    
    @objc func backButton(sender: UIButton){
        //print("back")
        performSegue(withIdentifier: "standardSetVC_unwind", sender: nil)
    }
    
    @objc func copy(sender: UIButton){
        UIPasteboard.general.string = set
            
        let alert = UIAlertController(title: "Copied!", message: "The set ID has been copied to your clipboard.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
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
    
//    @objc func export(sender: UIButton){
//        var cardsDictionary: [String: Any] = (defaults.object(forKey: "sets") as! [Dictionary<String, Any>])[set]
//        var oldLearn: [Int] = []
//        for _ in 0 ..< cardsDictionary.count {
//            oldLearn.append(0)
//        }
//        var oldFlash: [Bool] = []
//        for _ in 0 ..< cardsDictionary.count {
//            oldFlash.append(false)
//        }
//        cardsDictionary["flashcards"] = oldFlash
//        cardsDictionary["learn"] = oldLearn
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
    
    @IBAction func cancel (_ unwindSegue: UIStoryboardSegue){
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        segue.destination.modalPresentationStyle = .fullScreen
        if let destination = segue.destination as? StandardEditorVC {
            destination.set = set
        }
        if let destination = segue.destination as? FlashcardsVC {
            destination.set = set
        }
        if let destination = segue.destination as? StandardLearnVC {
            destination.set = set
        }
    }
    
//    func configureBannerView(_ bannerView: GADBannerView){
//
//        //bannerView.backgroundColor = .white
//    }
}
