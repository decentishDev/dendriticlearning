//
//  layout.swift
//  StudyApp
//
//  Created by Matthew Lundeen on 5/10/24.
//

import Foundation
import UIKit
import PencilKit
import FirebaseAuth
import FirebaseStorage

func con(_ sender: UIView, _ x: CGFloat, _ y: CGFloat){
    sender.widthAnchor.constraint(equalToConstant: x).isActive = true
    sender.heightAnchor.constraint(equalToConstant: y).isActive = true
}

func conW(_ sender: UIView, _ x: CGFloat){
    sender.widthAnchor.constraint(equalToConstant: x).isActive = true
}

func conH(_ sender: UIView, _ y: CGFloat){
    sender.heightAnchor.constraint(equalToConstant: y).isActive = true
}

func tAMC(_ sender: UIView){
    sender.translatesAutoresizingMaskIntoConstraints = false
}

func tAMC(_ sender: [UIView]){
    for i in sender{
        i.translatesAutoresizingMaskIntoConstraints = false
    }
}

func recolor(_ drawing: PKDrawing) -> PKDrawing {
    var newStrokes = [PKStroke]()
    for stroke in drawing.strokes {
        let newInk = PKInk(stroke.ink.inkType, color: Colors.text)
        let newStroke = PKStroke(ink: newInk, path: stroke.path, transform: stroke.transform, mask: stroke.mask)
        newStrokes.append(newStroke)
    }
    return PKDrawing(strokes: newStrokes)
}

func centerAndZoomDrawing(_ canvasView: PKCanvasView) {
    let drawing = canvasView.drawing

    guard !drawing.bounds.isEmpty else { return }

    // Add padding to the drawing bounds
    let paddedDrawingBounds = drawing.bounds.insetBy(dx: -20, dy: -20)

    // Calculate scale to fit drawing in canvasView
    let canvasSize = canvasView.bounds.size
    let scaleX = canvasSize.width / paddedDrawingBounds.width
    let scaleY = canvasSize.height / paddedDrawingBounds.height
    let scale = min(scaleX, scaleY, 1)

    // Set content size and zoom scale
    canvasView.minimumZoomScale = scale
    canvasView.maximumZoomScale = scale
    canvasView.zoomScale = scale

    // Set the content offset to center the drawing
    let scaledDrawingSize = CGSize(width: paddedDrawingBounds.width * scale,
                                   height: paddedDrawingBounds.height * scale)

    let offsetX = max((canvasSize.width - scaledDrawingSize.width) / 2, 0)
    let offsetY = max((canvasSize.height - scaledDrawingSize.height) / 2, 0)

    let contentOffset = CGPoint(x: paddedDrawingBounds.origin.x * scale - offsetX,
                                y: paddedDrawingBounds.origin.y * scale - offsetY)

    canvasView.contentOffset = contentOffset
}



func centerDrawing(_ canvasView: PKCanvasView) {
        let drawing = canvasView.drawing
        let boundingBox = calculateBoundingBox(for: drawing)
        
        guard !boundingBox.isNull else { return }
        
        let canvasSize = canvasView.bounds.size
        let offset = calculateOffsetToCenterBoundingBox(boundingBox, in: canvasSize)
        
        canvasView.contentOffset = offset
    }
    
    func calculateBoundingBox(for drawing: PKDrawing) -> CGRect {
        var boundingBox = CGRect.null
        
        for stroke in drawing.strokes {
            let path = stroke.path
            let step: CGFloat = 1.0
            
            for t in stride(from: 0, to: CGFloat(path.count), by: step) {
                let point = path.interpolatedLocation(at: t)
                let pointRect = CGRect(x: point.x, y: point.y, width: 1, height: 1)
                boundingBox = boundingBox.union(pointRect)
            }
        }
        
        return boundingBox
    }
    
    func calculateOffsetToCenterBoundingBox(_ boundingBox: CGRect, in canvasSize: CGSize) -> CGPoint {
        let centeredX = (canvasSize.width - boundingBox.width) / 2 - boundingBox.origin.x
        let centeredY = (canvasSize.height - boundingBox.height) / 2 - boundingBox.origin.y
        return CGPoint(x: centeredX, y: centeredY)
    }
	
func formatDate(_ date: Date) -> String {
        // Get the current date
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMM d'\(daySuffix(from: date))', yyyy"
    return dateFormatter.string(from: date)
}

func daySuffix(from date: Date) -> String {
    let calender = Calendar.current
    let day = calender.component(.day, from: date)
    switch day {
    case 1, 21, 31: return "st"
    case 2, 22: return "nd"
    case 3, 23: return "rd"
    default: return "th"
    }
}

func loadDrawing(url: String?, canvas: PKCanvasView){
    if url != "" {
        let storage = Storage.storage()
        if let drawingData = UserDefaults.standard.value(forKey: url!){
            do {
                try canvas.drawing = recolor(PKDrawing(data: drawingData as! Data))
            } catch {
                print("Error converting Data to PkDrawing: \(error)")
            }
        }else {
            let storageRef = storage.reference().child(url!)
            storageRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
                if let error = error {
                    print("Error downloading drawing from Firebase Storage: \(error)")
                }else if let data = data {
                    do {
                        try canvas.drawing = recolor(PKDrawing(data: data ))
                    } catch {
                        print("Error converting Data to PkDrawing: \(error)")
                    }
                    UserDefaults.standard.set(data, forKey: url!)
                }
            }
        }
    }else{
        canvas.drawing = PKDrawing()
    }
    centerAndZoomDrawing(canvas)
}

