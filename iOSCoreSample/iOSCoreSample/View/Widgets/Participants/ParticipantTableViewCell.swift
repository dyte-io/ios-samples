import RealtimeKit
import UIKit

class ParticipantTableViewCell: UITableViewCell {
    @IBOutlet var videoImageView: UIImageView!
    @IBOutlet var micImageView: UIImageView!
    @IBOutlet var usertitleLabel: UILabel!
    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var moreOptionsImageView: UIImageView!

    var participant: RtkMeetingParticipant? {
        didSet {
            updateUI()
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

    private func updateUI() {
        ImageLoader.shared.obtainImageWithPath(imagePath: participant?.picture ?? "") { [weak self] image in
            self?.profileImageView.image = image
        }
        usertitleLabel.text = participant?.name
        let micEnabled = participant?.audioEnabled ?? false
        let videoEnabled = participant?.videoEnabled ?? false
        micImageView.image = UIImage(systemName: micEnabled ? "mic" : "mic.slash")
        videoImageView.image = UIImage(systemName: videoEnabled ? "video" : "video.slash")
    }
}
