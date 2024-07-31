//
//  MeetingRoomViewController.swift
//  iosApp
//
//  Created by Shaunak Jagtap on 06/07/22.
//  Copyright © 2022 orgName. All rights reserved.
//

import UIKit
import DyteiOSCore
import AVKit
import CallKit

class MeetingRoomViewController: UIViewController {
    
    @IBOutlet weak var screenshareView: UIView!
    @IBOutlet weak var screenshareCollectionView: UICollectionView!
    @IBOutlet weak var meetingImageView: UIImageView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var participantsStatusButton: UIButton!
    @IBOutlet weak var videoContainer: UIView!
    @IBOutlet weak var meetingStartedAtLabel: UILabel!
    @IBOutlet weak var meetingTitleLabel: UILabel!
    @IBOutlet weak var pollsButton: UIButton!
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var participantsButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var recordMeetingButton: UIButton!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var videoToggleButton: UIButton!
    @IBOutlet weak var audioToggleButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var moreStack: UIStackView!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var screenshareStackView: UIStackView!
    
    private var meetingViewModel: MeetingViewModel?
    private var dyteMobileClient: DyteMobileClient?
    private var nextPageOffset = 6
    private var page = 0
    private var meetingMinutes = 0
    private var selectedScreenShareIndex: Int? = nil
    private var callManager = CallManager()

