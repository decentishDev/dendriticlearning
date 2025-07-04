//
//  StandardLearnVC.swift
//  StudyApp
//
//  Created by Matthew Lundeen on 4/13/24.
//

import UIKit
import PencilKit
import Vision
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import GoogleMobileAds

class StandardLearnVC: UIViewController, PKCanvasViewDelegate, UITextFieldDelegate, GADBannerViewDelegate {
    let defaults = UserDefaults.standard
    var set = ""
    var topHeight: CGFloat = 200
    var keyboard: CGFloat = 0
    
    let cardCounter = UILabel()
    
    let CardLabel = UILabel()
//    let CardOverlayLabel = UIView()
    let CardDrawing = PKCanvasView()
    let CardImage = UIImageView()
    
    let DrawingView = PKCanvasView()
    let TextField = UITextField()
    var currentDrawing = PKDrawing()
    let enterButton = UIButton()
    
    var currentInput = "t" //t, d, d-r, s, s-r
    var startOnFront = true
    var cardOrder: [Int] = []
    var cards: [[String: Any?]] = []
    var known: [Int] = []
    var index: Int = 0
    
    var recognizedText = ""
    var mostRecentProcess = 0
    var processing = false
    var waitingOnResult = false
    
    var random = true
    
    let EndScreen = UIView()
    let EndLabel = UILabel()
    
    let correctButton = UIButton()
    let incorrectButton = UIButton()
    
    var alreadyWrong = false
    
    var usingEraser = false
    
    let db = Firestore.firestore()
    let storage = Storage.storage()
    
    var previousSize = CGSize()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.background
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // Fetch data and initialize the view after fetching
        fetchDataAndInitialize()
        
