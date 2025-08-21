//
//  ActiveSpeakerMeetingControlBar.swift
//  active-speaker-ui-sample
//
//  Created by Dyte on 23/01/24.
//

import RealtimeKit
import RealtimeKitUI
import UIKit

protocol ActiveSpeakerMeetingControlBarDelegate {
    func settingClick(button: RtkControlBarButton)
    func chatClick(button: RtkControlBarButton)
    func pollsClick(button: RtkControlBarButton)
}

// This class inherits from RtkControlBar, which is having custom implementation.
class ActiveSpeakerMeetingControlBar: RtkControlBar {
    private let meeting: RealtimeKitClient
    var clickDelegate: ActiveSpeakerMeetingControlBarDelegate?
    private var chatReadCount: Int = 0
    private var viewedPollCount: Int = 0

    private let presentingViewController: UIViewController
    private var selfListner: RtkEventSelfListener?
    private var stageActionControlButton: RtkStageActionButtonControlBar?
    private var landscapeButtons = [RtkControlBarButton]()

    private var chatButton: ChatButtonControlBar?
    private var pollsButton: PollsButtonControlBar?
    private var previousOrientationIsLandscape = UIScreen.isLandscape()

    override init(meeting: RealtimeKitClient, delegate: RtkTabBarDelegate?, presentingViewController: UIViewController, appearance: RtkControlBarAppearance = RtkControlBarAppearanceModel(), settingViewControllerCompletion: (() -> Void)? = nil, onLeaveMeetingCompletion: (() -> Void)? = nil) {
        self.meeting = meeting
        self.presentingViewController = presentingViewController

        super.init(meeting: meeting, delegate: delegate, presentingViewController: presentingViewController, appearance: appearance, settingViewControllerCompletion: settingViewControllerCompletion, onLeaveMeetingCompletion: onLeaveMeetingCompletion)
        addNotificationObserver()
        if self.meeting.meta.meetingType == RtkMeetingType.webinar {
            refreshBar()
            selfListner = RtkEventSelfListener(rtkClient: meeting, identifier: "Webinar Control Bar")
            selfListner?.observeWebinarStageStatus { status in
                self.refreshBar()
                self.stageActionControlButton?.updateButton(stageStatus: status)
            }
            selfListner?.observeRequestToJoinStage { [weak self] in
                guard let self = self else { return }
                self.stageActionControlButton?.handleRequestToJoinStage()
            }
        } else {
            addButtons(meeting: meeting)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(onOrientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    @objc private func onOrientationChanged() {
        let currentOrientationIsLandscape = UIScreen.isLandscape()
        if previousOrientationIsLandscape != currentOrientationIsLandscape {
            previousOrientationIsLandscape = currentOrientationIsLandscape
            onRotationChange()
        }
    }

    private func onRotationChange() {
        landscapeButtons = [RtkControlBarButton]()
        if meeting.meta.meetingType == RtkMeetingType.webinar {
            refreshBar()
        } else {
            addButtons(meeting: meeting)
        }
    }

    override func addDefaultButtons(_ buttons: [RtkControlBarButton]) -> [RtkControlBarButton] {
        if UIScreen.isLandscape() == false {
            return super.addDefaultButtons(buttons)
        } else {
            var resultButtons = buttons
            for item in buttons {
                if item is RtkEndMeetingControlBarButton {
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
        for button in landscapeButtons {
            if button.isSelected {
                return true
            }
        }
        return false
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
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
    func newChatArrived(notification _: NSNotification) {
        chatButton?.notificationBadge.setBadgeCount(getUnreadChatCount(totalMessage: meeting.chat.messages.count))
    }

    @objc
    func newPollArrived(notification _: NSNotification) {
        if !(pollsButton?.isSelected ?? false) {
            pollsButton?.notificationBadge.setBadgeCount(getUnviewPollCount(totalPolls: meeting.polls.items.count))
        }
    }
}

// MARK: Methos related to button clicks

extension ActiveSpeakerMeetingControlBar {
    @objc open func onPollsClick(button: RtkControlBarButton) {
        resetButtonState(except: button)
        button.isSelected = !button.isSelected
        setPollViewCount(totalPolls: meeting.polls.items.count)
        pollsButton?.notificationBadge.setBadgeCount(0)
        clickDelegate?.pollsClick(button: button)
    }

    @objc open func onChatClick(button: RtkControlBarButton) {
        resetButtonState(except: button)
        button.isSelected = !button.isSelected
        setChatReadCount(totalMessage: meeting.chat.messages.count)
        chatButton?.notificationBadge.setBadgeCount(0)
        clickDelegate?.chatClick(button: button)
    }

    @objc open func onSettingClick(button: RtkControlBarButton) {
        resetButtonState(except: nil)
        clickDelegate?.settingClick(button: button)
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

    private func setChatReadCount(totalMessage: Int) {
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
        refreshBar(stageStatus: getStageStatus())
        setTabBarButtonTitles(numOfLines: UIScreen.isLandscape() ? 2 : 1)
    }

    private func getStageStatus() -> WebinarStageStatus {
        let state = meeting.stage.stageStatus
        switch state {
        case .offStage:
            // IN off Stage three condition is possible whether
            // 1 He can send request(Permission to join Stage) for approval.(canRequestToJoinStage)
            // 2 He is only in view mode, means can't do anything expect watching.(viewOnly)
            // 3 He is already have permission to join stage and if this is true then stage.stageStatus == acceptedToJoinStage (canJoinStage)
            let videoPermission = meeting.localUser.permissions.media.video.permission
            let audioPermission = meeting.localUser.permissions.media.audioPermission
            if videoPermission == MediaPermission.allowed || audioPermission == .allowed {
                // Person can able to join on Stage, It means he/she already have permission to join stage.
                return .canJoinStage
            } else if videoPermission == MediaPermission.canRequest || audioPermission == .canRequest {
                return .canRequestToJoinStage
            } else if videoPermission == MediaPermission.notAllowed && audioPermission == .notAllowed {
                return .viewOnly
            }
            return .viewOnly
        case .acceptedToJoinStage:
            return .canJoinStage
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
        setWebinarButton(stageStatus: stageStatus, isLandscape: UIScreen.isLandscape())
    }

    private func setWebinarButton(stageStatus: WebinarStageStatus, isLandscape: Bool) {
        var arrButtons = [RtkControlBarButton]()

        if isLandscape {
            if let chatButton = getChatButton() {
                self.chatButton = chatButton
                self.chatButton?.notificationBadge.setBadgeCount(getUnreadChatCount(totalMessage: meeting.chat.messages.count))
                landscapeButtons.append(chatButton)
                arrButtons.append(chatButton)
            }
            if let pollButton = getPollsButton() {
                pollsButton = pollButton
                pollsButton?.notificationBadge.setBadgeCount(getUnviewPollCount(totalPolls: meeting.polls.items.count))
                landscapeButtons.append(pollButton)
                arrButtons.append(pollButton)
            }
            arrButtons.append(RtkControlBarSpacerButton(space: CGSize(width: rtkSharedTokenSpace.space1, height: rtkSharedTokenSpace.space6)))
        }

        if stageStatus == .alreadyOnStage, isLandscape == false {
            let micButton = RtkAudioButtonControlBar(meeting: meeting)
            arrButtons.append(micButton)
            let videoButton = RtkVideoButtonControlBar(rtkClient: meeting)
            arrButtons.append(videoButton)
        }

        var stageButton: RtkStageActionButtonControlBar?

        if stageStatus != .viewOnly {
            let button = RtkStageActionButtonControlBar(rtkClient: meeting, buttonState: stageStatus, presentingViewController: presentingViewController)
            button.dataSource = self
            arrButtons.append(button)
            stageButton = button
        }

        if let settingButton = getSettingButton(), isLandscape == true {
            landscapeButtons.append(settingButton)
            arrButtons.append(settingButton)
        }

        setButtons(arrButtons)

        // This is done so that we will get the notification after releasing the old stageButton, Now we will receive one notification
        stageButton?.addObserver()

        stageActionControlButton = stageButton
    }

    private func addButtons(meeting: RealtimeKitClient) {
        if UIScreen.isLandscape() {
            addButtonsForLandscape(meeting: meeting)
        } else {
            addButtonsForPortrait(meeting: meeting)
        }
        setTabBarButtonTitles(numOfLines: UIScreen.isLandscape() ? 2 : 1)
    }

    private func addButtonsForPortrait(meeting: RealtimeKitClient) {
        var buttons = [RtkControlBarButton]()
        if meeting.localUser.permissions.media.canPublishAudio {
            let micButton = RtkAudioButtonControlBar(meeting: meeting)
            buttons.append(micButton)
        }
        if meeting.localUser.permissions.media.canPublishVideo {
            let videoButton = RtkVideoButtonControlBar(rtkClient: meeting)
            buttons.append(videoButton)
        }
        if buttons.count > 0 {
            setButtons(buttons)
        }
    }

    private func addButtonsForLandscape(meeting: RealtimeKitClient) {
        var buttons = [RtkControlBarButton]()

        if let chatButton = getChatButton() {
            self.chatButton = chatButton
            self.chatButton?.notificationBadge.setBadgeCount(getUnreadChatCount(totalMessage: self.meeting.chat.messages.count))
            landscapeButtons.append(chatButton)
            buttons.append(chatButton)
        }

        if let pollButton = getPollsButton() {
            pollsButton = pollButton
            pollsButton?.notificationBadge.setBadgeCount(getUnviewPollCount(totalPolls: self.meeting.polls.items.count))
            landscapeButtons.append(pollButton)
            buttons.append(pollButton)
        }
        buttons.append(RtkControlBarSpacerButton(space: CGSize(width: rtkSharedTokenSpace.space1, height: rtkSharedTokenSpace.space5)))

        if meeting.localUser.permissions.media.canPublishAudio {
            let micButton = RtkAudioButtonControlBar(meeting: meeting)
            buttons.append(micButton)
        }

        if meeting.localUser.permissions.media.canPublishVideo {
            let videoButton = RtkVideoButtonControlBar(rtkClient: meeting)
            buttons.append(videoButton)
        }

        if let settingButton = getSettingButton() {
            landscapeButtons.append(settingButton)
            buttons.append(settingButton)
        }

        if buttons.count > 0 {
            setButtons(buttons)
        }
    }

    private func getSettingButton() -> RtkControlBarButton? {
        let button = RtkControlBarButton(image: RtkImage(image: ImageProvider.image(named: "icon_setting")))
        button.selectedStateTintColor = rtkSharedTokenColor.brand.shade500
        button.addTarget(self, action: #selector(onSettingClick(button:)), for: .touchUpInside)
        return button
    }

    private func getPollsButton() -> PollsButtonControlBar? {
        let pollPermission = meeting.localUser.permissions.polls
        if pollPermission.canCreate || pollPermission.canView || pollPermission.canVote {
            let button = PollsButtonControlBar(meeting: meeting) { [weak self] button in
                guard let self = self else { return }
                self.onPollsClick(button: button)
            }
            return button
        }
        return nil
    }

    private func getChatButton() -> ChatButtonControlBar? {
        let button = ChatButtonControlBar(meeting: meeting) { [weak self] button in
            guard let self = self else { return }
            self.onChatClick(button: button)
        }
        return button
    }

    private func resetButtonState(except: RtkControlBarButton?) {
        for button in landscapeButtons {
            if except !== button {
                button.isSelected = false
            }
        }
    }
}

extension ActiveSpeakerMeetingControlBar: RtkStageActionButtonControlBarDataSource {
    func getImage(for stageStatus: WebinarStageStatus) -> RtkImage? {
        switch stageStatus {
        case .canRequestToJoinStage:
            return RtkImage(image: ImageProvider.image(named: "icon_raisehand"))
        case .requestingToJoinStage:
            return RtkImage(image: ImageProvider.image(named: "icon_raisehand"))
        case .inRequestedStateToJoinStage:
            return RtkImage(image: ImageProvider.image(named: "icon_raisehand"))
        case .canJoinStage:
            return RtkImage(image: ImageProvider.image(named: "icon_raisehand"))
        case .joiningStage:
            return RtkImage(image: ImageProvider.image(named: "icon_raisehand"))
        case .alreadyOnStage:
            return RtkImage(image: ImageProvider.image(named: "icon_stage_leave"))
        case .leavingFromStage:
            return RtkImage(image: ImageProvider.image(named: "icon_stage_leave"))
        case .viewOnly:
            print("")
        }

        return RtkImage(image: ImageProvider.image(named: "icon_raisehand"))
    }

    func getTitle(for stageStatus: WebinarStageStatus) -> String? {
        switch stageStatus {
        case .canRequestToJoinStage:
            return "Request"
        case .requestingToJoinStage:
            return "Requesting..."
        case .inRequestedStateToJoinStage:
            return "Cancel request"
        case .canJoinStage:
            return "Join stage"
        case .joiningStage:
            return "Joining..."
        case .alreadyOnStage:
            return "Leave stage"
        case .leavingFromStage:
            return "Leaving..."
        case .viewOnly:
            return ""
        }
    }

    func getAlertView() -> ConfigureWebinerAlertView {
        return JoinStageAlert(meeting: meeting, participant: meeting.localUser)
    }
}
