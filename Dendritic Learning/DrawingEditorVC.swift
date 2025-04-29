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
    
    var pencil = UIButton()
    var eraser = UIButton()
    var lasso = UIButton()

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
        
        canvas.frame = CGRect(x: 10, y: 70, width: centeredView.frame.width - 20, height: centeredView.frame.height - 80)
        canvas.layer.cornerRadius = 10
        canvas.clipsToBounds = true
        canvas.backgroundColor = .clear
        canvas.overrideUserInterfaceStyle = .light
        canvas.allowsFingerDrawing = defaults.bool(forKey: "fingerDrawing")
        canvas.delegate = self
        
        // Load drawing
        if let card = (defaults.value(forKey: "set") as? [String: Any])?["set"] as? [[String: Any?]] {
            let tempI = term ? "term" : "def"
            loadDrawing(url: card[i][tempI] as? String, canvas: self.canvas)
        }
        
        let backgroundView = UIView(frame: CGRect(x: 10, y: 70, width: centeredView.frame.width - 20, height: centeredView.frame.height - 80))
        backgroundView.backgroundColor = Colors.secondaryBackground
        backgroundView.layer.cornerRadius = 10
        centeredView.addSubview(backgroundView)
        
        centeredView.addSubview(canvas)
        
        setupToolbar(centeredView)
        updateCanvasTool()
        
        let gesture1 = UITapGestureRecognizer(target: self, action: nil)
        centeredView.addGestureRecognizer(gesture1)
    }
    
    func setupToolbar(_ container: UIView) {
        let buttonSize = CGSize(width: 50, height: 50)
        let spacing: CGFloat = 10
        
        let toolbar = UIView(frame: CGRect(x: spacing, y: spacing, width: buttonSize.width * 3, height: buttonSize.height))
        toolbar.layer.cornerRadius = 10
        toolbar.backgroundColor = Colors.secondaryBackground
        container.addSubview(toolbar)
        
        pencil = UIButton(frame: CGRect(x: spacing, y: spacing, width: buttonSize.width, height: buttonSize.height))
        eraser = UIButton(frame: CGRect(x: spacing + buttonSize.width, y: spacing, width: buttonSize.width, height: buttonSize.height))
        lasso = UIButton(frame: CGRect(x: spacing + buttonSize.width * 2, y: spacing, width: buttonSize.width, height: buttonSize.height))
        configBarButton(pencil, container)
        configBarButton(eraser, container)
        configBarButton(lasso, container)
        pencil.setImage(UIImage(systemName: "pencil"), for: .normal)
        pencil.addTarget(self, action: #selector(selectPencil), for: .touchUpInside)
        eraser.setImage(UIImage(systemName: "eraser"), for: .normal)
        eraser.addTarget(self, action: #selector(selectEraser), for: .touchUpInside)
        lasso.setImage(UIImage(systemName: "lasso"), for: .normal)
        lasso.addTarget(self, action: #selector(selectLasso), for: .touchUpInside)
        
        pencil.tintColor = Colors.highlight
        
        let undo = UIButton(frame: CGRect(x: spacing * 2 + buttonSize.width * 3, y: spacing, width: buttonSize.width, height: buttonSize.height))
        configButton(undo, container)
        undo.setImage(UIImage(systemName: "arrow.uturn.backward"), for: .normal)
        undo.addTarget(self, action: #selector(undoButton), for: .touchUpInside)
        
        let done = UIButton(frame: CGRect(x: container.frame.width - spacing - buttonSize.width, y: spacing, width: buttonSize.width, height: buttonSize.height))
        configButton(done, container)
        done.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
        done.addTarget(self, action: #selector(back), for: .touchUpInside)
        
        let reset = UIButton(frame: CGRect(x: container.frame.width - spacing * 2 - buttonSize.width * 2, y: spacing, width: buttonSize.width, height: buttonSize.height))
        configButton(reset, container)
        reset.setImage(UIImage(systemName: "arrow.circlepath"), for: .normal)
        reset.addTarget(self, action: #selector(clear), for: .touchUpInside)
        
        //overlayCrosshairAndBorder(canvas)
    }
    
    func configButton(_ button: UIButton, _ centeredView: UIView){
        button.contentMode = .scaleAspectFit
        button.tintColor = Colors.highlight
        button.backgroundColor = Colors.secondaryBackground
        button.layer.cornerRadius = 10
        centeredView.addSubview(button)
    }
    
    func configBarButton(_ button: UIButton, _ centeredView: UIView){
        button.contentMode = .scaleAspectFit
        button.tintColor = Colors.darkHighlight
        centeredView.addSubview(button)
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
        pencil.tintColor = Colors.highlight
        eraser.tintColor = Colors.darkHighlight
        lasso.tintColor = Colors.darkHighlight
    }
    
    @objc func selectEraser() {
        currentTool = .eraser
        pencil.tintColor = Colors.darkHighlight
        eraser.tintColor = Colors.highlight
        lasso.tintColor = Colors.darkHighlight
    }
    
    @objc func selectLasso() {
        currentTool = .lasso
        pencil.tintColor = Colors.darkHighlight
        eraser.tintColor = Colors.darkHighlight
        lasso.tintColor = Colors.highlight
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
