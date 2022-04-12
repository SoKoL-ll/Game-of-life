import UIKit

class ScreensCellView: UITableViewCell {
    
    var image: UIImageView!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.contentMode = .scaleAspectFit
        self.contentView.addSubview(image)
        
        NSLayoutConstraint.activate([
            self.image.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
            self.image.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 20),
            self.image.heightAnchor.constraint(equalToConstant: 100),
            self.image.widthAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
