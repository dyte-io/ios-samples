import RealtimeKit
import UIKit

class MessageTableViewCell: UITableViewCell {
    var message: ChatMessage? {
        didSet {
            updateUI()
        }
    }

    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var messageLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    fileprivate func updateUI() {
        if let msg = message {
            nameLabel.text = "\(msg.displayName) \(msg.time)"
            profileImageView.isHidden = true
            switch msg.type {
            case .text:
                if let textMsg = msg as? TextMessage {
                    messageLabel.text = textMsg.message
                }
            case .file:
                if let fileMsg = msg as? FileMessage {
                    messageLabel.text = fileMsg.name
                }
            case .image:
                profileImageView.isHidden = false
                if let imgMsg = msg as? ImageMessage {
                    messageLabel.text = imgMsg.displayName
                    ImageLoader.shared.obtainImageWithPath(imagePath: imgMsg.link, completionHandler: { [weak self] image in
                        DispatchQueue.main.async {
                            self?.profileImageView?.image = image
                        }
                    })
                }
            }
        }
    }
}
