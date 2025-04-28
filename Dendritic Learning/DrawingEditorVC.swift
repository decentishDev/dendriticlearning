//
//  DrawingEditorVC.swift
//  StudyApp
//
//  Created by Matthew Lundeen on 5/19/24.
//

import UIKit
import PencilKit
import FirebaseStorage

protocol DrawingEditorDelegate: AnyObject {
    func updateDrawing(_ i: Int, _ term: Bool)
}

enum DrawingTool {
    case pencil
    case eraser
    case lasso
}

class DrawingEditorVC: UIViewController, PKCanvasViewDelegate {
    
    weak var delegate: DrawingEditorDelegate?
    var set = ""
    var i = 0
    var term = true
    
    let canvas = PKCanvasView()
    var currentTool: DrawingTool = .pencil {
        didSet {
            updateCanvasTool()
        }
    }
    
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
        
        canvas.frame = CGRect(x: 0, y: 70, width: centeredView.frame.width, height: centeredView.frame.height - 70)
        canvas.layer.cornerRadius = 10
        canvas.clipsToBounds = true
        canvas.backgroundColor = Colors.background
        canvas.overrideUserInterfaceStyle = .light
        canvas.allowsFingerDrawing = defaults.bool(forKey: "fingerDrawing")
        canvas.delegate = self
        
        // Load drawing
        if let card = (defaults.value(forKey: "set") as? [String: Any])?["set"] as? [[String: Any?]] {
            let tempI = term ? "term" : "def"
            loadDrawing(url: card[i][tempI] as? String, canvas: self.canvas)
        }
        
        centeredView.addSubview(canvas)
        
        setupToolbar(centeredView)
        updateCanvasTool()
    }
    
    func setupToolbar(_ container: UIView) {
        let buttonSize = CGSize(width: 50, height: 50)
        let spacing: CGFloat = 10
        let buttonY: CGFloat = 10
        
        let buttons: [(String, Selector)] = [
            ("pencil", #selector(selectPencil)),
            ("eraser", #selector(selectEraser)),
            ("lasso", #selector(selectLasso)),
            ("arrow.circlepath", #selector(clear)),
            ("arrow.uturn.backward", #selector(undoButton)),
            ("checkmark.circle.fill", #selector(back))
        ]
        
        for (index, (systemImageName, selector)) in buttons.enumerated() {
            let button = UIButton(frame: CGRect(x: CGFloat(index) * (buttonSize.width + spacing) + 10, y: buttonY, width: buttonSize.width, height: buttonSize.height))
            button.setImage(UIImage(systemName: systemImageName), for: .normal)
            button.contentMode = .scaleAspectFit
            button.tintColor = Colors.highlight
            button.backgroundColor = Colors.secondaryBackground
            button.layer.cornerRadius = 10
            button.addTarget(self, action: selector, for: .touchUpInside)
            container.addSubview(button)
        }
    }
    
    @objc func dismissIt(_ sender: UITapGestureRecognizer){
        defaults.set(canvas.drawing.dataRepresentation(), forKey: "changedDrawing")
        delegate?.updateDrawing(i, term)
        dismiss(animated: true, completion: nil)
    }
    
    @objc func back(_ sender: UIButton) {
        defaults.set(canvas.drawing.dataRepresentation(), forKey: "changedDrawing")
        delegate?.updateDrawing(i, term)
        dismiss(animated: true, completion: nil)
    }
    
    @objc func selectPencil() {
        currentTool = .pencil
    }
    
    @objc func selectEraser() {
        currentTool = .eraser
    }
    
    @objc func selectLasso() {
        currentTool = .lasso
    }
    
    func updateCanvasTool() {
        switch currentTool {
        case .pencil:
            canvas.tool = Colors.pen
        case .eraser:
            canvas.tool = PKEraserTool(.vector)
        case .lasso:
            canvas.tool = PKLassoTool()
        }
    }
    
    @objc func clear(_ sender: UIButton) {
        canvas.drawing = recolor(PKDrawing())
    }
    
    @objc func undoButton(_ sender: UIButton) {
        canvas.undoManager?.undo()
    }
    
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        // Optional: Add logic if you want to auto-save etc.
    }
}
