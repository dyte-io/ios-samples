//
//  ActiveSpeakerMeetingViewModel.swift
//  active-speaker-ui-sample
//
//  Created by Dyte on 23/01/24.
//

import DyteiOSCore
import UIKit
import DyteUiKit


protocol ActiveSpeakerMeetingViewModelDelegate: AnyObject {
    func refreshMeetingGrid(forRotation: Bool, animation: Bool)
    func refreshPluginsView()
    func activeSpeakerChanged(participant: DyteMeetingParticipant)
    func pinnedChanged(participant: DyteMeetingParticipant)
    func activeSpeakerRemoved()
    func pinnedParticipantRemoved(participant: DyteMeetingParticipant)
    func participantJoined(participant: DyteMeetingParticipant)
    func participantLeft(participant: DyteMeetingParticipant)
    func newPollAdded(createdBy: String)
}

extension ActiveSpeakerMeetingViewModelDelegate {
    func refreshMeetingGrid() {
        self.refreshMeetingGrid(forRotation: false, animation: true)
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
    var screenShareViewModel = ScreenShareViewModel()
    var shouldShowShareScreen = false
    let dyteNotification = DyteNotification()
    var notificationDelegate: DyteNotificationDelegate?

    public init(dyteMobileClient: DyteMobileClient) {
        self.dyteMobileClient = dyteMobileClient
        self.waitlistEventListner = DyteWaitListParticipantUpdateEventListner(mobileClient: dyteMobileClient)
        self.dyteSelfListner = DyteEventSelfListner(mobileClient: dyteMobileClient)
        self.maxParticipantOnpage = 9
        self.currentlyShowingItemOnSinglePage = maxParticipantOnpage
        initialise()
    }
    
    public func clearChatNotification() {
        notificationDelegate?.clearChatNotification()
    }
    
    func trackOnGoingState() {
        
        if let participant = dyteMobileClient.participants.pinned {
            self.delegate?.pinnedChanged(participant: participant)
        }
        
        if dyteMobileClient.plugins.active.count >= 1 {
            screenShareViewModel.refresh(plugins: self.dyteMobileClient.plugins.active, selectedPlugin: nil)
            self.delegate?.refreshPluginsView()
        }
        
        //TODO: Do this onConnectedToMeetingRoom
        
    }
    
    func onReconnect() {
        if dyteMobileClient.participants.screenShares.count > 0 {
            self.updateScreenShareStatus()
        }
        if dyteMobileClient.plugins.active.count >= 1 {
            screenShareViewModel.refresh(plugins: self.dyteMobileClient.plugins.active, selectedPlugin: nil)
            self.delegate?.refreshPluginsView()
        }
        self.delegate?.refreshMeetingGrid()
    }
    
    func initialise() {
        dyteMobileClient.addParticipantEventsListener(participantEventsListener: self)
        dyteMobileClient.addPluginEventsListener(pluginEventsListener: self)
        dyteMobileClient.addChatEventsListener(chatEventsListener: self)
        self.dyteMobileClient.addPollEventsListener(pollEventsListener: self)

    }
    
    public func clean() {
        dyteSelfListner.clean()
        dyteMobileClient.removeParticipantEventsListener(participantEventsListener: self)
        dyteMobileClient.removePluginEventsListener(pluginEventsListener: self)
        dyteMobileClient.removeChatEventsListener(chatEventsListener: self)
        self.dyteMobileClient.removePollEventsListener(pollEventsListener: self)

    }
    
}

extension ActiveSpeakerMeetingViewModel: DytePollEventsListener {
    public func onNewPoll(poll: DytePollMessage) {
        delegate?.newPollAdded(createdBy: poll.createdBy)
        notificationDelegate?.didReceiveNotification(type: .Poll)
    }
    
    public func onPollUpdates(pollMessages: [DytePollMessage]) {
        
    }
    
    
}

extension ActiveSpeakerMeetingViewModel {
    
    public func refreshActiveParticipants(pageItemCount: UInt = 0) {
        //pageItemCount tell on first page how many tiles needs to be shown to user
        self.updateActiveGridParticipants(pageItemCount: pageItemCount)
        self.delegate?.refreshMeetingGrid()
    }
    
    private func updateActiveGridParticipants(pageItemCount: UInt = 0) {
        self.currentlyShowingItemOnSinglePage = pageItemCount
        self.arrGridParticipants = getParticipant(pageItemCount: pageItemCount)
    }
    
