import AVKit
import CallKit
import RealtimeKit
import ReplayKit
import UIKit
import WebKit

class MeetingRoomViewController: UIViewController {
    @IBOutlet var screenshareView: UIView!
    @IBOutlet var screenshareCollectionView: UICollectionView!
    @IBOutlet var meetingImageView: UIImageView!
    @IBOutlet var pageControl: UIPageControl!
    @IBOutlet var participantsStatusButton: UIButton!
    @IBOutlet var videoContainer: UIView!
    @IBOutlet var meetingStartedAtLabel: UILabel!
    @IBOutlet var meetingTitleLabel: UILabel!
    @IBOutlet var pollsButton: UIButton!
    @IBOutlet var chatButton: UIButton!
    @IBOutlet var participantsButton: UIButton!
    @IBOutlet var settingsButton: UIButton!
    @IBOutlet var recordMeetingButton: UIButton!
    @IBOutlet var disconnectButton: UIButton!
    @IBOutlet var cameraButton: UIButton!
    @IBOutlet var videoToggleButton: UIButton!
    @IBOutlet var audioToggleButton: UIButton!
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var moreStack: UIStackView!
    @IBOutlet var moreButton: UIButton!
    @IBOutlet var screenshareStackView: UIStackView!

    private var webView: UIView?
    private var meetingViewModel: MeetingViewModel?
    private var rtkClient: RealtimeKitClient?
    private var nextPageOffset = 6
    private var page = 0
    private var meetingMinutes = 0
    private var selectedScreenShareIndex: Int?
    private var callManager = CallManager()

    var meetingInfo: RtkMeetingInfo?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.showActivityIndicator()
        setupUI()
        rtkClientInit()
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

    private func rtkClientInit() {
        NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: nil, using: routeChange)