    var meetingInfo: DyteMeetingInfoV2?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.showActivityIndicator()
        setupUI()
        dyteMobileClientInit()
        setupCallKit()
    }
    
    private func setupUI() {
        screenshareStackView.isHidden = true
        screenshareView.isHidden = true
        moreStack.isHidden = true
        pageControl.isHidden = true
        participantsStatusButton.setTitle("\(meetingViewModel?.participants.count ?? 0)", for: .normal)
        moreButton.setTitle("", for: .normal)
        audioToggleButton.setTitle("", for: .normal)
        recordButton.setTitle("", for: .normal)
        recordButton.isHidden = false
        disconnectButton.setTitle("", for: .normal)
        videoToggleButton.setTitle("", for: .normal)
        cameraButton.setTitle("", for: .normal)
        
        screenshareCollectionView.register(UINib(nibName: "ScreenshareCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ScreenshareCollectionViewCell")
    }
    
    private func setupCallKit() {
        callManager.provider.setDelegate(self, queue: nil)
    }
    
    private func routeChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let value = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: value) else { return }
        
        switch reason {
        case .categoryChange, .oldDeviceUnavailable:
            try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
        default:
            print("Error: other reason for speaker route change!")
        }
    }
    
    private func dyteMobileClientInit() {
        NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: nil, using: routeChange)
        
        if let info = meetingInfo {
            callManager.startCall(handle: "Alex", meetingInfo: info)
            dyteMobileClient = callManager.dyteClient?.dyteMobileClient
            if let mobileClient = dyteMobileClient {
                meetingViewModel = MeetingViewModel(dyteClient: mobileClient)
                if let meetingModel = meetingViewModel {
                    meetingModel.meetingDelegate = self
                    dyteMobileClient?.addMeetingRoomEventsListener(meetingRoomEventsListener: meetingModel)
                    dyteMobileClient?.addParticipantEventsListener(participantEventsListener: meetingModel)
                    dyteMobileClient?.addSelfEventsListener(selfEventsListener: meetingModel)
                    dyteMobileClient?.addParticipantEventsListener(participantEventsListener: meetingModel)
                    dyteMobileClient?.addChatEventsListener(chatEventsListener: meetingModel)
                } else {
                    print("Error: meetingModel is nil!")
                }
            } else {
                print("Error: mobileClient is nil!")
            }
        } else {
            print("Error: dyteMobileClient failed!")
        }
    }
    
    private func refreshMessages() {
        if let chatMessages = dyteMobileClient?.chat.messages as? [DyteChatMessage], let msg = chatMessages.last {
            print("chat by: \(msg.displayName) : \(msg.type)")
        }
    }
    
    @IBAction func cancelMoreStack(_ sender: Any) {
        moreStack.isHidden = true
    }
    
    @IBAction func moreAction(_ sender: Any) {
        moreStack.isHidden = false
    }
    
    @IBAction func pollsAction(_ sender: Any) {
        let storyBoard = UIStoryboard(name: "Storyboard", bundle: nil)
        if let pollsViewController = storyBoard.instantiateViewController(withIdentifier: "PollsViewController") as? PollsViewController {
            pollsViewController.dyteMobileClient = dyteMobileClient
            pollsViewController.meetingViewModel = meetingViewModel
            self.present(pollsViewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func chatAction(_ sender: Any) {
        let storyBoard = UIStoryboard(name: "Storyboard", bundle: nil)
        if let chatViewController = storyBoard.instantiateViewController(withIdentifier: "ChatViewController") as? ChatViewController {
            chatViewController.dyteMobileClient = dyteMobileClient
            chatViewController.modalPresentationStyle = .fullScreen
            chatViewController.meetingViewModel = meetingViewModel
            self.present(chatViewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func participatsAction(_ sender: Any) {
        let storyBoard = UIStoryboard(name: "Storyboard", bundle: nil)
        if let participantsViewController = storyBoard.instantiateViewController(withIdentifier: "ParticipantsViewController") as? ParticipantsViewController {
            participantsViewController.dyteMobileClient = dyteMobileClient
            participantsViewController.meetingViewModel = meetingViewModel
            self.present(participantsViewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func settingsAction(_ sender: Any) {
        if let localUser = dyteMobileClient?.localUser {
            let shouldShowGlobalHostControlOptions = DyteUtils.canLocalUserDisableParticipantAudio(localUser) || DyteUtils.canLocalUserDisableParticipantVideo(localUser) || DyteUtils.canLocalUserKickParticipant(localUser)
            
            if shouldShowGlobalHostControlOptions {
                showGlobalHostControlOptions()
            } else {
                showNormalAlert(withTitle: "Not allowed", havingMessage: "You do not have the host permissions.")
            }
        }
    }
    
    @IBAction func leaveRoom(_ sender: Any) {
        let alert = UIAlertController(title: "Leave call?", message: "Do you really want to leave this awesome call?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { action in
            self.dyteMobileClient?.leaveRoom()
            self.callManager.dyteClient?.leaveMeeting()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func videoToggleAction(_ sender: Any) {
        if self.dyteMobileClient?.localUser.videoEnabled ?? false {
            try? self.dyteMobileClient?.localUser.disableVideo()
        } else {
            self.dyteMobileClient?.localUser.enableVideo()
        }
    }
    
    @IBAction func switchCameraAction(_ sender: Any) {
        if self.meetingViewModel?.isFrontCam ?? false {
            self.meetingViewModel?.isFrontCam = false
            cameraButton.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera.fill"), for: .normal)
        } else {
            self.meetingViewModel?.isFrontCam = true
            cameraButton.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)
        }
        
        DispatchQueue.main.async { [weak self] in
            if let devices = self?.dyteMobileClient?.localUser.getVideoDevices() {
                for device in devices {
                    if device.type != self?.dyteMobileClient?.localUser.getSelectedVideoDevice()?.type {
                        self?.dyteMobileClient?.localUser.setVideoDevice(dyteVideoDevice: device)
                        break
                    }
                }
            }
        }
    }
    
    @IBAction func recordAction(_ sender: Any) {
        Task { @MainActor in
            if dyteMobileClient?.recording.recordingState == .recording {
                dyteMobileClient?.recording.stop()
                self.recordButton.setImage(UIImage(systemName: "record.circle"), for: .normal)
                self.recordMeetingButton.setTitle("Record", for: .normal)
            } else {
                dyteMobileClient?.recording.start()
                self.recordMeetingButton.setTitle("Stop Recording", for: .normal)
                self.recordMeetingButton.setImage(UIImage(systemName: "record.circle.fill"), for: .normal)
            }
        }
    }
    
    @IBAction func audioToggleAction(_ sender: Any) {
        Task { @MainActor in
            if self.dyteMobileClient?.localUser.audioEnabled ?? false {
                try? self.dyteMobileClient?.localUser.disableAudio()
            } else {
                self.dyteMobileClient?.localUser.enableAudio()
            }
        }
    }
    
    private func showGlobalHostControlOptions() {
        if let localUser = dyteMobileClient?.localUser {
            var alertActions: [UIAlertAction] = []
            
            if DyteUtils.canLocalUserDisableParticipantAudio(localUser) {
                let muteAudioAction = UIAlertAction(title: "Mute all", style: .default) { _ in
                    self.dyteMobileClient?.participants.disableAllAudio()
                }
                alertActions.append(muteAudioAction)
            }
            
            if DyteUtils.canLocalUserDisableParticipantVideo(localUser) {
                let turnOffVideoAction = UIAlertAction(title: "Turn off video for all", style: .default) { _ in
                    try? self.dyteMobileClient?.participants.disableAllVideo()
                }
                alertActions.append(turnOffVideoAction)
            }
            
            if DyteUtils.canLocalUserKickParticipant(localUser) {
                let kickParticipantAction = UIAlertAction(title: "Kick all", style: .destructive) { _ in
                    self.dyteMobileClient?.participants.kickAll()
                }
                alertActions.append(kickParticipantAction)
            }
            
            if !alertActions.isEmpty {
                let hostControlsActionSheet = UIAlertController(title: "Host Controls", message: "", preferredStyle: .actionSheet)
                alertActions.forEach { hostControlsActionSheet.addAction($0) }
                hostControlsActionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                self.present(hostControlsActionSheet, animated: true)
            }
        }
    }
}

extension MeetingRoomViewController: MeetingDelegate {
    
    func onMeetingInitFailed() {
        let alert = UIAlertController(title: Constants.errorTitle, message: "Meeting Initialization Failed", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.onMeetingRoomLeft()
        })
        self.present(alert, animated: true, completion: nil)
    }
    
    func onMeetingRoomJoined() {
        self.meetingTitleLabel.text = dyteMobileClient?.meta.meetingTitle
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        if let dateObj = dateFormatter.date(from: dyteMobileClient?.meta.meetingStartedTimestamp ?? "") {
            let date = Date()
            let difference = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: dateObj, to: date)
            meetingMinutes = (difference.minute ?? 0) - 30
            Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        }
        
        ImageLoader.shared.obtainImageWithPath(imagePath: "https://dyte.io/images/Yellow.ai.png") { [weak self] image in
            self?.meetingImageView.image = image
        }
        
        self.view.hideActivityIndicator()
    }
    
    @objc func timerAction() {
        meetingMinutes += 1
        self.meetingStartedAtLabel.text = "\(meetingMinutes) Mins"
    }
    
    func onMeetingRoomLeft() {
        DispatchQueue.main.async { [weak self] in
            self?.dismiss(animated: true)
        }
    }
    
    func refreshList() {
        if meetingViewModel?.screenshares.count ?? 0 > 0 {
            self.screenshareStackView.isHidden = false
            self.screenshareCollectionView.reloadData()
        } else {
            self.screenshareView.isHidden = true
            self.screenshareStackView.isHidden = true
        }
        
        if self.dyteMobileClient?.localUser.videoEnabled ?? false {
            videoToggleButton.setImage(UIImage(systemName: "video"), for: .normal)
        } else {
            videoToggleButton.setImage(UIImage(systemName: "video.slash"), for: .normal)
        }
        
        if self.dyteMobileClient?.localUser.audioEnabled ?? false {
            self.audioToggleButton.setImage(UIImage(systemName: "mic"), for: .normal)
        } else {
            self.audioToggleButton.setImage(UIImage(systemName: "mic.slash"), for: .normal)
        }
        
        participantsStatusButton.setTitle("\(meetingViewModel?.participants.count ?? 0)", for: .normal)
        recordMeetingButton.isHidden = !(self.dyteMobileClient?.localUser.permissions.host.canTriggerRecording ?? false)
        
        if dyteMobileClient?.recording.recordingState == .recording {
            recordButton.blink()
            recordMeetingButton.setImage(UIImage(systemName: "record.circle.fill"), for: .normal)
            recordButton.isHidden = false
        } else {
            recordMeetingButton.setImage(UIImage(systemName: "record.circle"), for: .normal)
            recordButton.isHidden = true
            recordButton.stopBlink()
        }
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(rerenderParticipants), object: nil)
        self.perform(#selector(rerenderParticipants), with: nil, afterDelay: 0.5)
    }
    
    @objc private func rerenderParticipants() {
        videoContainer.subviews.forEach { $0.removeFromSuperview() }
        
        guard let participants = dyteMobileClient?.participants.active else { return }
        
        let participantCount = participants.count
        switch participantCount {
        case 0: return
        case 1:
            let selfVideoView = getSelfVideo()
            selfVideoView.frame = videoContainer.bounds
            videoContainer.addSubview(selfVideoView)
        case 2:
            let twoUsersView = TwoUsersView(frame: videoContainer.bounds)
            twoUsersView.setupUI()
            twoUsersView.renderUI(participants: participants)
            videoContainer.addSubview(twoUsersView)
        case 3:
            let threeUsersView = ThreeUsersView(frame: videoContainer.bounds)
            threeUsersView.setupUI()
            threeUsersView.renderUI(participants: participants)
            videoContainer.addSubview(threeUsersView)
        case 4:
            let fourPeerView = FourPeerView(frame: videoContainer.bounds)
            fourPeerView.setupUI()
            fourPeerView.renderUI(participants: participants)
            videoContainer.addSubview(fourPeerView)
        case 5:
            let fivePeerView = FivePeerView(frame: videoContainer.bounds)
            fivePeerView.setupUI()
            fivePeerView.renderUI(participants: participants)
            videoContainer.addSubview(fivePeerView)
        case 6:
            let sixPeerView = SixPeerView(frame: videoContainer.bounds)
            sixPeerView.setupUI()
            sixPeerView.renderUI(participants: participants)
            videoContainer.addSubview(sixPeerView)
        default:
            pageControl.isHidden = false
            let sixPeerView = SixPeerView(frame: videoContainer.bounds)
            sixPeerView.setupUI()
            sixPeerView.renderUI(participants: participants)
            videoContainer.addSubview(sixPeerView)
        }
        self.videoContainer.layoutIfNeeded()
    }
    
    private func setSelfVideo(selfVideoView: PeerCollectionViewCell) {
        if let user = dyteMobileClient?.localUser {
            let selfView = user.getSelfPreview()
            selfView.frame = selfVideoView.videoView.bounds
            selfVideoView.videoView.addSubview(selfView)
            selfVideoView.nameLabel.text = user.name
            selfVideoView.statusStack.isHidden = true
        }
    }
    
    private func getSelfVideo() -> PeerCollectionViewCell {
        if let selfVideoView = meetingViewModel?.participantDict[dyteMobileClient?.localUser.id ?? ""] as? PeerCollectionViewCell {
            setSelfVideo(selfVideoView: selfVideoView)
            return selfVideoView
        } else {
            let nib = UINib(nibName: "PeerCollectionViewCell", bundle: nil)
            if let selfVideoView = nib.instantiate(withOwner: self, options: nil).first as? PeerCollectionViewCell {
                setSelfVideo(selfVideoView: selfVideoView)
                meetingViewModel?.participantDict[dyteMobileClient?.localUser.id ?? ""] = selfVideoView
                return selfVideoView
            }
        }
        return PeerCollectionViewCell()
    }
}

extension MeetingRoomViewController: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        // Handle provider reset
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        action.fulfill()
        callManager.dyteClient?.joinMeeting { success, error in
            if let error = error {
                print("Error answering Dyte meeting: \(error)")
            } else if success {
                print("Successfully answered Dyte meeting")
            }
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        action.fulfill()
        callManager.dyteClient?.leaveMeeting()
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        action.fulfill()
        callManager.dyteClient?.joinMeeting { success, error in
            if let error = error {
                print("Error starting Dyte meeting: \(error)")
            } else if success {
                print("Successfully started Dyte meeting")
            }
        }
    }
}

extension MeetingRoomViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return meetingViewModel?.screenshares.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ScreenshareCollectionViewCell", for: indexPath) as? ScreenshareCollectionViewCell,
           let screenshare = meetingViewModel?.screenshares[indexPath.row] {
            cell.backgroundColor = (selectedScreenShareIndex == indexPath.row) ? .green : .clear
            cell.ssLabel.text = screenshare.name
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let index = selectedScreenShareIndex, screenshareView.isHidden == false, index == indexPath.row {
            screenshareView.isHidden = true
            refreshList()
        } else if let index = selectedScreenShareIndex, screenshareView.isHidden == true, index == indexPath.row {
            screenshareView.isHidden = false
        } else {
            selectedScreenShareIndex = indexPath.row
            screenshareView.isHidden = false
            refreshList()
        }
    }
}

