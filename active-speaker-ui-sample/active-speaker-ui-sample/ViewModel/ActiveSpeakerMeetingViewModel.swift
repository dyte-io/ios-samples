//
//  ActiveSpeakerMeetingViewModel.swift
//  active-speaker-ui-sample
//
//  Created by Dyte on 23/01/24.
//

import DyteiOSCore
import DyteUiKit
import UIKit

protocol ActiveSpeakerMeetingViewModelDelegate: AnyObject {
    func refreshMeetingGrid(forRotation: Bool, animation: Bool, completion: @escaping () -> Void)
    func refreshPluginsView(completion: @escaping () -> Void)
    func activeSpeakerChanged(participant: DyteMeetingParticipant)
    func pinnedChanged(participant: DyteMeetingParticipant)
    func activeSpeakerRemoved()
    func pinnedParticipantRemoved(participant: DyteMeetingParticipant)
    func participantJoined(participant: DyteMeetingParticipant)
    func participantLeft(participant: DyteMeetingParticipant)
    func newPollAdded(createdBy: String)
    func leaveMeeting()
}

extension ActiveSpeakerMeetingViewModelDelegate {
    func refreshMeetingGrid(completion: @escaping () -> Void) {
        refreshMeetingGrid(forRotation: false, animation: true, completion: completion)
    }
}

public final class ActiveSpeakerMeetingViewModel {
    private let dyteMobileClient: DyteMobileClient
    let dyteSelfListner: DyteEventSelfListner
    let maxParticipantOnpage: UInt
    let waitlistEventListner: DyteWaitListParticipantUpdateEventListner

    weak var delegate: ActiveSpeakerMeetingViewModelDelegate?
    var chatDelegate: ChatDelegate?
    var currentlyShowingItemOnSinglePage: UInt
    var arrGridParticipants = [GridCellViewModel]()
    let screenShareViewModel: ScreenShareViewModel
    var shouldShowShareScreen = false
    let dyteNotification = DyteNotification()
    var notificationDelegate: DyteNotificationDelegate?

    public init(dyteMobileClient: DyteMobileClient) {
        self.dyteMobileClient = dyteMobileClient
        screenShareViewModel = ScreenShareViewModel(selfActiveTab: dyteMobileClient.meta.selfActiveTab)
        waitlistEventListner = DyteWaitListParticipantUpdateEventListner(mobileClient: dyteMobileClient)
        dyteSelfListner = DyteEventSelfListner(mobileClient: dyteMobileClient)
        maxParticipantOnpage = 9
        currentlyShowingItemOnSinglePage = maxParticipantOnpage
        initialise()
    }

    public func clearChatNotification() {
        notificationDelegate?.clearChatNotification()
    }

    func trackOnGoingState() {
        if let participant = dyteMobileClient.participants.pinned {
            delegate?.pinnedChanged(participant: participant)
        }

        if dyteMobileClient.plugins.active.count >= 1 {
            screenShareViewModel.refresh(plugins: dyteMobileClient.plugins.active, selectedPlugin: nil)
            delegate?.refreshPluginsView(completion: {})
        }

        // TODO: Do this onConnectedToMeetingRoom
    }

    func onReconnect() {
        if dyteMobileClient.participants.screenShares.count > 0 {
            updateScreenShareStatus()
        }
        if dyteMobileClient.plugins.active.count >= 1 {
            screenShareViewModel.refresh(plugins: dyteMobileClient.plugins.active, selectedPlugin: nil)
            delegate?.refreshPluginsView { [weak self] in
                guard let self = self else { return }
                self.delegate?.refreshMeetingGrid {}
            }
        } else {
            delegate?.refreshMeetingGrid {}
        }
    }

    func initialise() {
        dyteMobileClient.addParticipantEventsListener(participantEventsListener: self)
        dyteMobileClient.addPluginEventsListener(pluginEventsListener: self)
        dyteMobileClient.addChatEventsListener(chatEventsListener: self)
        dyteMobileClient.addMeetingRoomEventsListener(meetingRoomEventsListener: self)
        dyteMobileClient.addPollEventsListener(pollEventsListener: self)
    }

