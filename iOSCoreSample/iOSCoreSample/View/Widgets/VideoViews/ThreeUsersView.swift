import RealtimeKit
import UIKit

class ThreeUsersView: UIView {
    @IBOutlet var peerOneVideoView: UIView!
    @IBOutlet var peerOneHideButton: UIButton!
    @IBOutlet var peerOneNameLabel: UILabel!
    @IBOutlet var peerOneMutebutton: UIButton!
    @IBOutlet var peerOneStatusStack: UIStackView!

    @IBOutlet var peerTwoVideoView: UIView!
    @IBOutlet var peerTwoHideButton: UIButton!
    @IBOutlet var peerTwoNameLabel: UILabel!
    @IBOutlet var peerTwoMutebutton: UIButton!
    @IBOutlet var peerTwoStatusStack: UIStackView!

    @IBOutlet var selfVideoView: UIView!
    @IBOutlet var selfViewNameLabel: UILabel!

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
        let viewFromXib = Bundle.main.loadNibNamed("ThreeUsersView", owner: self, options: nil)![0] as! UIView
        viewFromXib.frame = bounds
        addSubview(viewFromXib)
    }

    func setupUI() {
        peerOneMutebutton.setTitle("", for: .normal)
        peerOneHideButton.setTitle("", for: .normal)
        peerTwoMutebutton.setTitle("", for: .normal)
        peerTwoHideButton.setTitle("", for: .normal)
    }

    func renderUI(participants: [RtkMeetingParticipant]) {
        if participants.count > 0 {
            let participant = participants[0]
            peerOneNameLabel.text = participant.name

            peerOneHideButton.setImage(UIImage(systemName: participant.videoEnabled ? "video" : "video.slash"), for: .normal)
            let participantAudioEnabled = participant.audioEnabled
            peerOneMutebutton.setImage(UIImage(systemName: participantAudioEnabled ? "volume.3" : "volume.slash"), for: .normal)

            if let rtkView = participant.getVideoView() {
                rtkView.frame = peerOneVideoView.bounds
                peerOneVideoView.addSubview(rtkView)
            }
        }

        if participants.count > 1 {
            let participant = participants[1]
            peerTwoNameLabel.text = participant.name
            let participantVideoEnabled = participant.videoEnabled

            peerTwoHideButton.setImage(UIImage(systemName: participantVideoEnabled ? "video" : "video.slash"), for: .normal)
            let participantAudioEnabled = participant.audioEnabled
            peerTwoMutebutton.setImage(UIImage(systemName: participantAudioEnabled ? "volume.3" : "volume.slash"), for: .normal)
            if let rtkView = participant.getVideoView() {
                rtkView.frame = peerTwoVideoView.bounds
                peerTwoVideoView.addSubview(rtkView)
            }
        }

        if participants.count > 2 {
            let participant = participants[2]
            selfViewNameLabel.text = participant.name
            if let rtkView = participant.getVideoView() {
                rtkView.frame = selfVideoView.bounds
                selfVideoView.addSubview(rtkView)
            }
        }
    }
}