    private func getParticipant(pageItemCount: UInt = 0) -> [GridCellViewModel] {
        let activeParticipants = self.dyteMobileClient.participants.active

        let rowCount = (pageItemCount == 0 || pageItemCount >= activeParticipants.count) ? UInt(activeParticipants.count) : min(UInt(activeParticipants.count), pageItemCount)

        var itemCount = 0
        var result =  [GridCellViewModel]()
        for participant in activeParticipants {
            if itemCount < rowCount {
                if participant.isPinned {
                    result.insert(GridCellViewModel(participant: participant), at: 0)
                }else {
                    result.append(GridCellViewModel(participant: participant))
                }
            } else {
                break;
            }
            itemCount += 1
        }
        return result
    }
}

extension ActiveSpeakerMeetingViewModel: DyteParticipantEventsListener {
    public func onScreenSharesUpdated() {
        
    }
    

    public func onUpdate(participants: DyteRoomParticipants) {
        
    }

    public func onAllParticipantsUpdated(allParticipants: [DyteParticipant]) {

    }
    
    public func onScreenShareEnded(participant_ participant: DyteScreenShareMeetingParticipant) {
    
    }
    
    public func onScreenShareStarted(participant_ participant: DyteScreenShareMeetingParticipant) {
   
    }
    
    public func onScreenShareEnded(participant: DyteJoinedMeetingParticipant) {
      
        updateScreenShareStatus()
    }
    
    public func onScreenShareStarted(participant: DyteJoinedMeetingParticipant) {
        
        updateScreenShareStatus()
    }
    
    public func onParticipantLeave(participant: DyteJoinedMeetingParticipant) {
        
        delegate?.participantLeft(participant: participant)
        notificationDelegate?.didReceiveNotification(type: .Leave)
    }
    
    public func onActiveParticipantsChanged(active: [DyteJoinedMeetingParticipant]) {
       
        self.refreshActiveParticipants(pageItemCount: self.currentlyShowingItemOnSinglePage)
    }
    
    public func onActiveSpeakerChanged(participant: DyteJoinedMeetingParticipant) {
        self.delegate?.activeSpeakerChanged(participant: participant)
    }

    public  func onNoActiveSpeaker() {
        self.delegate?.activeSpeakerRemoved()

    }

    public func onAudioUpdate(audioEnabled: Bool, participant: DyteMeetingParticipant) {

    }
    
    public func onParticipantJoin(participant: DyteJoinedMeetingParticipant) {
        delegate?.participantJoined(participant: participant)
        notificationDelegate?.didReceiveNotification(type: .Joined)
    }
    
    public func onParticipantPinned(participant: DyteJoinedMeetingParticipant) {
        self.refreshActiveParticipants(pageItemCount: self.currentlyShowingItemOnSinglePage)
        self.delegate?.pinnedChanged(participant: participant)
    }
    
    public func onParticipantUnpinned(participant: DyteJoinedMeetingParticipant) {
       
        self.delegate?.pinnedParticipantRemoved(participant: participant)
    }

    private func updateScreenShareStatus() {
        screenShareViewModel.refresh(participants: self.dyteMobileClient.participants.screenShares)
        self.shouldShowShareScreen = screenShareViewModel.arrScreenShareParticipants.count > 0 ? true : false
        self.delegate?.refreshPluginsView()
    }
    
    public func onVideoUpdate(videoEnabled: Bool, participant: DyteMeetingParticipant) {
        
    }
    
}


extension ActiveSpeakerMeetingViewModel: DyteChatEventsListener {
    public  func onChatUpdates(messages: [DyteChatMessage]) {
        self.chatDelegate?.refreshMessages()
    }
    
    public func onNewChatMessage(message: DyteChatMessage) {
        if message.userId != dyteMobileClient.localUser.userId {
            var chat = ""
            if  let textMessage = message as? DyteTextMessage {
                chat = "\(textMessage.displayName): \(textMessage.message)"
            }else {
                if message.type == DyteMessageType.image {
                    chat = "\(message.displayName): Send you an Image"
                } else if message.type == DyteMessageType.file {
                    chat = "\(message.displayName): Send you an File"
                }
            }
            notificationDelegate?.didReceiveNotification(type: .Chat(message:chat))
        }
    }
}

extension ActiveSpeakerMeetingViewModel: DytePluginEventsListener {
    public func onPluginMessage(plugin: DytePlugin, eventName: String, data: Any?) {
        
    }
    
    
    public func onPluginActivated(plugin: DytePlugin) {
        
        screenShareViewModel.refresh(plugins: self.dyteMobileClient.plugins.active, selectedPlugin: plugin)
        self.delegate?.refreshPluginsView()
    }
    
    public func onPluginDeactivated(plugin: DytePlugin) {
        
        screenShareViewModel.removed(plugin: plugin)
        self.delegate?.refreshPluginsView()
    }
    
    public func onPluginFileRequest(plugin: DytePlugin) {
        
    }
    
    public func onPluginMessage(message: [String : Kotlinx_serialization_jsonJsonElement]) {
        
    }
    
}
