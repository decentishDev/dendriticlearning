//
//  AddTermsVC.swift
//  Dendritic Learning
//
//  Created by Matthew Lundeen on 6/19/25.
//

import UIKit
import PencilKit
import FirebaseStorage

//import Foundation
//import FoundationModels

protocol AddTermsDelegate: AnyObject {
    func addBasicTerm(_ term: String, _ definition: String)
}

class AddTermsVC: UIViewController, PKCanvasViewDelegate {
    
    weak var delegate: AddTermsDelegate?
    
    let defaults = UserDefaults.standard
    let storage = Storage.storage()
    
    var centeredView = UIView()
    var optionsStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.definesPresentationContext = true
        view.backgroundColor = .black.withAlphaComponent(0.5)
        
        centeredView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width * 0.5, height: view.frame.height * 0.5))
        centeredView.backgroundColor = Colors.background
        centeredView.isUserInteractionEnabled = true
        centeredView.layer.cornerRadius = 20
        centeredView.clipsToBounds = true
        centeredView.center = view.center
        view.addSubview(centeredView)
        
        tAMC(centeredView)
        NSLayoutConstraint.activate([
            centeredView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centeredView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            centeredView.widthAnchor.constraint(equalToConstant: view.frame.width * 0.5),
            centeredView.heightAnchor.constraint(equalToConstant: view.frame.height * 0.5)
        ])
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(dismissIt(_:)))
        view.addGestureRecognizer(gesture)
        
        let gesture1 = UITapGestureRecognizer(target: self, action: nil)
        centeredView.addGestureRecognizer(gesture1)
        
        let textPatternButton = UIButton()
        formatButton(textPatternButton, "Add terms from text pattern")
        textPatternButton.addTarget(self, action: #selector(textPattern), for: .touchUpInside)
        
        let aiTextButton = UIButton()
        formatButton(aiTextButton, "Generate terms from pasted notes")
        aiTextButton.addTarget(self, action: #selector(aiText), for: .touchUpInside)
        
        aiTextButton.alpha = 0.5
        aiTextButton.isUserInteractionEnabled = false
        
        let aiPictureButton = UIButton()
        formatButton(aiPictureButton, "Generate terms from a picture of notes")
        aiPictureButton.addTarget(self, action: #selector(aiPicture), for: .touchUpInside)
        
        aiPictureButton.alpha = 0.5
        aiPictureButton.isUserInteractionEnabled = false
        
        optionsStack = UIStackView(frame: CGRect(x: 0, y: 0, width: (view.frame.width - 161), height: 2*(view.frame.width - 161)/3))
        optionsStack.addArrangedSubview(textPatternButton)
        optionsStack.addArrangedSubview(aiTextButton)
        optionsStack.addArrangedSubview(aiPictureButton)
        optionsStack.axis = .vertical
        optionsStack.distribution = .fillEqually
        optionsStack.spacing = 20
        optionsStack.alignment = .fill
        centeredView.addSubview(optionsStack)
        tAMC(optionsStack)
        NSLayoutConstraint.activate([
            optionsStack.leftAnchor.constraint(equalTo: centeredView.leftAnchor, constant: 20),
            optionsStack.rightAnchor.constraint(equalTo: centeredView.rightAnchor, constant: -20),
            optionsStack.topAnchor.constraint(equalTo: centeredView.topAnchor, constant: 20),
            optionsStack.bottomAnchor.constraint(equalTo: centeredView.bottomAnchor, constant: -20),
        ])
    }
    
    func formatButton(_ button: UIButton, _ text: String){
        button.setTitle(text, for: .normal)
        button.setTitleColor(Colors.text, for: .normal)
        button.titleLabel?.font = UIFont(name: "LilGrotesk-Regular", size: 25)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        button.backgroundColor = Colors.secondaryBackground
        button.layer.cornerRadius = 10
    }
    
    @objc func textPattern() {
        optionsStack.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.3, animations: {
            self.centeredView.alpha = 0
        }, completion: { _ in
            self.optionsStack.removeFromSuperview()
            NSLayoutConstraint.deactivate(self.centeredView.constraints)
            NSLayoutConstraint.activate([
                self.centeredView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                self.centeredView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
                self.centeredView.widthAnchor.constraint(equalToConstant: self.view.frame.width * 0.7),
                self.centeredView.heightAnchor.constraint(equalToConstant: self.view.frame.height * 0.7)
            ])
            self.spawnBulkAddMenu(on: self.centeredView)
            UIView.animate(withDuration: 0.3, animations: {
                self.centeredView.alpha = 1
            })
        })
    }
    
    @objc func aiText() {
        optionsStack.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.3, animations: {
            self.centeredView.alpha = 0
        }, completion: { _ in
            self.optionsStack.removeFromSuperview()
            
            
            UIView.animate(withDuration: 0.3, animations: {
                self.centeredView.alpha = 1
            })
        })
    }
    
    func spawnBulkAddMenu(on centerView: UIView) {
        // Container view for all UI elements
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        centerView.addSubview(container)

        NSLayoutConstraint.activate([
            container.leftAnchor.constraint(equalTo: centerView.leftAnchor, constant: 20),
            container.rightAnchor.constraint(equalTo: centerView.rightAnchor, constant: -20),
            container.topAnchor.constraint(equalTo: centerView.topAnchor, constant: 20),
            container.bottomAnchor.constraint(equalTo: centerView.bottomAnchor, constant: -20),
        ])

        // MARK: - Labels
        let termSeparatorLabel = UILabel()
        termSeparatorLabel.text = "Term / Definition Separator (e.g. :)"
        termSeparatorLabel.font = UIFont(name: "LilGrotesk-Regular", size: 15)
        termSeparatorLabel.textColor = Colors.text
        termSeparatorLabel.translatesAutoresizingMaskIntoConstraints = false

        let entrySeparatorLabel = UILabel()
        entrySeparatorLabel.text = "Entry Separator (e.g. newline or ;)"
        entrySeparatorLabel.font = UIFont(name: "LilGrotesk-Regular", size: 15)
        entrySeparatorLabel.textColor = Colors.text
        entrySeparatorLabel.translatesAutoresizingMaskIntoConstraints = false

        let inputTextLabel = UILabel()
        inputTextLabel.text = "Terms and Definitions"
        inputTextLabel.font = UIFont(name: "LilGrotesk-Regular", size: 15)
        inputTextLabel.textColor = Colors.text
        inputTextLabel.translatesAutoresizingMaskIntoConstraints = false

        // MARK: - Fields
        let termSeparatorField = UITextField()
        termSeparatorField.borderStyle = .roundedRect
        termSeparatorField.translatesAutoresizingMaskIntoConstraints = false
        termSeparatorField.textColor = Colors.text
        termSeparatorField.backgroundColor = Colors.secondaryBackground
        termSeparatorField.font = UIFont(name: "LilGrotesk-Regular", size: 15)
        termSeparatorField.tintColor = Colors.highlight

        let entrySeparatorField = UITextField()
        entrySeparatorField.borderStyle = .roundedRect
        entrySeparatorField.translatesAutoresizingMaskIntoConstraints = false
        entrySeparatorField.textColor = Colors.text
        entrySeparatorField.backgroundColor = Colors.secondaryBackground
        entrySeparatorField.font = UIFont(name: "LilGrotesk-Regular", size: 15)
        entrySeparatorField.tintColor = Colors.highlight

        let inputTextView = UITextView()
        inputTextView.layer.cornerRadius = 6
        inputTextView.translatesAutoresizingMaskIntoConstraints = false
        inputTextView.textColor = Colors.text
        inputTextView.backgroundColor = Colors.secondaryBackground
        inputTextView.font = UIFont(name: "LilGrotesk-Regular", size: 15)
        inputTextView.tintColor = Colors.highlight

        let addButton = UIButton(type: .system)
        addButton.setTitle("Add All Terms", for: .normal)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.backgroundColor = Colors.secondaryBackground
        addButton.setTitleColor(Colors.highlight, for: .normal)
        addButton.titleLabel?.font = UIFont(name: "LilGrotesk-Medium", size: 20)

        // MARK: - Add Subviews
        [termSeparatorLabel, termSeparatorField,
         entrySeparatorLabel, entrySeparatorField,
         inputTextLabel, inputTextView,
         addButton].forEach { container.addSubview($0) }

        // MARK: - Constraints
        NSLayoutConstraint.activate([
            termSeparatorLabel.topAnchor.constraint(equalTo: container.topAnchor),
            termSeparatorLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            termSeparatorLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            termSeparatorField.topAnchor.constraint(equalTo: termSeparatorLabel.bottomAnchor, constant: 4),
            termSeparatorField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            termSeparatorField.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            termSeparatorField.heightAnchor.constraint(equalToConstant: 40),

            entrySeparatorLabel.topAnchor.constraint(equalTo: termSeparatorField.bottomAnchor, constant: 12),
            entrySeparatorLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            entrySeparatorLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            entrySeparatorField.topAnchor.constraint(equalTo: entrySeparatorLabel.bottomAnchor, constant: 4),
            entrySeparatorField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            entrySeparatorField.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            entrySeparatorField.heightAnchor.constraint(equalToConstant: 40),

            inputTextLabel.topAnchor.constraint(equalTo: entrySeparatorField.bottomAnchor, constant: 12),
            inputTextLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            inputTextLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            inputTextView.topAnchor.constraint(equalTo: inputTextLabel.bottomAnchor, constant: 4),
            inputTextView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            inputTextView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            inputTextView.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -20),

            //addButton.topAnchor.constraint(equalTo: inputTextView.bottomAnchor, constant: 12),
            addButton.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            addButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            addButton.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            addButton.heightAnchor.constraint(equalToConstant: 60),
            
        ])

        // MARK: - Button Action
        addButton.addAction(UIAction(handler: { _ in
            let termSep = termSeparatorField.text ?? ":"
            let entrySepInput = entrySeparatorField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
            let rawText = inputTextView.text ?? ""

            let entries: [String]
            if entrySepInput == "newline" {
                entries = rawText
                    .components(separatedBy: CharacterSet.newlines)
                    .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            } else {
                entries = rawText.components(separatedBy: entrySepInput)
            }

            for entry in entries {
                let parts = entry.components(separatedBy: termSep)
                if parts.count >= 2 {
                    let term = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let definition = parts[1...].joined(separator: termSep).trimmingCharacters(in: .whitespacesAndNewlines)
                    self.delegate?.addBasicTerm(term, definition)
                }
            }

            self.dismiss(animated: true, completion: nil)
        }), for: .touchUpInside)
    }

