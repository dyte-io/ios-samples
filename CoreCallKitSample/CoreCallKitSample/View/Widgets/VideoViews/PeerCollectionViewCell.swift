//
//  PeerCollectionViewCell.swift
//  iosApp
//
//  Created by Shaunak Jagtap on 26/07/22.
//  Copyright © 2022 orgName. All rights reserved.
//

import DyteiOSCore
import UIKit

class PeerCollectionViewCell: UICollectionViewCell {
    @IBOutlet var videoView: UIView!
    @IBOutlet var hideButton: UIButton!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var mutebutton: UIButton!
    private var audioEnabled = true
    private var videoEnabled = true
    @IBOutlet var statusStack: UIStackView!
    var participant: DyteJoinedMeetingParticipant?

    override func awakeFromNib() {
        super.awakeFromNib()
        mutebutton.setTitle("", for: .normal)
        hideButton.setTitle("", for: .normal)
    }

    @IBAction func videoAction(_: Any) {
        if videoEnabled {
            videoEnabled = false

            do {
                try participant?.disableVideo()
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        } else {
            videoEnabled = true
            hideButton.setImage(UIImage(systemName: "video"), for: .normal)
        }
    }

    @IBAction func audioAction(_: Any) {
        if audioEnabled {
            audioEnabled = false
            do {
                try participant?.disableAudio()
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        } else {
            audioEnabled = true
            mutebutton.setImage(UIImage(systemName: "volume.3"), for: .normal)
        }
    }
}
