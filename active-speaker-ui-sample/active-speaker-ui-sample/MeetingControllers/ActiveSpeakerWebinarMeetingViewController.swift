//
//  ActiveSpeakerWebinarMeetingViewController.swift
//  active-speaker-ui-sample
//
//  Created by Dyte on 23/01/24.
//

import RealtimeKit
import RealtimeKitUI
import UIKit

class ActiveSpeakerWebinarMeetingViewController: ActiveSpeakerMeetingViewController {
    private var waitingView: WaitingRoomView?

    func createWaitingView(message: String) -> WaitingRoomView {
        let waitingView = WaitingRoomView(automaticClose: false, onCompletion: {})
        waitingView.backgroundColor = view.backgroundColor
        gridBaseView.addSubview(waitingView)
        waitingView.set(.fillSuperView(gridBaseView))
        waitingView.button.isHidden = true
        waitingView.show(message: message)
        waitingView.clipsToBounds = true
        return waitingView
    }

    override func refreshMeetingGrid(forRotation: Bool = false, animation: Bool, completion: @escaping () -> Void) {
        super.refreshMeetingGrid(forRotation: forRotation, animation: animation, completion: completion)
        waitingView?.removeFromSuperview()
        let mediaPermission = meeting.localUser.permissions.media

        if mediaPermission.audioPermission == MediaPermission.allowed || mediaPermission.video.permission == MediaPermission.allowed, meeting.participants.active.isEmpty, StageStatus.getStageStatus(rtkClient: meeting) == .canJoinStage {
            waitingView = createWaitingView(message: "The stage is empty\nTo begin the webinar, please join the stage or accept a join stage request from the participants tab.")
        } else if meeting.participants.active.isEmpty {
            waitingView = createWaitingView(message: "Webinar has not yet been started")
        }
    }
}
