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
class DrawingEditorVC: UIViewController, PKCanvasViewDelegate {
    weak var delegate: DrawingEditorDelegate?
    var set = ""
    var i = 0
    var term = true
    let canvas = PKCanvasView()
    var usingEraser = false
    
    let defaults = UserDefaults.standard
    let storage = Storage.storage()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.definesPresentationContext = true
        
        view.backgroundColor = .black.withAlphaComponent(0.5)
        let centeredView = UIView(frame: CGRect(x: 0, y: 0, width: (view.frame.width - 161), height: 2*(view.frame.width - 161)/3))
        centeredView.backgroundColor = Colors.background
        centeredView.isUserInteractionEnabled = true
        view.addSubview(centeredView)
        centeredView.center = view.center
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
//        view.addGestureRecognizer(UIGestureRecognizer(target: self, action: #selector(cancelTap(_:))))
        
        centeredView.backgroundColor = Colors.background
        centeredView.layer.cornerRadius = 20
        let gesture = UITapGestureRecognizer(target: self, action: #selector(dismissIt(_:)))
        view.addGestureRecognizer(gesture)
        
        canvas.frame = CGRect(x: 0, y: 0, width: centeredView.frame.width, height: centeredView.frame.height)
        canvas.layer.cornerRadius = 10
        canvas.clipsToBounds = true
        canvas.backgroundColor = Colors.background
        canvas.tool = Colors.pen
        canvas.overrideUserInterfaceStyle = .light
        canvas.allowsFingerDrawing = defaults.value(forKey: "fingerDrawing") as! Bool
        
        let card = (UserDefaults.standard.value(forKey: "set") as! [String: Any])["set"] as! [[String: Any?]]
        var tempI = "def"
        if(term){
            tempI = "term"
        }
        loadDrawing(url: card[i][tempI] as? String, canvas: self.canvas)
        
        canvas.delegate = self
        centeredView.addSubview(canvas)
        
        let doneButton = UIButton(frame: CGRect(x: 10, y: 10, width: 50, height: 50))
        doneButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
        doneButton.contentMode = .scaleAspectFit
        doneButton.tintColor = Colors.highlight
        doneButton.backgroundColor = Colors.secondaryBackground
        doneButton.layer.cornerRadius = 10
        doneButton.addTarget(self, action: #selector(back(_:)), for: .touchUpInside)
        centeredView.addSubview(doneButton)
        let clearButton = UIButton(frame: CGRect(x: 70, y: 10, width: 50, height: 50))
        clearButton.setImage(UIImage(systemName: "arrow.circlepath"), for: .normal)
        clearButton.contentMode = .scaleAspectFit
        clearButton.tintColor = Colors.highlight
        clearButton.backgroundColor = Colors.secondaryBackground
        clearButton.layer.cornerRadius = 10
        clearButton.addTarget(self, action: #selector(clear(_:)), for: .touchUpInside)
        centeredView.addSubview(clearButton)
        let eraserButton = UIButton(frame: CGRect(x: 130, y: 10, width: 50, height: 50))
        eraserButton.setImage(UIImage(systemName: "eraser.fill"), for: .normal)
        eraserButton.contentMode = .scaleAspectFit
        eraserButton.tintColor = Colors.highlight
        eraserButton.backgroundColor = Colors.secondaryBackground
        eraserButton.layer.cornerRadius = 10
        eraserButton.addTarget(self, action: #selector(eraser(_:)), for: .touchUpInside)
        centeredView.addSubview(eraserButton)
        let undoButton = UIButton(frame: CGRect(x: 190, y: 10, width: 50, height: 50))
        undoButton.setImage(UIImage(systemName: "arrow.uturn.backward"), for: .normal)
        undoButton.contentMode = .scaleAspectFit
        undoButton.tintColor = Colors.highlight
        undoButton.backgroundColor = Colors.secondaryBackground
        undoButton.layer.cornerRadius = 10
        undoButton.addTarget(self, action: #selector(undoButton(_:)), for: .touchUpInside)
        centeredView.addSubview(undoButton)
    }
    
    @objc func dismissIt(_ sender: UITapGestureRecognizer){
        defaults.set(canvas.drawing.dataRepresentation(), forKey: "changedDrawing")
        delegate?.updateDrawing(i, term)
        dismiss(animated: true, completion: nil)
    }
    
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        //defaults.set(canvasView.drawing.dataRepresentation(), forKey: "changedDrawing")
//        var card = ((UserDefaults.standard.value(forKey: "sets") as! [Dictionary<String, Any>])[set]["set"] as! [[Any]])
//        if(term){
//            card[i][1] = canvasView.drawing.dataRepresentation()
//        }else{
//            card[i][3] = canvasView.drawing.dataRepresentation()
//        }
//        var originalset = (UserDefaults.standard.value(forKey: "sets") as! [Dictionary<String, Any>])[set]
//        originalset["set"] = card
//        var allsets = UserDefaults.standard.value(forKey: "sets") as! [Dictionary<String, Any>]
//        allsets[set] = originalset
//        UserDefaults.standard.setValue(allsets, forKey: "sets")
    }
    
    @objc func back(_ sender: UIButton) {
        defaults.set(canvas.drawing.dataRepresentation(), forKey: "changedDrawing")
        delegate?.updateDrawing(i, term)
        dismiss(animated: true, completion: nil)
    }
    
    @objc func eraser(_ sender: UIButton) {
        if(usingEraser){
            sender.setImage(UIImage(systemName: "eraser.fill"), for: .normal)
            canvas.tool = PKInkingTool(.pen, color: Colors.text, width: PKInkingTool.InkType.pen.defaultWidth)
        }else{
            sender.setImage(UIImage(systemName: "pencil"), for: .normal)
            canvas.tool = PKEraserTool(.vector)
        }
        usingEraser = !usingEraser
    }
    
    @objc func clear(_ sender: UIButton) {
        canvas.drawing = recolor(PKDrawing())
    }
    
    @objc func undoButton(_ sender: UIButton){
        canvas.undoManager?.undo()
    }
}
