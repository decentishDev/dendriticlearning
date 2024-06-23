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

class StandardSetVC: UIViewController {

    let defaults = UserDefaults.standard
    
    let scrollView = UIScrollView()
    let stackView = UIStackView()
    
    var set = "" // passed through mainpage
    var cards: [[String: Any?]] = [] //t: text, d: drawing, s: speech - maybe
    var name: String = ""
    var date: String = ""
    
    var setData: [String: Any] = [:]
    
    var image: String = ""
    
    var goToEditor = false
    
    let db = Firestore.firestore()
    let storage = Storage.storage()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //print(goToEditor)
        
        if goToEditor {
            var newSet: [String: Any] = [:]
            newSet["name"] = "New Set"
            //newSet["author"] = userData["username"]!
            newSet["authorID"] = Auth.auth().currentUser?.uid
            //newSet["date"] = Timestamp(date: Date())
            newSet["version"] = Colors.version
            newSet["image"] = ""
            newSet["type"] = "standard"
            newSet["set"] = [[
                "termType": "t",
                "term": "Example term",
                "defType": "t",
                "def": "Example definition"
            ]]
            defaults.set(newSet, forKey: "set")
            //UIView.setAnimationsEnabled(false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                self.performSegue(withIdentifier: "standardEditor", sender: self)
            }
            //print("whyyyyy")
            editSet()
            //UIView.setAnimationsEnabled(true)
        }
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
        let storageRef = storage.reference()
        fetchSetData { [weak self] in
            self?.setupUI()
        }
    }

    private func fetchSetData(completion: @escaping () -> Void) {
        let dataRef = db.collection("sets").document(set)
        dataRef.getDocument { (document, error) in
            if let document = document, document.exists {
                self.setData = document.data()!
                self.cards = self.setData["set"] as! [[String: Any?]]
                self.name = self.setData["name"] as? String ?? ""
                self.image = (self.setData["image"] as? String)!
                if let timestamp = self.setData["date"] as? Timestamp {
                    let date = timestamp.dateValue()
                    self.date = formatDate(date)
                }
                self.setData.removeValue(forKey: "date")
                self.defaults.set(self.setData, forKey: "set")
                
                completion()
            } else {
                print("Document does not exist")
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
        
        addBreakView(to: stackView, size: 15)
        
        let titleLabel = createLabel(text: name, font: UIFont(name: "LilGrotesk-Black", size: 50))
        stackView.addArrangedSubview(titleLabel)
        
        let dateLabel = createLabel(text: "Last edited " + date, font: UIFont(name: "LilGrotesk-Light", size: 20))
        stackView.addArrangedSubview(dateLabel)
        
        addBreakView(to: stackView, size: 30)
    }

    private func setupButtons() {
        let learnButton = createButton(withTitle: "Learn")
        let flashcardsButton = createButton(withTitle: "Flashcards")
        let editButton = createButton(withTitle: "Edit")
        let spacer = UIView()
        
        let buttonsStackView = UIStackView(arrangedSubviews: [learnButton, flashcardsButton, editButton, spacer])
        buttonsStackView.axis = .horizontal
        buttonsStackView.spacing = 20
        buttonsStackView.distribution = .fill
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonsStackView.widthAnchor.constraint(equalToConstant: 600).isActive = true
        stackView.addArrangedSubview(buttonsStackView)
        
        addBreakView(to: stackView, size: 100)
    }

    private func setupTermsSection() {
        let termsLabel = createLabel(text: "Terms", font: UIFont(name: "LilGrotesk-Bold", size: 30))
        stackView.addArrangedSubview(termsLabel)
        
        addBreakView(to: stackView, size: 10)
        
        let allTermsStackView = UIStackView()
        allTermsStackView.axis = .vertical
        allTermsStackView.spacing = 10
        allTermsStackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(allTermsStackView)
        
        NSLayoutConstraint.activate([
            allTermsStackView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            allTermsStackView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
        ])
        
        for card in cards {
            print("heyy")
            let termDefinitionStackView = createTermDefinitionStackView(for: card)
            allTermsStackView.addArrangedSubview(termDefinitionStackView)
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

    private func addBreakView(to stackView: UIStackView, size: CGFloat) {
        let breakView = UIView()
        breakView.widthAnchor.constraint(equalToConstant: size).isActive = true
        breakView.heightAnchor.constraint(equalToConstant: size).isActive = true
        stackView.addArrangedSubview(breakView)
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
}
