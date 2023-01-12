
import Foundation
import SDWebImage
import UIKit


class NewConversationCell: UITableViewCell {
    
    static let identifier = "NewConversationCell"
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 35
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private let userNameLable: UILabel = {
        let lable = UILabel()
        lable.font = .systemFont(ofSize: 21, weight: .semibold)
        return lable
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLable)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        userImageView.frame = CGRect(x: 10, y: 10, width: 70, height: 70)
    
        userNameLable.frame = CGRect(x: userImageView.frame.size.width + 20,
                                     y: 20,
                                     width: contentView.frame.size.width - 20 - userImageView.frame.size.width,
                                     height: 50)
        
    }
    
    public func configure(with model: SearchResult) {
        self.userNameLable.text = model.name
        let safeEmail = DatabaseManeger.safeEmail(emailAdres: model.email)
        let fileName = safeEmail + "_profile_picture.png"
        let path = "images/" + fileName
        print(path)
        StorageManager.shared.downloadUrl(for: path) { results in
            switch results {
            case .success(let url):
                DispatchQueue.main.async {
                    self.userImageView.sd_setImage(with: url)
                }
            case .failure(let error):
                print("error to download image \(error)")
        }
    }
    }
    
}
