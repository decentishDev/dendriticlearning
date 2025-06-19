//
//  StandardEditorVC.swift
//  StudyApp
//
//  Created by Matthew Lundeen on 5/9/24.
//

import UIKit
import PencilKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class StandardEditorVC: UIViewController, UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, DrawingEditorDelegate {
    
    let defaults = UserDefaults.standard
    
    let scrollView = UIScrollView()
    let stackView = UIStackView()
    let allTermsStackView = UIStackView()
    
    var set = "" // passed through mainpage
    var cards: [[String: Any?]] = [] //t: text, d: drawing, s: speech - maybe
    var name: String = ""
    var date: String = ""
    var image: String? = ""
    var isPaid = false
//    var flashcards: [Bool] = []
//    var learn: [Int] = []
    
    var currentImagePicker = -1
    
    let imagePicker = UIImagePickerController()
    let imageButton = UIButton()
    
    var keyboardHeight = 0
    
    var defaultTerm = "t"
    var defaultDefinition = "t"
    
    var indexes: [Int] = []
    
    let db = Firestore.firestore()
    let storage = Storage.storage()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let data = defaults.value(forKey: "set") as! [String: Any]
        name = data["name"] as! String
        //date = data["date"] as! String
        cards = data["set"] as! [[String: Any?]]
        image = data["image"] as! String?
        isPaid = defaults.value(forKey: "isPaid") as! Bool
//        flashcards = data["flashcards"] as! [Bool]
//        learn = data["learn"] as! [Int]
        view.backgroundColor = Colors.background
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(dismissIt(_:)))
        view.addGestureRecognizer(gesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        setup()
    }