//    func generateFlashcards(from notes: String) async {
//        let model = TextGeneration.Model.lLaMA3
//
//        let prompt = """
//        You are an assistant that converts study notes into flashcards.
//        Extract the most important terms and their definitions from the text below.
//        Return your answer as a JSON array of objects, each with "term" and "definition".
//
//        Notes:
//        \(notes)
//
//        Output format:
//        [
//          { "term": "Term1", "definition": "Definition1" },
//          { "term": "Term2", "definition": "Definition2" }
//        ]
//        """
//
//        do {
//            let result = try await model.generate(prompt: prompt, options: .init(temperature: 0.3))
//            let jsonString = result.output
//
//            // Decode the JSON string into an array of dictionaries
//            if let data = jsonString.data(using: .utf8) {
//                let flashcards = try JSONDecoder().decode([[String: String]].self, from: data)
//                for card in flashcards {
//                    if let term = card["term"], let definition = card["definition"] {
//                        addBasicTerm(term: term, definition: definition)
//                    }
//                }
//            }
//        } catch {
//            print("Error generating flashcards: \(error)")
//        }
//    }
    
    @objc func aiPicture() {
        optionsStack.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.3, animations: {
            self.centeredView.alpha = 0
        }, completion: { _ in
            self.optionsStack.removeFromSuperview()
            
            
            UIView.animate(withDuration: 0.3, animations: {
                self.centeredView.alpha = 1
            })
        })
    }
    
    @objc func dismissIt(_ sender: UITapGestureRecognizer){
        dismiss(animated: true, completion: nil)
    }
    
    @objc func back(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}
