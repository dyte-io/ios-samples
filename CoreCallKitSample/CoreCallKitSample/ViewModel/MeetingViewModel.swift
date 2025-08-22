//
//  MeetingViewModel.swift
//  iosApp
//
//  Created by Shaunak Jagtap on 18/08/22.
//  Copyright © 2022 orgName. All rights reserved.
//
import RealtimeKit
import UIKit

protocol MeetingDelegate {
    func refreshList()
    func onMeetingRoomLeft()
    func onMeetingRoomJoined()
    func onMeetingInitFailed()
}

protocol PluginDelegate {
    func refreshPluginView(plugin: RtkPlugin)
    func closePluginView()
}

protocol ChatDelegate {
    func refreshMessages()
}

protocol PollDelegate {
    func refreshPolls(pollMessages: [Poll])
}

protocol ParticipantsDelegate {
    func refreshList()
}

final class MeetingViewModel {
    private var rtkClient: RealtimeKitClient?

    init(rtkClient: RealtimeKitClient) {
        self.rtkClient = rtkClient
    }

    var meetingDelegate: MeetingDelegate?
    var pluginDelegate: PluginDelegate?
    var chatDelegate: ChatDelegate?
    var pollDelegate: PollDelegate?
    var participantsDelegate: ParticipantsDelegate?
    var participants = [RtkMeetingParticipant]()
    var screenshares = [RtkMeetingParticipant]()
    var participantDict = [String: UIView]()
    var isFrontCam = true

    private func refreshData() {
        participants.removeAll()
        if let array = rtkClient?.participants.joined {
            participants = array
            participants = participants.sorted(by: { $0.id > $1.id })
        }
        meetingDelegate?.refreshList()
        participantsDelegate?.refreshList()
    }

    private func refreshPolls(pollMessages: [Poll]) {
        pollDelegate?.refreshPolls(pollMessages: pollMessages)
    }

    private func refreshMessages() {
        chatDelegate?.refreshMessages()
    }
}

extension MeetingViewModel: RtkParticipantsEventListener {
    func onParticipantJoin(participant: RtkRemoteParticipant) {
        var peerExist = false
        let nib = UINib(nibName: "PeerCollectionViewCell", bundle: nil)
        if let videoView = nib.instantiate(withOwner: meetingDelegate, options: nil).first as? PeerCollectionViewCell {
            participantDict[participant.id] = videoView
        }

        for lParticipant in participants {
            if lParticipant.id == participant.id {
                peerExist = true
            }
        }
        if !peerExist {
            participant.addParticipantUpdateListener(participantUpdateListener: self)
            participants.append(participant)
            refreshData()
        }
    }

    func onParticipantLeave(participant: RtkRemoteParticipant) {
        if let index = participants.firstIndex(of: participant) {
            participants.remove(at: index)
            participantDict.removeValue(forKey: participant.id)
        }
        refreshData()
    }

    func onAudioUpdate(participant _: RtkRemoteParticipant, isEnabled _: Bool) {
        meetingDelegate?.refreshList()
        participantsDelegate?.refreshList()
    }

    func onVideoUpdate(participant _: RtkRemoteParticipant, isEnabled _: Bool) {
        meetingDelegate?.refreshList()
        participantsDelegate?.refreshList()
    }

    func onScreenShareUpdate(participant: RtkRemoteParticipant, isEnabled: Bool) {
        if isEnabled {
            if let screenShares = rtkClient?.participants.screenShares {
                for participant in screenShares {
                    screenshares.append(participant)
                }
                refreshData()
            }
        } else {
            screenshares.removeAll()
            if let screenShares = rtkClient?.participants.screenShares {
                for participant in screenShares {
                    screenshares.append(participant)
                }
                refreshData()
            }
        }
    }

    func onParticipantPinned(participant _: RtkRemoteParticipant) {
        refreshData()
    }

    func onParticipantUnpinned(participant _: RtkRemoteParticipant) {
        refreshData()
    }

    func onActiveParticipantsChanged(active _: [RtkRemoteParticipant]) {
        refreshData()
    }

    func onActiveSpeakerChanged(participant _: RtkRemoteParticipant?) {
        refreshData()
    }

    func onAllParticipantsUpdated(allParticipants _: [RtkParticipant]) {
        refreshData()
    }

    func onNewBroadcastMessage(type _: String, payload _: [String: Any]) {}