        previousSize = view.bounds.size
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.reformat()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if previousSize != view.bounds.size {
            previousSize = view.bounds.size
            reformat()
        }
    }

    func fetchDataAndInitialize() {
        guard let data = defaults.value(forKey: "set") as? [String: Any] else { return }
        cards = data["set"] as! [[String: Any]]
        
        var userData: [String: Any] = [:]
        let userRef = db.collection("users").document(Auth.auth().currentUser!.uid)
        
        userRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let document = document, document.exists {
                userData = document.data()!
                self.initializeView(userData: userData)
            } else {
                print("Document does not exist")
                // Handle the case where the document doesn't exist if necessary
            }
        }
    }

    func initializeView(userData: [String: Any]) {
        // Process userData and update the view accordingly
        for i in userData["studiedSets"] as! [[String: Any]] {
            if i["setID"] as! String == set {
                known = i["learn"] as! [Int]
                break
            }
        }
        
        if known.count != cards.count {
            var c: [Int] = []
            for _ in 0..<cards.count {
                c.append(0)
            }
            known = c
            save()
        }
        
        var t = true
        for i in known {
            if i != 2 {
                t = false
                break
            }
        }
        
        if t {
            for i in 0..<known.count {
                known[i] = 0
            }
        }
        
        for i in 0..<cards.count {
            if known[i] != 2 {
                cardOrder.append(i)
            }
        }
        
        if random {
            cardOrder.shuffle()
        }
        
        setup()
        nextTerm()
    }

    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    func setup(){
        let backButton = UIButton()
        backButton.frame = CGRect(x: 20, y: 20, width: 30, height: 30)
        backButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        backButton.contentMode = .scaleAspectFit
        backButton.imageView!.contentMode = .scaleAspectFit
        backButton.addTarget(self, action: #selector(self.BackButton(sender:)), for: .touchUpInside)
        backButton.tintColor = Colors.highlight
        //backButton.contentVerticalAlignment = .fill
        //backButton.contentHorizontalAlignment = .fill
        //backButton.backgroundColor = .red
        view.addSubview(backButton)
        let settingsButton = UIButton()
        settingsButton.frame = CGRect(x: view.layer.frame.width - 50, y: 20, width: 30, height: 30)
        settingsButton.setImage(UIImage(systemName: "gearshape.fill"), for: .normal)
        settingsButton.contentMode = .scaleAspectFit
        settingsButton.imageView!.contentMode = .scaleAspectFit
        settingsButton.addTarget(self, action: #selector(self.SettingsButton(sender:)), for: .touchUpInside)
        settingsButton.tintColor = Colors.highlight
        //settingsButton.contentVerticalAlignment = .fill
        //settingsButton.contentHorizontalAlignment = .fill
        view.addSubview(settingsButton)
        cardCounter.frame = CGRect(x: 60, y: 20, width: view.frame.width - 120, height: 20)
        cardCounter.font = .systemFont(ofSize: 15)
        cardCounter.textAlignment = .center
        cardCounter.textColor = Colors.text
        cardCounter.text = String(index + 1) + "/" + String(cardOrder.count)
        view.addSubview(cardCounter)
        CardLabel.font = UIFont(name: "LilGrotesk-Regular", size: 50)
        CardLabel.frame = CGRect(x: 20, y: 0, width: view.frame.width - 40, height: topHeight - keyboard)
        CardLabel.textColor = Colors.text
        CardLabel.textAlignment = .center
        CardLabel.numberOfLines = 0
        CardLabel.text = ""
        view.addSubview(CardLabel)
        CardDrawing.frame = CGRect(x: 0, y: 0, width: (view.frame.width - 161), height: 2*(view.frame.width - 161)/3)
        CardDrawing.backgroundColor = .clear
        CardDrawing.center = CGPoint(x: view.frame.width/2, y: (topHeight-keyboard)/2)
        CardDrawing.tool = Colors.pen
        CardDrawing.overrideUserInterfaceStyle = .light
        view.addSubview(CardDrawing)
        CardImage.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: topHeight-keyboard)
        CardImage.contentMode = .scaleAspectFit
        view.addSubview(CardImage)
        TextField.frame = CGRect(x: 50, y: topHeight - keyboard + 20, width: view.frame.width - 110, height: 50)
        TextField.font = UIFont(name: "LilGrotesk-Regular", size: 35)
        TextField.textColor = Colors.text
        TextField.placeholder = "Type your answer here . . ."
        TextField.delegate = self
        TextField.backgroundColor = Colors.secondaryBackground
        TextField.layer.cornerRadius = 10
        let paddingView = UIView(frame: CGRectMake(0, 0, 10, TextField.frame.height))
        TextField.leftView = paddingView
        TextField.leftViewMode = .always
        view.addSubview(TextField)
        DrawingView.frame = CGRect(x: 50, y: topHeight - keyboard + 20, width: view.frame.width - 100, height: 250)
        DrawingView.backgroundColor = Colors.secondaryBackground
        DrawingView.delegate = self
        DrawingView.tool = Colors.pen
        DrawingView.overrideUserInterfaceStyle = .light
        DrawingView.backgroundColor = Colors.secondaryBackground
        DrawingView.layer.cornerRadius = 10
        DrawingView.allowsFingerDrawing = defaults.value(forKey: "fingerDrawing") as! Bool
        view.addSubview(DrawingView)
        let clearButton = UIButton(frame: CGRect(x: 50, y: 10, width: 30, height: 30))
        DrawingView.addSubview(clearButton)
        clearButton.setImage(UIImage(systemName: "arrow.circlepath"), for: .normal)
        clearButton.contentMode = .scaleAspectFit
        clearButton.tintColor = Colors.highlight
        clearButton.layoutMargins = .zero
        //clearButton.backgroundColor = Colors.background
        //clearButton.layer.cornerRadius = 10
        clearButton.addTarget(self, action: #selector(clear(_:)), for: .touchUpInside)
        let eraserButton = UIButton(frame: CGRect(x: 10, y: 10, width: 30, height: 30))
        eraserButton.setImage(UIImage(systemName: "eraser.fill"), for: .normal)
        eraserButton.contentMode = .scaleAspectFit
        eraserButton.tintColor = Colors.highlight
        eraserButton.layoutMargins = .zero
        //eraserButton.backgroundColor = Colors.background
        //eraserButton.layer.cornerRadius = 10
        eraserButton.addTarget(self, action: #selector(eraser(_:)), for: .touchUpInside)
        DrawingView.addSubview(eraserButton)
        let undoButton = UIButton(frame: CGRect(x: 90, y: 10, width: 30, height: 30))
        DrawingView.addSubview(undoButton)
        undoButton.setImage(UIImage(systemName: "arrow.uturn.backward"), for: .normal)
        undoButton.contentMode = .scaleAspectFit
        undoButton.tintColor = Colors.highlight
        undoButton.layoutMargins = .zero
        //clearButton.backgroundColor = Colors.background
        //clearButton.layer.cornerRadius = 10
        undoButton.addTarget(self, action: #selector(self.undoButton(_:)), for: .touchUpInside)
        enterButton.frame = CGRect(x: view.frame.width - 100, y: topHeight-keyboard + 20, width: 50, height: 50)
        enterButton.setImage(UIImage(systemName: "arrowshape.right.fill"), for: .normal)
        enterButton.tintColor = Colors.highlight
        //enterButton.backgroundColor = Colors.background
        //enterButton.layer.cornerRadius = 10
        enterButton.addTarget(self, action: #selector(enter(sender:)), for: .touchUpInside)
        enterButton.contentMode = .scaleAspectFit
        enterButton.layoutMargins = .init(top: 10, left: 10, bottom: 10, right: 10)
        view.addSubview(enterButton)
        
        EndScreen.frame = CGRect(x: 50, y: 0, width: view.frame.width - 100, height: view.frame.height)
        view.addSubview(EndScreen)
        EndLabel.frame = CGRect(x: 0, y: 100, width: view.frame.width - 100, height: view.frame.height - 315)
        EndLabel.text = ""
        EndLabel.font = UIFont(name: "LilGrotesk-Regular", size: 40)
        EndLabel.textColor = Colors.text
        EndLabel.textAlignment = .center
        EndLabel.numberOfLines = 0
        EndScreen.addSubview(EndLabel)
        let EndButton = UIButton()
        EndButton.frame = CGRect(x: (view.frame.width / 2) - 125 - 50, y: view.frame.height - 215, width: 250, height: 75)
        EndButton.backgroundColor = Colors.highlight
        EndButton.layer.cornerRadius = 15
        EndButton.setTitle("Next round", for: .normal)
        EndButton.setTitleColor(Colors.text, for: .normal)
        EndButton.titleLabel!.font = UIFont(name: "LilGrotesk-Bold", size: 30)
        EndButton.addTarget(self, action: #selector(nextRound(sender:)), for: .touchUpInside)
        EndScreen.addSubview(EndButton)
        
        if(defaults.value(forKey: "isPaid") as! Bool != true){
            let bannerView = GADBannerView(adSize: GADAdSizeFromCGSize(CGSize(width: min(600, previousSize.width), height: 100)))
            EndScreen.addSubview(bannerView)
            bannerView.delegate = self
            bannerView.adUnitID = "ca-app-pub-5124969442805102/7426291738"
            bannerView.rootViewController = self
            bannerView.load(GADRequest())
            tAMC(bannerView)
            NSLayoutConstraint.activate([
                bannerView.bottomAnchor.constraint(equalTo: EndScreen.bottomAnchor, constant: -20),
                bannerView.centerXAnchor.constraint(equalTo: EndScreen.centerXAnchor)
            ])
        }
        EndScreen.isHidden = true
        
        incorrectButton.frame = CGRect(x: (view.frame.width / 2) - 60, y: topHeight - keyboard + 20 - 70, width: 50, height: 50)
        incorrectButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        incorrectButton.tintColor = Colors.red
        incorrectButton.contentVerticalAlignment = .fill
        incorrectButton.contentHorizontalAlignment = .fill
        incorrectButton.imageView?.contentMode = .scaleAspectFit
        incorrectButton.contentEdgeInsets = .zero
        incorrectButton.addTarget(self, action: #selector(incorrectDrawing(sender:)), for: .touchUpInside)

        correctButton.frame = CGRect(x: (view.frame.width / 2) + 10, y: topHeight - keyboard + 20 - 70, width: 50, height: 50)
        correctButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
        correctButton.tintColor = Colors.green
        correctButton.contentVerticalAlignment = .fill
        correctButton.contentHorizontalAlignment = .fill
        correctButton.imageView?.contentMode = .scaleAspectFit
        correctButton.contentEdgeInsets = .zero
        correctButton.addTarget(self, action: #selector(correctDrawing(sender:)), for: .touchUpInside)

        view.addSubview(incorrectButton)
        view.addSubview(correctButton)

        incorrectButton.alpha = 0
        correctButton.alpha = 0
        incorrectButton.isHidden = true
        correctButton.isHidden = true
        view.bringSubviewToFront(incorrectButton)
        view.bringSubviewToFront(correctButton)

    }
    
    @objc func eraser(_ sender: UIButton) {
        if(usingEraser){
            sender.setImage(UIImage(systemName: "eraser.fill"), for: .normal)
            DrawingView.tool = PKInkingTool(.pen, color: Colors.text, width: PKInkingTool.InkType.pen.defaultWidth)
        }else{
            sender.setImage(UIImage(systemName: "pencil"), for: .normal)
            DrawingView.tool = PKEraserTool(.vector)
        }
        usingEraser = !usingEraser
    }
    
    @objc func clear(_ sender: UIButton) {
        DrawingView.drawing = recolor(PKDrawing())
    }
    
    @objc func undoButton(_ sender: UIButton){
        DrawingView.undoManager?.undo()
    }
    
    func correctAnim(_ i: Int){
        DrawingView.backgroundColor = Colors.green
        TextField.backgroundColor = Colors.green
        UIView.animate(withDuration: 0.5, animations: {
            self.DrawingView.backgroundColor = Colors.secondaryBackground
            self.TextField.backgroundColor = Colors.secondaryBackground
        })
        if(!alreadyWrong){
            known[i] += 1
        }
        alreadyWrong = false
        save()
    }
    
    func incorrectAnim(_ i: Int){
        DrawingView.backgroundColor = Colors.red
        TextField.backgroundColor = Colors.red
        UIView.animate(withDuration: 0.5, animations: {
            self.DrawingView.backgroundColor = Colors.secondaryBackground
            self.TextField.backgroundColor = Colors.secondaryBackground
        })
        TextField.text = ""
        known[i] = 0
        alreadyWrong = true
        save()
        if(currentInput == "t" || currentInput == "d-r"){
            UIView.animate(withDuration: 0.2, animations: {
                self.CardLabel.alpha = 0
                self.CardDrawing.alpha = 0
            }, completion: {_ in
                self.CardLabel.text = self.cards[i]["def"] as? String
                UIView.animate(withDuration: 1, animations: {
                    self.CardLabel.alpha = 1
                }, completion: {_ in
                    UIView.animate(withDuration: 1, animations: {
                        self.CardLabel.alpha = 0
                    }, completion: {_ in
                        if(self.cards[i]["termType"] as! String == "t"){
                            self.CardLabel.text = self.cards[i]["term"] as? String
                        }else{
                            loadDrawing(url: self.cards[i]["term"] as? String, canvas: self.CardDrawing)
                        }
                        UIView.animate(withDuration: 0.2, animations: {
                            self.CardLabel.alpha = 1
                            self.CardDrawing.alpha = 1
                        })
                    })
                })
            })
        }
    }
    @objc func incorrectDrawing(sender: UIButton) {
        DrawingView.drawing = recolor(PKDrawing())
        UIView.animate(withDuration: 0.3, animations: {
            self.incorrectButton.alpha = 0
            self.correctButton.alpha = 0
            self.enterButton.alpha = 1
        })
        enterButton.isEnabled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
            self.incorrectButton.isHidden = true
            self.correctButton.isHidden = true
        }
        DrawingView.backgroundColor = Colors.red
        TextField.backgroundColor = Colors.red
        UIView.animate(withDuration: 0.5, animations: {
            self.DrawingView.backgroundColor = Colors.secondaryBackground
            self.TextField.backgroundColor = Colors.secondaryBackground
        })
        known[cardOrder[index]] = 0
        index+=1
        nextTerm()
    }
    @objc func correctDrawing(sender: UIButton) {
        DrawingView.drawing = recolor(PKDrawing())
        UIView.animate(withDuration: 0.3, animations: {
            self.incorrectButton.alpha = 0
            self.correctButton.alpha = 0
            self.enterButton.alpha = 1
        })
        enterButton.isEnabled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
            self.incorrectButton.isHidden = true
            self.correctButton.isHidden = true
        }
        correctAnim(cardOrder[index])
        index+=1
        nextTerm()
    }
    @objc func nextRound(sender: UIButton) {
        cardOrder.removeAll()
        for (i, j) in known.enumerated() {
            if(j != 2){
                cardOrder.append(i)
            }
        }
        if(cardOrder.count == 0){
            for i in 0..<known.count {
                known[i] = 0
            }
            for i in 0..<cards.count{
                cardOrder.append(i)
            }
        }
        if(random){
            cardOrder.shuffle()
        }
        EndScreen.isHidden = true
        enterButton.isHidden = false
        index = 0
        nextTerm()
        cardCounter.text = "1/" + String(cardOrder.count)
    }
    @objc func enter(sender: UIButton) {
        if currentInput == "t" {
            let goal = getNormalizedString(from: cards[cardOrder[index]]["def"] as! String)
            let current = getNormalizedString(from: TextField.text ?? "")
            
            if goal == current {
                index += 1
                nextTerm()
                correctAnim(cardOrder[index])
            } else {
                incorrectAnim(cardOrder[index])
            }
        } else if currentInput == "d" {
            CardDrawing.isHidden = false
            CardLabel.isHidden = true
            CardImage.isHidden = true
            
            loadDrawing(url: cards[cardOrder[index]]["def"] as? String, canvas: self.CardDrawing)
            
            incorrectButton.isHidden = false
            correctButton.isHidden = false
            
            UIView.animate(withDuration: 0.3) {
                self.incorrectButton.alpha = 1
                self.correctButton.alpha = 1
                self.enterButton.alpha = 0.5
            }
            enterButton.isEnabled = false
        } else if currentInput == "d-r" {
            if processing {
                waitingOnResult = true
            } else {
                processRecognitionResult()
            }
        }
    }

    private func getNormalizedString(from input: String) -> String {
        return input.filter { !$0.isWhitespace }.lowercased()
    }

    private func processRecognitionResult() {
        let goal = getNormalizedString(from: cards[cardOrder[index]]["def"] as! String)
        let current = getNormalizedString(from: recognizedText)
        //print(current)
        if goal == current {
            correctAnim(cardOrder[index])
            index += 1
            nextTerm()
        } else {
            incorrectAnim(cardOrder[index])
        }
        DrawingView.drawing = recolor(PKDrawing())
    }

    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        enter(sender: UIButton())
        return true
    }
    
    func nextTerm(){
        TextField.text = ""
        
        CardLabel.isHidden = true
        CardDrawing.isHidden = true
        CardImage.isHidden = true
        TextField.isHidden = true
        DrawingView.isHidden = true
        if(index == cardOrder.count){
            TextField.resignFirstResponder()
            EndScreen.isHidden = false
            enterButton.isHidden = true
            var Unknown = 0
            var Known = 0
            var Mastered = 0
            for i in known {
                if(i == 0){
                    Unknown+=1
                }else if(i == 1){
                    Known+=1
                }else{
                    Mastered+=1
                }
            }
            EndLabel.text = "Unknown terms: " + String(Unknown) + "\nKnown terms: " + String(Known) + "\nMastered terms: " + String(Mastered)
        }else{
            cardCounter.text = String(index + 1) + "/" + String(cardOrder.count)
            
            if(cards[cardOrder[index]]["termType"] as! String == "t"){
                CardLabel.isHidden = false
                CardLabel.text = cards[cardOrder[index]]["term"] as? String
            }else if(cards[cardOrder[index]]["termType"] as! String == "d"){
                CardDrawing.isHidden = false
                
                loadDrawing(url: cards[cardOrder[index]]["term"] as? String, canvas: self.CardDrawing)
                
            }else{
                CardImage.isHidden = false
                loadImage(url: self.cards[self.cardOrder[self.index]]["term"] as? String, imageView: self.CardImage)
            }
            
            currentInput = cards[cardOrder[index]]["defType"] as! String
            reformat()
        }
    }
    
    @objc func BackButton(sender: UIButton){
        performSegue(withIdentifier: "standardLearnVC_unwind", sender: nil)
    }
    
    func save() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userRef = db.collection("users").document(uid)
        
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                var oldUser = document.data()!
                var oldStudied = oldUser["studiedSets"] as! [[String: Any]]
                var t = false
                for (i, set) in oldStudied.enumerated() {
                    if set["setID"] as! String == self.set {
                        oldStudied[i]["learn"] = self.known
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
                
//                if(!t){
//                    oldStudied.append([
//                        "setID": self.set
//                        "learn": self.known
//                        "flashcards":
//                    ])
//                }
                
                oldUser["studiedSets"] = oldStudied
                
                userRef.setData(oldUser, merge: true) { error in
                    if let error = error {
                        print("Error updating document: \(error)")
                    } else {
                        print("Document successfully updated")
                    }
                }
            } else {
                print("Document does not exist")
            }
        }
    }

    
    @objc func SettingsButton(sender: UIButton){
        
    }
    
    func reformat(){
        if(currentInput == "t"){
            TextField.isHidden = false
            topHeight = view.frame.height - 90
        }else if(currentInput == "d" || currentInput == "d-r"){
            TextField.resignFirstResponder()
            DrawingView.isHidden = false
            topHeight = view.frame.height - 290
        }
        UIView.animate(withDuration: 0.5, animations: {
            self.CardLabel.frame = CGRect(x: 20, y: 0, width: self.view.frame.width - 40, height: self.topHeight-self.keyboard)
            self.CardDrawing.frame = CGRect(x: 0, y: 0, width: (self.view.frame.width - 161), height: 2*(self.view.frame.width - 161)/3)
            self.CardImage.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.topHeight-self.keyboard)
            self.TextField.frame = CGRect(x: 50, y: self.topHeight-self.keyboard + 20, width: self.view.frame.width - 100, height: 50)
            self.DrawingView.frame = CGRect(x: 50, y: self.topHeight-self.keyboard + 20, width: self.view.frame.width - 100, height: 250)
            self.enterButton.frame = CGRect(x: self.view.frame.width - 100, y: self.topHeight-self.keyboard + 20, width: 50, height: 50)
            self.CardDrawing.center = CGPoint(x: self.view.frame.width/2, y: (self.topHeight-self.keyboard)/2)
            self.incorrectButton.frame = CGRect(x: (self.view.frame.width/2) - 60, y: self.topHeight - self.keyboard + 20 - 70, width: 50, height: 50)
            self.correctButton.frame = CGRect(x: (self.view.frame.width/2) + 10, y: self.topHeight - self.keyboard + 20 - 70, width: 50, height: 50)
        })
    }
    
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        guard canvasView == DrawingView, currentInput == "d-r" else {
            return
        }
        
        mostRecentProcess += 1
        let thisProcess = mostRecentProcess
        processing = true
        
        DispatchQueue.main.async {
            UIGraphicsBeginImageContextWithOptions(self.DrawingView.bounds.size, false, UIScreen.main.scale)
            self.DrawingView.drawHierarchy(in: self.DrawingView.bounds, afterScreenUpdates: true)
            let image = UIGraphicsGetImageFromCurrentImageContext()?.cgImage
            UIGraphicsEndImageContext()
            
            guard let cgImage = image else {
                self.processing = false
                return
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                let requestHandler = VNImageRequestHandler(cgImage: cgImage)
                let request = VNRecognizeTextRequest { [weak self] (request, error) in
                    guard let self = self else { return }
                    self.handleTextRecognitionResult(request, forProcess: thisProcess)
                }
                
                do {
                    try requestHandler.perform([request])
                } catch {
                    print("Error performing text recognition: \(error)")
                    self.processing = false
                }
            }
        }
    }

    private func handleTextRecognitionResult(_ request: VNRequest, forProcess process: Int) {
        guard let observations = request.results as? [VNRecognizedTextObservation], mostRecentProcess == process else {
            return
        }
        
        var processedText = ""
        for observation in observations {
            if let bestCandidate = observation.topCandidates(1).first {
                processedText += bestCandidate.string.filter { !$0.isWhitespace }.lowercased()
            }
        }
        
        DispatchQueue.main.async {
            self.recognizedText = processedText
            self.processing = false
            
            if self.waitingOnResult {
                self.processRecognitionResult()
            }
        }
    }


    
    @IBAction func cancel (_ unwindSegue: UIStoryboardSegue){
    }
}

extension StandardLearnVC {
    
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