        if let info = meetingInfo {
            callManager.startCall(handle: "Alex", meetingInfo: info)
            rtkClient = callManager.rtkClient?.rtkClient
            if let mobileClient = rtkClient {
                meetingViewModel = MeetingViewModel(rtkClient: mobileClient)
                if let meetingModel = meetingViewModel {
                    meetingModel.meetingDelegate = self
                    rtkClient?.addMeetingRoomEventListener(meetingRoomEventListener: meetingModel)
                    rtkClient?.addSelfEventListener(selfEventListener: meetingModel)
                    rtkClient?.addParticipantsEventListener(participantsEventListener: meetingModel)
                    rtkClient?.doInit(meetingInfo: info, onSuccess: {}, onFailure: { _ in })
                } else {
                    print("Error: meetingModel is nil!")
                }
            } else {
                print("Error: mobileClient is nil!")
            }
        } else {
            print("Error: rtkClient failed!")
        }
    }

    private func refreshMessages() {
        if let chatMessages = rtkClient?.chat.messages as? [ChatMessage] {
            if let msg = chatMessages.last {
                print("chat by: \(msg.displayName) : \(msg.type)")
            }
        }
    }

    @IBAction func cancelMoreStack(_: Any) {
        moreStack.isHidden = true
    }

    @IBAction func moreAction(_: Any) {
        moreStack.isHidden = !moreStack.isHidden
    }

    @IBAction func pollsAction(_: Any) {
        let storyBoard = UIStoryboard(name: "Storyboard", bundle: nil)
        let pollsViewController = storyBoard.instantiateViewController(withIdentifier: "PollsViewController") as! PollsViewController
        pollsViewController.rtkClient = rtkClient
        pollsViewController.meetingViewModel = meetingViewModel
        present(pollsViewController, animated: true, completion: nil)
    }

    @IBAction func screenshareAction(_: Any) {
        let screenShareExtensionId = Bundle.main.infoDictionary?["RTKRTCScreenSharingExtension"] as? String
        let view = RPSystemBroadcastPickerView()
        view.preferredExtension = screenShareExtensionId
        view.showsMicrophoneButton = false
        let selector = NSSelectorFromString("buttonPressed:")
        if view.responds(to: selector) {
            view.perform(selector, with: nil)
        }
        rtkClient?.localUser.enableScreenShare()
    }

    @IBAction func chatAction(_: Any) {
        let storyBoard = UIStoryboard(name: "Storyboard", bundle: nil)
        let chatViewController = storyBoard.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
        chatViewController.rtkClient = rtkClient
        chatViewController.modalPresentationStyle = .fullScreen
        chatViewController.meetingViewModel = meetingViewModel
        present(chatViewController, animated: true, completion: nil)
    }

    @IBAction func participantAction(_: Any) {
        let storyBoard = UIStoryboard(name: "Storyboard", bundle: nil)
        let participantsViewController = storyBoard.instantiateViewController(withIdentifier: "ParticipantsViewController") as! ParticipantsViewController
        participantsViewController.rtkClient = rtkClient
        participantsViewController.meetingViewModel = meetingViewModel
        present(participantsViewController, animated: true, completion: nil)
    }

    @IBAction func settingsAction(_: Any) {
        if let localUser = rtkClient?.localUser {
            let shouldShowGlobalHostControlOptions = RtkUtils.canLocalUserDisableParticipantAudio(localUser) || RtkUtils.canLocalUserDisableParticipantVideo(localUser) || RtkUtils.canLocalUserKickParticipant(localUser)

            if shouldShowGlobalHostControlOptions {
                showGlobalHostControlOptions()
            } else {
                showNormalAlert(withTitle: "Not allowed", havingMessage: "You do not have the host permissions.")
            }
        }
    }

    @IBAction func leaveRoom(_: Any) {
        let alert = UIAlertController(title: "Leave call?", message: "Do you really want to leave this awesome call?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.rtkClient?.leaveRoom(onSuccess: {}, onFailure: { _ in })
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
        }))
        present(alert, animated: true, completion: nil)
    }

    @IBAction func videoToggleAction(_: Any) {
        if rtkClient?.localUser.videoEnabled ?? false {
            rtkClient?.localUser.disableVideo { error in
                if let error = error {
                    print("Error: \(error.message)")
                }
            }
        } else {
            rtkClient?.localUser.enableVideo { error in
                if let error = error {
                    print("Error: \(error.message)")
                }
            }
        }
    }

    @IBAction func switchCameraAction(_: Any) {
        if meetingViewModel?.isFrontCam ?? false {
            meetingViewModel?.isFrontCam = false
            cameraButton.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera.fill"), for: .normal)
        } else {
            meetingViewModel?.isFrontCam = true
            cameraButton.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)
        }

        DispatchQueue.main.async { [weak self] in
            if let devices = self?.rtkClient?.localUser.getVideoDevices() {
                for device in devices {
                    if device.type != self?.rtkClient?.localUser.getSelectedVideoDevice()?.type {
                        self?.rtkClient?.localUser.setVideoDevice(rtkVideoDevice: device)
                        break
                    }
                }
            }
        }
    }

    @IBAction func recordAction(_: Any) {
        Task { @MainActor in
            if rtkClient?.recording.recordingState == .recording {
                rtkClient?.recording.stop(onResult: { error in
                    if error == nil {
                        self.recordButton.setImage(UIImage(systemName: "record.circle"), for: .normal)
                        self.recordMeetingButton.setTitle("Record", for: .normal)
                    }

                })

            } else {
                rtkClient?.recording.start(onResult: { error in
                    if error == nil {
                        self.recordMeetingButton.setTitle("Stop Recording", for: .normal)
                        self.recordMeetingButton.setImage(UIImage(systemName: "record.circle.fill"), for: .normal)
                    }
                })
            }
        }
    }

    @IBAction func audioToggleAction(_: Any) {
        Task { @MainActor in
            if self.rtkClient?.localUser.audioEnabled ?? false {
                self.rtkClient?.localUser.disableAudio { err in
                    if let error = err {
                        print("Error: \(error.message)")
                    }
                }
            } else {
                self.rtkClient?.localUser.enableAudio { err in
                    if let error = err {
                        print("Error: \(error.message)")
                    }
                }
            }
        }
    }

    private func showGlobalHostControlOptions() {
        if let localUser = rtkClient?.localUser {
            var alertActions: [UIAlertAction] = []

            if RtkUtils.canLocalUserDisableParticipantAudio(localUser) {
                let muteAudioAction = UIAlertAction(title: "Mute all", style: .default) { _ in
                    self.rtkClient?.participants.disableAllAudio()
                }
                alertActions.append(muteAudioAction)
            }

            if RtkUtils.canLocalUserDisableParticipantVideo(localUser) {
                let turnOffVideoAction = UIAlertAction(title: "Turn off video for all", style: .default) { _ in
                    self.rtkClient?.participants.disableAllVideo()
                }
                alertActions.append(turnOffVideoAction)
            }

            if RtkUtils.canLocalUserKickParticipant(localUser) {
                let kickParticipantAction = UIAlertAction(title: "Kick all", style: .destructive) { _ in
                    self.rtkClient?.participants.kickAll()
                }
                alertActions.append(kickParticipantAction)
            }

            if !alertActions.isEmpty {
                let hostControlsActionSheet = UIAlertController(title: "Host Controls", message: "", preferredStyle: .actionSheet)

                for action in alertActions {
                    hostControlsActionSheet.addAction(action)
                }
                hostControlsActionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

                present(hostControlsActionSheet, animated: true)
            }
        }
    }
}

