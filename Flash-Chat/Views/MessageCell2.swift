
//MARK: - Here we create a custom cell for messages that user send you.

import UIKit

class MessageCell2: UITableViewCell {
    
    @IBOutlet weak var leftImage: UIImageView!
    @IBOutlet weak var lable: UILabel!
    @IBOutlet weak var messageBody: UIView!
    @IBOutlet weak var nikName: UILabel!
    
//MARK: - Here we set up messageBubble view.
    
    override func awakeFromNib() {
        super.awakeFromNib()
       // messageBody.layer.cornerRadius = messageBody.frame.size.height / 2.5
      //  leftImage.layer.cornerRadius = leftImage.frame.width/2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
  
}
