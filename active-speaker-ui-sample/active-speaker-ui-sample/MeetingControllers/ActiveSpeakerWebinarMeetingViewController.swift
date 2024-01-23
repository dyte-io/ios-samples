//
//  ActiveSpeakerWebinarMeetingViewController.swift
//  active-speaker-ui-sample
//
//  Created by Dyte on 23/01/24.
//

import UIKit
import DyteUiKit
import DyteiOSCore

class ActiveSpeakerWebinarMeetingViewController: ActiveSpeakerMeetingViewController {
    private var waitingView : WaitingRoomView?
    
    func createWaitingView(message: String) -> WaitingRoomView {
        let waitingView = WaitingRoomView(automaticClose: false, onCompletion: {})
        waitingView.backgroundColor = self.view.backgroundColor
        self.gridBaseView.addSubview(waitingView)
        waitingView.set(.fillSuperView(self.gridBaseView))
        waitingView.button.isHidden = true
        waitingView.show(message: message)
        return waitingView
    }
    
    public override func refreshMeetingGrid(forRotation: Bool = false, animation: Bool) {
        super.refreshMeetingGrid(forRotation: forRotation, animation: animation)
        self.waitingView?.removeFromSuperview()
        let mediaPermission = meeting.localUser.permissions.media
        
        if (mediaPermission.audioPermission == DyteMediaPermission.allowed || mediaPermission.video.permission == DyteMediaPermission.allowed) && meeting.participants.active.isEmpty && StageStatus.getStageStatus(mobileClient: meeting) == .canJoinStage {
            self.waitingView = createWaitingView(message: "The stage is empty\nTo begin the webinar, please join the stage or accept a join stage request from the participants tab.")
        } else if meeting.participants.active.isEmpty {
            self.waitingView = createWaitingView(message: "Webinar has not yet been started")
        }
    }
}