    public func clean() {
        dyteSelfListner.clean()
        delegate = nil
        dyteMobileClient.removeMeetingRoomEventsListener(meetingRoomEventsListener: self)
        dyteMobileClient.removeParticipantEventsListener(participantEventsListener: self)
        dyteMobileClient.removePluginEventsListener(pluginEventsListener: self)
        dyteMobileClient.removeChatEventsListener(chatEventsListener: self)
        dyteMobileClient.removePollEventsListener(pollEventsListener: self)
    }
}

extension ActiveSpeakerMeetingViewModel: DyteMeetingRoomEventsListener {
    public func onActiveTabUpdate(activeTab _: ActiveTab) {}

    public func onMeetingEnded() {}

    public func onActiveTabUpdate(id _: String, tabType _: ActiveTabType) {}

    public func onMeetingInitCompleted() {}

    public func onMeetingInitFailed(exception _: KotlinException) {}

    public func onMeetingInitStarted() {}

    public func onMeetingRoomJoinCompleted() {}

    public func onMeetingRoomJoinFailed(exception _: KotlinException) {}

    public func onMeetingRoomJoinStarted() {}

    public func onMeetingRoomLeaveCompleted() {
        delegate?.leaveMeeting()
    }

    public func onMeetingRoomLeaveStarted() {}

    public func onConnectedToMeetingRoom() {}

    public func onConnectingToMeetingRoom() {}

    public func onDisconnectedFromMeetingRoom() {}

    public func onMeetingRoomConnectionFailed() {}

    public func onMeetingRoomDisconnected() {}

    public func onMeetingRoomReconnectionFailed() {}

    public func onReconnectedToMeetingRoom() {}

    public func onReconnectingToMeetingRoom() {}
}

extension ActiveSpeakerMeetingViewModel: DytePollEventsListener {
    public func onNewPoll(poll: DytePollMessage) {
        delegate?.newPollAdded(createdBy: poll.createdBy)
        notificationDelegate?.didReceiveNotification(type: .Poll)
    }

    public func onPollUpdates(pollMessages _: [DytePollMessage]) {}
}

extension ActiveSpeakerMeetingViewModel {
    public func refreshActiveParticipants(pageItemCount: UInt = 0, completion: @escaping () -> Void) {
        // pageItemCount tell on first page how many tiles needs to be shown to user
        updateActiveGridParticipants(pageItemCount: pageItemCount)
        delegate?.refreshMeetingGrid(completion: completion)
    }

    private func updateActiveGridParticipants(pageItemCount: UInt = 0) {
        currentlyShowingItemOnSinglePage = pageItemCount
        arrGridParticipants = getParticipant(pageItemCount: pageItemCount)
    }

    // Returned a pin particpant at the zero position if exists
    private func getParticipant(pageItemCount: UInt = 0) -> [GridCellViewModel] {
        let activeParticipants = dyteMobileClient.participants.active

        let rowCount = (pageItemCount == 0 || pageItemCount >= activeParticipants.count) ? UInt(activeParticipants.count) : min(UInt(activeParticipants.count), pageItemCount)

        var itemCount = 0
        var result = [GridCellViewModel]()
        for participant in activeParticipants {
            if itemCount < rowCount {
                if participant.isPinned {
                    result.insert(GridCellViewModel(participant: participant), at: 0)
                } else {
                    result.append(GridCellViewModel(participant: participant))
                }
            } else {
                break
            }
            itemCount += 1
        }
        return result
    }
}

extension ActiveSpeakerMeetingViewModel: DyteParticipantEventsListener {
    public func onScreenSharesUpdated() {}

    public func onUpdate(participants _: DyteRoomParticipants) {}

    public func onAllParticipantsUpdated(allParticipants _: [DyteParticipant]) {}

