import UIKit

class ClassCardCell: UICollectionViewCell {
    
    static let reuseIdentifier = "ClassCardCell"

    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let setsLabel = UILabel()
    private let teacherLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = Colors.secondaryBackground
        contentView.layer.cornerRadius = 20
        contentView.layer.masksToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = UIFont(name: "LilGrotesk-Bold", size: 25)
        titleLabel.textColor = Colors.text

        setsLabel.font = UIFont(name: "LilGrotesk-Medium", size: 18)
        setsLabel.textColor = Colors.text.withAlphaComponent(0.7)

        teacherLabel.font = UIFont(name: "LilGrotesk-Medium", size: 18)
        teacherLabel.textColor = Colors.text.withAlphaComponent(0.7)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, setsLabel, teacherLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(imageView)
        contentView.addSubview(textStack)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: contentView.heightAnchor), // Make image square based on height

            textStack.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 20),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with classInfo: [String: Any]) {
        titleLabel.text = classInfo["name"] as? String
        setsLabel.text = "\(classInfo["sets"] ?? 0) sets"
        teacherLabel.text = classInfo["teacher"] as? String

        if let imageName = classInfo["picture"] as? String,
           let image = UIImage(named: imageName) {
            imageView.image = image
        } else {
            imageView.image = UIImage(named: "DendriticLearning_icon_1024x1024_v2-3.png")
            imageView.tintColor = Colors.text.withAlphaComponent(0.4)
        }
    }
    
    
}
