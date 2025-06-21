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
    var ids: [String] = []
    var sets: [[String: Any]] = []
    var likedSets: [String] = []
    
    var previousSize: CGSize?
    
    var previousSearch = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.background
        //setup()
        previousSize = view.bounds.size
        setup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setup()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.setup()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if previousSize != view.bounds.size {
            previousSize = view.bounds.size
            setup()
        }
    }
    
    func setup(){
        for subview in resultsStack.arrangedSubviews {
            resultsStack.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        
        resultsStack.removeFromSuperview()
        for subview in view.subviews {
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
        
        let searchLabel = UILabel(frame: CGRect(x: 50, y: 100, width: view.frame.width - 100, height: 100))
        searchLabel.text = "Enter the name of a set to search for it."
        searchLabel.numberOfLines = 0
        searchLabel.lineBreakStrategy = .pushOut
        searchLabel.font = UIFont(name: "LilGrotesk-Regular", size: min(previousSize!.width/25, 30))
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
        searchBar.text = previousSearch
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
        tAMC([resultsStack, resultsScroll])
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
        
        if let uid = Auth.auth().currentUser?.uid {
            let dataRef = db.collection("users").document(uid)
            dataRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    let userData = document.data()!
                    
                    if var liked = userData["likedSets"] as? [String] {
                        liked.reverse()
                        self.likedSets = liked
                    }
                } else {
                    self.performSegue(withIdentifier: "searchVC_unwind", sender: nil)
                }
            }
        } else {
            performSegue(withIdentifier: "searchVC_unwind", sender: nil)
        }
        
        if retrievedSets.count > 0 {
            addSets()
        }
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
                        self.destinationSet = text
                        var setData = document.data()!
                        if let timestamp = setData["date"] as? Timestamp {
                            let date = timestamp.dateValue()
                            self.defaults.setValue(formatDate(date), forKey: "date")
                        }
                        setData.removeValue(forKey: "date")
                        self.defaults.set(setData, forKey: "set")
                        
                        if setData["type"] as! String == "standard" {
                            self.destinationType = "standard"
                            self.performSegue(withIdentifier: "searchToStandard", sender: nil)
                        }else{
                            self.destinationType = "web"
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
        previousSearch = searchBar.text ?? ""
        
        for subview in resultsStack.arrangedSubviews {
            resultsStack.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        retrievedSets = [:]
        let loadView = createLoadingIcon()
        loadView.center = view.center
        view.addSubview(loadView)
        if var text = searchBar.text {
            if(text.last == " "){
                text = String(text.dropLast())
            }
            let input = text.lowercased()
            db.collection("sets").whereField("keyWords", arrayContains: input).order(by: "likes", descending: true).getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error in query: \(error.localizedDescription)")
                    return
                }
                loadView.removeFromSuperview()
                self.retrievedSets = [:]
                self.ids = []
                self.sets = []
                for document in querySnapshot!.documents {
                    let data = document.data()
                    self.sets.append(data)
                    self.retrievedSets[document.documentID] = data
                    self.ids.append(document.documentID)
                }
                
                self.addSets()
            }
        }
    }
    
    func addSets(){
        let minimumWidth: CGFloat = 400
        let rowCount = Int(max((self.previousSize!.width - 100) / minimumWidth, 1))
        
        for i in 0...((self.sets.count - 1) / rowCount) {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 20
            row.alignment = .leading
            row.distribution = .fillEqually
            tAMC(row)
            self.resultsStack.addArrangedSubview(row)
            conW(row, self.view.frame.width - 100)
            for j in rowCount * i...(rowCount * i) + rowCount {
                if self.sets.count > j {
                    let setView = self.createSetView(set: self.sets[j], id: self.ids[j])
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

    
    func createSetView(set: [String: Any], id: String) -> UIView {
        let button = UIButton()
        button.backgroundColor = Colors.secondaryBackground
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)

        var identifier = "s"
        if set["type"] as? String == "web" {
            identifier = "w"
        }
        button.accessibilityIdentifier = identifier + id

        // --- Title Label ---
        let titleLabel = UILabel()
        titleLabel.text = set["name"] as? String
        titleLabel.textColor = Colors.text
        titleLabel.font = UIFont(name: "LilGrotesk-Bold", size: 30)
        titleLabel.numberOfLines = 0

        // --- Author and Likes ---
        let authorLabel = UILabel()
        authorLabel.text = set["author"] as? String
        authorLabel.textColor = Colors.text
        authorLabel.font = UIFont(name: "LilGrotesk-Bold", size: 20)

        let heartImage = UIImageView()
        heartImage.image = UIImage(systemName: likedSets.contains(id) ? "heart.fill" : "heart")
        heartImage.tintColor = Colors.highlight
        heartImage.contentMode = .scaleAspectFit

        let heartCount = UILabel()
        heartCount.text = String(set["likes"] as? Int ?? 0)
        heartCount.textColor = Colors.highlight
        heartCount.font = UIFont(name: "LilGrotesk-Regular", size: 20)

        let heartStack = UIStackView(arrangedSubviews: [heartCount, heartImage])
        heartStack.axis = .horizontal
        heartStack.spacing = 4
        heartStack.alignment = .center

        let authorLikesStack = UIStackView(arrangedSubviews: [authorLabel, UIView(), heartStack])
        authorLikesStack.axis = .horizontal
        authorLikesStack.spacing = 8
        authorLikesStack.alignment = .center

        // --- Date and Term Count ---
        let dateLabel = UILabel()
        if let timestamp = set["date"] as? Timestamp {
            dateLabel.text = formatDate(timestamp.dateValue())
        }
        dateLabel.textColor = Colors.text
        dateLabel.font = UIFont(name: "LilGrotesk-Regular", size: 20)

        let termsLabel = UILabel()
        let count = (set["set"] as? [[String: Any]])?.count ?? 0
        termsLabel.text = "\(count) terms"
        termsLabel.textColor = Colors.text
        termsLabel.font = UIFont(name: "LilGrotesk-Regular", size: 20)
        termsLabel.textAlignment = .right

        let bottomStack = UIStackView(arrangedSubviews: [dateLabel, UIView(), termsLabel])
        bottomStack.axis = .horizontal
        bottomStack.spacing = 8
        bottomStack.alignment = .center

        // --- Main Vertical Stack ---
        let stack = UIStackView(arrangedSubviews: [titleLabel, authorLikesStack, bottomStack])
        stack.axis = .vertical
        stack.spacing = 8
        tAMC([button, heartImage, stack])

        button.addSubview(stack)

        // --- Constraints ---
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: button.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -12),

            heartImage.widthAnchor.constraint(equalToConstant: 16),
            heartImage.heightAnchor.constraint(equalToConstant: 16),
        ])
        
        for i in button.subviews {
            i.isUserInteractionEnabled = false
        }

        return button
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
            if(likedSets.firstIndex(of: destinationSet) != nil){
                vc.isLiked = true
            }
            vc.alreadyHasSet = true
        }else{
            guard let vc = segue.destination as? WebSetVC else {return}
            vc.set = destinationSet
            if(likedSets.firstIndex(of: destinationSet) != nil){
                vc.isLiked = true
            }
            vc.alreadyHasSet = true
        }
    }
}
