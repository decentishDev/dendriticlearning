//
//  FlashCardsVC.swift
//  StudyApp
//
//  Created by Matthew Lundeen on 4/8/24.
//

import UIKit
import PencilKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import GoogleMobileAds

class FlashcardsVC: UIViewController, GADBannerViewDelegate {
    
    var set = ""
    
    let cardCounter = UILabel()
    
    let IncorrectView = UIView()
    let CorrectView = UIView()
    let CardView = UIView()
    let CardLabel = UILabel()
//    let CardOverlayLabel = UIView()
    let CardDrawing = PKCanvasView()
    let CardImage = UIImageView()
    let cardButton = UIButton()
    let OverlayCard = UIView()
    let OverlayLabel = UILabel()
    let OverlayDrawing = PKCanvasView()
    let OverlayImage = UIImageView()
    
    let swipeRight = UISwipeGestureRecognizer()
    let swipeLeft = UISwipeGestureRecognizer()
    
    var onFront = true
    var startOnFront = true
    var random = true
    var cardOrder: [Int] = []
    let defaults = UserDefaults.standard
    var cards: [[String: Any?]] = [] //t: text, d: drawing, s: speech - maybe

    var known: [Bool] = []
    var index: Int = 0
    let cardAnimation = 0.4
    
    let endScreen = UIView()
    let endLabel = UILabel()
    
    let db = Firestore.firestore()
    let storage = Storage.storage()
    
    var bottomSpace: CGFloat = 0
    
    var previousSize: CGSize?
    
    var mainStack = UIStackView()
    var optionsStack = UIStackView()
    var fullStack = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.background

        guard let data = defaults.value(forKey: "set") as? [String: Any] else {
            print("No set found in defaults")
            return
        }
        
