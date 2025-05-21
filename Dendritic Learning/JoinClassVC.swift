//
//  JoinClassVC.swift
//  StudyApp
//
//  Created by Matthew Lundeen on 5/19/24.
//

import UIKit
import PencilKit
import FirebaseStorage

protocol JoinClassDelegate: AnyObject {
    //func updateDrawing(_ i: Int, _ term: Bool)
}

class JoinClassVC: UIViewController {
    
    weak var delegate: JoinClassDelegate?
    
    let defaults = UserDefaults.standard
    let storage = Storage.storage()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.definesPresentationContext = true
        view.backgroundColor = .black.withAlphaComponent(0.5)
        
        let centeredView = UIView(frame: CGRect(x: 0, y: 0, width: (view.frame.width - 350), height: 2*(view.frame.width - 350)/3))
        centeredView.backgroundColor = Colors.background
        centeredView.isUserInteractionEnabled = true
        centeredView.layer.cornerRadius = 20
        centeredView.clipsToBounds = true
        centeredView.center = view.center
        view.addSubview(centeredView)
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(dismissIt(_:)))
        view.addGestureRecognizer(gesture)
        
        setup(centeredView)
        
        let gesture1 = UITapGestureRecognizer(target: self, action: nil)
        centeredView.addGestureRecognizer(gesture1)
    }
    
    func setup(_ container: UIView) {
        let spacing = 20.0
        let buttonSize = CGSize(width: 40, height: 40)
        let done = UIButton(frame: CGRect(x: container.frame.width - spacing - buttonSize.width, y: spacing, width: buttonSize.width, height: buttonSize.height))
        configButton(done, container)
        done.setImage(UIImage(systemName: "xmark"), for: .normal)
        done.addTarget(self, action: #selector(back), for: .touchUpInside)
        
        let joinButton = UIButton(frame: CGRect(x: spacing, y: container.frame.height - spacing - 50, width: container.frame.width - spacing * 2, height: 50))
        joinButton.layer.cornerRadius = 10
        joinButton.backgroundColor = Colors.highlight
        
        let joinText = UILabel(frame: joinButton.frame)
        joinText.text = "Join Class"
        joinText.textAlignment = .center
        joinText.font = UIFont(name: "LilGrotesk-Regular", size: 20)
        
        let codeField = UITextField(frame: CGRect(x: spacing, y: container.frame.height - (spacing * 4) - 50, width: container.frame.width - spacing * 2, height: 40))
        codeField.font = UIFont(name: "LilGrotesk-Regular", size: 13)
        codeField.layer.cornerRadius = 5
        codeField.backgroundColor = Colors.secondaryBackground
        
        let codeText = UILabel(frame: CGRect(x: spacing, y: container.frame.height - (spacing * 4) - 80, width: container.frame.width - spacing * 2, height: 20))
        codeText.font = UIFont(name: "LilGrotesk-Regular", size: 15)
        codeText.textAlignment = .left
        codeText.text = "Classroom code"
        
        let nameField = UITextField(frame: CGRect(x: spacing, y: container.frame.height - (spacing * 6) - 130, width: container.frame.width - spacing * 2, height: 40))
        nameField.font = UIFont(name: "LilGrotesk-Regular", size: 13)
        nameField.layer.cornerRadius = 5
        nameField.backgroundColor = Colors.secondaryBackground
        
        let nameText = UILabel(frame: CGRect(x: spacing, y: container.frame.height - (spacing * 6) - 160, width: container.frame.width - spacing * 2, height: 20))
        nameText.font = UIFont(name: "LilGrotesk-Regular", size: 15)
        nameText.textAlignment = .left
        nameText.text = "Class name"
        
        let mainText = UILabel(frame: CGRect(x: spacing, y: spacing, width: container.frame.width - spacing * 2, height: container.frame.height - (spacing * 6) - 160))
        mainText.font = UIFont(name: "LilGrotesk-Regular", size: 20)
        mainText.textAlignment = .center
        mainText.text = "Enter the class details"
        
        for i in [joinButton, joinText, codeField, codeText, nameField, nameText, mainText] {
            container.addSubview(i)
        }
    }
    
    func configButton(_ button: UIButton, _ centeredView: UIView){
        button.contentMode = .scaleAspectFit
        button.tintColor = Colors.highlight
        //button.backgroundColor = Colors.secondaryBackground
        //button.layer.cornerRadius = 10
        centeredView.addSubview(button)
    }
    
    @objc func dismissIt(_ sender: UITapGestureRecognizer){
        //defaults.set(canvas.drawing.dataRepresentation(), forKey: "changedDrawing")
        //delegate?.updateDrawing(i, term)
        dismiss(animated: true, completion: nil)
    }
    
    @objc func back(_ sender: UIButton) {
        //defaults.set(canvas.drawing.dataRepresentation(), forKey: "changedDrawing")
        //delegate?.updateDrawing(i, term)
        dismiss(animated: true, completion: nil)
    }
}