    public func onScreenShareEnded(participant_ _: DyteScreenShareMeetingParticipant) {}

    public func onScreenShareStarted(participant_ _: DyteScreenShareMeetingParticipant) {}

    public func onScreenShareEnded(participant _: DyteJoinedMeetingParticipant) {
        updateScreenShareStatus()
    }

    public func onScreenShareStarted(participant _: DyteJoinedMeetingParticipant) {
        updateScreenShareStatus()
    }

    public func onParticipantLeave(participant: DyteJoinedMeetingParticipant) {
        delegate?.participantLeft(participant: participant)
        notificationDelegate?.didReceiveNotification(type: .Leave)
    }

    public func onActiveParticipantsChanged(active _: [DyteJoinedMeetingParticipant]) {
        refreshActiveParticipants(pageItemCount: currentlyShowingItemOnSinglePage) {}
    }

    public func onActiveSpeakerChanged(participant: DyteJoinedMeetingParticipant) {
        delegate?.activeSpeakerChanged(participant: participant)
    }

    public func onNoActiveSpeaker() {
        delegate?.activeSpeakerRemoved()
    }

    public func onAudioUpdate(audioEnabled _: Bool, participant _: DyteMeetingParticipant) {}

    public func onParticipantJoin(participant: DyteJoinedMeetingParticipant) {
        delegate?.participantJoined(participant: participant)
        notificationDelegate?.didReceiveNotification(type: .Joined)
    }

    public func onParticipantPinned(participant: DyteJoinedMeetingParticipant) {
        refreshActiveParticipants(pageItemCount: currentlyShowingItemOnSinglePage) { [weak self] in
            guard let self = self else { return }
            self.delegate?.pinnedChanged(participant: participant)
        }
    }

    public func onParticipantUnpinned(participant: DyteJoinedMeetingParticipant) {
        delegate?.pinnedParticipantRemoved(participant: participant)
    }

    private func updateScreenShareStatus() {
        screenShareViewModel.refresh(participants: dyteMobileClient.participants.screenShares)
        shouldShowShareScreen = screenShareViewModel.arrScreenShareParticipants.count > 0 ? true : false
        delegate?.refreshPluginsView {}
    }

    public func onVideoUpdate(videoEnabled _: Bool, participant _: DyteMeetingParticipant) {}
}

extension ActiveSpeakerMeetingViewModel: DyteChatEventsListener {
    public func onMessageRateLimitReset() {}

    public func onChatUpdates(messages _: [DyteChatMessage]) {
        chatDelegate?.refreshMessages()
    }

    public func onNewChatMessage(message: DyteChatMessage) {
        if message.userId != dyteMobileClient.localUser.userId {
            var chat = ""
            if let textMessage = message as? DyteTextMessage {
                chat = "\(textMessage.displayName): \(textMessage.message)"
            } else {
                if message.type == DyteMessageType.image {
                    chat = "\(message.displayName): Send you an Image"
                } else if message.type == DyteMessageType.file {
                    chat = "\(message.displayName): Send you an File"
                }
            }
            notificationDelegate?.didReceiveNotification(type: .Chat(message: chat))
        }
    }
}

extension ActiveSpeakerMeetingViewModel: DytePluginEventsListener {
    public func onPluginMessage(plugin _: DytePlugin, eventName _: String, data _: Any?) {}

    public func onPluginActivated(plugin: DytePlugin) {
        screenShareViewModel.refresh(plugins: dyteMobileClient.plugins.active, selectedPlugin: plugin)
        delegate?.refreshPluginsView {}
    }

    public func onPluginDeactivated(plugin: DytePlugin) {
        screenShareViewModel.removed(plugin: plugin)
        delegate?.refreshPluginsView {}
    }

    public func onPluginFileRequest(plugin _: DytePlugin) {}

    public func onPluginMessage(message _: [String: Kotlinx_serialization_jsonJsonElement]) {}
}