deinit {
        // Unregister from keyboard notifications
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // Step 1: Create a function to fetch data
    func setup(){

            for subview in stackView.arrangedSubviews {

                subview.removeFromSuperview()
            }
            for subview in allTermsStackView.arrangedSubviews {

                subview.removeFromSuperview()
            }
            stackView.removeFromSuperview()
            for subview in view.subviews {
                subview.removeFromSuperview()
            }
            stackView.axis = .vertical
            stackView.spacing = 10
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
            
            let topBar = UIView()
            topBar.widthAnchor.constraint(equalToConstant: 530).isActive = true
            topBar.heightAnchor.constraint(equalToConstant: 50).isActive = true
        tAMC(topBar)
            stackView.addArrangedSubview(topBar)
            
            let backButton = UIButton()
            backButton.setImage(UIImage(systemName: "arrowshape.backward.fill"), for: .normal)
            backButton.addTarget(self, action: #selector(back(_:)), for: .touchUpInside)
            backButton.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
            backButton.backgroundColor = Colors.secondaryBackground
            backButton.layer.cornerRadius = 10
            backButton.tintColor = Colors.highlight
            
            topBar.addSubview(backButton)
            
            let titleField = UITextField()
            titleField.delegate = self
            titleField.text = name
            titleField.placeholder = "Set name"
            titleField.frame = CGRect(x: 60, y: 0, width: 350, height: 50)
            titleField.font = UIFont(name: "LilGrotesk-Bold", size: 25)
            titleField.textColor = Colors.highlight
            titleField.backgroundColor = Colors.secondaryBackground
            titleField.layer.cornerRadius = 10
            let paddingView = UIView(frame: CGRectMake(0, 0, 15, titleField.frame.height))
            titleField.leftView = paddingView
            titleField.leftViewMode = .always
            
            topBar.addSubview(titleField)
            
            if(image == ""){
                imageButton.setImage(UIImage(systemName: "photo"), for: .normal)
            }else{
                imageButton.setImage(UIImage(systemName: "rectangle.badge.xmark.fill"), for: .normal)
            }
            imageButton.addTarget(self, action: #selector(changeImage(_:)), for: .touchUpInside)
            imageButton.frame = CGRect(x: 420, y: 0, width: 50, height: 50)
            imageButton.backgroundColor = Colors.secondaryBackground
            imageButton.layer.cornerRadius = 10
            imageButton.tintColor = Colors.highlight
            
            topBar.addSubview(imageButton)
            
            let deleteButton = UIButton()
            deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
            deleteButton.addTarget(self, action: #selector(deleteSet(_:)), for: .touchUpInside)
            deleteButton.frame = CGRect(x: 480, y: 0, width: 50, height: 50)
            deleteButton.backgroundColor = Colors.secondaryBackground
            deleteButton.layer.cornerRadius = 10
            deleteButton.tintColor = Colors.highlight
            
            topBar.addSubview(deleteButton)
            
        addBreakView(stackView, 30)
            
            allTermsStackView.axis = .vertical
            allTermsStackView.spacing = 10
        tAMC(allTermsStackView)
            stackView.addArrangedSubview(allTermsStackView)
            NSLayoutConstraint.activate([
                allTermsStackView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
                allTermsStackView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
            ])
            for (i, card) in cards.enumerated(){
                indexes.append(i)
                let termDefinitionStackView = UIStackView()
                tAMC(termDefinitionStackView)
                let term = card["term"] as? String
                let definition = card["def"] as? String
                if(card["termType"] as! String == "t"){
                    let termView = UITextView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
                    termView.isEditable = true
                    termView.text = term
                    termView.font = UIFont(name: "LilGrotesk-Regular", size: 20)
                    termView.delegate = self
                    tAMC(termView)
                    termView.isScrollEnabled = false
                    termView.backgroundColor = .clear
                    termView.accessibilityIdentifier = "t" + String(i)
                    termView.widthAnchor.constraint(equalToConstant: (view.frame.width - 141)/2).isActive = true
                    termView.textColor = Colors.text
                    termDefinitionStackView.addArrangedSubview(termView)

                }else if(card["termType"] as! String == "i"){
                    let termImage = UIButton(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
                    tAMC(termImage)

                    termImage.widthAnchor.constraint(equalToConstant: (view.frame.width - 141)/2).isActive = true
                    termImage.heightAnchor.constraint(equalToConstant: (view.frame.width - 141)/3).isActive = true
                    termImage.imageView?.contentMode = .scaleAspectFit
                    termImage.contentMode = .scaleAspectFit
                    termImage.layer.cornerRadius = 10
                    termImage.accessibilityIdentifier = String(i)
                    termImage.addTarget(self, action: #selector(changeTermImage(_:)), for: .touchUpInside)
                    loadButtonImage(url: card["term"] as? String, imageView: termImage)
                    termImage.accessibilityIdentifier = String(i)
                    termDefinitionStackView.addArrangedSubview(termImage)

                }else{
                    let drawingButton = UIButton(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
                    
                    drawingButton.widthAnchor.constraint(equalToConstant: (view.frame.width - 141)/2).isActive = true
                    drawingButton.heightAnchor.constraint(equalToConstant: (view.frame.width - 141)/3).isActive = true
                    drawingButton.addTarget(self, action: #selector(editDrawing(_:)), for: .touchUpInside)
                    drawingButton.accessibilityIdentifier = "t" + String(i)
                    let termDrawing = PKCanvasView(frame: CGRect(x: 0, y: 0, width: view.frame.width - 141, height: 2*(view.frame.width - 141)/3))
                    termDrawing.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                    termDrawing.tool = Colors.pen
                    termDrawing.overrideUserInterfaceStyle = .light
                    termDrawing.backgroundColor = .clear
                    termDrawing.layer.cornerRadius = 10

                    termDrawing.isUserInteractionEnabled = false
                    loadDrawing(url: card["term"] as? String, canvas: termDrawing)
                    tAMC([drawingButton, termDrawing])

                    drawingButton.insertSubview(termDrawing, at: 0)
                    termDrawing.anchorPoint = CGPoint(x: 1, y: 1)
                    

                    
                    termDefinitionStackView.addArrangedSubview(drawingButton)

                }
                
                let breakView = UIView()
                breakView.widthAnchor.constraint(equalToConstant: 1).isActive = true
                tAMC(breakView)
                breakView.backgroundColor = Colors.text.withAlphaComponent(0.5)
                termDefinitionStackView.addArrangedSubview(breakView)
                
                if(card["defType"] as! String == "t" || card["defType"] as! String == "d-r"){
                    let definitionView = UITextView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
                    definitionView.isEditable = true
                    definitionView.text = definition
                    definitionView.font = UIFont(name: "LilGrotesk-Regular", size: 20)
                    definitionView.delegate = self
                    tAMC(definitionView)
                    definitionView.isScrollEnabled = false
                    definitionView.backgroundColor = .clear
                    definitionView.accessibilityIdentifier = "d" + String(i)
                    definitionView.textColor = Colors.text
                    termDefinitionStackView.addArrangedSubview(definitionView)

                }else if card["defType"] as! String == "d"{
                    let drawingButton = UIButton(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
                    drawingButton.heightAnchor.constraint(equalToConstant: (view.frame.width - 141)/3).isActive = true
                    drawingButton.addTarget(self, action: #selector(editDrawing(_:)), for: .touchUpInside)
                    
                    drawingButton.accessibilityIdentifier = "d" + String(i)
                    let definitionDrawing = PKCanvasView(frame: CGRect(x: 0, y: 0, width: view.frame.width - 141, height: 2*(view.frame.width - 141)/3))
                    definitionDrawing.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                    definitionDrawing.layer.cornerRadius = 10

                    definitionDrawing.isUserInteractionEnabled = false
                    definitionDrawing.tool = Colors.pen
                    definitionDrawing.overrideUserInterfaceStyle = .light
                    loadDrawing(url: card["def"] as? String, canvas: definitionDrawing)
                    tAMC([drawingButton, definitionDrawing])

                    drawingButton.insertSubview(definitionDrawing, at: 0)

                    definitionDrawing.anchorPoint = CGPoint(x: 1, y: 1)
                    definitionDrawing.backgroundColor = .clear
                    
                    termDefinitionStackView.addArrangedSubview(drawingButton)
                }
                
                tAMC(termDefinitionStackView)
                termDefinitionStackView.isLayoutMarginsRelativeArrangement = true
                termDefinitionStackView.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
                termDefinitionStackView.axis = .horizontal
                termDefinitionStackView.spacing = 10
                termDefinitionStackView.backgroundColor = Colors.secondaryBackground
                termDefinitionStackView.layer.cornerRadius = 10
                
                let buttonsView = UIView()
                tAMC(buttonsView)
                con(buttonsView, view.frame.width - 100, 30)
                let button1 = UIButton()
                button1.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
                button1.setImage(UIImage(systemName: "text.alignleft"), for: .normal)
                if(cards[i]["termType"] as! String == "t"){
                    button1.tintColor = Colors.highlight
                }else{
                    button1.tintColor = Colors.darkHighlight
                }
                button1.addTarget(self, action: #selector(changeInput(_:)), for: .touchUpInside)
                button1.accessibilityIdentifier = "1" + String(i)
                let button2 = UIButton()
                let button3 = UIButton()
                if(isPaid){
                    button2.frame = CGRect(x: 30, y: 0, width: 30, height: 30)
                    button2.setImage(UIImage(systemName: "photo"), for: .normal)
                        if(cards[i]["termType"] as! String == "i"){
                        button2.tintColor = Colors.highlight
                    }else{
                        button2.tintColor = Colors.darkHighlight
                    }
                    button2.addTarget(self, action: #selector(changeInput(_:)), for: .touchUpInside)
                    button2.accessibilityIdentifier = "2" + String(i)
                    button3.frame = CGRect(x: 60, y: 0, width: 30, height: 30)
                }else{
                    con(button2, 0, 0)
                    button2.isEnabled = false
                    button3.frame = CGRect(x: 30, y: 0, width: 30, height: 30)
                }
                
                
                button3.setImage(UIImage(systemName: "pencil.and.scribble"), for: .normal)
                if(cards[i]["termType"] as! String == "d"){
                    button3.tintColor = Colors.highlight
                }else{
                    button3.tintColor = Colors.darkHighlight
                }
                button3.addTarget(self, action: #selector(changeInput(_:)), for: .touchUpInside)
                button3.accessibilityIdentifier = "3" + String(i)
                let button4 = UIButton()
                button4.frame = CGRect(x: ((view.frame.width - 100) / 2), y: 0, width: 30, height: 30)
                button4.setImage(UIImage(systemName: "text.alignleft"), for: .normal)
                
                button4.addTarget(self, action: #selector(changeInput(_:)), for: .touchUpInside)
                button4.accessibilityIdentifier = "4" + String(i)
                let button6 = UIButton()
                button6.frame = CGRect(x: ((view.frame.width - 100) / 2) + 30, y: 0, width: 30, height: 30)
                button6.setImage(UIImage(systemName: "pencil.and.scribble"), for: .normal)
                if(cards[i]["defType"] as! String == "d"){
                    button6.tintColor = Colors.highlight
                }else{
                    button6.tintColor = Colors.darkHighlight
                }
                button6.addTarget(self, action: #selector(changeInput(_:)), for: .touchUpInside)
                button6.accessibilityIdentifier = "5" + String(i)
                let recognize = UILabel(frame: CGRect(x: ((view.frame.width - 100) / 2) + 60, y: 0, width: 100, height: 30))
                recognize.text = "Recognize:"
                recognize.textAlignment = .right
                recognize.font = UIFont(name: "LilGrotesk-Regular", size: 15)
                recognize.textColor = Colors.text
                let button7 = UIButton()
                button7.frame = CGRect(x: ((view.frame.width - 100) / 2) + 160, y: 0, width: 30, height: 30)
                
                button7.tintColor = Colors.highlight
                button7.addTarget(self, action: #selector(changeInput(_:)), for: .touchUpInside)
                button7.accessibilityIdentifier = "6" + String(i)
                
                let deleteButton = UIButton()
                deleteButton.frame = CGRect(x: view.frame.width - 130, y: 0, width: 30, height: 30)
                deleteButton.tintColor = .init(red: 0.6, green: 0.3, blue: 0.3, alpha: 1)
                deleteButton.addTarget(self, action: #selector(deleteTerm(_:)), for: .touchUpInside)
                deleteButton.accessibilityIdentifier = String(i)
                deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
                
                if(cards[i]["defType"] as! String == "t"){
                    button4.tintColor = Colors.highlight
                    button7.setImage(UIImage(systemName: "circle"), for: .normal)
                }else if(cards[i]["defType"] as! String == "d-r"){
                    button4.tintColor = Colors.highlight
                    button7.setImage(UIImage(systemName: "circle.fill"), for: .normal)
                }else{
                    button4.tintColor = Colors.darkHighlight
                    recognize.isHidden = true
                    button7.isHidden = true
                    button7.setImage(UIImage(systemName: "circle"), for: .normal)
                    
                }
                
                buttonsView.addSubview(button1)
                buttonsView.addSubview(button2)
                buttonsView.addSubview(button3)
                buttonsView.addSubview(button4)
                buttonsView.addSubview(button6)
                buttonsView.addSubview(recognize)
                buttonsView.addSubview(button7)
                buttonsView.addSubview(deleteButton)
                
                let cardAndButtons = UIStackView()
                tAMC(cardAndButtons)
                cardAndButtons.axis = .vertical
                cardAndButtons.spacing = 0
                cardAndButtons.addArrangedSubview(termDefinitionStackView)
                cardAndButtons.addArrangedSubview(buttonsView)
                
                allTermsStackView.addArrangedSubview(cardAndButtons)
            }
            
            let newTerm = UIButton()
            newTerm.backgroundColor = Colors.secondaryBackground
            newTerm.layer.cornerRadius = 10
            newTerm.setImage(UIImage(systemName: "plus"), for: .normal)
            newTerm.imageView?.tintColor = Colors.highlight
            newTerm.imageView?.contentMode = .scaleAspectFit
            newTerm.addTarget(self, action: #selector(addTerm(_:)), for: .touchUpInside)
            con(newTerm, view.frame.width - 100, 60)
            stackView.addArrangedSubview(newTerm)
            
            let buttonsView = UIView()
        tAMC(buttonsView)
            con(buttonsView, view.frame.width - 100, 30)
            let button1 = UIButton()
            button1.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            button1.setImage(UIImage(systemName: "text.alignleft"), for: .normal)
            button1.tintColor = Colors.highlight
            button1.addTarget(self, action: #selector(changeDefaultInput(_:)), for: .touchUpInside)
            button1.accessibilityIdentifier = "1" + String(cards.count)
            let button2 = UIButton()
            let button3 = UIButton()
            if isPaid {
                button2.frame = CGRect(x: 30, y: 0, width: 30, height: 30)
                button2.setImage(UIImage(systemName: "photo"), for: .normal)
                button2.tintColor = Colors.darkHighlight
                button2.addTarget(self, action: #selector(changeDefaultInput(_:)), for: .touchUpInside)
                button2.accessibilityIdentifier = "2" + String(cards.count)
                button3.frame = CGRect(x: 60, y: 0, width: 30, height: 30)
            }else{
                con(button2, 0, 0)
                button2.isEnabled = false
                button3.frame = CGRect(x: 30, y: 0, width: 30, height: 30)
            }
            button3.setImage(UIImage(systemName: "pencil.and.scribble"), for: .normal)
            button3.tintColor = Colors.darkHighlight

            button3.addTarget(self, action: #selector(changeDefaultInput(_:)), for: .touchUpInside)
            button3.accessibilityIdentifier = "3" + String(cards.count)
            let button4 = UIButton()
            button4.frame = CGRect(x: ((view.frame.width - 100) / 2), y: 0, width: 30, height: 30)
            button4.setImage(UIImage(systemName: "text.alignleft"), for: .normal)
            
            button4.addTarget(self, action: #selector(changeDefaultInput(_:)), for: .touchUpInside)
            button4.accessibilityIdentifier = "4" + String(cards.count)
            let button6 = UIButton()
            button6.frame = CGRect(x: ((view.frame.width - 100) / 2) + 30, y: 0, width: 30, height: 30)
            button6.setImage(UIImage(systemName: "pencil.and.scribble"), for: .normal)
            button6.tintColor = Colors.darkHighlight
            button6.addTarget(self, action: #selector(changeDefaultInput(_:)), for: .touchUpInside)
            button6.accessibilityIdentifier = "5" + String(cards.count)
            let recognize = UILabel(frame: CGRect(x: ((view.frame.width - 100) / 2) + 60, y: 0, width: 100, height: 30))
            recognize.text = "Recognize:"
            recognize.textAlignment = .right
            recognize.textColor = Colors.text
            recognize.font = UIFont(name: "LilGrotesk-Regular", size: 15)
            let button7 = UIButton()
            button7.frame = CGRect(x: ((view.frame.width - 100) / 2) + 160, y: 0, width: 30, height: 30)
            
            button7.tintColor = Colors.highlight
            button7.addTarget(self, action: #selector(changeDefaultInput(_:)), for: .touchUpInside)
            button7.accessibilityIdentifier = "6" + String(cards.count)

            button4.tintColor = Colors.highlight
            button7.setImage(UIImage(systemName: "circle"), for: .normal)
            
            buttonsView.addSubview(button1)
            buttonsView.addSubview(button2)
            buttonsView.addSubview(button3)
            buttonsView.addSubview(button4)
            buttonsView.addSubview(button6)
            buttonsView.addSubview(recognize)
            buttonsView.addSubview(button7)
            
            stackView.addArrangedSubview(buttonsView)
        }

    
    @objc func addTerm(_ sender: UIButton){
        let termDefinitionStackView = UIStackView()
        tAMC(termDefinitionStackView)
        var term : Any? = ""
        var definition : Any? = ""
        if(defaultTerm == "t"){
            let termView = UITextView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            termView.isEditable = true
            termView.text = term as? String
            termView.font = UIFont(name: "LilGrotesk-Regular", size: 20)
            termView.delegate = self
            tAMC(termView)
            termView.isScrollEnabled = false
            termView.backgroundColor = .clear
            termView.accessibilityIdentifier = "t" + String(cards.count)
            termView.widthAnchor.constraint(equalToConstant: (view.frame.width - 141)/2).isActive = true
            termView.textColor = Colors.text
            termDefinitionStackView.addArrangedSubview(termView)
            //termView.backgroundColor = .green
        }else if(defaultTerm == "i"){
            term = UIImage(named: "color1.png")!.pngData()!
            let termImage = UIButton(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            tAMC(termImage)
            //termImage.setImage(UIImage(named: "color1.png"), for: .normal)
            termImage.widthAnchor.constraint(equalToConstant: (view.frame.width - 141)/2).isActive = true
            termImage.heightAnchor.constraint(equalToConstant: (view.frame.width - 141)/3).isActive = true
            termImage.imageView?.contentMode = .scaleAspectFit
            termImage.contentMode = .scaleAspectFit
            termImage.layer.cornerRadius = 10
            termImage.accessibilityIdentifier = String(cards.count)
            termImage.addTarget(self, action: #selector(changeTermImage(_:)), for: .touchUpInside)
            termImage.setImage(UIImage(named: "DendriticLearning_icon_1024x1024_v2-2.png"), for: .normal)
            termDefinitionStackView.addArrangedSubview(termImage)
            //termImage.backgroundColor = .blue
        }else{
            term = ""
            let drawingButton = UIButton(frame: CGRect(x: 0, y: 0, width: 1, height: 1))

            drawingButton.widthAnchor.constraint(equalToConstant: (view.frame.width - 141)/2).isActive = true
            drawingButton.heightAnchor.constraint(equalToConstant: (view.frame.width - 141)/3).isActive = true
            drawingButton.addTarget(self, action: #selector(editDrawing(_:)), for: .touchUpInside)
            drawingButton.accessibilityIdentifier = "t" + String(cards.count)
            let termDrawing = PKCanvasView(frame: CGRect(x: 0, y: 0, width: view.frame.width - 141, height: 2*(view.frame.width - 141)/3))
            termDrawing.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            termDrawing.tool = Colors.pen
            termDrawing.overrideUserInterfaceStyle = .light
            termDrawing.backgroundColor = .clear
            termDrawing.layer.cornerRadius = 10
            //definitionDrawing.widthAnchor.constraint(equalTo: definitionView.widthAnchor).isActive = true
            //definitionDrawing.heightAnchor.constraint(equalToConstant: (view.frame.width - 141)/3).isActive = true
            termDrawing.isUserInteractionEnabled = false
            termDrawing.drawing = recolor(PKDrawing())
            tAMC([drawingButton, termDrawing])
            //definitionDrawing.backgroundColor = .red
            drawingButton.insertSubview(termDrawing, at: 0)
            termDrawing.anchorPoint = CGPoint(x: 1, y: 1)
            
//                termDrawing.leadingAnchor.constraint(equalTo: drawingButton.leadingAnchor).isActive = true
//                termDrawing.trailingAnchor.constraint(equalTo: drawingButton.trailingAnchor).isActive = true
//                termDrawing.topAnchor.constraint(equalTo: drawingButton.topAnchor).isActive = true
//                termDrawing.bottomAnchor.constraint(equalTo: drawingButton.bottomAnchor).isActive = true
            
            termDefinitionStackView.addArrangedSubview(drawingButton)
            
            //centerDrawing(termDrawing)
        }
        
        let breakView = UIView()
        breakView.widthAnchor.constraint(equalToConstant: 1).isActive = true
        tAMC(breakView)
        breakView.backgroundColor = Colors.text.withAlphaComponent(0.5)
        termDefinitionStackView.addArrangedSubview(breakView)
        //breakView.heightAnchor.constraint(equalTo: termDefinitionStackView.heightAnchor, multiplier: 0.5).isActive = true
        
        if(defaultDefinition == "t" || defaultDefinition == "d-r"){
            let definitionView = UITextView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            definitionView.isEditable = true
            definitionView.text = definition as? String
            definitionView.font = UIFont(name: "LilGrotesk-Regular", size: 20)
            definitionView.delegate = self
            tAMC(definitionView)
            definitionView.isScrollEnabled = false
            definitionView.backgroundColor = .clear
            definitionView.accessibilityIdentifier = "d" + String(cards.count)
            definitionView.textColor = Colors.text
            termDefinitionStackView.addArrangedSubview(definitionView)
            //definitionView.backgroundColor = .blue
        }else if defaultDefinition == "d"{
            definition = ""
            let drawingButton = UIButton(frame: CGRect(x: 0, y: 0, width: 1, height: 1))

            drawingButton.heightAnchor.constraint(equalToConstant: (view.frame.width - 141)/3).isActive = true
            drawingButton.addTarget(self, action: #selector(editDrawing(_:)), for: .touchUpInside)
            
            drawingButton.accessibilityIdentifier = "d" + String(cards.count)
            let definitionDrawing = PKCanvasView(frame: CGRect(x: 0, y: 0, width: view.frame.width - 141, height: 2*(view.frame.width - 141)/3))
            definitionDrawing.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            definitionDrawing.layer.cornerRadius = 10
            //definitionDrawing.widthAnchor.constraint(equalTo: definitionView.widthAnchor).isActive = true
            //definitionDrawing.heightAnchor.constraint(equalToConstant: (view.frame.width - 141)/3).isActive = true
            definitionDrawing.isUserInteractionEnabled = false
            definitionDrawing.tool = Colors.pen
            definitionDrawing.overrideUserInterfaceStyle = .light
            definitionDrawing.drawing = recolor(PKDrawing())
            tAMC([drawingButton, definitionDrawing])
            //definitionDrawing.backgroundColor = .red
            drawingButton.insertSubview(definitionDrawing, at: 0)
//                definitionDrawing.leadingAnchor.constraint(equalTo: drawingButton.leadingAnchor).isActive = true
//                definitionDrawing.trailingAnchor.constraint(equalTo: drawingButton.trailingAnchor).isActive = true
//                definitionDrawing.topAnchor.constraint(equalTo: drawingButton.topAnchor).isActive = true
//                definitionDrawing.bottomAnchor.constraint(equalTo: drawingButton.bottomAnchor).isActive = true
            definitionDrawing.anchorPoint = CGPoint(x: 1, y: 1)
            definitionDrawing.backgroundColor = .clear
            
            termDefinitionStackView.addArrangedSubview(drawingButton)
            
            //centerDrawing(definitionDrawing)
            
        }
        
        tAMC(termDefinitionStackView)
        termDefinitionStackView.isLayoutMarginsRelativeArrangement = true
        termDefinitionStackView.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        termDefinitionStackView.axis = .horizontal
        termDefinitionStackView.spacing = 10
        termDefinitionStackView.backgroundColor = Colors.secondaryBackground
        termDefinitionStackView.layer.cornerRadius = 10
        
        cards.append([
            "termType": defaultTerm,
            "term": term,
            "defType": defaultDefinition,
            "def": definition
        ])
        save()
        
        let i = indexes[cards.count - 2] + 1
        indexes.append(i)
        
        let buttonsView = UIView()
        tAMC(buttonsView)
        con(buttonsView, view.frame.width - 100, 30)
        let button1 = UIButton()
        button1.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        button1.setImage(UIImage(systemName: "text.alignleft"), for: .normal)
        if(cards[i]["termType"] as! String == "t"){
            button1.tintColor = Colors.highlight
        }else{
            button1.tintColor = Colors.darkHighlight
        }
        button1.addTarget(self, action: #selector(changeInput(_:)), for: .touchUpInside)
        button1.accessibilityIdentifier = "1" + String(i)
        let button2 = UIButton()
        if isPaid {
            button2.frame = CGRect(x: 30, y: 0, width: 30, height: 30)
            button2.setImage(UIImage(systemName: "photo"), for: .normal)
            if(cards[i]["termType"] as! String == "i"){
                button2.tintColor = Colors.highlight
            }else{
                button2.tintColor = Colors.darkHighlight
            }
            button2.addTarget(self, action: #selector(changeInput(_:)), for: .touchUpInside)
            button2.accessibilityIdentifier = "2" + String(i)
        }else{
            con(button2, 0, 0)
            button2.isEnabled = false
        }
        let button3 = UIButton()
        button3.frame = CGRect(x: 60, y: 0, width: 30, height: 30)
        button3.setImage(UIImage(systemName: "pencil.and.scribble"), for: .normal)
        if(cards[i]["termType"] as! String == "d"){
            button3.tintColor = Colors.highlight
        }else{
            button3.tintColor = Colors.darkHighlight
        }
        button3.addTarget(self, action: #selector(changeInput(_:)), for: .touchUpInside)
        button3.accessibilityIdentifier = "3" + String(i)
        let button4 = UIButton()
        button4.frame = CGRect(x: ((view.frame.width - 100) / 2), y: 0, width: 30, height: 30)
        button4.setImage(UIImage(systemName: "text.alignleft"), for: .normal)
        
        button4.addTarget(self, action: #selector(changeInput(_:)), for: .touchUpInside)
        button4.accessibilityIdentifier = "4" + String(i)
//            let button5 = UIButton()
//            button5.frame = CGRect(x: ((view.frame.width - 100) / 2) + 30, y: 0, width: 30, height: 30)
//            button5.setImage(UIImage(systemName: "photo"), for: .normal)
//            button5.tintColor = Colors.darkHighlight
//            button5.addTarget(self, action: #selector(changeInput(_:)), for: .touchUpInside)
//            button5.accessibilityIdentifier = "5" + String(i)
        let button6 = UIButton()
        button6.frame = CGRect(x: ((view.frame.width - 100) / 2) + 30, y: 0, width: 30, height: 30)
        button6.setImage(UIImage(systemName: "pencil.and.scribble"), for: .normal)
        if(cards[i]["defType"] as! String == "d"){
            button6.tintColor = Colors.highlight
        }else{
            button6.tintColor = Colors.darkHighlight
        }
        button6.addTarget(self, action: #selector(changeInput(_:)), for: .touchUpInside)
        button6.accessibilityIdentifier = "5" + String(i)
        let recognize = UILabel(frame: CGRect(x: ((view.frame.width - 100) / 2) + 60, y: 0, width: 100, height: 30))
        recognize.text = "Recognize:"
        recognize.textAlignment = .right
        recognize.textColor = Colors.text
        recognize.font = UIFont(name: "LilGrotesk-Regular", size: 15)
        let button7 = UIButton()
        button7.frame = CGRect(x: ((view.frame.width - 100) / 2) + 160, y: 0, width: 30, height: 30)
        
        button7.tintColor = Colors.highlight
        button7.addTarget(self, action: #selector(changeInput(_:)), for: .touchUpInside)
        button7.accessibilityIdentifier = "6" + String(i)
        
        let deleteButton = UIButton()
        deleteButton.frame = CGRect(x: view.frame.width - 130, y: 0, width: 30, height: 30)
        deleteButton.tintColor = .init(red: 0.6, green: 0.3, blue: 0.3, alpha: 1)
        deleteButton.addTarget(self, action: #selector(deleteTerm(_:)), for: .touchUpInside)
        deleteButton.accessibilityIdentifier = String(i)
        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
        
        if(cards[i]["defType"] as! String == "t"){
            button4.tintColor = Colors.highlight
            button7.setImage(UIImage(systemName: "circle"), for: .normal)
        }else if(cards[i]["defType"] as! String == "d-r"){
            button4.tintColor = Colors.highlight
            button7.setImage(UIImage(systemName: "circle.fill"), for: .normal)
        }else{
            button4.tintColor = Colors.darkHighlight
            recognize.isHidden = true
            button7.isHidden = true
            button7.setImage(UIImage(systemName: "circle"), for: .normal)
            
        }
        
        buttonsView.addSubview(button1)
        buttonsView.addSubview(button2)
        buttonsView.addSubview(button3)
        buttonsView.addSubview(button4)
        //buttonsView.addSubview(button5)
        buttonsView.addSubview(button6)
        buttonsView.addSubview(recognize)
        buttonsView.addSubview(button7)
        buttonsView.addSubview(deleteButton)
        
        let cardAndButtons = UIStackView()
        tAMC(cardAndButtons)
        cardAndButtons.axis = .vertical
        cardAndButtons.spacing = 0
        cardAndButtons.addArrangedSubview(termDefinitionStackView)
        cardAndButtons.addArrangedSubview(buttonsView)
        
        allTermsStackView.addArrangedSubview(cardAndButtons)
    }
    @objc func dismissIt(_ sender: UITapGestureRecognizer){
        save()
        view.endEditing(true)
    }
    @objc func changeInput(_ sender: UIButton){
        let i = indexes.firstIndex(of: Int(sender.accessibilityIdentifier!.dropFirst())!)!
        switch sender.accessibilityIdentifier!.first.map(String.init) {
        case "1":
            if cards[i]["termType"] as! String != "t" {
                let media = cards[i]["term"] as! String
                if(media != ""){
                    self.defaults.removeObject(forKey: media)
                    let mediaRef = storage.reference().child(Auth.auth().currentUser!.uid).child(media)
                    mediaRef.delete(){ error in
                        if let error = error{
                            print("Error deleting media: \(error.localizedDescription)")
                        }
                    }
                }
                
                sender.tintColor = Colors.highlight
                sender.superview!.subviews[1].tintColor = Colors.darkHighlight
                sender.superview!.subviews[2].tintColor = Colors.darkHighlight
                cards[i]["termType"] = "t"
                cards[i]["term"] = ""
                let termView = UITextView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
                termView.isEditable = true
                termView.text = ""
                termView.font = UIFont(name: "LilGrotesk-Regular", size: 20)
                termView.delegate = self
                tAMC(termView)
                termView.isScrollEnabled = false
                termView.backgroundColor = .clear
                termView.textColor = Colors.text
                termView.accessibilityIdentifier = "t" + String(i)
                termView.widthAnchor.constraint(equalToConstant: (view.frame.width - 141)/2).isActive = true
                //termView.backgroundColor = .green
                ((sender.superview!.superview! as! UIStackView).arrangedSubviews[0] as! UIStackView).arrangedSubviews[0].removeFromSuperview()
//                let original = ((sender.superview!.superview! as! UIStackView).arrangedSubviews[0] as! UIStackView).arrangedSubviews[0]
//                ((sender.superview!.superview! as! UIStackView).arrangedSubviews[0] as! UIStackView).removeArrangedSubview(original)
                ((sender.superview!.superview! as! UIStackView).arrangedSubviews[0] as! UIStackView).insertArrangedSubview(termView, at: 0)
            }
        case "2":
            if cards[i]["termType"] as! String != "i" {
                if(cards[i]["termType"] as! String == "d"){
                    let media = cards[i]["term"] as! String
                    if(media != ""){
                        self.defaults.removeObject(forKey: media)
                        let mediaRef = storage.reference().child(Auth.auth().currentUser!.uid).child(media)
                        mediaRef.delete(){ error in
                            if let error = error{
                                print("Error deleting media: \(error.localizedDescription)")
                            }
                        }
                    }
                }
                sender.tintColor = Colors.highlight
                sender.superview!.subviews[0].tintColor = Colors.darkHighlight
                sender.superview!.subviews[2].tintColor = Colors.darkHighlight
                cards[i]["termType"] = "i"
                cards[i]["term"] = ""
                let termImage = UIButton(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
                termImage.setImage(UIImage(named: "DendriticLearning_icon_1024x1024_v2-2.png"), for: .normal)
                termImage.widthAnchor.constraint(equalToConstant: (view.frame.width - 141)/2).isActive = true
                //termImage.heightAnchor.constraint(equalToConstant: (view.frame.width - 141)/2).isActive = true
                termImage.heightAnchor.constraint(equalToConstant: (view.frame.width - 141)/3).isActive = true
                termImage.imageView?.contentMode = .scaleAspectFit
                termImage.contentMode = .scaleAspectFit
                termImage.layer.cornerRadius = 10
                termImage.accessibilityIdentifier = String(i)
                
                tAMC(termImage)
                termImage.addTarget(self, action: #selector(changeTermImage(_:)), for: .touchUpInside)
                //termImage.setImage(UIImage(named: "DendriticLearning_icon_1024x1024_v2-2.png"), for: .normal)
                termImage.accessibilityIdentifier = String(i)
                //termImage.backgroundColor = .blue
                ((sender.superview!.superview! as! UIStackView).arrangedSubviews[0] as! UIStackView).arrangedSubviews[0].removeFromSuperview()
//                let original = ((sender.superview!.superview! as! UIStackView).arrangedSubviews[0] as! UIStackView).arrangedSubviews[0]
//                ((sender.superview!.superview! as! UIStackView).arrangedSubviews[0] as! UIStackView).removeArrangedSubview(original)
                ((sender.superview!.superview! as! UIStackView).arrangedSubviews[0] as! UIStackView).insertArrangedSubview(termImage, at: 0)
                
            }
        case "3":
            if cards[i]["termType"] as! String != "d" {
                if(cards[i]["termType"] as! String == "i"){
                    let media = cards[i]["term"] as! String
                    if(media != ""){
                        self.defaults.removeObject(forKey: media)
                        let mediaRef = storage.reference().child(Auth.auth().currentUser!.uid).child(media)
                        mediaRef.delete(){ error in
                            if let error = error{
                                print("Error deleting media: \(error.localizedDescription)")
                            }
                        }
                    }
                }
                sender.tintColor = Colors.highlight
                sender.superview!.subviews[0].tintColor = Colors.darkHighlight
                sender.superview!.subviews[1].tintColor = Colors.darkHighlight
                cards[i]["termType"] = "d"
                let drawingButton = UIButton(frame: CGRect(x: 0, y: 0, width: 1, height: 1))

                drawingButton.widthAnchor.constraint(equalToConstant: (view.frame.width - 141)/2).isActive = true
                drawingButton.heightAnchor.constraint(equalToConstant: (view.frame.width - 141)/3).isActive = true
                drawingButton.addTarget(self, action: #selector(editDrawing(_:)), for: .touchUpInside)
                drawingButton.accessibilityIdentifier = "t" + String(i)
                let termDrawing = PKCanvasView(frame: CGRect(x: 0, y: 0, width: view.frame.width - 141, height: 2*(view.frame.width - 141)/3))
                termDrawing.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                //definitionDrawing.widthAnchor.constraint(equalTo: definitionView.widthAnchor).isActive = true
                //definitionDrawing.heightAnchor.constraint(equalToConstant: (view.frame.width - 141)/3).isActive = true
                termDrawing.isUserInteractionEnabled = false
                termDrawing.drawing = recolor(PKDrawing())
                tAMC([drawingButton, termDrawing])
                termDrawing.layer.cornerRadius = 10
                termDrawing.backgroundColor = .clear
                termDrawing.tool = Colors.pen
                termDrawing.overrideUserInterfaceStyle = .light
                //definitionDrawing.backgroundColor = .red
                drawingButton.insertSubview(termDrawing, at: 0)
                termDrawing.anchorPoint = CGPoint(x: 1, y: 1)
//                termDrawing.leadingAnchor.constraint(equalTo: drawingButton.leadingAnchor).isActive = true
//                termDrawing.trailingAnchor.constraint(equalTo: drawingButton.trailingAnchor).isActive = true
//                termDrawing.topAnchor.constraint(equalTo: drawingButton.topAnchor).isActive = true
//                termDrawing.bottomAnchor.constraint(equalTo: drawingButton.bottomAnchor).isActive = true
                //termDrawing.backgroundColor = .red
                ((sender.superview!.superview! as! UIStackView).arrangedSubviews[0] as! UIStackView).arrangedSubviews[0].removeFromSuperview()
//                let original = ((sender.superview!.superview! as! UIStackView).arrangedSubviews[0] as! UIStackView).arrangedSubviews[0]
//                ((sender.superview!.superview! as! UIStackView).arrangedSubviews[0] as! UIStackView).removeArrangedSubview(original)
                ((sender.superview!.superview! as! UIStackView).arrangedSubviews[0] as! UIStackView).insertArrangedSubview(drawingButton, at: 0)
                cards[i]["term"] = ""
            }
        case "4":
            if cards[i]["defType"] as! String != "t" && cards[i]["defType"] as! String != "d-r"{
                let media = cards[i]["def"] as! String
                if(media != ""){
                    self.defaults.removeObject(forKey: media)
                    let mediaRef = storage.reference().child(Auth.auth().currentUser!.uid).child(media)
                    mediaRef.delete(){ error in
                        if let error = error{
                            print("Error deleting media: \(error.localizedDescription)")
                        }
                    }
                }
                sender.tintColor = Colors.highlight
                sender.superview!.subviews[4].tintColor = Colors.darkHighlight
                cards[i]["defType"] = "t"
                cards[i]["def"] = ""
                sender.superview!.subviews[5].isHidden = false
                sender.superview!.subviews[6].isHidden = false
                let definitionView = UITextView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
                definitionView.isEditable = true
                definitionView.text = ""
                definitionView.font = UIFont(name: "LilGrotesk-Regular", size: 20)
                definitionView.delegate = self
                tAMC(definitionView)
                definitionView.isScrollEnabled = false
                definitionView.backgroundColor = .clear
                definitionView.accessibilityIdentifier = "d" + String(i)
                definitionView.textColor = Colors.text
                //definitionView.backgroundColor = .blue
                ((sender.superview!.superview! as! UIStackView).arrangedSubviews[0] as! UIStackView).arrangedSubviews[2].removeFromSuperview()
//                let original = ((sender.superview!.superview! as! UIStackView).arrangedSubviews[0] as! UIStackView).arrangedSubviews[2]
//                ((sender.superview!.superview! as! UIStackView).arrangedSubviews[0] as! UIStackView).removeArrangedSubview(original)
                ((sender.superview!.superview! as! UIStackView).arrangedSubviews[0] as! UIStackView).addArrangedSubview(definitionView)
                (sender.superview!.subviews[6] as! UIButton).setImage(UIImage(systemName: "circle"), for: .normal)
            }
        case "5":
            sender.tintColor = Colors.highlight
            sender.superview!.subviews[3].tintColor = Colors.darkHighlight
            sender.superview!.subviews[5].isHidden = true
            sender.superview!.subviews[6].isHidden = true
            cards[i]["defType"] = "d"
            
            let drawingButton = UIButton(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            drawingButton.heightAnchor.constraint(equalToConstant: (view.frame.width - 141)/3).isActive = true
            drawingButton.addTarget(self, action: #selector(editDrawing(_:)), for: .touchUpInside)
            drawingButton.accessibilityIdentifier = "d" + String(i)
            let definitionDrawing = PKCanvasView(frame: CGRect(x: 0, y: 0, width: view.frame.width - 141, height: 2*(view.frame.width - 141)/3))
            definitionDrawing.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            //definitionDrawing.widthAnchor.constraint(equalTo: definitionView.widthAnchor).isActive = true
            //definitionDrawing.heightAnchor.constraint(equalToConstant: (view.frame.width - 141)/3).isActive = true
            definitionDrawing.isUserInteractionEnabled = false
            definitionDrawing.drawing = recolor(PKDrawing())
            tAMC([drawingButton, definitionDrawing])
            definitionDrawing.layer.cornerRadius = 10
            definitionDrawing.backgroundColor = .clear
            definitionDrawing.tool = Colors.pen
            definitionDrawing.overrideUserInterfaceStyle = .light
            //definitionDrawing.backgroundColor = .red
            drawingButton.insertSubview(definitionDrawing, at: 0)
            definitionDrawing.anchorPoint = CGPoint(x: 1, y: 1)
            
            //definitionDrawing.backgroundColor = .red
            ((sender.superview!.superview! as! UIStackView).arrangedSubviews[0] as! UIStackView).arrangedSubviews[2].removeFromSuperview()
//            let original = ((sender.superview!.superview! as! UIStackView).arrangedSubviews[0] as! UIStackView).arrangedSubviews[2]
//            ((sender.superview!.superview! as! UIStackView).arrangedSubviews[0] as! UIStackView).removeArrangedSubview(original)
            ((sender.superview!.superview! as! UIStackView).arrangedSubviews[0] as! UIStackView).addArrangedSubview(drawingButton)
            cards[i]["def"] = ""
        case "6":
            if(cards[i]["defType"] as! String == "d-r"){
                sender.setImage(UIImage(systemName: "circle"), for: .normal)
                cards[i]["defType"] = "t"
            }else{
                sender.setImage(UIImage(systemName: "circle.fill"), for: .normal)
                cards[i]["defType"] = "d-r"
            }
        default:
            break
        }
        save()
    }
    
    @objc func changeDefaultInput(_ sender: UIButton){
        switch sender.accessibilityIdentifier!.first.map(String.init) {
        case "1":
            sender.tintColor = Colors.highlight
            sender.superview!.subviews[1].tintColor = Colors.darkHighlight
            sender.superview!.subviews[2].tintColor = Colors.darkHighlight
            defaultTerm = "t"
        case "2":
            sender.tintColor = Colors.highlight
            sender.superview!.subviews[0].tintColor = Colors.darkHighlight
            sender.superview!.subviews[2].tintColor = Colors.darkHighlight
            defaultTerm = "i"
        case "3":
            sender.tintColor = Colors.highlight
            sender.superview!.subviews[0].tintColor = Colors.darkHighlight
            sender.superview!.subviews[1].tintColor = Colors.darkHighlight
            defaultTerm = "d"
        case "4":
            sender.tintColor = Colors.highlight
            sender.superview!.subviews[4].tintColor = Colors.darkHighlight
            defaultDefinition = "t"
            sender.superview!.subviews[5].isHidden = false
            sender.superview!.subviews[6].isHidden = false
            sender.setImage(UIImage(systemName: "circle.fill"), for: .normal)
        case "5":
            sender.tintColor = Colors.highlight
            sender.superview!.subviews[3].tintColor = Colors.darkHighlight
            sender.superview!.subviews[5].isHidden = true
            sender.superview!.subviews[6].isHidden = true
            defaultDefinition = "d"
        case "6":
            if(sender.imageView!.image == UIImage(systemName: "circle.fill")){
                sender.setImage(UIImage(systemName: "circle"), for: .normal)
                defaultDefinition = "t"
            }else{
                sender.setImage(UIImage(systemName: "circle.fill"), for: .normal)
                defaultDefinition = "d-r"
            }
        default:
            break
        }
    }
    
    func save(){
        var oldSet: [String: Any] = [:]
        let setRef = self.db.collection("sets").document(set)
        setRef.getDocument { (document, error) in
            if let document = document, document.exists {
                oldSet = document.data()!
            } else {
                print("Document does not exist")
            }
        }
        oldSet["name"] = name
        oldSet["date"] = Timestamp(date: Date())
        oldSet["set"] = cards
        oldSet["image"] = image
        oldSet["keyWords"] = getKeyWords(name)
        db.collection("sets").document(set).setData(oldSet, merge: true)
        oldSet.removeValue(forKey: "date")
        defaults.setValue(oldSet, forKey: "set")
        
//        let userRef = self.db.collection("users").document(Auth.auth().currentUser!.uid)
//        
//        userRef.getDocument { [weak self] (document, error) in
//            guard let self = self else { return }
//            
//            if let document = document, document.exists {
//                var oldUser = document.data()!
//                var oldStudied = oldUser["studiedSets"] as! [[String: Any]]
//                
//                for (i, set) in oldStudied.enumerated() {
//                    if set["setID"] as! String == self.set {
//                        oldStudied[i]["name"] = name
//                        oldStudied[i]["image"] = image
//                        break
//                    }
//                }
//                
//                oldUser["studiedSets"] = oldStudied
//                self.db.collection("users").document(Auth.auth().currentUser!.uid).setData(oldUser, merge: true) { error in
//                    if let error = error {
//                        print("Error updating user data: \(error.localizedDescription)")
//                    } else {
//                        print("User data successfully updated.")
//                    }
//                }
//            } else {
//                print("Document does not exist")
//            }
//        }
    }
    
    @IBAction func cancel (_ unwindSegue: UIStoryboardSegue){
        
    }
    
    func textViewDidChange(_ textView: UITextView) {
        var original = textView.accessibilityIdentifier!
        original.removeFirst()
        let i: Int = Int(original)!
        if(String(textView.accessibilityIdentifier!.first!) == "t"){
            cards[i]["term"] = textView.text!
        }else{
            cards[i]["def"] = textView.text!
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        save()
        return true
    }
    
    @objc func back(_ sender: UIButton) {
        save()
        performSegue(withIdentifier: "standardEditorVC_unwind", sender: nil)
    }
    
    @objc func deleteSet(_ sender: UIButton) {
        let alertController = UIAlertController(title: nil, message: "Are you sure you want to delete this set?", preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) {_ in
            var oldUser: [String: Any] = [:]
            let userRef = self.db.collection("users").document(Auth.auth().currentUser!.uid)
            userRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    for i in 0..<self.cards.count {
                        if(self.cards[i]["defType"] as! String == "d" || self.cards[i]["defType"] as! String == "i"){
                            self.defaults.removeObject(forKey: self.cards[i]["def"] as! String)
                            let imageRef = self.storage.reference().child(self.cards[i]["def"] as! String)
                            imageRef.delete(){ error in
                                if let error = error{
                                    print("Error deleting media: \(error.localizedDescription)")
                                }
                            }
                        }
                        if(self.cards[i]["termType"] as! String == "d"){
                            self.defaults.removeObject(forKey: self.cards[i]["term"] as! String)
                            let imageRef = self.storage.reference().child(self.cards[i]["term"] as! String)
                            imageRef.delete(){ error in
                                if let error = error{
                                    print("Error deleting media: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                    oldUser = document.data()!
                    print(oldUser)
                    var oldStudied = oldUser["studiedSets"] as! [[String: Any]]
                    for (i, set) in oldStudied.enumerated() {
                        if(set["setID"] as! String == self.set){
                            oldStudied.remove(at: i)
                            break
                        }
                    }
                    oldUser["studiedSets"] = oldStudied
                    
                    var oldCreated = oldUser["createdSets"] as! [String]
                    for (i, set) in oldCreated.enumerated() {
                        if(set == self.set){
                            oldCreated.remove(at: i)
                            break
                        }
                    }
                    oldUser["createdSets"] = oldCreated
                    
                    self.db.collection("users").document(Auth.auth().currentUser!.uid).setData(oldUser, merge: true)
                    self.db.collection("sets").document(self.set).delete()
                    self.performSegue(withIdentifier: "standardEditorVC_unwind", sender: nil)
                    self.performSegue(withIdentifier: "standardEditorVC_unwind", sender: nil)
                } else {
                    print("Document does not exist")
                }
            }
            
            
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func deleteTerm(_ sender: UIButton){
        let i = Int(sender.accessibilityIdentifier!)!
        let actualI = indexes.firstIndex(of: i)!
        allTermsStackView.arrangedSubviews[actualI].removeFromSuperview()
        //allTermsStackView.removeArrangedSubview(allTermsStackView.arrangedSubviews[i])
        if(self.cards[actualI]["defType"] as! String == "d" || self.cards[i]["defType"] as! String == "i"){
            self.defaults.removeObject(forKey: self.cards[actualI]["def"] as! String)
            let imageRef = self.storage.reference().child(self.cards[actualI]["def"] as! String)
            imageRef.delete(){ error in
                if let error = error{
                    print("Error deleting media: \(error.localizedDescription)")
                }
            }
        }
        if(self.cards[actualI]["termType"] as! String == "d"){
            self.defaults.removeObject(forKey: self.cards[actualI]["term"] as! String)
            let imageRef = self.storage.reference().child(self.cards[actualI]["term"] as! String)
            imageRef.delete(){ error in
                if let error = error{
                    print("Error deleting media: \(error.localizedDescription)")
                }
            }
        }
        cards.remove(at: actualI)
        indexes.remove(at: actualI)
        save()
    }
    
    @objc func changeTermImage(_ sender: UIButton) {
        currentImagePicker = Int(sender.accessibilityIdentifier!)!
        present(imagePicker, animated: true, completion: nil)
    }
    
    @objc func editDrawing(_ sender: UIButton) {
        var original = sender.accessibilityIdentifier!
        original.removeFirst()
        let i: Int = Int(original)!
        if(String(sender.accessibilityIdentifier!.first!) == "t"){
            //cards[i]["term"]
        }else{
            //cards[i]["def"]
        }
        let popupVC = DrawingEditorVC()
        popupVC.delegate = self
        popupVC.modalPresentationStyle = .overCurrentContext
        popupVC.modalTransitionStyle = .crossDissolve
        popupVC.i = i

        if(String(sender.accessibilityIdentifier!.first!) == "t"){
            popupVC.term = true
        }else{
            popupVC.term = false
        }
        popupVC.set = set
        present(popupVC, animated: true, completion: nil)
    }
    
    
    
    @objc func changeImage(_ sender: UIButton) {
        if image == "" {
            currentImagePicker = -1
            present(imagePicker, animated: true, completion: nil)
        }else{
            defaults.removeObject(forKey: image!)
            let imageRef = storage.reference().child(image!)
            imageRef.delete(){ error in
                if let error = error{
                    print("Error deleting image: \(error.localizedDescription)")
                }
            }
            image = ""
            imageButton.setImage(UIImage(systemName: "photo"), for: .normal)
        }
        save()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        name = textField.text!
        save()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        //print(textView.text!)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            if let imageData = pickedImage.jpegData(compressionQuality: 0.8) {
                let imagesRef = storage.reference().child(Auth.auth().currentUser!.uid)
                let imageName = UUID().uuidString
                let imageRef = imagesRef.child("\(imageName).jpg")
                
                let metadata = StorageMetadata()
                metadata.contentType = "image/jpeg"
                
                let uploadTask = imageRef.putData(imageData, metadata: metadata) { [weak self] (metadata, error) in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("Error uploading image: \(error.localizedDescription)")
                        return
                    }
                    
                    guard metadata != nil else {
                        print("Metadata is nil after upload.")
                        return
                    }
                    
                    self.image = imageRef.fullPath
                    self.defaults.set(imageData, forKey: self.image!)
                    self.imageButton.setImage(UIImage(systemName: "rectangle.badge.xmark.fill"), for: .normal)
                    
                    self.save()
                }
            }
        }
        dismiss(animated: true, completion: nil)
        save()
    }

//    func updateUserDataWithImagePath(_ imagePath: String) {
//        let userRef = self.db.collection("users").document(Auth.auth().currentUser!.uid)
//        
//        userRef.getDocument { [weak self] (document, error) in
//            guard let self = self else { return }
//            
//            if let document = document, document.exists {
//                var oldUser = document.data()!
//                var oldStudied = oldUser["studiedSets"] as! [[String: Any]]
//                
//                for (i, set) in oldStudied.enumerated() {
//                    if set["setID"] as! String == self.set {
//                        oldStudied[i]["image"] = imagePath
//                        break
//                    }
//                }
//                
//                oldUser["studiedSets"] = oldStudied
//                self.db.collection("users").document(Auth.auth().currentUser!.uid).setData(oldUser, merge: true) { error in
//                    if let error = error {
//                        print("Error updating user data: \(error.localizedDescription)")
//                    } else {
//                        print("User data successfully updated.")
//                    }
//                }
//            } else {
//                print("Document does not exist")
//            }
//        }
//    }

    
    func updateDrawing(_ i: Int, _ term: Bool) {
        var t = "def"
        if term {
            t = "term"
        }
        
        if(cards[i][t] as! String != ""){
            defaults.removeObject(forKey: cards[i][t] as! String)
            let imageRef = storage.reference().child(cards[i][t] as! String)
            imageRef.delete(){ error in
                if let error = error{
                    print("Error deleting drawing: \(error.localizedDescription)")
                }
            }
        }
        
        let drawingData = defaults.value(forKey: "changedDrawing") as! Data
        if drawingData != PKDrawing().dataRepresentation(){
            let drawingsRef = storage.reference().child(Auth.auth().currentUser!.uid)
            let drawingName = UUID().uuidString
            let drawingRef = drawingsRef.child("\(drawingName).drawing")
            
            let uploadTask = drawingRef.putData(drawingData , metadata: nil) { (metadata, error) in
                if let error = error {
                    print("Error updating drawing: \(error.localizedDescription)")
                }
            }
            cards[i][t] = drawingRef.fullPath
            defaults.set(drawingData, forKey: drawingRef.fullPath)
            
        }else{
            cards[i][t] = ""
        }
        save()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
            self.setup()
        }
    }
    
}

extension StandardEditorVC {
    
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        
        let keyboardHeight = keyboardFrame.height
        
        // Adjust the content inset and scroll indicator insets
        var contentInset = scrollView.contentInset
        contentInset.bottom = keyboardHeight
        scrollView.contentInset = contentInset
        
        var scrollIndicatorInsets = scrollView.scrollIndicatorInsets
        scrollIndicatorInsets.bottom = keyboardHeight
        scrollView.scrollIndicatorInsets = scrollIndicatorInsets
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        // Reset the content inset and scroll indicator insets
        var contentInset = scrollView.contentInset
        contentInset.bottom = 0
        scrollView.contentInset = contentInset
        
        var scrollIndicatorInsets = scrollView.scrollIndicatorInsets
        scrollIndicatorInsets.bottom = 0
        scrollView.scrollIndicatorInsets = scrollIndicatorInsets
    }
}

