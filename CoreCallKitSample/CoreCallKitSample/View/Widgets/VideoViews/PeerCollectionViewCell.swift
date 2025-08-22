import RealtimeKit
import UIKit

class PeerCollectionViewCell: UICollectionViewCell {
    @IBOutlet var videoView: UIView!
    @IBOutlet var hideButton: UIButton!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var mutebutton: UIButton!
    private var audioEnabled = true
    private var videoEnabled = true
    @IBOutlet var statusStack: UIStackView!
    var participant: RtkSelfParticipant?

    override func awakeFromNib() {
        super.awakeFromNib()
        mutebutton.setTitle("", for: .normal)
        hideButton.setTitle("", for: .normal)
    }

    @IBAction func videoAction(_: Any) {
        if videoEnabled {
            videoEnabled = false

            participant?.disableVideo(onResult: { err in
                if let error = err {
                    print("Error: \(error.message)")
                }
            })
        } else {
            videoEnabled = true
            hideButton.setImage(UIImage(systemName: "video"), for: .normal)
        }
    }

    @IBAction func audioAction(_: Any) {
        if audioEnabled {
            audioEnabled = false
            participant?.disableAudio(onResult: { err in
                if let error = err {
                    print("Error: \(error.message)")
                }
            })
        } else {
            audioEnabled = true
            mutebutton.setImage(UIImage(systemName: "volume.3"), for: .normal)
        }
    }
}