func loadImage(url: String?, imageView: UIImageView){
    if url != "" {
        let storage = Storage.storage()
        if let imageData = UserDefaults.standard.value(forKey: url!){
            imageView.image = UIImage(data: imageData as! Data)
        }else {
            let storageRef = storage.reference().child(url!)
            storageRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
                if let error = error {
                    print("Error downloading drawing from Firebase Storage: \(error)")
                }else if let data = data {
                    imageView.image = UIImage(data: data )
                    UserDefaults.standard.set(data, forKey: url!)
                }
            }
        }
    }else{
        imageView.image = UIImage(named: "placeholderimage.png")
    }
}

func loadButtonImage(url: String?, imageView: UIButton){
    if url != "" {
        let storage = Storage.storage()
        if let imageData = UserDefaults.standard.value(forKey: url!){
            imageView.setImage(UIImage(data: imageData as! Data), for: .normal)
        }else {
            let storageRef = storage.reference().child(url!)
            storageRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
                if let error = error {
                    print("Error downloading drawing from Firebase Storage: \(error)")
                }else if let data = data {
                    imageView.setImage(UIImage(data: data), for: .normal)
                    UserDefaults.standard.set(data, forKey: url!)
                }
            }
        }
    }else{
        imageView.setImage(UIImage(named: "placeholderimage.png"), for: .normal)
    }
}


func createLoadingIcon() -> UIImageView {
    let loadingImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    loadingImageView.contentMode = .scaleAspectFit

    var animationImages: [UIImage] = []
    for i in 1...49 {
        if let image = UIImage(named: "d\(i)") {
            animationImages.append(image)
        }
    }

    loadingImageView.animationImages = animationImages
    loadingImageView.animationDuration = 1.5
    loadingImageView.animationRepeatCount = 0
    
    loadingImageView.startAnimating()
    
    return loadingImageView
}

func getKeyWords(_ input: String) -> [String] {

    let words = input.lowercased().split(separator: " ").map { String($0) }

    var combinations: [String] = []
    
    func combinationsHelper(_ current: [String], _ start: Int) {
        for i in start..<words.count {
            let newCombination = current + [words[i]]
            combinations.append(newCombination.joined(separator: " "))
            combinationsHelper(newCombination, i + 1)
        }
    }
    
    combinationsHelper([], 0)
    
    return combinations
}

func addBreakView(_ to: UIStackView, _ size: CGFloat){
    let breakView = UIView()
    con(breakView, size, size)
    to.addArrangedSubview(breakView)
}

func overlayCrosshairAndBorder(_ canvasView: PKCanvasView) {
    // Remove any existing overlays (optional, depending on your app)
//    canvasView.subviews.filter { $0.tag == 999 }.forEach { $0.removeFromSuperview() }
    
    // Create a new overlay view
    let overlay = UIView(frame: canvasView.bounds)
    overlay.backgroundColor = .clear
    overlay.isUserInteractionEnabled = false
    overlay.tag = 999  // Tag it so we can find/remove later if needed

    // Draw crosshair
    let crosshair = CAShapeLayer()
    let crosshairPath = UIBezierPath()
    
    let centerX = overlay.bounds.midX
    let centerY = overlay.bounds.midY
    
    // Horizontal line
    crosshairPath.move(to: CGPoint(x: 0, y: centerY))
    crosshairPath.addLine(to: CGPoint(x: overlay.bounds.width, y: centerY))
    
    // Vertical line
    crosshairPath.move(to: CGPoint(x: centerX, y: 0))
    crosshairPath.addLine(to: CGPoint(x: centerX, y: overlay.bounds.height))
    
    crosshair.path = crosshairPath.cgPath
    crosshair.strokeColor = UIColor.red.cgColor
    crosshair.lineWidth = 1.5

    // Draw border
    let border = CAShapeLayer()
    let borderPath = UIBezierPath(rect: overlay.bounds)
    border.path = borderPath.cgPath
    border.strokeColor = UIColor.red.cgColor
    border.lineWidth = 2.0
    border.fillColor = UIColor.clear.cgColor

    // Add layers
    overlay.layer.addSublayer(crosshair)
    overlay.layer.addSublayer(border)
    
    // Add overlay to canvasView
    canvasView.addSubview(overlay)
}
func darken(_ color: UIColor) -> UIColor {
    return adjust(color: color, by: -abs(20.0))
}

func lighten(_ color: UIColor) -> UIColor {
    return adjust(color: color, by: abs(7.0))
}

private func adjust(color: UIColor, by percentage: CGFloat) -> UIColor {
    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
    
    if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
        let adjustment = percentage / 100
        return UIColor(
            red: min(max(red + adjustment, 0.0), 1.0),
            green: min(max(green + adjustment, 0.0), 1.0),
            blue: min(max(blue + adjustment, 0.0), 1.0),
            alpha: alpha
        )
    }
    return color // return the original color if it couldn't extract components
}


