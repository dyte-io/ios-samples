import RealtimeKit
import UIKit

class TwoUsersView: UIView {
    @IBOutlet var videoView: UIView!

    @IBOutlet var hideButton: UIButton!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var mutebutton: UIButton!
    private var audioEnabled = true
    private var videoEnabled = true
    @IBOutlet var statusStack: UIStackView!
    @IBOutlet var smallVideoView: UIView!

    @IBOutlet var smallViewNameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        comminInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        comminInit()
    }

    func comminInit() {
        let viewFromXib = Bundle.main.loadNibNamed("TwoUsersView", owner: self, options: nil)![0] as! UIView
        viewFromXib.frame = bounds
        addSubview(viewFromXib)
    }

    func setupUI() {
        mutebutton.setTitle("", for: .normal)
        hideButton.setTitle("", for: .normal)
    }

    func renderUI(participants: [RtkMeetingParticipant]) {
        if participants.count > 0 {
            let participant = participants[0]
            let participantVideoEnabled = participant.videoEnabled
            hideButton.setImage(UIImage(systemName: participantVideoEnabled ? "video" : "video.slash"), for: .normal)
            let participantAudioEnabled = participant.audioEnabled
            mutebutton.setImage(UIImage(systemName: participantAudioEnabled ? "volume.3" : "volume.slash"), for: .normal)
            nameLabel.text = participant.name
            if let rtkView = participant.getVideoView() {
                rtkView.frame = videoView.bounds
                videoView.addSubview(rtkView)
            }
        }

        if participants.count > 1 {
            let participant = participants[1]
            smallViewNameLabel.text = participant.name
            if let rtkView = participant.getVideoView() {
                rtkView.frame = smallVideoView.bounds
                smallVideoView.addSubview(rtkView)
            }
        }
    }
}
