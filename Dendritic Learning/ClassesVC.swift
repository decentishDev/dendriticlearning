import UIKit

class ClassesVC: UIViewController {
    
    let defaults = UserDefaults.standard

    var collectionView: UICollectionView!
    var classes: [[String: Any]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.background
        setup()
        loadData()
    }

    func setup() {
        // Common Symbol Config for smaller, bold icons
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)

        // Back Button
        let backButton = UIButton(type: .system)
        backButton.setTitle(" Back", for: .normal)
        let backIcon = UIImage(systemName: "chevron.left", withConfiguration: iconConfig)
        backButton.setImage(backIcon, for: .normal)
        backButton.tintColor = Colors.highlight
        backButton.setTitleColor(Colors.highlight, for: .normal)
        backButton.titleLabel?.font = UIFont(name: "LilGrotesk-Bold", size: 18)
        backButton.backgroundColor = Colors.secondaryBackground
        backButton.layer.cornerRadius = 10
        backButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 12)
        backButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        backButton.addTarget(self, action: #selector(self.backButton(sender:)), for: .touchUpInside)


        // Title Label
        let titleLabel = UILabel()
        titleLabel.text = "My Classes"
        titleLabel.font = UIFont(name: "LilGrotesk-Bold", size: 40)
        titleLabel.textColor = Colors.text

        // Add Class Button
        let addClassButton = UIButton(type: .system)
        addClassButton.setTitle(" Add a class", for: .normal)
        let plusIcon = UIImage(systemName: "plus", withConfiguration: iconConfig)
        addClassButton.setImage(plusIcon, for: .normal)
        addClassButton.tintColor = Colors.highlight
        addClassButton.setTitleColor(Colors.highlight, for: .normal)
        addClassButton.titleLabel?.font = UIFont(name: "LilGrotesk-Bold", size: 18)
        addClassButton.backgroundColor = Colors.secondaryBackground
        addClassButton.layer.cornerRadius = 10
        addClassButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        addClassButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 0)
        // addClassButton.addTarget(self, action: #selector(addClass), for: .touchUpInside)

        // Top Horizontal Stack
        let topStack = UIStackView()
        topStack.axis = .horizontal
        topStack.alignment = .center
        topStack.spacing = 30
        topStack.translatesAutoresizingMaskIntoConstraints = false

        topStack.addArrangedSubview(backButton)
        topStack.addArrangedSubview(titleLabel)
        topStack.addArrangedSubview(UIView()) // Flexible spacer
        topStack.addArrangedSubview(addClassButton)

        view.addSubview(topStack)

        NSLayoutConstraint.activate([
            topStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            topStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            topStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50)
        ])

        // Collection View Layout
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 20
        layout.minimumInteritemSpacing = 20

        let width = (view.frame.width - 120) / 2
        layout.itemSize = CGSize(width: width, height: 150)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(ClassCardCell.self, forCellWithReuseIdentifier: ClassCardCell.reuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self

        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topStack.bottomAnchor, constant: 50),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }


    func loadData() {
        classes = defaults.value(forKey: "classes") as! [[String: Any]]
    }

    @objc func addClassTapped() {
        // TODO: Present your class creation UI here
        print("Add Class button tapped")
    }

    @objc func cancel() {
        dismiss(animated: true, completion: nil)
    }

    @objc func backButton(sender: UIButton){
        performSegue(withIdentifier: "classesVC_unwind", sender: nil)
    }
}

extension ClassesVC: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return classes.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ClassCardCell.reuseIdentifier, for: indexPath) as! ClassCardCell
        cell.configure(with: classes[indexPath.item])
        return cell
    }
}
