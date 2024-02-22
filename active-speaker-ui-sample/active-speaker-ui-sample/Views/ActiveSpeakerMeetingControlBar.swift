//
//  ActiveSpeakerMeetingControlBar.swift
//  active-speaker-ui-sample
//
//  Created by Dyte on 23/01/24.
//

import DyteUiKit
import DyteiOSCore
import UIKit

protocol ActiveSpeakerMeetingControlBarDelegate {
    func settingClick(button: DyteControlBarButton)
    func chatClick(button: DyteControlBarButton)
    func pollsClick(button: DyteControlBarButton)
}

// This class inherits from DyteControlBar, which is having custom implementation.
class ActiveSpeakerMeetingControlBar: DyteControlBar {
    private let meeting: DyteMobileClient
    var clickDelegate: ActiveSpeakerMeetingControlBarDelegate?
    private var chatReadCount: Int = 0
    private var viewedPollCount: Int = 0
    
    private let presentingViewController: UIViewController
    private var selfListner: DyteEventSelfListner?
    private var stageActionControlButton: DyteStageActionButtonControlBar?
    private var landscapeButtons = [DyteControlBarButton]()
 
    private var chatButton: ChatButtonControlBar?
    private var pollsButton: PollsButtonControlBar?
    
    public override init(meeting: DyteMobileClient, delegate: DyteTabBarDelegate?, presentingViewController: UIViewController, appearance: DyteControlBarAppearance = DyteControlBarAppearanceModel(), settingViewControllerCompletion:(()->Void)? = nil, onLeaveMeetingCompletion: (()->Void)? = nil) {
        self.meeting = meeting
        self.presentingViewController = presentingViewController

        super.init(meeting: meeting, delegate: delegate, presentingViewController: presentingViewController, appearance: appearance, settingViewControllerCompletion: settingViewControllerCompletion, onLeaveMeetingCompletion: onLeaveMeetingCompletion)
       addNotificationObserver()
       if self.meeting.meta.meetingType == DyteMeetingType.webinar {
           self.refreshBar()
           self.selfListner = DyteEventSelfListner(mobileClient: meeting, identifier: "Webinar Control Bar")
           self.selfListner?.observeWebinarStageStatus { status in
               self.refreshBar()
               self.stageActionControlButton?.updateButton(stageStatus: status)
           }
           self.selfListner?.observeRequestToJoinStage { [weak self] in
               guard let self = self else {return}
               self.stageActionControlButton?.handleRequestToJoinStage()
           }
       } else {
           addButtons(meeting: meeting)
       }
        
        NotificationCenter.default.addObserver(self, selector: #selector(onOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    deinit {
       NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @objc private func onOrientationChange() {
        landscapeButtons = [DyteControlBarButton]()
        if self.meeting.meta.meetingType == DyteMeetingType.webinar {
            self.refreshBar()
        } else {
            addButtons(meeting: meeting)
        }
    }
    
    override func addDefaultButtons(_ buttons: [DyteControlBarButton]) -> [DyteControlBarButton] {
        if UIScreen.isLandscape() == false {
            return super.addDefaultButtons(buttons)
        }else {
            var resultButtons = buttons
            for item in buttons {
                if item is DyteEndMeetingControlBarButton {
                    resultButtons.removeAll { button in
                        if button == item {
                            return false
                        }
                        return true
                    }
                }
            }
            return super.addDefaultButtons(resultButtons)
        }
    }
    
    func isSplitContentButtonSelected() -> Bool {
        print("Sudhir ++ Landscape button Count \(landscapeButtons)")
        for button in landscapeButtons {
            if button.isSelected {
                return true
            }
        }
        return false
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Methos related to Notification observers
extension ActiveSpeakerMeetingControlBar {
    private func addNotificationObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(newChatArrived(notification:)), name: Notification.Name("Notify_NewChatArrived"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newPollArrived(notification:)), name: Notification.Name("Notify_NewPollArrived"), object: nil)
    }
    
    @objc
    func newChatArrived(notification: NSNotification) {
        self.chatButton?.notificationBadge.setBadgeCount(self.getUnreadChatCount(totalMessage: self.meeting.chat.messages.count))
    }
    
    @objc
    func newPollArrived(notification: NSNotification) {
        self.pollsButton?.notificationBadge.setBadgeCount(self.getUnviewPollCount(totalPolls: self.meeting.polls.polls.count))
    }
}

// MARK: Methos related to button clicks
extension ActiveSpeakerMeetingControlBar {
    @objc open func onPollsClick(button: DyteControlBarButton) {
        resetButtonState(except: button)
        button.isSelected = !button.isSelected
        self.clickDelegate?.pollsClick(button: button)
    }
    
    @objc open func onChatClick(button: DyteControlBarButton) {
        resetButtonState(except: button)
        button.isSelected = !button.isSelected
        self.clickDelegate?.chatClick(button: button)
    }
    
    @objc open func onSettingClick(button: DyteControlBarButton) {
        resetButtonState(except: nil)
        self.clickDelegate?.settingClick(button: button)
    }

}

// MARK: Methos related to notification count
extension ActiveSpeakerMeetingControlBar {
    private func getUnreadChatCount(totalMessage: Int) -> Int {
        let unreadCount = totalMessage - chatReadCount
        if unreadCount < 0 {
            return 0
        }
        return unreadCount
    }
    
    private  func setChatReadCount(totalMessage: Int) {
        chatReadCount = totalMessage
    }
    
    private func getUnviewPollCount(totalPolls: Int) -> Int {
        let unreadCount = totalPolls - viewedPollCount
        if unreadCount < 0 {
            return 0
        }
        return unreadCount
    }
    
    private func setPollViewCount(totalPolls: Int) {
        viewedPollCount = totalPolls
    }
}

extension ActiveSpeakerMeetingControlBar {
    
    private func refreshBar() {
        self.refreshBar(stageStatus: self.getStageStatus())
        self.setTabBarButtonTitles(numOfLines: UIScreen.isLandscape() ? 2 : 1)
    }
    
    private func getStageStatus() -> WebinarStageStatus {
        let state = self.meeting.stage.stageStatus
        switch state {
        case .offStage:
            // IN off Stage three condition is possible whether
            // 1 He can send request(Permission to join Stage) for approval.(canRequestToJoinStage)
            // 2 He is only in view mode, means can't do anything expect watching.(viewOnly)
            // 3 He is already have permission to join stage and if this is true then stage.stageStatus == acceptedToJoinStage (canJoinStage)
            let videoPermission = self.meeting.localUser.permissions.media.video
            let audioPermission = self.meeting.localUser.permissions.media.audioPermission
            if videoPermission == DyteMediaPermission.allowed || audioPermission == .allowed {
                // Person can able to join on Stage, It means he/she already have permission to join stage.
                return .canJoinStage
            }
            else if videoPermission == DyteMediaPermission.canRequest || audioPermission == .canRequest {
                return .canRequestToJoinStage
            } else if videoPermission == DyteMediaPermission.notAllowed && audioPermission == .notAllowed {
                return .viewOnly
            }
            return .viewOnly
        case .acceptedToJoinStage:
            return .canJoinStage
        case .rejectedToJoinStage:
            return .canRequestToJoinStage
        case .onStage:
            return .alreadyOnStage
        case .requestedToJoinStage:
            return .inRequestedStateToJoinStage
        default:
            print("Not Handle")
        }
        return .canRequestToJoinStage
    }

    private func refreshBar(stageStatus: WebinarStageStatus) {
        self.setWebinarButton(stageStatus: stageStatus, isLandscape: UIScreen.isLandscape())
    }
      
    private func setWebinarButton(stageStatus: WebinarStageStatus, isLandscape: Bool) {
        var arrButtons = [DyteControlBarButton]()
       
        if isLandscape {
            if let chatButton = self.getChatButton() {
                self.chatButton = chatButton
                landscapeButtons.append(chatButton)
                arrButtons.append(chatButton)
            }
            if let pollButton = self.getPollsButton() {
                self.pollsButton = pollButton
                landscapeButtons.append(pollButton)
                arrButtons.append(pollButton)
            }
            arrButtons.append(DyteControlBarSpacerButton(space: CGSize(width: dyteSharedTokenSpace.space1, height: dyteSharedTokenSpace.space6)))
        }
       
        if stageStatus == .alreadyOnStage && isLandscape == false {
            let micButton =  DyteAudioButtonControlBar(meeting: meeting)
            arrButtons.append(micButton)
            let videoButton = DyteVideoButtonControlBar(mobileClient: meeting)
            arrButtons.append(videoButton)
        }
        
        var stageButton: DyteStageActionButtonControlBar?
        
        if stageStatus != .viewOnly {
            let button = DyteStageActionButtonControlBar(mobileClient: meeting, buttonState: stageStatus, presentingViewController: self.presentingViewController)
            button.dataSource = self
            button.selectedStateTintColor = dyteSharedTokenColor.brand.shade500

            arrButtons.append(button)
            stageButton = button
        }
         
        if let settingButton = self.getSettingButton(), isLandscape == true {
            landscapeButtons.append(settingButton)
            arrButtons.append(settingButton)
        }

        self.setButtons(arrButtons)

        //This is done so that we will get the notification after releasing the old stageButton, Now we will receive one notification
        stageButton?.addObserver()

        self.stageActionControlButton = stageButton
       
    }
 
    private func addButtons(meeting: DyteMobileClient) {

        if UIScreen.isLandscape() {
            self.addButtonsForLandscape(meeting: meeting)
        }else {
            self.addButtonsForPortrait(meeting: meeting)
        }
        self.setTabBarButtonTitles(numOfLines: UIScreen.isLandscape() ? 2 : 1)
    }
    
    private func addButtonsForPortrait(meeting: DyteMobileClient) {
        var buttons = [DyteControlBarButton]()
        if meeting.localUser.permissions.media.canPublishAudio {
            let micButton = DyteAudioButtonControlBar(meeting: meeting)
            buttons.append(micButton)
        }
        if meeting.localUser.permissions.media.canPublishVideo {
            let videoButton = DyteVideoButtonControlBar(mobileClient: meeting)
            buttons.append(videoButton)
        }
        if buttons.count > 0 {
            self.setButtons(buttons)
        }
    }
    
    private func addButtonsForLandscape(meeting: DyteMobileClient) {
        var buttons = [DyteControlBarButton]()
        
        if let chatButton = self.getChatButton() {
            self.chatButton = chatButton
            landscapeButtons.append(chatButton)
            buttons.append(chatButton)
        }
        
        if let pollButton = self.getPollsButton() {
            self.pollsButton = pollButton
            landscapeButtons.append(pollButton)
            buttons.append(pollButton)
        }
        buttons.append(DyteControlBarSpacerButton(space: CGSize(width: dyteSharedTokenSpace.space1, height: dyteSharedTokenSpace.space5)))

        if meeting.localUser.permissions.media.canPublishAudio {
            let micButton = DyteAudioButtonControlBar(meeting: meeting)
            buttons.append(micButton)
        }
        
        if meeting.localUser.permissions.media.canPublishVideo {
            let videoButton = DyteVideoButtonControlBar(mobileClient: meeting)
            buttons.append(videoButton)
        }
        
        if let settingButton = self.getSettingButton() {
            landscapeButtons.append(settingButton)
            buttons.append(settingButton)
        }
        
        if buttons.count > 0 {
            self.setButtons(buttons)
        }
    }

    
    private func getSettingButton() -> DyteControlBarButton? {
        let mediaPermission = self.meeting.localUser.permissions.media
        if mediaPermission.canPublishAudio || mediaPermission.canPublishVideo {
            let button =  DyteControlBarButton(image: DyteImage(image: ImageProvider.image(named: "icon_setting")))
            button.selectedStateTintColor = dyteSharedTokenColor.brand.shade500
            button.addTarget(self, action: #selector(onSettingClick(button:)), for: .touchUpInside)
            return button
         }
        return nil
     }
     
    private func getPollsButton() -> PollsButtonControlBar? {
         let pollPermission = self.meeting.localUser.permissions.polls
         if pollPermission.canCreate || pollPermission.canView || pollPermission.canVote {
             let button =  PollsButtonControlBar(meeting: self.meeting) { [weak self] button in
                 guard let self = self else {return}
                 self.setPollViewCount(totalPolls: self.meeting.polls.polls.count)
                 self.onPollsClick(button: button)
             }
             return button
         }
         return nil
     }
     
    private func getChatButton() -> ChatButtonControlBar? {

         let chatPermission = self.meeting.localUser.permissions.chat
         if chatPermission.canSendFiles || chatPermission.canSendText {
             let button = ChatButtonControlBar(meeting: self.meeting) { [weak self] button in
                 guard let self = self else {return}
                 self.setChatReadCount(totalMessage: self.meeting.chat.messages.count)
                 self.onChatClick(button: button)
             }
             return button
         }
         return nil
     }
    
    private func resetButtonState(except: DyteControlBarButton?) {
        self.landscapeButtons.forEach { button in
            if except !== button {
                button.isSelected = false
            }
        }
    }
}

extension ActiveSpeakerMeetingControlBar: DyteStageActionButtonControlBarDataSource {
    
    func getImage(for stageStatus: WebinarStageStatus) -> DyteImage? {
        return DyteImage(image: ImageProvider.image(named: "icon_raisehand"))
    }
    
    func getTitle(for stageStatus: WebinarStageStatus) -> String? {
        return ""
    }
    
    func getAlertView() -> ConfigureWebinerAlertView {
        return  JoinStageAlert(meetingClient: self.meeting, participant: self.meeting.localUser)
    }
    
}
