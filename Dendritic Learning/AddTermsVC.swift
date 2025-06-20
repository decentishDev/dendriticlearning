//
//  AddTermsVC.swift
//  Dendritic Learning
//
//  Created by Matthew Lundeen on 6/19/25.
//

import UIKit
import PencilKit
import FirebaseStorage

protocol AddTermsDelegate: AnyObject {
    func addBasicTerm(_ term: String, _ definition: String)
}

class AddTermsVC: UIViewController, PKCanvasViewDelegate {
    
    weak var delegate: AddTermsDelegate?
    
    let defaults = UserDefaults.standard
    let storage = Storage.storage()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.definesPresentationContext = true
        view.backgroundColor = .black.withAlphaComponent(0.5)
        
        let centeredView = UIView(frame: CGRect(x: 0, y: 0, width: (view.frame.width - 161), height: 2*(view.frame.width - 161)/3))
        centeredView.backgroundColor = Colors.background
        centeredView.isUserInteractionEnabled = true
        centeredView.layer.cornerRadius = 20
        centeredView.clipsToBounds = true
        centeredView.center = view.center
        view.addSubview(centeredView)
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(dismissIt(_:)))
        view.addGestureRecognizer(gesture)
        
        let backgroundView = UIView(frame: CGRect(x: 10, y: 70, width: centeredView.frame.width - 20, height: centeredView.frame.height - 80))
        backgroundView.backgroundColor = Colors.secondaryBackground
        backgroundView.layer.cornerRadius = 10
        centeredView.addSubview(backgroundView)
        
        let gesture1 = UITapGestureRecognizer(target: self, action: nil)
        centeredView.addGestureRecognizer(gesture1)
    }
    
    @objc func dismissIt(_ sender: UITapGestureRecognizer){
        dismiss(animated: true, completion: nil)
    }
    
    @objc func back(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}