        cards = data["set"] as! [[String: Any?]]
        var userData: [String: Any] = [:]
        let userRef = self.db.collection("users").document(Auth.auth().currentUser!.uid)
        
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                userData = document.data()!
                self.handleUserData(userData)
            } else {
                print("Document does not exist")
                self.handleUserData([:])
            }
        }
        
        previousSize = view.bounds.size
    }

    func handleUserData(_ userData: [String: Any]) {
        for setInfo in userData["studiedSets"] as? [[String: Any]] ?? [] {
            if setInfo["setID"] as? String == set {
                known = setInfo["flashcards"] as? [Bool] ?? []
                break
            }
        }
        
        if known.count != cards.count {
            known = Array(repeating: false, count: cards.count)
            save()
        }
        
        if known.allSatisfy({ $0 }) {
            known = Array(repeating: false, count: known.count)
        }
        
        for (index, isKnown) in known.enumerated() {
            if !isKnown {
                cardOrder.append(index)
            }
        }
        
        if random {
            cardOrder.shuffle()
        }
        setup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //setup()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            //self.setup()
            self.layout()
            self.layoutOverlay()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if previousSize != view.bounds.size {
            previousSize = view.bounds.size
            //setup()
//            if previousSize!.width < 500 {
//                IncorrectView.backgroundColor = .clear
//                CorrectView.backgroundColor = .clear
//            }
            layout()
            layoutOverlay()
        }
    }
    
    
    func setup(){
        for i in view.subviews {
            i.removeFromSuperview()
        }
        
        if(defaults.value(forKey: "isPaid") as! Bool != true){
            let bannerView = GADBannerView(adSize: GADAdSizeFromCGSize(CGSize(width: min(600, view.bounds.width), height: 100)))
            view.addSubview(bannerView)
            bannerView.delegate = self
            bannerView.adUnitID = "ca-app-pub-5124969442805102/7426291738"
            bannerView.rootViewController = self
            bannerView.load(GADRequest())
            
            tAMC(bannerView)
            NSLayoutConstraint.activate([
                bannerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                bannerView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
            
            //bottomSpace = GADCurrentOrientationInlineAdaptiveBannerAdSizeWithWidth(min(view.frame.height, view.frame.width) - 300).size.height + 10
            bottomSpace = 120
        }
        //print(bottomSpace)
        
        
        
        IncorrectView.backgroundColor = Colors.secondaryBackground
        IncorrectView.layer.cornerRadius = 20
        CardView.backgroundColor = Colors.secondaryBackground
        CardView.layer.cornerRadius = 20
        
        CorrectView.backgroundColor = Colors.secondaryBackground
        CorrectView.layer.cornerRadius = 20
        
//        view.addSubview(CorrectView)
//        view.addSubview(IncorrectView)
        
        
        layout()
        
        
        
        let incorrectImage = UIImageView()
        incorrectImage.image = UIImage(systemName: "xmark")
        incorrectImage.tintColor = Colors.text
        incorrectImage.layer.frame = CGRect(x: (IncorrectView.layer.frame.width / 2) - 25, y: (IncorrectView.layer.frame.height / 2) - 25, width: 50, height: 50)
        conH(incorrectImage, 50)
        incorrectImage.contentMode = .scaleAspectFit
        IncorrectView.addSubview(incorrectImage)
        let incorrectButton = UIButton()
        incorrectButton.addTarget(self, action: #selector(self.IncorrectButton(sender:)), for: .touchUpInside)
        incorrectButton.layer.frame = CGRect(x: 0, y: 0, width: IncorrectView.frame.width, height: IncorrectView.frame.height)
        IncorrectView.addSubview(incorrectButton)
        
        tAMC([incorrectImage, incorrectButton])
        NSLayoutConstraint.activate([
            //stack.topAnchor.constraint(equalTo: button.topAnchor, constant: 12)
            incorrectImage.leftAnchor.constraint(equalTo: IncorrectView.leftAnchor, constant: 0),
            incorrectImage.rightAnchor.constraint(equalTo: IncorrectView.rightAnchor, constant: 0),
            incorrectImage.centerYAnchor.constraint(equalTo: IncorrectView.centerYAnchor),
            incorrectButton.leftAnchor.constraint(equalTo: IncorrectView.leftAnchor),
            incorrectButton.rightAnchor.constraint(equalTo: IncorrectView.rightAnchor),
            incorrectButton.topAnchor.constraint(equalTo: IncorrectView.topAnchor),
            incorrectButton.bottomAnchor.constraint(equalTo: IncorrectView.bottomAnchor),
        ])
        
        CardLabel.font = UIFont(name: "LilGrotesk-Regular", size: 40)
        CardLabel.textAlignment = .center
        CardLabel.frame = CGRect(x: 20, y: 0, width: CardView.frame.width - 40, height: CardView.frame.height)
        CardLabel.numberOfLines = 0
        CardLabel.textColor = Colors.text
        CardView.addSubview(CardLabel)
        CardDrawing.frame = CGRect(x: 0, y: 0, width: (view.frame.width - 161), height: 2*(view.frame.width - 161)/3 - bottomSpace)
        
        CardDrawing.isUserInteractionEnabled = false
        CardDrawing.layer.cornerRadius = 20
        CardDrawing.backgroundColor = .clear
        CardDrawing.tool = Colors.pen
        CardDrawing.overrideUserInterfaceStyle = .light
        CardView.addSubview(CardDrawing)
        CardDrawing.center = CGPoint(x: CardView.frame.width/2, y: CardView.frame.height/2)
        CardImage.frame = CGRect(x: 20, y: 20, width: CardView.frame.width - 40, height: CardView.frame.height - 40)
        CardImage.contentMode = .scaleAspectFit
        CardView.addSubview(CardImage)
        
        tAMC([CardLabel, CardDrawing, CardImage])
        
        NSLayoutConstraint.activate([
            //stack.topAnchor.constraint(equalTo: button.topAnchor, constant: 12)
            
            CardLabel.leadingAnchor.constraint(equalTo: CardView.leadingAnchor, constant: 20),
            CardLabel.trailingAnchor.constraint(equalTo: CardView.trailingAnchor, constant: -20),
            CardLabel.topAnchor.constraint(equalTo: CardView.topAnchor, constant: 20),
            CardLabel.bottomAnchor.constraint(equalTo: CardView.bottomAnchor, constant: -20),
            
            CardDrawing.leadingAnchor.constraint(equalTo: CardView.leadingAnchor, constant: 20),
            CardDrawing.trailingAnchor.constraint(equalTo: CardView.trailingAnchor, constant: -20),
            CardDrawing.topAnchor.constraint(equalTo: CardView.topAnchor, constant: 20),
            CardDrawing.bottomAnchor.constraint(equalTo: CardView.bottomAnchor, constant: -20),
            
            CardImage.leadingAnchor.constraint(equalTo: CardView.leadingAnchor, constant: 20),
            CardImage.trailingAnchor.constraint(equalTo: CardView.trailingAnchor, constant: -20),
            CardImage.topAnchor.constraint(equalTo: CardView.topAnchor, constant: 20),
            CardImage.bottomAnchor.constraint(equalTo: CardView.bottomAnchor, constant: -20),
        ])
        
        if(onFront){
            if(cards[cardOrder[index]]["termType"] as! String == "t" || cards[cardOrder[index]]["termType"] as! String == "d-r"){
                CardLabel.text = cards[cardOrder[index]]["term"] as? String
                CardLabel.isHidden = false
                CardDrawing.isHidden = true
                CardImage.isHidden = true
            }else if(cards[cardOrder[index]]["termType"] as! String == "d"){
                loadDrawing(url: cards[cardOrder[index]]["term"] as? String, canvas: self.CardDrawing)
                
                CardLabel.isHidden = true
                CardDrawing.isHidden = false
                CardImage.isHidden = true
            }else{
                loadImage(url: self.cards[self.cardOrder[self.index]]["term"] as? String, imageView: self.CardImage)
                CardLabel.isHidden = true
                CardDrawing.isHidden = true
                CardImage.isHidden = false
            }
        }
        
        cardButton.addTarget(self, action: #selector(self.CardButton(sender:)), for: .touchUpInside)
        cardButton.frame = CGRect(x: 0, y: 0, width: CardView.frame.width, height: CardView.frame.height)
        CardView.addSubview(cardButton)
        CardView.bringSubviewToFront(cardButton)
        
        swipeLeft.addTarget(self, action: #selector(self.IncorrectSwipe(sender:)))
        swipeLeft.direction = .left
        swipeLeft.view?.layer.frame = CGRect(x: 0, y: 0, width: CardView.frame.width, height: CardView.frame.height)
        swipeRight.addTarget(self, action: #selector(self.CorrectSwipe(sender:)))
        swipeRight.direction = .right
        swipeRight.view?.layer.frame = CGRect(x: 0, y: 0, width: CardView.frame.width, height: CardView.frame.height)
        CardView.addGestureRecognizer(swipeLeft)
        CardView.addGestureRecognizer(swipeRight)
        
        let correctImage = UIImageView()
        correctImage.image = UIImage(systemName: "checkmark")
        correctImage.tintColor = Colors.text
        correctImage.layer.position = CorrectView.center
        correctImage.layer.frame = CGRect(x: (CorrectView.layer.frame.width / 2) - 25, y: (CorrectView.layer.frame.height / 2) - 25, width: 50, height: 50)
        conH(correctImage, 50)
        
        correctImage.contentMode = .scaleAspectFit
        CorrectView.addSubview(correctImage)
        let correctButton = UIButton()
        correctButton.addTarget(self, action: #selector(self.CorrectButton(sender:)), for: .touchUpInside)
        correctButton.layer.frame = CGRect(x: 0, y: 0, width: CorrectView.frame.width, height: CorrectView.frame.height)
        tAMC([correctImage, correctButton])
        CorrectView.addSubview(correctButton)
        
        NSLayoutConstraint.activate([
            //stack.topAnchor.constraint(equalTo: button.topAnchor, constant: 12)
            correctImage.leftAnchor.constraint(equalTo: CorrectView.leftAnchor, constant: 0),
            correctImage.rightAnchor.constraint(equalTo: CorrectView.rightAnchor, constant: 0),
            correctImage.centerYAnchor.constraint(equalTo: CorrectView.centerYAnchor),
            correctButton.leftAnchor.constraint(equalTo: CorrectView.leftAnchor),
            correctButton.rightAnchor.constraint(equalTo: CorrectView.rightAnchor),
            correctButton.topAnchor.constraint(equalTo: CorrectView.topAnchor),
            correctButton.bottomAnchor.constraint(equalTo: CorrectView.bottomAnchor),
        ])
        
        let backButton = UIButton()
        con(backButton, 30, 30)
        backButton.frame = CGRect(x: 15, y: 15, width: 30, height: 30)
        backButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        backButton.tintColor = Colors.highlight
        backButton.contentMode = .scaleAspectFit
        backButton.addTarget(self, action: #selector(self.BackButton(sender:)), for: .touchUpInside)
        view.addSubview(backButton)
        let settingsButton = UIButton()
        con(settingsButton, 30, 30)
        settingsButton.frame = CGRect(x: view.layer.frame.width - 45, y: 15, width: 30, height: 30)
        settingsButton.setImage(UIImage(systemName: "gearshape.fill"), for: .normal)
        settingsButton.tintColor = Colors.highlight
        settingsButton.contentMode = .scaleAspectFit
        settingsButton.addTarget(self, action: #selector(self.SettingsButton(sender:)), for: .touchUpInside)
        view.addSubview(settingsButton)
        cardCounter.frame = CGRect(x: 60, y: 20, width: view.frame.width - 120, height: 20)
        conH(cardCounter, 30)
        cardCounter.font = UIFont(name: "LilGrotesk-Bold", size: 15)
        cardCounter.textAlignment = .center
        cardCounter.text = String(index + 1) + "/" + String(cardOrder.count)
        cardCounter.textColor = Colors.text
        view.addSubview(cardCounter)
        
        tAMC([backButton, settingsButton, cardCounter])
        
        NSLayoutConstraint.activate([
            //stack.topAnchor.constraint(equalTo: button.topAnchor, constant: 12)
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            cardCounter.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 15),
            cardCounter.trailingAnchor.constraint(equalTo: settingsButton.leadingAnchor, constant: -15),
            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 15),
            cardCounter.topAnchor.constraint(equalTo: view.topAnchor, constant: 15),
            settingsButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 15),
        ])
        
        OverlayCard.frame = CardView.frame
        OverlayCard.layer.cornerRadius = 20
        OverlayCard.backgroundColor = Colors.secondaryBackground
        OverlayLabel.font = UIFont(name: "LilGrotesk-Regular", size: 40)
        OverlayLabel.textAlignment = .center
        OverlayLabel.frame = CGRect(x: 20, y: 0, width: CardView.frame.width - 40, height: CardView.frame.height)
        OverlayLabel.numberOfLines = 0
        OverlayLabel.textColor = Colors.text
        OverlayCard.addSubview(OverlayLabel)
        //OverlayDrawing.frame = CGRect(x: 0, y: 0, width: (view.frame.width - 161), height: 2*(view.frame.width - 161)/3 - bottomSpace)
        OverlayDrawing.frame = CGRect(x: 0, y: 0, width: CardDrawing.frame.width, height: CardDrawing.frame.height)
        OverlayDrawing.isUserInteractionEnabled = false
        OverlayDrawing.layer.cornerRadius = 20
        OverlayDrawing.backgroundColor = .clear
        OverlayDrawing.tool = Colors.pen
        OverlayDrawing.overrideUserInterfaceStyle = .light
        OverlayCard.addSubview(OverlayDrawing)
        OverlayDrawing.center = CGPoint(x: OverlayCard.frame.width/2, y: OverlayCard.frame.height/2)
        OverlayImage.frame = CGRect(x: 20, y: 20, width: CardView.frame.width - 40, height: CardView.frame.height - 40)
        OverlayImage.contentMode = .scaleAspectFit
        OverlayCard.addSubview(OverlayImage)
        OverlayCard.isHidden = true
        view.addSubview(OverlayCard)
        
        layoutOverlay()
        
        endScreen.frame = CGRect(x: 0, y: 0, width: CardView.frame.width, height: CardView.frame.height)
        CardView.addSubview(endScreen)
        
        endLabel.text = ""
        endLabel.font = UIFont(name: "LilGrotesk-Regular", size: 40)
        endLabel.textColor = Colors.text
        endLabel.frame = CGRect(x: 10, y: 10, width: CardView.frame.width - 20, height: CardView.frame.height - 130)
        endLabel.numberOfLines = 0
        endLabel.textAlignment = .center
        endScreen.addSubview(endLabel)
        
        let endButton = UIButton()
        endButton.frame = CGRect(x: 10, y: CardView.frame.height - 110, width: CardView.frame.width - 20, height: 100)
        endButton.backgroundColor = Colors.highlight
        endButton.setTitle("Next round", for: .normal)
        endButton.setTitleColor(Colors.text, for: .normal)
        endButton.titleLabel!.font = UIFont(name: "LilGrotesk-Bold", size: 30)
        endButton.layer.cornerRadius = 10
        endButton.addTarget(self, action: #selector(self.nextRound(sender:)), for: .touchUpInside)
        endScreen.addSubview(endButton)
        
        endScreen.isHidden = true
        
        view.bringSubviewToFront(OverlayCard)
        
        //CardView.frame = CGRect(x: 40 + IncorrectView.frame.width, y: 60, width: (view.layer.frame.width - 80) * 0.7, height: view.frame.height - 80 - bottomSpace)
        
        tAMC([endScreen, endLabel, endButton])
        
        NSLayoutConstraint.activate([
            //stack.topAnchor.constraint(equalTo: button.topAnchor, constant: 12)
            endScreen.leadingAnchor.constraint(equalTo: CardView.leadingAnchor),
            endScreen.trailingAnchor.constraint(equalTo: CardView.trailingAnchor),
            endScreen.topAnchor.constraint(equalTo: CardView.topAnchor),
            endScreen.bottomAnchor.constraint(equalTo: CardView.bottomAnchor),
            
            endLabel.leadingAnchor.constraint(equalTo: CardView.leadingAnchor, constant: 10),
            endLabel.trailingAnchor.constraint(equalTo: CardView.trailingAnchor, constant: -10),
            endLabel.topAnchor.constraint(equalTo: CardView.topAnchor, constant: 10),
            endLabel.bottomAnchor.constraint(equalTo: endButton.topAnchor, constant: 10),
            
            endButton.leadingAnchor.constraint(equalTo: CardView.leadingAnchor, constant: 10),
            endButton.trailingAnchor.constraint(equalTo: CardView.trailingAnchor, constant: -10),
            endButton.heightAnchor.constraint(equalToConstant: 100),
            endButton.bottomAnchor.constraint(equalTo: CardView.bottomAnchor, constant: -10),
        ])
        
        //overlayCrosshairAndBorder(CardDrawing)
        
//        view.addSubview(CardView)
//        view.bringSubviewToFront(CardView)
    }
    
    @objc func nextRound(sender: UIButton){
        cardOrder = []
        index = 0
        var t = true
        for i in known {
            if(!i){
                t = false
                break
            }
        }
        if t {
            for i in 0..<known.count {
                known[i] = false
            }
        }
        for i in 0 ..< cards.count{
            if(!known[i]){
                cardOrder.append(i)
            }
        }
        if(random){
            cardOrder.shuffle()
        }
        UIView.animate(withDuration: 0.5, animations: {
            self.CardView.layer.opacity = 0
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
            self.cardCounter.text = "1/" + String(self.cardOrder.count)
            self.cardButton.isUserInteractionEnabled = true
            self.IncorrectView.isUserInteractionEnabled = true
            self.CorrectView.isUserInteractionEnabled = true
            self.swipeLeft.isEnabled = true
            self.swipeRight.isEnabled = true
            self.endScreen.isHidden = true
            if(self.cards[self.cardOrder[self.index]]["termType"] as! String == "t" || self.cards[self.cardOrder[self.index]]["termType"] as! String == "d-r"){
                self.CardLabel.text = self.cards[self.cardOrder[self.index]]["term"] as? String
                self.CardLabel.isHidden = false
                self.CardDrawing.isHidden = true
                self.CardImage.isHidden = true
            }else if(self.cards[self.cardOrder[self.index]]["termType"] as! String == "d"){
                loadDrawing(url: self.cards[self.cardOrder[self.index]]["term"] as? String, canvas: self.CardDrawing)
                self.CardLabel.isHidden = true
                self.CardDrawing.isHidden = false
                self.CardImage.isHidden = true
            }else{
                loadImage(url: self.cards[self.cardOrder[self.index]]["term"] as? String, imageView: self.CardImage)
                self.CardLabel.isHidden = true
                self.CardDrawing.isHidden = true
                self.CardImage.isHidden = false
            }
            UIView.animate(withDuration: 0.5, animations: {
                self.CardView.layer.opacity = 1
            })
        }
    }
    
    @objc func IncorrectButton(sender: UIButton) {
        nextCard(false)
    }
    
    @objc func CorrectButton(sender: UIButton) {
        nextCard(true)
    }
    
    @objc func IncorrectSwipe(sender: UISwipeGestureRecognizer) {
        nextCard(false)
    }
    
    @objc func CorrectSwipe(sender: UISwipeGestureRecognizer) {
        nextCard(true)
    }
    
    func nextCard(_ correct: Bool){
        let overlayI = index
        //CardView.frame = CGRect(x: 40 + IncorrectView.frame.width, y: 60, width: (view.layer.frame.width - 80) * 0.7, height: view.frame.height - 80 - bottomSpace)
        view.bringSubviewToFront(OverlayCard)
        CardView.sendSubviewToBack(endScreen)
        if(correct){
            CorrectView.backgroundColor = Colors.green
            UIView.animate(withDuration: 0.5, animations: {
                self.CorrectView.backgroundColor = Colors.secondaryBackground
            })
        }else{
            IncorrectView.backgroundColor = Colors.red
            UIView.animate(withDuration: 0.5, animations: {
                self.IncorrectView.backgroundColor = Colors.secondaryBackground
            })
        }
        known[cardOrder[index]] = correct
        if(index == cardOrder.count - 1){
            endScreen.isHidden = false
            var t = 0
            for i in cardOrder {
                if(known[i]){
                    t+=1
                }
            }
            var c = 0
            for i in known {
                if(i){
                    c+=1
                }
            }
            endLabel.text = "Correct this round: " + String(t) + "/" + String(cardOrder.count) + "\nCorrect overall: " + String(c) + "/" + String(cards.count)
            cardButton.isUserInteractionEnabled = false
            IncorrectView.isUserInteractionEnabled = false
            CorrectView.isUserInteractionEnabled = false
            swipeLeft.isEnabled = false
            swipeRight.isEnabled = false
            CardLabel.isHidden = true
            CardDrawing.isHidden = true
            CardImage.isHidden = true
        }else{
            index+=1
            cardCounter.text = String(index + 1) + "/" + String(cardOrder.count)
            if(self.cards[self.cardOrder[self.index]]["termType"] as! String == "t"){
                self.CardLabel.text = self.cards[self.cardOrder[self.index]]["term"] as? String
                self.CardLabel.isHidden = false
                self.CardDrawing.isHidden = true
                self.CardImage.isHidden = true
            }else if(self.cards[self.cardOrder[self.index]]["termType"] as! String == "d"){
                loadDrawing(url: self.cards[self.cardOrder[self.index]]["term"] as? String, canvas: self.CardDrawing)
                self.CardLabel.isHidden = true
                self.CardDrawing.isHidden = false
                self.CardImage.isHidden = true
            }else{
                loadImage(url: self.cards[self.cardOrder[self.index]]["term"] as? String, imageView: self.CardImage)
                self.CardLabel.isHidden = true
                self.CardDrawing.isHidden = true
                self.CardImage.isHidden = false
            }
            UIView.animate(withDuration: 0.5, animations: {
                self.CardView.layer.opacity = 1
            })
            
        }
        
        if(onFront){
            if(cards[cardOrder[overlayI]]["termType"] as! String == "t"){
                OverlayLabel.text = cards[cardOrder[overlayI]]["term"] as? String
                OverlayLabel.isHidden = false
                OverlayDrawing.isHidden = true
                OverlayImage.isHidden = true
            }else if(cards[cardOrder[overlayI]]["termType"] as! String == "d"){
                loadDrawing(url: cards[cardOrder[overlayI]]["term"] as? String, canvas: self.OverlayDrawing)
                OverlayLabel.isHidden = true
                OverlayDrawing.isHidden = false
                OverlayImage.isHidden = true
            }else{
                loadImage(url: self.cards[self.cardOrder[self.index]]["term"] as? String, imageView: self.OverlayImage)
                OverlayLabel.isHidden = true
                OverlayDrawing.isHidden = true
                OverlayImage.isHidden = false
            }
        }else{
            if(cards[cardOrder[overlayI]]["defType"] as! String == "t" || cards[cardOrder[overlayI]]["defType"] as! String == "d-r"){
                OverlayLabel.text = cards[cardOrder[overlayI]]["def"] as? String
                OverlayLabel.isHidden = false
                OverlayDrawing.isHidden = true
                OverlayImage.isHidden = true
            }else if(cards[cardOrder[overlayI]]["defType"] as! String == "d"){
                loadDrawing(url: cards[cardOrder[overlayI]]["def"] as? String, canvas: self.OverlayDrawing)
                OverlayLabel.isHidden = true
                OverlayDrawing.isHidden = false
                OverlayImage.isHidden = true
            }//else{
//                OverlayImage.image = UIImage(data: cards[cardOrder[index]]["def"] as! Data)
//                OverlayLabel.isHidden = true
//                OverlayDrawing.isHidden = true
//                OverlayImage.isHidden = false
//            }
        }
        OverlayCard.layer.transform = CATransform3DIdentity
        OverlayCard.isHidden = false
        OverlayCard.alpha = 1

        var initialTransform = CATransform3DIdentity
        initialTransform.m34 = -1.0 / 500
        initialTransform = CATransform3DRotate(initialTransform, .pi, 0, 0, 0)
        OverlayCard.layer.transform = initialTransform

        CardView.layer.opacity = 0
        if(correct){
            UIView.animate(withDuration: 0.5, animations: {
                var finalTransform = CATransform3DIdentity
                finalTransform.m34 = -1.0 / 500
                finalTransform = CATransform3DRotate(finalTransform, .pi, 0, 0.5, 1)
                finalTransform = CATransform3DTranslate(finalTransform, -700, -700, -500)
                self.OverlayCard.layer.transform = finalTransform

                self.OverlayCard.alpha = 0
                self.CardView.layer.opacity = 1
            })
        }else{
            UIView.animate(withDuration: 0.5, animations: {
                var finalTransform = CATransform3DIdentity
                finalTransform.m34 = -1.0 / 500
                finalTransform = CATransform3DRotate(finalTransform, .pi, 0, 0.5, -1)
                finalTransform = CATransform3DTranslate(finalTransform, 700, 700, -500)
                self.OverlayCard.layer.transform = finalTransform

                self.OverlayCard.alpha = 0
                self.CardView.layer.opacity = 1
            })
        }
        
        CardView.layer.transform = CATransform3DIdentity
        CardLabel.layer.transform = CATransform3DIdentity
        CardDrawing.layer.transform = CATransform3DIdentity
        CardImage.layer.transform = CATransform3DIdentity
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
            self.OverlayCard.isHidden = true
        }
        
        onFront = true
        save()
    }
    
    func save() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userRef = db.collection("users").document(uid)
        
        // Fetch the existing user data
        userRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            if let document = document, document.exists, var oldUser = document.data() {
                // Update the studiedSets with the new known data
                if var oldStudied = oldUser["studiedSets"] as? [[String: Any]] {
                    var t = false
                    for (i, set) in oldStudied.enumerated() {
                        if set["setID"] as? String == self.set {
                            oldStudied[i]["flashcards"] = self.known
                            oldStudied[i]["date"] = Timestamp()
                            t = true
                            break
                        }
                    }
                    if !t {
                        oldStudied.append([
                            "setID": self.set,
                            "learn": self.known,
                            "date": Timestamp()
                        ])
                    }
                    oldUser["studiedSets"] = oldStudied
                    
                    // Save the updated data back to Firestore
                    userRef.setData(oldUser, merge: true) { error in
                        if let error = error {
                            print("Error updating document: \(error)")
                        } else {
                            print("Document successfully updated")
                        }
                    }
                }
            } else {
                print("Document does not exist or data format is invalid")
            }
        }
    }

    
    @objc func CardButton(sender: UIButton) {
        var perspective = CATransform3DIdentity
        perspective.m34 = -1.0 / 1000.0

        let halfwayDuration = cardAnimation / 2
        let originalColor = self.CardView.backgroundColor

        UIView.animate(withDuration: halfwayDuration, delay: 0, options: [.curveEaseIn], animations: {
            var transform = CATransform3DRotate(perspective, .pi / 2, 1, 0, 0)
            self.CardView.layer.transform = transform
            self.CardView.backgroundColor = lighten(originalColor!)
            self.CardDrawing.alpha = 0.5
            self.CardLabel.alpha = 0.5
            self.CardImage.alpha = 0.5
        }, completion: { _ in
            if self.onFront {
                if let defType = self.cards[self.cardOrder[self.index]]["defType"] as? String {
                    if defType == "t" || defType == "d-r" {
                        self.CardLabel.text = self.cards[self.cardOrder[self.index]]["def"] as? String
                        self.CardLabel.isHidden = false
                        self.CardDrawing.isHidden = true
                        self.CardImage.isHidden = true
                    } else if defType == "d" {
                        loadDrawing(url: self.cards[self.cardOrder[self.index]]["def"] as? String, canvas: self.CardDrawing)
                        self.CardLabel.isHidden = true
                        self.CardDrawing.isHidden = false
                        self.CardImage.isHidden = true
                    }
                }
            } else {
                if let termType = self.cards[self.cardOrder[self.index]]["termType"] as? String {
                    if termType == "t" {
                        self.CardLabel.text = self.cards[self.cardOrder[self.index]]["term"] as? String
                        self.CardLabel.isHidden = false
                        self.CardDrawing.isHidden = true
                        self.CardImage.isHidden = true
                    } else if termType == "d" {
                        loadDrawing(url: self.cards[self.cardOrder[self.index]]["term"] as? String, canvas: self.CardDrawing)
                        self.CardLabel.isHidden = true
                        self.CardDrawing.isHidden = false
                        self.CardImage.isHidden = true
                    } else {
                        loadImage(url: self.cards[self.cardOrder[self.index]]["term"] as? String, imageView: self.CardImage)
                        self.CardLabel.isHidden = true
                        self.CardDrawing.isHidden = true
                        self.CardImage.isHidden = false
                    }
                }
            }
            self.onFront.toggle()

            var backTransform = CATransform3DRotate(perspective, -.pi / 2, 1, 0, 0)
            self.CardView.layer.transform = backTransform
            self.CardView.backgroundColor = darken(originalColor!)
            self.CardDrawing.alpha = 0.15
            self.CardLabel.alpha = 0.15
            self.CardImage.alpha = 0.15

            UIView.animate(withDuration: halfwayDuration, delay: 0, options: [.curveEaseOut], animations: {
                self.CardView.layer.transform = CATransform3DIdentity
                self.CardView.backgroundColor = originalColor
                self.CardDrawing.alpha = 1.0
                self.CardLabel.alpha = 1.0
                self.CardImage.alpha = 1.0
            })
        })
    }

    @objc func BackButton(sender: UIButton){
        performSegue(withIdentifier: "flashcardsVC_unwind", sender: nil)
    }
    
    @objc func SettingsButton(sender: UIButton){
        
    }
    
    func layout(){
        mainStack.removeFromSuperview()
        fullStack.removeFromSuperview()
        optionsStack.removeFromSuperview()
        CardView.removeFromSuperview()
        IncorrectView.removeFromSuperview()
        CorrectView.removeFromSuperview()
        
        if(view.layer.frame.width > view.layer.frame.height){
            IncorrectView.frame = CGRect(x: 20, y: 60, width: (view.layer.frame.width - 80) * 0.15, height: view.frame.height - 80 - bottomSpace)
            CardView.frame = CGRect(x: 40 + IncorrectView.frame.width, y: 60, width: (view.layer.frame.width - 80) * 0.7, height: view.frame.height - 80 - bottomSpace)
            CorrectView.frame = CGRect(x: 60 + IncorrectView.frame.width + CardView.frame.width, y: 60, width: (view.layer.frame.width - 80) * 0.15, height: view.frame.height - 80 - bottomSpace)
            
            mainStack = UIStackView(arrangedSubviews: [IncorrectView, CardView, CorrectView])
            mainStack.spacing = 20
            mainStack.axis = .horizontal
            view.addSubview(mainStack)
            
            NSLayoutConstraint.activate([
                //stack.topAnchor.constraint(equalTo: button.topAnchor, constant: 12)
                
                mainStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
                mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                mainStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20 - bottomSpace),
                
                IncorrectView.heightAnchor.constraint(equalTo: mainStack.heightAnchor, multiplier: 1),
                
                CardView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
                CardView.heightAnchor.constraint(equalTo: mainStack.heightAnchor, multiplier: 1),
                
                CorrectView.heightAnchor.constraint(equalTo: mainStack.heightAnchor, multiplier: 1),
                CorrectView.widthAnchor.constraint(equalTo: IncorrectView.widthAnchor, multiplier: 1)
            ])
            
            tAMC([mainStack, IncorrectView, CardView, CorrectView])
        }else{
            let optionsHeight: CGFloat = (view.layer.frame.height - 100 - bottomSpace) * 0.3
            let topHeight: CGFloat = (view.layer.frame.height - 100 - bottomSpace) * 0.7
            
            IncorrectView.frame = CGRect(x: 20, y: 80 + topHeight, width: (view.layer.frame.width - 60) * 0.5, height: optionsHeight)
            CardView.frame = CGRect(x: 20, y: 60, width: view.layer.frame.width - 40, height: topHeight)
            CorrectView.frame = CGRect(x: 40 + IncorrectView.frame.width, y: 80 + topHeight, width: (view.layer.frame.width - 60) * 0.5, height: optionsHeight)
            
            optionsStack = UIStackView(arrangedSubviews: [IncorrectView, CorrectView])
            optionsStack.spacing = 20
            optionsStack.axis = .horizontal
            optionsStack.distribution = .fillEqually
            
            fullStack = UIStackView(arrangedSubviews: [CardView, optionsStack])
            fullStack.spacing = 20
            fullStack.axis = .vertical
            fullStack.distribution = .fill
            view.addSubview(fullStack)
            
            NSLayoutConstraint.activate([
                //stack.topAnchor.constraint(equalTo: button.topAnchor, constant: 12)
                
                fullStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
                fullStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                fullStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                fullStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20 - bottomSpace),
                
                CardView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),
                CardView.widthAnchor.constraint(equalTo: fullStack.widthAnchor),
                
                IncorrectView.heightAnchor.constraint(equalTo: optionsStack.heightAnchor),
                CorrectView.heightAnchor.constraint(equalTo: optionsStack.heightAnchor),
                optionsStack.widthAnchor.constraint(equalTo: fullStack.widthAnchor)
            ])
            
            tAMC([fullStack, optionsStack, IncorrectView, CardView, CorrectView])
        }
    }
    
    func layoutOverlay(){
        OverlayCard.frame = CardView.frame
        OverlayLabel.frame = CGRect(x: 20, y: 0, width: CardView.frame.width - 40, height: CardView.frame.height)
        OverlayDrawing.frame = CGRect(x: 0, y: 0, width: CardDrawing.frame.width, height: CardDrawing.frame.height)
        OverlayDrawing.center = CGPoint(x: OverlayCard.frame.width/2, y: OverlayCard.frame.height/2)
        OverlayImage.frame = CGRect(x: 20, y: 20, width: CardView.frame.width - 40, height: CardView.frame.height - 40)
        
        
        tAMC([OverlayCard, OverlayLabel, OverlayDrawing, OverlayImage])
        
        NSLayoutConstraint.activate([
            //stack.topAnchor.constraint(equalTo: button.topAnchor, constant: 12)
            
            OverlayCard.leadingAnchor.constraint(equalTo: CardView.leadingAnchor),
            OverlayCard.trailingAnchor.constraint(equalTo: CardView.trailingAnchor),
            OverlayCard.topAnchor.constraint(equalTo: CardView.topAnchor),
            OverlayCard.bottomAnchor.constraint(equalTo: CardView.bottomAnchor),
            
            OverlayLabel.leadingAnchor.constraint(equalTo: OverlayCard.leadingAnchor, constant: 20),
            OverlayLabel.trailingAnchor.constraint(equalTo: OverlayCard.trailingAnchor, constant: -20),
            OverlayLabel.topAnchor.constraint(equalTo: OverlayCard.topAnchor, constant: 20),
            OverlayLabel.bottomAnchor.constraint(equalTo: OverlayCard.bottomAnchor, constant: -20),
            
            OverlayDrawing.leadingAnchor.constraint(equalTo: OverlayCard.leadingAnchor, constant: 20),
            OverlayDrawing.trailingAnchor.constraint(equalTo: OverlayCard.trailingAnchor, constant: -20),
            OverlayDrawing.topAnchor.constraint(equalTo: OverlayCard.topAnchor, constant: 20),
            OverlayDrawing.bottomAnchor.constraint(equalTo: OverlayCard.bottomAnchor, constant: -20),
            
            OverlayImage.leadingAnchor.constraint(equalTo: OverlayCard.leadingAnchor, constant: 20),
            OverlayImage.trailingAnchor.constraint(equalTo: OverlayCard.trailingAnchor, constant: -20),
            OverlayImage.topAnchor.constraint(equalTo: OverlayCard.topAnchor, constant: 20),
            OverlayImage.bottomAnchor.constraint(equalTo: OverlayCard.bottomAnchor, constant: -20),
        ])
    }
    
    @IBAction func cancel (_ unwindSegue: UIStoryboardSegue){
        
    }
}