extension MeetingRoomViewController: MeetingDelegate {
    func onMeetingInitFailed() {
        let alert = UIAlertController(title: Constants.errorTitle, message: "Meeting Initialization Failed", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
            self?.onMeetingRoomLeft()
        }))

        present(alert, animated: true, completion: nil)
    }

    func onMeetingRoomJoined() {
        rtkClient?.addChatEventListener(chatEventListener: meetingViewModel!)
        meetingTitleLabel.text = rtkClient?.meta.meetingTitle

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        if let dateObj = dateFormatter.date(from: rtkClient?.meta.meetingStartedTimestamp ?? "") {
            let date = Date()
            let difference = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: dateObj, to: date)

            meetingMinutes = (difference.minute ?? 0) - 30

            Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        }

        ImageLoader.shared.obtainImageWithPath(imagePath: "https://dyte.io/images/Yellow.ai.png") { [weak self] image in
            self?.meetingImageView.image = image
        }

        view.hideActivityIndicator()
    }

    @objc func timerAction() {
        meetingMinutes = meetingMinutes + 1
        meetingStartedAtLabel.text = "\(meetingMinutes) Mins"
    }

    func onMeetingRoomLeft() {
        DispatchQueue.main.async { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    func refreshList() {
        if meetingViewModel?.screenshares.count ?? 0 > 0 {
            screenshareStackView.isHidden = false
            screenshareCollectionView.reloadData()
        } else {
            screenshareView.isHidden = true
            screenshareStackView.isHidden = true
        }

        if rtkClient?.localUser.videoEnabled ?? false {
            videoToggleButton.setImage(UIImage(systemName: "video"), for: .normal)
        } else {
            videoToggleButton.setImage(UIImage(systemName: "video.slash"), for: .normal)
        }

        if rtkClient?.localUser.audioEnabled ?? false {
            audioToggleButton.setImage(UIImage(systemName: "mic"), for: .normal)
        } else {
            audioToggleButton.setImage(UIImage(systemName: "mic.slash"), for: .normal)
        }

        participantsStatusButton.setTitle("\(meetingViewModel?.participants.count ?? 0)", for: .normal)
        recordMeetingButton.isHidden = !(rtkClient?.localUser.permissions.host.canTriggerRecording ?? false)

        if rtkClient?.recording.recordingState == .recording {
            recordButton.blink()
            recordMeetingButton.setImage(UIImage(systemName: "record.circle.fill"), for: .normal)
            recordButton.isHidden = false
        } else {
            recordMeetingButton.setImage(UIImage(systemName: "record.circle"), for: .normal)
            recordButton.isHidden = true
            recordButton.stopBlink()
        }
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(rerenderParticipants), object: nil)

        perform(#selector(rerenderParticipants), with: nil, afterDelay: 0.5)
    }

    @objc private func rerenderParticipants() {
        for subview in videoContainer.subviews {
            subview.removeFromSuperview()
        }

        let participantCount = rtkClient?.participants.active.count ?? 1
        let participants = rtkClient?.participants.active

        switch participantCount {
        case 0:
            return
        case 1:
            let selfVideoView = getSelfVideo()
            selfVideoView.frame = videoContainer.bounds
            videoContainer.addSubview(selfVideoView)
        case 2:
            let twoUsersView = TwoUsersView(frame: videoContainer.bounds)
            twoUsersView.setupUI()
            twoUsersView.renderUI(participants: participants ?? [])
            videoContainer.addSubview(twoUsersView)
        case 3:
            let threeUsersView = ThreeUsersView(frame: videoContainer.bounds)
            threeUsersView.setupUI()
            threeUsersView.renderUI(participants: participants ?? [])
            videoContainer.addSubview(threeUsersView)
        case 4:
            let fourPeerView = FourPeerView(frame: videoContainer.bounds)
            fourPeerView.setupUI()
            fourPeerView.renderUI(participants: participants ?? [])
            videoContainer.addSubview(fourPeerView)
        case 5:
            let fivePeerView = FivePeerView(frame: videoContainer.bounds)
            fivePeerView.setupUI()
            fivePeerView.renderUI(participants: participants ?? [])
            videoContainer.addSubview(fivePeerView)
        case 6:
            let sixPeerView = SixPeerView(frame: videoContainer.bounds)
            sixPeerView.setupUI()
            sixPeerView.renderUI(participants: participants ?? [])
            videoContainer.addSubview(sixPeerView)
        default:
            pageControl.isHidden = false
            let sixPeerView = SixPeerView(frame: videoContainer.bounds)
            sixPeerView.setupUI()
            sixPeerView.renderUI(participants: participants ?? [])
            videoContainer.addSubview(sixPeerView)
        }
        videoContainer.layoutIfNeeded()
    }

    private func setSelfVideo(selfVideoView: PeerCollectionViewCell) {
        if let user = rtkClient?.localUser {
            guard let selfView = user.getSelfPreview() else { return }
            selfView.frame = selfVideoView.videoView.bounds
            selfVideoView.videoView.addSubview(selfView)

            selfVideoView.nameLabel.text = rtkClient?.localUser.name
            selfVideoView.statusStack.isHidden = true
        }
    }

    private func getSelfVideo() -> PeerCollectionViewCell {
        if let selfVideoView = meetingViewModel?.participantDict[rtkClient?.localUser.id ?? ""] as? PeerCollectionViewCell {
            setSelfVideo(selfVideoView: selfVideoView)
            return selfVideoView
        } else {
            let nib = UINib(nibName: "PeerCollectionViewCell", bundle: nil)
            if let selfVideoView = nib.instantiate(withOwner: self, options: nil).first as? PeerCollectionViewCell {
                setSelfVideo(selfVideoView: selfVideoView)
                meetingViewModel?.participantDict[rtkClient?.localUser.id ?? ""] = selfVideoView
                return selfVideoView
            }
        }
        return PeerCollectionViewCell()
    }
}

extension MeetingRoomViewController: CXProviderDelegate {
    func providerDidReset(_: CXProvider) {
        // Handle provider reset
    }

    func provider(_: CXProvider, perform action: CXAnswerCallAction) {
        action.fulfill()
        callManager.rtkClient?.joinMeeting { success, error in
            if let error = error {
                print("Error answering Dyte meeting: \(error)")
            } else if success {
                print("Successfully answered Dyte meeting")
            }
        }

        func provider(_: CXProvider, perform action: CXEndCallAction) {
            action.fulfill()
            callManager.rtkClient?.leaveMeeting()
        }

        func provider(_: CXProvider, perform action: CXStartCallAction) {
            action.fulfill()
            callManager.rtkClient?.joinMeeting { success, error in
                if let error = error {
                    print("Error starting Dyte meeting: \(error)")
                } else if success {
                    print("Successfully started Dyte meeting")
                }
            }
        }
    }
}

extension MeetingRoomViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        meetingViewModel?.screenshares.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ScreenshareCollectionViewCell", for: indexPath as IndexPath) as? ScreenshareCollectionViewCell, (meetingViewModel?.screenshares.count ?? 0) > indexPath.row, let screenshare = meetingViewModel?.screenshares[indexPath.row] {
            if let index = selectedScreenShareIndex, index == indexPath.row {
                cell.backgroundColor = .green
            } else {
                cell.backgroundColor = .clear
            }

            cell.ssLabel.text = screenshare.name
            return cell
        }
        return UICollectionViewCell(frame: .zero)
    }

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let index = selectedScreenShareIndex, screenshareView.isHidden == false, index == indexPath.row {
            screenshareView.isHidden = true
            refreshList()
            return
        } else if let index = selectedScreenShareIndex, screenshareView.isHidden == true, index == indexPath.row {
            screenshareView.isHidden = false
        } else {
            for subview in screenshareView.subviews {
                selectedScreenShareIndex = nil
                subview.removeFromSuperview()
            }

            if (meetingViewModel?.screenshares.count ?? 0) > indexPath.row, let ssParticipant = meetingViewModel?.screenshares[indexPath.row], let ssView = ssParticipant.getScreenShareVideoView() {
                ssView.frame = screenshareView.bounds
                screenshareView.addSubview(ssView)
                selectedScreenShareIndex = indexPath.row
                screenshareView.isHidden = false
            }
        }
        refreshList()
    }
}
