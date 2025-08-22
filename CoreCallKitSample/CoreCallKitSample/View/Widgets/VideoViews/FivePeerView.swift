//
//  FivePeerView.swift
//  iosApp
//
//  Created by Shaunak Jagtap on 29/08/22.
//  Copyright © 2022 orgName. All rights reserved.
//

import DyteiOSCore
import UIKit

class FivePeerView: UIView {
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

    @IBOutlet var peerThreeVideoView: UIView!
    @IBOutlet var peerThreeHideButton: UIButton!
    @IBOutlet var peerThreeNameLabel: UILabel!
    @IBOutlet var peerThreeMutebutton: UIButton!
    @IBOutlet var peerThreeStatusStack: UIStackView!

    @IBOutlet var peerFourVideoView: UIView!
    @IBOutlet var peerFourHideButton: UIButton!
    @IBOutlet var peerFourNameLabel: UILabel!
    @IBOutlet var peerFourMutebutton: UIButton!
    @IBOutlet var peerFourStatusStack: UIStackView!

    @IBOutlet var peerFiveVideoView: UIView!
    @IBOutlet var peerFiveHideButton: UIButton!
    @IBOutlet var peerFiveNameLabel: UILabel!
    @IBOutlet var peerFiveMutebutton: UIButton!
    @IBOutlet var peerFiveStatusStack: UIStackView!

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
        let viewFromXib = Bundle.main.loadNibNamed("FivePeerView", owner: self, options: nil)![0] as! UIView
        viewFromXib.frame = bounds
        addSubview(viewFromXib)
    }

    func setupUI() {
        peerOneMutebutton.setTitle("", for: .normal)
        peerOneHideButton.setTitle("", for: .normal)
        peerTwoMutebutton.setTitle("", for: .normal)
        peerTwoHideButton.setTitle("", for: .normal)
        peerThreeMutebutton.setTitle("", for: .normal)
        peerThreeHideButton.setTitle("", for: .normal)
        peerFourMutebutton.setTitle("", for: .normal)
        peerFourHideButton.setTitle("", for: .normal)
        peerFiveMutebutton.setTitle("", for: .normal)
        peerFiveHideButton.setTitle("", for: .normal)
    }

    func renderUI(participants: [DyteJoinedMeetingParticipant]) {
        if participants.count > 0 {
            let participant = participants[0]
            peerOneNameLabel.text = participant.name
            let participantVideoEnabled = participant.videoEnabled

            peerOneHideButton.setImage(UIImage(systemName: participantVideoEnabled ? "video" : "video.slash"), for: .normal)
            let participantAudioEnabled = participant.audioEnabled
            peerOneMutebutton.setImage(UIImage(systemName: participantAudioEnabled ? "volume.3" : "volume.slash"), for: .normal)

            if let dyteView = participant.getVideoView() {
                dyteView.frame = peerOneVideoView.bounds
                peerOneVideoView.addSubview(dyteView)
            }
        }

        if participants.count > 1 {
            let participant = participants[1]
            peerTwoNameLabel.text = participant.name
            let participantVideoEnabled = participant.videoEnabled

            peerTwoHideButton.setImage(UIImage(systemName: participantVideoEnabled ? "video" : "video.slash"), for: .normal)
            let participantAudioEnabled = participant.audioEnabled
            peerTwoMutebutton.setImage(UIImage(systemName: participantAudioEnabled ? "volume.3" : "volume.slash"), for: .normal)

            if let dyteView = participant.getVideoView() {
                dyteView.frame = peerTwoVideoView.bounds
                peerTwoVideoView.addSubview(dyteView)
            }
        }

        if participants.count > 2 {
            let participant = participants[2]
            peerThreeNameLabel.text = participant.name
            let participantVideoEnabled = participant.videoEnabled

            peerThreeHideButton.setImage(UIImage(systemName: participantVideoEnabled ? "video" : "video.slash"), for: .normal)
            let participantAudioEnabled = participant.audioEnabled
            peerThreeMutebutton.setImage(UIImage(systemName: participantAudioEnabled ? "volume.3" : "volume.slash"), for: .normal)

            if let dyteView = participant.getVideoView() {
                dyteView.frame = peerThreeVideoView.bounds
                peerThreeVideoView.addSubview(dyteView)
            }
        }

        if participants.count > 3 {
            let participant = participants[3]
            peerFourNameLabel.text = participant.name
            let participantVideoEnabled = participant.videoEnabled

            peerFourHideButton.setImage(UIImage(systemName: participantVideoEnabled ? "video" : "video.slash"), for: .normal)
            let participantAudioEnabled = participant.audioEnabled
            peerFourMutebutton.setImage(UIImage(systemName: participantAudioEnabled ? "volume.3" : "volume.slash"), for: .normal)

            if let dyteView = participant.getVideoView() {
                dyteView.frame = peerFourVideoView.bounds
                peerFourVideoView.addSubview(dyteView)
            }
        }

        if participants.count > 4 {
            let participant = participants[4]
            peerFiveNameLabel.text = participant.name
            let participantVideoEnabled = participant.videoEnabled

            peerFiveHideButton.setImage(UIImage(systemName: participantVideoEnabled ? "video" : "video.slash"), for: .normal)
            let participantAudioEnabled = participant.audioEnabled
            peerFiveMutebutton.setImage(UIImage(systemName: participantAudioEnabled ? "volume.3" : "volume.slash"), for: .normal)

            if let dyteView = participant.getVideoView() {
                dyteView.frame = peerFiveVideoView.bounds
                peerFiveVideoView.addSubview(dyteView)
            }
        }
    }
}