    func onUpdate(participants: RtkParticipants) {
        for participant in participants.joined {
            participantDict[participant.id] = UIView()
        }
        meetingDelegate?.refreshList()
        participantsDelegate?.refreshList()
        screenshares.removeAll()
        if let screenShares = rtkClient?.participants.screenShares {
            for participant in screenShares {
                screenshares.append(participant)
            }
            refreshData()
        }
    }
}

extension MeetingViewModel: RtkSelfEventListener {
    func onMeetingRoomJoinedWithoutCameraPermission() {
        meetingDelegate?.onMeetingRoomJoined()
    }

    func onMeetingRoomJoinedWithoutMicPermission() {
        meetingDelegate?.onMeetingRoomJoined()
    }

    func onAudioUpdate(isEnabled _: Bool) {
        meetingDelegate?.refreshList()
        participantsDelegate?.refreshList()
    }

    func onVideoUpdate(isEnabled _: Bool) {
        meetingDelegate?.refreshList()
        participantsDelegate?.refreshList()
    }

    func onScreenShareUpdate(isEnabled _: Bool) {}

    func onPinned() {}

    func onUnpinned() {}

    func onAudioDevicesUpdated() {}

    func onVideoDeviceChanged(videoDevice _: VideoDevice) {}

    func onWaitListStatusUpdate(waitListStatus _: WaitListStatus) {}

    func onUpdate(participant _: RtkSelfParticipant) {}

    func onRemovedFromMeeting() {}

    func onScreenShareStartFailed(reason _: String = "unknown") {}

    func onPermissionsUpdated(permission _: SelfPermissions) {}
}

extension MeetingViewModel: RtkChatEventListener {
    func onMessageRateLimitReset() {}

    func onChatUpdates(messages _: [ChatMessage]) {
        chatDelegate?.refreshMessages()
    }

    func onNewChatMessage(message _: ChatMessage) {
        // use to show noptifications
    }
}

extension MeetingViewModel: RtkMeetingRoomEventListener {
    func onMeetingInitStarted() {}

    func onMeetingInitCompleted(meeting _: RealtimeKitClient) {
        rtkClient?.localUser.setDisplayName(name: MeetingConfig.USER_NAME)
        rtkClient?.joinRoom(onSuccess: {}, onFailure: { _ in })
    }

    func onMeetingInitFailed(error: MeetingError) {
        print("Error: onMeetingInitFailed: \(error.message)")
        meetingDelegate?.onMeetingInitFailed()
    }

    func onMeetingRoomJoinStarted() {}

    func onMeetingRoomJoinCompleted(meeting _: RealtimeKitClient) {
        meetingDelegate?.onMeetingRoomJoined()
    }

    func onMeetingRoomJoinFailed(error: MeetingError) {
        print("Error: onMeetingRoomJoinFailed: \(error.message)")
    }

    func onMeetingRoomLeaveStarted() {}

    func onMeetingRoomLeaveCompleted() {
        meetingDelegate?.onMeetingRoomLeft()
    }

    func onMeetingEnded() {
        participantDict.removeAll()
        participants.removeAll()
    }

    func onActiveTabUpdate(meeting _: RealtimeKitClient, activeTab _: ActiveTab) {}

    func onMediaConnectionUpdate(update _: MediaConnectionUpdate) {}

    func onSocketConnectionUpdate(newState _: SocketConnectionState) {}
}

extension MeetingViewModel: RtkParticipantUpdateListener {
    func onAudioUpdate(participant _: RtkMeetingParticipant, isEnabled _: Bool) {}

    func onVideoUpdate(participant _: RtkMeetingParticipant, isEnabled _: Bool) {}

    func onPinned(participant _: RtkMeetingParticipant) {}

    func onUnpinned(participant _: RtkMeetingParticipant) {}

    func onScreenShareUpdate(participant _: RtkMeetingParticipant, isEnabled _: Bool) {}

    func onUpdate(participant _: RtkMeetingParticipant) {}
}

extension MeetingViewModel: RtkPluginsEventListener {
    func onPluginMessage(plugin _: RtkPlugin, eventName _: String, data _: Any?) {}

    func onPluginActivated(plugin: RtkPlugin) {
        pluginDelegate?.refreshPluginView(plugin: plugin)
    }

    func onPluginDeactivated(plugin _: RtkPlugin) {
        pluginDelegate?.closePluginView()
    }

    func onPluginFileRequest(plugin _: RtkPlugin) {}

    func onPluginMessage(message _: [String: Kotlinx_serialization_jsonJsonElement]) {}
}
