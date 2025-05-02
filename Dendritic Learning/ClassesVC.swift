//
//  ClassesVC.swift
//  Dendritic Learning
//
//  Created by Matthew J. Lundeen on 4/30/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ClassesVC: UIViewController {
    
    var scrollView = UIScrollView()
    var stackView = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Colors.background
        setup()
    }
    
    func setup(){
        view.backgroundColor = Colors.background
        // Clear any existing views
        for subview in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        stackView.removeFromSuperview()
        for subview in view.subviews {
            subview.removeFromSuperview()
        }
        
        // Configure stackView and scrollView
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .leading
        scrollView.addSubview(stackView)
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
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
        
        // Add other subviews
        let backButton = UIButton()
        backButton.setTitle("< Back", for: .normal)
        backButton.titleLabel!.font = UIFont(name: "LilGrotesk-Bold", size: 20)
        backButton.addTarget(self, action: #selector(self.backButton(sender:)), for: .touchUpInside)
        backButton.setTitleColor(Colors.highlight, for: .normal)
        stackView.addArrangedSubview(backButton)
        
        addBreakView(stackView, 15)
        
        let titleLabel = UILabel()
        titleLabel.text = "Classes"
        titleLabel.font = UIFont(name: "LilGrotesk-Black", size: 50)
        titleLabel.sizeToFit()
        titleLabel.textColor = Colors.text
        stackView.addArrangedSubview(titleLabel)
        
        addBreakView(stackView, 15)
    }
    
    @IBAction func cancel (_ unwindSegue: UIStoryboardSegue){
        
    }
    
    @objc func backButton(sender: UIButton){
        performSegue(withIdentifier: "classesVC_unwind", sender: nil)
    }
}
