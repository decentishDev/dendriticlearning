//
//  SearchVC.swift
//  Dendritic Learning
//
//  Created by Matthew Lundeen on 6/26/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class SearchVC: UIViewController, UITextFieldDelegate {
    
    let db = Firestore.firestore()
    let defaults = UserDefaults.standard
    var resultsScroll = UIScrollView()
    var resultsStack = UIStackView()
    
    var searchBar = UITextField()
    
    var destinationSet = ""
    var destinationType = ""
    var retrievedSets: [String: Any] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.background
        setup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setup()
    }
    
    func setup(){
        for subview in resultsStack.arrangedSubviews {
            resultsStack.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        
//        let banner = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 320))
//        banner.backgroundColor = Colors.background
//        view.addSubview(banner)
        
        let backButton = UIButton(frame: CGRect(x: 50, y: 50, width: 100, height: 50))
        backButton.setTitle("< Back", for: .normal)
        backButton.titleLabel!.font = UIFont(name: "LilGrotesk-Bold", size: 20)
        backButton.addTarget(self, action: #selector(self.backButton(sender:)), for: .touchUpInside)
        backButton.setTitleColor(Colors.highlight, for: .normal)
        backButton.backgroundColor = Colors.secondaryBackground
        backButton.layer.cornerRadius = 10
        view.addSubview(backButton)
        
        let idButton = UIButton(frame: CGRect(x: view.frame.width - 200, y: 50, width: 150, height: 50))
        idButton.setTitle("Enter set ID", for: .normal)
        idButton.titleLabel!.font = UIFont(name: "LilGrotesk-Bold", size: 20)
        idButton.addTarget(self, action: #selector(self.idButton(sender:)), for: .touchUpInside)
        idButton.setTitleColor(Colors.highlight, for: .normal)
        idButton.backgroundColor = Colors.secondaryBackground
        idButton.layer.cornerRadius = 10
        view.addSubview(idButton)
        
        let searchLabel = UILabel(frame: CGRect(x: 50, y: 150, width: view.frame.width - 100, height: 50))
        searchLabel.text = "Enter the name of a set to search for it."
        searchLabel.font = UIFont(name: "LilGrotesk-Regular", size: 30)
        searchLabel.textAlignment = .center
        searchLabel.textColor = Colors.text
        view.addSubview(searchLabel)
        
        searchBar = UITextField(frame: CGRect(x: 50, y: 200, width: view.frame.width - 100, height: 50))
        searchBar.backgroundColor = Colors.secondaryBackground
        searchBar.textColor = Colors.text
        searchBar.leftViewMode = .always
        searchBar.leftView = UIView(frame: CGRectMake(0, 0, 12, searchBar.frame.height))
        searchBar.font = UIFont(name: "LilGrotesk-Regular", size: 25)
        searchBar.layer.cornerRadius = 10
        searchBar.delegate = self
        view.addSubview(searchBar)
        
        let searchButton = UIButton(frame: CGRect(x: view.frame.width - 90, y: 210, width: 30, height: 30))
        searchButton.layoutMargins = .zero
        searchButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        searchButton.imageView!.contentMode = .scaleAspectFit
        searchButton.tintColor = Colors.highlight
        searchButton.addTarget(self, action: #selector(self.searchButton(sender:)), for: .touchUpInside)
        view.addSubview(searchButton)
        
        //resultsScroll.frame = CGRect(x: 50, y: 350, width: view.frame.width - 100, height: view.frame.height - 400)
        resultsStack.axis = .vertical
        resultsStack.spacing = 20
        resultsStack.alignment = .leading
        resultsScroll.addSubview(resultsStack)
        view.addSubview(resultsScroll)
        //view.sendSubviewToBack(resultsScroll)
        resultsScroll.translatesAutoresizingMaskIntoConstraints = false
        resultsStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            resultsScroll.topAnchor.constraint(equalTo: view.topAnchor, constant: 270),
            resultsScroll.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            resultsScroll.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            resultsScroll.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 50),
            resultsStack.topAnchor.constraint(equalTo: resultsScroll.topAnchor),
            resultsStack.bottomAnchor.constraint(equalTo: resultsScroll.bottomAnchor),
            resultsStack.leadingAnchor.constraint(equalTo: resultsScroll.leadingAnchor),
            resultsStack.trailingAnchor.constraint(equalTo: resultsScroll.trailingAnchor)
        ])
    }
    
    @objc func idButton(sender: UIButton){
        let alertController = UIAlertController(title: "Enter the ID of a set", message: nil, preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.placeholder = "Set ID"
        }
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { [weak alertController] _ in
            if let textField = alertController?.textFields?.first, let text = textField.text {
                let loadingImage = createLoadingIcon()
                loadingImage.center = self.view.center
                self.view.addSubview(loadingImage)
                let dataRef = self.db.collection("sets").document(text)
                dataRef.getDocument { (document, error) in
                    if let document = document, document.exists {
                        var setData = document.data()!
                        if let timestamp = setData["date"] as? Timestamp {
                            let date = timestamp.dateValue()
                            self.defaults.setValue(formatDate(date), forKey: "date")
                        }
                        setData.removeValue(forKey: "date")
                        self.defaults.set(setData, forKey: "set")
                        
                        if setData["type"] as! String == "standard" {
                            self.performSegue(withIdentifier: "searchToStandard", sender: nil)
                        }else{
                            self.performSegue(withIdentifier: "searchToWeb", sender: nil)
                        }
                    } else {
                        print("Document does not exist")
                    }
                    loadingImage.removeFromSuperview()
                }
                
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func backButton(sender: UIButton){
        performSegue(withIdentifier: "searchVC_unwind", sender: nil)
    }
    
    @IBAction func cancel (_ unwindSegue: UIStoryboardSegue){
        
    }
    
    @objc func searchButton(sender: UIButton){
        for i in resultsStack.arrangedSubviews {
            resultsStack.removeArrangedSubview(i)
        }
        let loadView = createLoadingIcon()
        loadView.center = view.center
        view.addSubview(loadView)
        if let text = searchBar.text {
            let input = text.lowercased()
            db.collection("sets").whereField("keyWords", arrayContains: input).order(by: "likes", descending: true).getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error in query: \(error.localizedDescription)")
                    return
                }
                loadView.removeFromSuperview()
                self.retrievedSets = [:]
                var ids: [String] = []
                var sets: [[String: Any]] = []
                for document in querySnapshot!.documents {
                    let data = document.data()
                    sets.append(data)
                    self.retrievedSets[document.documentID] = data
                    ids.append(document.documentID)
                }
                for i in 0...((sets.count - 1) / 3) {
                    let row = UIStackView()
                    row.axis = .horizontal
                    row.spacing = 20
                    row.alignment = .leading
                    row.translatesAutoresizingMaskIntoConstraints = false
                    self.resultsStack.addArrangedSubview(row)
                    con(row, self.view.frame.width - 100, 150)
                    for j in 3 * i...(3 * i) + 2 {
                        if sets.count > j {
                            let setView = self.createSetView(set: sets[j], id: ids[j])
                            row.addArrangedSubview(setView)
                        } else {
                            let setView = UIView()
                            row.addArrangedSubview(setView)
                            NSLayoutConstraint.activate([
                                setView.heightAnchor.constraint(equalTo: row.heightAnchor),
                            ])
                        }
                    }
                }
            }
        }
    }

    
    func createSetView(set: [String: Any], id: String) -> UIView {
        let w = (view.frame.width - 140)/3
        let rect = UIButton(frame: CGRect(x: 0, y: 0, width: w, height: 150))
        con(rect, w, 150)
        rect.backgroundColor = Colors.secondaryBackground
        rect.layer.cornerRadius = 10
        let titleLabel = UILabel(frame: CGRect(x: 10, y: 10, width: w - 20, height: 100))
        titleLabel.text = set["name"] as? String
        titleLabel.textColor = Colors.text
        titleLabel.font = UIFont(name: "LilGrotesk-Bold", size: 30)
        titleLabel.numberOfLines = 0
        titleLabel.sizeToFit()
        rect.addSubview(titleLabel)
        let creatorLabel = UILabel(frame: CGRect(x: 10, y: 90, width: w - 20, height: 15))
        creatorLabel.text = set["author"] as? String
        creatorLabel.textColor = Colors.text
        creatorLabel.font = UIFont(name: "LilGrotesk-Bold", size: 20)
        rect.addSubview(creatorLabel)
        let dateLabel = UILabel(frame: CGRect(x: 10, y: 120, width: w - 20, height: 15))
        dateLabel.text = formatDate((set["date"] as! Timestamp).dateValue())
        dateLabel.textColor = Colors.text
        dateLabel.font = UIFont(name: "LilGrotesk-Regular", size: 20)
        rect.addSubview(dateLabel)
        let heartLabel = UILabel(frame: CGRect(x: 10, y: 90, width: w - 40, height: 15))
        heartLabel.text = String(set["likes"] as! Int)
        heartLabel.textColor = Colors.highlight
        heartLabel.font = UIFont(name: "LilGrotesk-Regular", size: 20)
        heartLabel.textAlignment = .right
        rect.addSubview(heartLabel)
        let heartImage = UIImageView(image: UIImage(systemName: "heart"))
        heartImage.contentMode = .scaleAspectFit
        heartImage.tintColor = Colors.highlight
        heartImage.frame = CGRect(x: w - 25, y: 90, width: 15, height: 15)
        rect.addSubview(heartImage)
        let heartButton = UIButton(frame: CGRect(x: w - 80, y: 90, width: 70, height: 15))
        rect.addSubview(heartButton)
        let cardsLabel = UILabel(frame: CGRect(x: 10, y: 120, width: w - 20, height: 15))
        cardsLabel.text = String((set["set"] as! [[String: Any]]).count) + " terms"
        cardsLabel.textColor = Colors.text
        cardsLabel.font = UIFont(name: "LilGrotesk-Regular", size: 20)
        cardsLabel.textAlignment = .right
        
        rect.addSubview(cardsLabel)
        rect.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        var t = "s"
        if set["type"] as! String == "web" {
            t = "w"
        }
        rect.accessibilityIdentifier = t + id
        return rect
    }
    
    @objc func buttonTapped(_ sender: UIButton) {
        destinationSet = String(sender.accessibilityIdentifier!.dropFirst())
        var t = retrievedSets[destinationSet] as! [String: Any]
        if let timestamp = t["date"] as? Timestamp {
            let date = timestamp.dateValue()
            self.defaults.setValue(formatDate(date), forKey: "date")
        }
        t.removeValue(forKey: "date")
        defaults.set(t, forKey: "set")
        if(String(sender.accessibilityIdentifier!.first!) == "s"){
            destinationType = "standard"
            performSegue(withIdentifier: "searchToStandard", sender: self)
        }else{
            destinationType = "web"
            performSegue(withIdentifier: "searchToWeb", sender: self)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        searchButton(sender: UIButton())
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        segue.destination.modalPresentationStyle = .fullScreen
        if(destinationType == "standard"){
            guard let vc = segue.destination as? StandardSetVC else {return}
            vc.set = destinationSet
            vc.alreadyHasSet = true
        }else{
            guard let vc = segue.destination as? WebSetVC else {return}
            vc.set = destinationSet
            vc.alreadyHasSet = true
        }
    }
}
