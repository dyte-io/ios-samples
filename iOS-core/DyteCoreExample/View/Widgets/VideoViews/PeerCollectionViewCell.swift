//
//  PeerCollectionViewCell.swift
//  iosApp
//
//  Created by Shaunak Jagtap on 26/07/22.
//  Copyright © 2022 orgName. All rights reserved.
//

import UIKit
import DyteiOSCore

class PeerCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var hideButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var mutebutton: UIButton!
    private var audioEnabled = true
    private var videoEnabled = true
    @IBOutlet weak var statusStack: UIStackView!
    var participant: DyteRemoteParticipant?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        mutebutton.setTitle("", for: .normal)
        hideButton.setTitle("", for: .normal)
    }
    
    @IBAction func videoAction(_ sender: Any) {
        if videoEnabled {
            videoEnabled = false

            if let error = participant?.disableVideo() {
                print("Error: \(error.description())")
            }
        } else {
            videoEnabled = true
            hideButton.setImage(UIImage(systemName: "video"), for: .normal)
        }
    }
    
    @IBAction func audioAction(_ sender: Any) {
        if audioEnabled {
            audioEnabled = false
            
            if let error = participant?.disableAudio() {
                print("Error: \(error.description())")
            }
        } else {
            audioEnabled = true
            mutebutton.setImage(UIImage(systemName: "volume.3"), for: .normal)
        }
    }
}
