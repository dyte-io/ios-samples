//
//  ActiveSpeakerMeetingViewController.swift
//  active-speaker-ui-sample
//
//  Created by Dyte on 23/01/24.
//

import RealtimeKit
import RealtimeKitUI
import UIKit

enum Animations {
    static let gridViewAnimationDuration = 0.3
}

public class ActiveSpeakerMeetingViewController: RtkBaseMeetingViewController {
    private var gridView: GridView<RtkParticipantTileContainerView>!
    let pluginScreenShareView: RtkPluginsView
    var activePeerView: RtkParticipantTileView?
    var activePeerBaseView: UIView?

    var panGesture = UIPanGestureRecognizer()
    let gridBaseView = UIView()
    private let pluginBaseView = UIView()
    private let splitContentBaseView = UIView()

    private var fullScreenView: FullScreenView!

    let baseContentView = UIView()

    private var isPluginOrScreenShareActive = false

    let fullScreenButton: RtkControlBarButton = {
        let button = RtkControlBarButton(image: RtkImage(image: ImageProvider.image(named: "icon_show_fullscreen")))
        button.setSelected(image: RtkImage(image: ImageProvider.image(named: "icon_hide_fullscreen")))
        button.backgroundColor = rtkSharedTokenColor.background.shade800
        return button
    }()

    let viewModel: ActiveSpeakerMeetingViewModel

    private var topBar: RtkMeetingHeaderView!
    private var bottomBar: ActiveSpeakerMeetingControlBar!

    let onFinishedMeeting: () -> Void
    private var viewWillAppear = false

    var moreButtonBottomBar: RtkControlBarButton?

    private var layoutPortraitContraintPluginBaseZeroHeight: NSLayoutConstraint!
    private var layoutPortraitContraintPluginBaseVariableHeight: NSLayoutConstraint!

    private var layoutLandscapeContraintGridZeroWidth: NSLayoutConstraint!
    private var layoutPortraitContraintSplitContentViewZeroHeight: NSLayoutConstraint!
    private var layoutLandscapeContraintSplitContentViewZeroWidth: NSLayoutConstraint!
    private var layoutLandscapeContraintSplitContentViewNonZeroWidth: NSLayoutConstraint!

    private var layoutLandscapeContraintPluginBaseNonZeroWidth: NSLayoutConstraint!
    private var layoutLandscapeContraintPluginBaseZeroWidth: NSLayoutConstraint!

    private var waitingRoomView: WaitingRoomView?
    private var splitContentViewController: UIViewController?

    public init(meeting: RealtimeKitClient, completion: @escaping () -> Void) {
        // TODO: Check the local user passed now
        pluginScreenShareView = RtkPluginsView(videoPeerViewModel: VideoPeerViewModel(meeting: meeting, participant: meeting.localUser, showSelfPreviewVideo: false, showScreenShareVideoView: true))
        onFinishedMeeting = completion
        viewModel = ActiveSpeakerMeetingViewModel(meeting: meeting)
        super.init(meeting: meeting)
        viewModel.notificationDelegate = self
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        topBar.setContentTop(offset: view.safeAreaInsets.top)
        view.endEditing(true)
        if UIScreen.isLandscape() {
            bottomBar.setWidth()
        } else {
            bottomBar.setHeight()
        }
        setLeftPaddingContraintForBaseContentView()
    }

    private func setLeftPaddingContraintForBaseContentView() {
        if UIScreen.deviceOrientation == .landscapeLeft {
            baseContentView.get(.top)?.constant = view.safeAreaInsets.top
            baseContentView.get(.bottom)?.constant = -view.safeAreaInsets.bottom
            baseContentView.get(.leading)?.constant = view.safeAreaInsets.bottom
        } else if UIScreen.deviceOrientation == .landscapeRight {
            baseContentView.get(.bottom)?.constant = -view.safeAreaInsets.bottom
            baseContentView.get(.leading)?.constant = view.safeAreaInsets.right
            baseContentView.get(.top)?.constant = view.safeAreaInsets.top
        }
    }

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        resetConstraints()
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = true
        view.accessibilityIdentifier = "Meeting_Base_View"
        view.backgroundColor = DesignLibrary.shared.color.background.shade1000
        meeting.chat.setCharacterLimit(characterLimit: 500)
        meeting.chat.setMessageRateLimit(maxMessages: Int32(5), intervalInSeconds: Int64(60))
        createTopbar()
        createBottomBar()
        createSubView()
        setInitialsConfiguration()
        setupNotifications()
        viewModel.delegate = self

        viewModel.selfListener.observeSelfMeetingEndForAll { [weak self] _ in
            guard let self = self else { return }

            func showWaitingRoom(status: ParticipantMeetingStatus, time _: TimeInterval, onComplete: @escaping () -> Void) {
                if status != .none {
                    let waitingView = WaitingRoomView(automaticClose: true, onCompletion: onComplete)
                    waitingView.backgroundColor = self.view.backgroundColor
                    self.view.addSubview(waitingView)
                    waitingView.set(.fillSuperView(self.view))
                    self.view.endEditing(true)
                    waitingView.show(status: status)
                }
            }
            // self.dismiss(animated: true)
            showWaitingRoom(status: .meetingEnded, time: 2) { [weak self] in
                guard let self = self else { return }
                self.viewModel.clean()
                self.onFinishedMeeting()
            }
        }

        viewModel.selfListener.observeSelfRemoved { [weak self] _ in
            guard let self = self else { return }

            func showWaitingRoom(status: ParticipantMeetingStatus, time _: TimeInterval, onComplete: @escaping () -> Void) {
                if status != .none {
                    let waitingView = WaitingRoomView(automaticClose: true, onCompletion: onComplete)
                    waitingView.backgroundColor = self.view.backgroundColor
                    self.view.addSubview(waitingView)
                    waitingView.set(.fillSuperView(self.view))
                    self.view.endEditing(true)
                    waitingView.show(status: status)
                }
            }
            // self.dismiss(animated: true)
            showWaitingRoom(status: .kicked, time: 2) { [weak self] in
                guard let self = self else { return }
                self.viewModel.clean()
                self.onFinishedMeeting()
            }
        }
        viewModel.selfListener.observePluginScreenShareTabSync(update: { id in
            self.selectPluginOrScreenShare(id: id)
        })

        if meeting.localUser.permissions.host.canAcceptRequests {
            viewModel.waitlistEventListner.participantJoinedCompletion = { [weak self] participant in
                guard let self = self else { return }

                self.view.showToast(toastMessage: "\(participant.name) has requested to join the call ", duration: 2.0, uiBlocker: false)
                if self.meeting.getWaitlistCount() > 0 {
                    self.moreButtonBottomBar?.notificationBadge.isHidden = false
                } else {
                    self.moreButtonBottomBar?.notificationBadge.isHidden = false
                }
                NotificationCenter.default.post(name: Notification.Name("Notify_ParticipantListUpdate"), object: nil, userInfo: nil)
            }

            viewModel.waitlistEventListner.participantRequestRejectCompletion = { [weak self] _ in
                guard let self = self else { return }
                if self.meeting.getWaitlistCount() > 0 {
                    self.moreButtonBottomBar?.notificationBadge.isHidden = false
                } else {
                    self.moreButtonBottomBar?.notificationBadge.isHidden = false
                }
            }
            viewModel.waitlistEventListner.participantRequestAcceptedCompletion = { [weak self] _ in
                guard let self = self else { return }
                if self.meeting.getWaitlistCount() > 0 {
                    self.moreButtonBottomBar?.notificationBadge.isHidden = false
                } else {
                    self.moreButtonBottomBar?.notificationBadge.isHidden = false
                }
            }
            viewModel.waitlistEventListner.participantRemovedCompletion = { [weak self] _ in
                guard let _ = self else { return }

                NotificationCenter.default.post(name: Notification.Name("Notify_ParticipantListUpdate"), object: nil, userInfo: nil)
            }
        }
        addWaitingRoom { [weak self] in
            guard let self = self else { return }
            self.viewModel.clean()
            self.onFinishedMeeting()
        }
        setUpReconnection { [weak self] in
            guard let self = self else { return }
            self.viewModel.clean()
            self.onFinishedMeeting()
        } success: { [weak self] in
            guard let self = self else { return }
            self.refreshMeetingGrid { [weak self] in
                guard let self = self else { return }
                self.refreshPluginsView {}
            }
        }
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if viewWillAppear == false {
            viewWillAppear = true
            viewModel.refreshActiveParticipants { [weak self] in
                guard let self = self else { return }
                self.viewModel.trackOnGoingState()
            }
        }
    }

    public func refreshMeetingGrid(forRotation: Bool = false, animation: Bool = true, completion: @escaping () -> Void) {
        meetingGridPageBecomeVisible()

        let arrModels = viewModel.arrGridParticipants

        func prepareGridViewsForReuse() {
            gridView.prepareForReuse { peerView in
                peerView.prepareForReuse()
            }
        }

        if meeting.participants.currentPageNumber == 0 {
            showPluginView(show: isPluginOrScreenShareActive, animation: false) { [weak self] _ in
                guard let self = self else { return }
            }
            loadGrid(fullScreen: !isPluginOrScreenShareActive, animation: animation, completion: {
                if forRotation == false {
                    prepareGridViewsForReuse()
                    populateGridChildViews(models: arrModels)
                }
                completion()
            })
        } else {
            showPluginView(show: false, animation: false) { _ in
                self.loadGrid(fullScreen: true, animation: animation, completion: {
                    if forRotation == false {
                        prepareGridViewsForReuse()
                        populateGridChildViews(models: arrModels)
                    }
                    completion()
                })
            }
        }

        func populateGridChildViews(models: [GridCellViewModel]) {
            for i in 0 ..< models.count {
                if let peerContainerView = gridView.childView(index: i) {
                    peerContainerView.setParticipant(meeting: meeting, participant: models[i].participant)
                }
            }
        }
    }

    private func createBottomBar() {
        bottomBar = getBottomBar()
        moreButtonBottomBar = bottomBar.moreButton
        view.addSubview(bottomBar)
        addBottomBarConstraint()
    }

    func getBottomBar() -> ActiveSpeakerMeetingControlBar {
        let controlBar = ActiveSpeakerMeetingControlBar(meeting: meeting, delegate: nil, presentingViewController: self) {
            [weak self] in
            guard let self = self else { return }
            self.refreshMeetingGridTile(participant: self.meeting.localUser)
        } onLeaveMeetingCompletion: {
            [weak self] in
            guard let self = self else { return }
            self.leaveMeeting()
        }
        controlBar.clickDelegate = self
        controlBar.accessibilityIdentifier = "Meeting_ControlBottomBar"
        return controlBar
    }

    private func addBottomBarConstraint() {
        addPortraitContraintBottombar()
        addLandscapeContraintBottombar()
        applyConstraintAsPerOrientation()
        bottomBar.applyConstraintAsPerOrientation(isLandscape: UIScreen.isLandscape()) {
            bottomBar.setItemsOrientation(axis: .horizontal)
            bottomBar.setHeight()
        } onLandscape: {
            bottomBar.setItemsOrientation(axis: .vertical)
            bottomBar.setWidth()
        }
    }

    private func addPortraitContraintBottombar() {
        bottomBar.set(.sameLeadingTrailing(view),
                      .bottom(view))
        portraitConstraints.append(contentsOf: [bottomBar.get(.leading)!,
                                                bottomBar.get(.trailing)!,
                                                bottomBar.get(.bottom)!])
    }

    private func addLandscapeContraintBottombar() {
        bottomBar.set(.trailing(view),
                      .sameTopBottom(view))
        landscapeConstraints.append(contentsOf: [bottomBar.get(.trailing)!,
                                                 bottomBar.get(.top)!,
                                                 bottomBar.get(.bottom)!])
    }

    deinit {
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func resetConstraints() {
        presentedViewController?.dismiss(animated: false)

        bottomBar.moreButton.hideBottomSheet()
        if UIScreen.isLandscape() {
            bottomBar.moreButton.superview?.isHidden = true
        } else {
            bottomBar.moreButton.superview?.isHidden = false
        }

        applyConstraintAsPerOrientation {
            self.fullScreenButton.isHidden = true
            self.closefullscreen()
        } onLandscape: {
            self.fullScreenButton.isSelected = false
            self.fullScreenButton.isHidden = false
        }

        showPluginViewAsPerOrientation(show: isPluginOrScreenShareActive, activeSplitContentView: bottomBar.isSplitContentButtonSelected())
        setLeftPaddingContraintForBaseContentView()
        DispatchQueue.main.async {
            self.refreshMeetingGrid(forRotation: true, completion: {})
        }
    }
}

extension ActiveSpeakerMeetingViewController {
    @objc func draggedView(_ sender: UIPanGestureRecognizer) {
        if let activePeerView = activePeerBaseView {
            let translation = sender.translation(in: activePeerView.superview!)
            var newCenter = CGPoint(x: activePeerView.center.x + translation.x, y: activePeerView.center.y + translation.y)
            let halfWidth = activePeerView.frame.width / 2.0
            if newCenter.x <= halfWidth {
                newCenter.x = halfWidth
            }
            if newCenter.y <= halfWidth {
                newCenter.y = halfWidth
            }
            let parentView = activePeerView.superview!

            if newCenter.x >= (parentView.frame.width - halfWidth) {
                newCenter.x = parentView.frame.width - halfWidth
            }

            if newCenter.y >= (parentView.frame.height - halfWidth) {
                newCenter.y = parentView.frame.height - halfWidth
            }
            activePeerView.center = newCenter
            sender.setTranslation(CGPoint.zero, in: view)
        }
    }
}

private extension ActiveSpeakerMeetingViewController {
    private func setInitialsConfiguration() {
        // self.topBar.setInitialConfiguration()
    }

    private func createSubView() {
        splitContentBaseView.clipsToBounds = true
        view.addSubview(baseContentView)
        baseContentView.addSubview(pluginBaseView)
        baseContentView.addSubview(gridBaseView)
        baseContentView.addSubview(splitContentBaseView)

        pluginBaseView.accessibilityIdentifier = "Grid_Plugin_View"

        gridView = GridView(showingCurrently: 9, getChildView: {
            RtkParticipantTileContainerView()
        })
        gridBaseView.addSubview(gridView)
        pluginBaseView.addSubview(pluginScreenShareView)

        pluginScreenShareView.addSubview(fullScreenButton)
        fullScreenButton.set(.trailing(pluginScreenShareView, rtkSharedTokenSpace.space1),
                             .bottom(pluginScreenShareView, rtkSharedTokenSpace.space1))
        fullScreenButton.addTarget(self, action: #selector(buttonClick(button:)), for: .touchUpInside)
        fullScreenButton.isHidden = !UIScreen.isLandscape()
        fullScreenButton.isSelected = false

        addPortraitConstraintForSubviews()
        addLandscapeConstraintForSubviews()
        applyConstraintAsPerOrientation(isLandscape: UIScreen.isLandscape())
        showPluginViewAsPerOrientation(show: isPluginOrScreenShareActive, activeSplitContentView: bottomBar.isSplitContentButtonSelected())
    }

    @objc func buttonClick(button: RtkButton) {
        if UIScreen.isLandscape() {
            if button.isSelected == false {
                pluginScreenShareView.removeFromSuperview()
                addFullScreenView(contentView: pluginScreenShareView)
            } else {
                closefullscreen()
            }
            button.isSelected = !button.isSelected
        }
    }

    private func closefullscreen() {
        if fullScreenView?.isVisible == true {
            pluginBaseView.addSubview(pluginScreenShareView)
            pluginScreenShareView.set(.fillSuperView(pluginBaseView))
            removeFullScreenView()
        }
    }

    private func showPluginViewAsPerOrientation(show: Bool, activeSplitContentView: Bool, animation: Bool = false) {
        splitContentBaseView.isHidden = !activeSplitContentView
        layoutPortraitContraintPluginBaseVariableHeight.isActive = false
        layoutPortraitContraintPluginBaseZeroHeight.isActive = false

        // layoutLandscapeContraintPluginBaseNonZeroWidth.isActive = false
        layoutLandscapeContraintPluginBaseZeroWidth.isActive = false

        layoutLandscapeContraintSplitContentViewZeroWidth.isActive = false
        layoutLandscapeContraintSplitContentViewNonZeroWidth.isActive = false

        layoutLandscapeContraintGridZeroWidth.isActive = false
        layoutPortraitContraintSplitContentViewZeroHeight.isActive = false
        if UIScreen.isLandscape() {
            if show {
                addActivePeerViewTitle()
                refreshActiveTitleView()
            }

            if activeSplitContentView {
                layoutLandscapeContraintSplitContentViewNonZeroWidth.isActive = true
                if show {
                    // show Plugin. So no need to show Grid view
                    layoutLandscapeContraintGridZeroWidth.isActive = true
                } else {
                    // Show Grid View instead of plugin and separate GridTile
                    layoutLandscapeContraintPluginBaseZeroWidth.isActive = true
                }

            } else {
                layoutPortraitContraintSplitContentViewZeroHeight.isActive = true
                layoutLandscapeContraintSplitContentViewZeroWidth.isActive = true
                if show {
                    // show PluginView
                    layoutLandscapeContraintGridZeroWidth.isActive = true
                } else {
                    layoutLandscapeContraintPluginBaseZeroWidth.isActive = true
                }
            }
        } else {
            layoutPortraitContraintSplitContentViewZeroHeight.isActive = true
            layoutPortraitContraintPluginBaseVariableHeight.isActive = show
            layoutPortraitContraintPluginBaseZeroHeight.isActive = !show
            removeActivePeerViewTile()
        }
        if animation {
            UIView.animate(withDuration: Animations.gridViewAnimationDuration) {
                self.baseContentView.layoutIfNeeded()
            }
        } else {
            baseContentView.layoutIfNeeded()
        }
    }

    private func addActivePeerViewTitle() {
        if activePeerBaseView == nil {
            activePeerBaseView = UIView()
            let tileBaseView = activePeerBaseView!
            pluginScreenShareView.addSubview(tileBaseView)
            pluginScreenShareView.bringSubviewToFront(tileBaseView)
            tileBaseView.set(.bottom(pluginScreenShareView), .leading(pluginScreenShareView), .equateAttribute(.width, toView: pluginScreenShareView, toAttribute: .height, withRelation: .equal, multiplier: 0.27), .equateAttribute(.height, toView: pluginScreenShareView, toAttribute: .height, withRelation: .equal, multiplier: 0.27))

            panGesture = UIPanGestureRecognizer(target: self, action: #selector(draggedView(_:)))
            tileBaseView.addGestureRecognizer(panGesture)
            tileBaseView.isUserInteractionEnabled = true
        }
    }

    private func removeActivePeerViewTile() {
        activePeerBaseView?.removeFromSuperview()
        activePeerBaseView = nil
    }

    private func refreshActiveTitleView() {
        guard let titleBaseView = activePeerBaseView else { return }
        // All action should only takePlace when activeTileView is present on the screen, And It should definitely be present when Plugin/ScreenShare is active and in Landscape mode.
        var tileVisible = true
        if let pinnedUser = meeting.participants.pinned {
            activePeerView = RtkParticipantTileView(rtkClient: meeting, participant: pinnedUser, isForLocalUser: pinnedUser.userId == meeting.localUser.userId)
        } else if let active = meeting.participants.activeSpeaker {
            activePeerView = RtkParticipantTileView(rtkClient: meeting, participant: active, isForLocalUser: active.userId == meeting.localUser.userId)
        } else if meeting.localUser.stageStatus == StageStatus.onStage {
            activePeerView = RtkParticipantTileView(rtkClient: meeting, participant: meeting.localUser, isForLocalUser: true)
        } else if let active = meeting.participants.active.first {
            activePeerView = RtkParticipantTileView(rtkClient: meeting, participant: active, isForLocalUser: active.userId == meeting.localUser.userId)
        } else {
            tileVisible = false
        }

        if let tile = activePeerView, tileVisible {
            tile.isUserInteractionEnabled = true
            titleBaseView.addSubview(tile)
            tile.set(.fillSuperView(titleBaseView))
        }
    }

    private func addPortraitConstraintForSubviews() {
        baseContentView.set(.sameLeadingTrailing(view),
                            .below(topBar),
                            .above(bottomBar))
        portraitConstraints.append(contentsOf: [baseContentView.get(.leading)!,
                                                baseContentView.get(.trailing)!,
                                                baseContentView.get(.top)!,
                                                baseContentView.get(.bottom)!])

        pluginBaseView.set(.sameLeadingTrailing(baseContentView),
                           .top(baseContentView))
        portraitConstraints.append(contentsOf: [pluginBaseView.get(.leading)!,
                                                pluginBaseView.get(.trailing)!,
                                                pluginBaseView.get(.top)!])

        layoutPortraitContraintPluginBaseVariableHeight = NSLayoutConstraint(item: pluginBaseView, attribute: .height, relatedBy: .equal, toItem: baseContentView, attribute: .height, multiplier: 0.7, constant: 0)
        layoutPortraitContraintPluginBaseVariableHeight.isActive = false

        layoutPortraitContraintPluginBaseZeroHeight = NSLayoutConstraint(item: pluginBaseView, attribute: .height, relatedBy: .equal, toItem: baseContentView, attribute: .height, multiplier: 0.0, constant: 0)

        layoutPortraitContraintPluginBaseZeroHeight.isActive = false

        gridBaseView.set(.sameLeadingTrailing(baseContentView),
                         .below(pluginBaseView))

        portraitConstraints.append(contentsOf: [gridBaseView.get(.leading)!,
                                                gridBaseView.get(.trailing)!,
                                                gridBaseView.get(.top)!])

        splitContentBaseView.set(.sameLeadingTrailing(baseContentView),
                                 .below(gridBaseView),
                                 .bottom(baseContentView))

        portraitConstraints.append(contentsOf: [splitContentBaseView.get(.leading)!,
                                                splitContentBaseView.get(.trailing)!,
                                                splitContentBaseView.get(.top)!,
                                                splitContentBaseView.get(.bottom)!])

        layoutPortraitContraintSplitContentViewZeroHeight = NSLayoutConstraint(item: splitContentBaseView, attribute: .height, relatedBy: .equal, toItem: baseContentView, attribute: .height, multiplier: 0.0, constant: 0)

        layoutPortraitContraintSplitContentViewZeroHeight.isActive = false

        gridView.set(.fillSuperView(gridBaseView))
        portraitConstraints.append(contentsOf: [gridView.get(.leading)!,
                                                gridView.get(.trailing)!,
                                                gridView.get(.top)!,
                                                gridView.get(.bottom)!])
        pluginScreenShareView.set(.fillSuperView(pluginBaseView))
        portraitConstraints.append(contentsOf: [pluginScreenShareView.get(.leading)!,
                                                pluginScreenShareView.get(.trailing)!,
                                                pluginScreenShareView.get(.top)!,
                                                pluginScreenShareView.get(.bottom)!])
    }

    private func addLandscapeConstraintForSubviews() {
        baseContentView.set(.leading(view),
                            .below(topBar),
                            .bottom(view),
                            .before(bottomBar))

        landscapeConstraints.append(contentsOf: [baseContentView.get(.leading)!,
                                                 baseContentView.get(.trailing)!,
                                                 baseContentView.get(.top)!,
                                                 baseContentView.get(.bottom)!])

        pluginBaseView.set(.leading(baseContentView),
                           .sameTopBottom(baseContentView))
        landscapeConstraints.append(contentsOf: [pluginBaseView.get(.leading)!,
                                                 pluginBaseView.get(.bottom)!,
                                                 pluginBaseView.get(.top)!])

//        layoutLandscapeContraintPluginBaseNonZeroWidth = NSLayoutConstraint(item: pluginBaseView, attribute: .width, relatedBy: .equal, toItem: baseContentView, attribute: .width, multiplier: 1.0, constant: 0)
//        layoutLandscapeContraintPluginBaseNonZeroWidth.isActive = false

        layoutLandscapeContraintPluginBaseZeroWidth = NSLayoutConstraint(item: pluginBaseView, attribute: .width, relatedBy: .equal, toItem: baseContentView, attribute: .width, multiplier: 0.0, constant: 0)

        layoutLandscapeContraintPluginBaseZeroWidth.isActive = false

        gridBaseView.set(.sameTopBottom(baseContentView),
                         .after(pluginBaseView))

        landscapeConstraints.append(contentsOf: [gridBaseView.get(.leading)!,
                                                 gridBaseView.get(.top)!,
                                                 gridBaseView.get(.bottom)!])

        layoutLandscapeContraintGridZeroWidth = NSLayoutConstraint(item: gridBaseView, attribute: .width, relatedBy: .equal, toItem: baseContentView, attribute: .width, multiplier: 0.0, constant: 0)
        layoutLandscapeContraintGridZeroWidth.isActive = false

        splitContentBaseView.set(.sameTopBottom(baseContentView),
                                 .after(gridBaseView),
                                 .trailing(baseContentView))
        landscapeConstraints.append(contentsOf: [splitContentBaseView.get(.leading)!,
                                                 splitContentBaseView.get(.top)!,
                                                 splitContentBaseView.get(.bottom)!,
                                                 splitContentBaseView.get(.trailing)!])

        layoutLandscapeContraintSplitContentViewZeroWidth = NSLayoutConstraint(item: splitContentBaseView, attribute: .width, relatedBy: .equal, toItem: baseContentView, attribute: .width, multiplier: 0.0, constant: 0)
        layoutLandscapeContraintSplitContentViewZeroWidth.isActive = false

        layoutLandscapeContraintSplitContentViewNonZeroWidth = NSLayoutConstraint(item: splitContentBaseView, attribute: .width, relatedBy: .equal, toItem: baseContentView, attribute: .width, multiplier: 0.35, constant: 0)
        layoutLandscapeContraintSplitContentViewNonZeroWidth.isActive = false

        gridView.set(.fillSuperView(gridBaseView))
        landscapeConstraints.append(contentsOf: [gridView.get(.leading)!,
                                                 gridView.get(.trailing)!,
                                                 gridView.get(.top)!,
                                                 gridView.get(.bottom)!])

        pluginScreenShareView.set(.fillSuperView(pluginBaseView))
        landscapeConstraints.append(contentsOf: [pluginScreenShareView.get(.leading)!,
                                                 pluginScreenShareView.get(.trailing)!,
                                                 pluginScreenShareView.get(.top)!,
                                                 pluginScreenShareView.get(.bottom)!])
    }

    private func createTopbar() {
        let topbar = RtkMeetingHeaderView(meeting: meeting)
        view.addSubview(topbar)
        topbar.accessibilityIdentifier = "Meeting_ControlTopBar"
        topBar = topbar
        addPotraitContraintTopbar()
        addLandscapeContraintTopbar()
    }

    private func addPotraitContraintTopbar() {
        topBar.set(.sameLeadingTrailing(view), .top(view))
        portraitConstraints.append(contentsOf: [topBar.get(.leading)!,
                                                topBar.get(.trailing)!,
                                                topBar.get(.top)!])
        setPortraitContraintAsDeactive()
    }

    private func addLandscapeContraintTopbar() {
        topBar.set(.sameLeadingTrailing(view), .top(view))

        topBar.set(.height(0))
        landscapeConstraints.append(contentsOf: [topBar.get(.leading)!,
                                                 topBar.get(.trailing)!,
                                                 topBar.get(.top)!,
                                                 topBar.get(.height)!])
        setLandscapeContraintAsDeactive()
    }
}

extension ActiveSpeakerMeetingViewController: ActiveSpeakerMeetingViewModelDelegate {
    func leaveMeeting() {
        viewModel.clean()
        onFinishedMeeting()
    }

    func newPollAdded(createdBy: String) {
        view.showToast(toastMessage: "New poll created by \(createdBy)", duration: 2.0, uiBlocker: false)
    }

    func participantJoined(participant _: RtkMeetingParticipant) {
        topBar.refreshNextPreviouButtonState()

        // Uncomment if you want to show toast
        // self.view.showToast(toastMessage: "\(participant.name) just joined", duration: 2.0, uiBlocker: false)
    }

    func participantLeft(participant _: RtkMeetingParticipant) {
        topBar.refreshNextPreviouButtonState()

        // Uncomment if you want to show toast
        // self.view.showToast(toastMessage: "\(participant.name) left", duration: 2.0, uiBlocker: false)
    }

    func activeSpeakerChanged(participant _: RtkMeetingParticipant) {
        // For now commenting out the functionality of Active Speaker, It's Not working as per our expectation
        refreshActiveTitleView()
    }

    func pinnedChanged(participant _: RtkMeetingParticipant) {
        // No need to do here, Because we are refreshing whole Screen when we get a callback from Core, Which we will automatically pin participant if exist at zero position.
        refreshActiveTitleView()
    }

    func activeSpeakerRemoved() {
        // For now commenting out the functionality of Active Speaker, It's Not working as per our expectation
        refreshActiveTitleView()
    }

    func pinnedParticipantRemoved(participant: RtkMeetingParticipant) {
        refreshActiveTitleView()
        updatePin(show: false, participant: participant)
    }

    private func getScreenShareTabButton(participants: [ParticipantsShareControl]) -> [RtkPluginScreenShareTabButton] {
        var arrButtons = [RtkPluginScreenShareTabButton]()
        for participant in participants {
            var image: RtkImage?
            if let _ = participant as? ScreenShareModel {
                // For
                image = RtkImage(image: ImageProvider.image(named: "icon_screen_share"))
            } else {
                if let strUrl = participant.image, let imageUrl = URL(string: strUrl) {
                    image = RtkImage(url: imageUrl)
                }
            }

            let button = RtkPluginScreenShareTabButton(image: image, title: participant.name, id: participant.id)
            // TODO: Below hardcoding is not needed, We also need to scale down the image as well.
            button.btnImageView?.set(.height(20),
                                     .width(20))
            arrButtons.append(button)
        }
        return arrButtons
    }

    private func handleClicksOnPluginsTab(model: PluginButtonModel, at index: Int) {
        guard let pluginView = model.plugin.getPluginView() else { return }
        pluginScreenShareView.show(pluginView: pluginView)
        viewModel.screenShareViewModel.selectedIndex = (UInt(index), model.id)
    }

    private func handleClicksOnScreenShareTab(model: ScreenShareModel, index: Int) {
        pluginScreenShareView.showVideoView(participant: model.participant)
        pluginScreenShareView.pluginVideoView.viewModel.refreshNameTag()
        viewModel.screenShareViewModel.selectedIndex = (UInt(index), model.id)
    }

    public func selectPluginOrScreenShare(id: String) {
        var index: Int = -1
        for button in pluginScreenShareView.activeListView.buttons {
            index = index + 1
            if button.id == id {
                pluginScreenShareView.selectForAutoSync(button: button)
                break
            }
        }
    }

    func refreshPluginsButtonTab(pluginsButtonsModels: [ParticipantsShareControl], arrButtons: [RtkPluginScreenShareTabButton]) {
        if arrButtons.count >= 1 {
            var selectedIndex: Int?
            if let index = viewModel.screenShareViewModel.selectedIndex?.0 {
                selectedIndex = Int(index)
            }
            pluginScreenShareView.setButtons(buttons: arrButtons, selectedIndex: selectedIndex) { [weak self] button, isUserClick in
                guard let self = self else { return }
                if let plugin = pluginsButtonsModels[button.index] as? PluginButtonModel {
                    if self.pluginScreenShareView.syncButton?.isSelected == false, isUserClick {
                        // This is send only when Syncbutton is on and Visible
                        self.meeting.meta.syncTab(id: plugin.id, tabType: .plugin)
                    }
                    self.handleClicksOnPluginsTab(model: plugin, at: button.index)

                } else if let screenShare = pluginsButtonsModels[button.index] as? ScreenShareModel {
                    if self.pluginScreenShareView.syncButton?.isSelected == false, isUserClick {
                        // This is send only when Syncbutton is on and Visible
                        self.meeting.meta.syncTab(id: screenShare.id, tabType: .screenshare)
                    }
                    self.handleClicksOnScreenShareTab(model: screenShare, index: button.index)
                }
                for (index, element) in arrButtons.enumerated() {
                    element.isSelected = index == button.index ? true : false
                }

                self.pluginScreenShareView.observeSyncButtonClick { syncButton in
                    if syncButton.isSelected == false {
                        if let selectedIndex = self.viewModel.screenShareViewModel.selectedIndex {
                            let model = self.viewModel.screenShareViewModel.arrScreenShareParticipants[Int(selectedIndex.0)]
                            if let model = model as? ScreenSharePluginsProtocol {
                                self.meeting.meta.syncTab(id: model.id, tabType: .screenshare)
                            } else if let model = model as? PluginsButtonModelProtocol {
                                self.meeting.meta.syncTab(id: model.id, tabType: .plugin)
                            }
                        }
                    }
                }
            }
        }
    }

    func refreshPluginsView(completion: @escaping () -> Void) {
        let participants = viewModel.screenShareViewModel.arrScreenShareParticipants
        let arrButtons = getScreenShareTabButton(participants: participants)
        refreshPluginsButtonTab(pluginsButtonsModels: participants, arrButtons: arrButtons)
        var onCompletion = {
            self.meetingGridPageBecomeVisible()
            completion()
        }
        if arrButtons.count >= 1 {
            var selectedIndex: Int?
            if let index = viewModel.screenShareViewModel.selectedIndex?.0 {
                selectedIndex = Int(index)
            }
            if let index = selectedIndex {
                if let pluginModel = participants[index] as? PluginButtonModel {
                    guard let pluginView = pluginModel.plugin.getPluginView() else { return }
                    pluginScreenShareView.show(pluginView: pluginView)
                } else if let screenShare = participants[index] as? ScreenShareModel {
                    pluginScreenShareView.showVideoView(participant: screenShare.participant)
                }
                showPlugInView {
                    onCompletion()
                }
            }
        } else {
            hidePlugInView(tab: arrButtons) {
                onCompletion()
            }
        }
    }

    private func showPluginView(show: Bool, animation: Bool, completion: @escaping ((Bool) -> Void)) {
        showPluginViewAsPerOrientation(show: show, activeSplitContentView: bottomBar.isSplitContentButtonSelected())
        pluginBaseView.isHidden = !show
        if animation {
            UIView.animate(withDuration: Animations.gridViewAnimationDuration, animations: {
                self.view.layoutIfNeeded()
            }, completion: completion)
        } else {
            view.layoutIfNeeded()
            completion(true)
        }
    }

    private func loadGrid(fullScreen: Bool, animation: Bool, completion: @escaping () -> Void) {
        let arrModels = viewModel.arrGridParticipants
        if fullScreen == false {
            if UIScreen.isLandscape() {
                gridView.settingFramesForPluginsActiveInLandscapeMode(visibleItemCount: UInt(arrModels.count), animation: animation) { _ in
                    completion()
                }
            } else {
                gridView.settingFramesForPluginsActiveInPortraitMode(visibleItemCount: UInt(arrModels.count), animation: animation) { _ in
                    completion()
                }
            }

        } else {
            if UIScreen.isLandscape() {
                gridView.settingFramesForLandScape(visibleItemCount: UInt(arrModels.count), animation: animation) { _ in
                    completion()
                }
            } else {
                gridView.settingFrames(visibleItemCount: UInt(arrModels.count), animation: animation) { _ in
                    completion()
                }
            }
        }
    }

    private func showPlugInView(completion: @escaping () -> Void) {
        // We need to move gridview to Starting View
        isPluginOrScreenShareActive = true
        if meeting.participants.currentPageNumber == 0 {
            // We have to only show PluginView on page == 0 only
            showPluginView(show: true, animation: true) { _ in
                self.loadGrid(fullScreen: false, animation: true, completion: completion)
            }
        } else {
            completion()
        }
    }

    private func hidePlugInView(tab buttons: [RtkPluginScreenShareTabButton], completion: @escaping () -> Void) {
        // No need to show any plugin or share view
        isPluginOrScreenShareActive = false
        pluginScreenShareView.setButtons(buttons: buttons, selectedIndex: nil) { _, _ in }
        showPluginView(show: false, animation: true) { _ in
            if self.meeting.participants.currentPageNumber == 0 {
                self.loadGrid(fullScreen: true, animation: true, completion: completion)
            } else {
                completion()
            }
        }
    }

    func updatePin(show: Bool, participant: RtkMeetingParticipant) {
        let arrModels = viewModel.arrGridParticipants
        var index = -1
        for model in arrModels {
            index += 1
            if model.participant.userId == participant.userId {
                if let peerView = gridView.childView(index: index)?.tileView {
                    peerView.pinView(show: show)
                }
            }
        }
    }

    /* This method is used to refresh (Mainly to reload video view) Single grid tile associated with participant passed*/
    func refreshMeetingGridTile(participant: RtkMeetingParticipant) {
        let arrModels = viewModel.arrGridParticipants
        var index = -1
        for model in arrModels {
            index += 1
            if model.participant.userId == participant.userId {
                if let peerContainerView = gridView.childView(index: index) {
                    peerContainerView.setParticipant(meeting: meeting, participant: arrModels[index].participant)
                    return
                }
            }
        }
    }

    private func meetingGridPageBecomeVisible() {
        if let participant = meeting.participants.pinned {
            refreshMeetingGridTile(participant: participant)
        }
        topBar.refreshNextPreviouButtonState()
    }
}

extension ActiveSpeakerMeetingViewController: RtkNotificationDelegate {
    public func didReceiveNotification(type: RtkNotificationType) {
        switch type {
        case let .Chat(message):
            viewModel.rtkNotification.playNotificationSound(type: type)
            if message.isEmpty == false {
                view.showToast(toastMessage: message, duration: 2.0, uiBlocker: false, showInBottom: true, bottomSpace: bottomBar.bounds.height)
            }
            NotificationCenter.default.post(name: Notification.Name("Notify_NewChatArrived"), object: nil, userInfo: nil)
            moreButtonBottomBar?.notificationBadge.isHidden = false
        case .Poll:
            NotificationCenter.default.post(name: Notification.Name("Notify_NewPollArrived"), object: nil, userInfo: nil)
            viewModel.rtkNotification.playNotificationSound(type: .Poll)
            moreButtonBottomBar?.notificationBadge.isHidden = false
        case .Joined:
            // Uncomment if you want to play sound
            // viewModel.dyteNotification.playNotificationSound(type: .Joined)
            break
        case .Leave:
            // Uncomment if you want to play sound
            // viewModel.dyteNotification.playNotificationSound(type: .Leave)
            break
        }
    }

    public func clearChatNotification() {
        moreButtonBottomBar?.notificationBadge.isHidden = true
    }
}

extension ActiveSpeakerMeetingViewController {
    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(onEndMettingForAllButtonPressed), name: RtkLeaveDialog.onEndMeetingForAllButtonPress, object: nil)
    }

    // MARK: Notification Setup Functionality

    @objc private func onEndMettingForAllButtonPressed(notification _: Notification) {
        viewModel.selfListener.observeSelfRemoved(update: nil)
    }
}

extension ActiveSpeakerMeetingViewController {
    func addFullScreenView(contentView: UIView) {
        if fullScreenView == nil {
            fullScreenView = FullScreenView()
            view.addSubview(fullScreenView)
            fullScreenView.set(.fillSuperView(view))
        }
        fullScreenView.backgroundColor = view.backgroundColor
        fullScreenView.isUserInteractionEnabled = true
        fullScreenView.set(contentView: contentView)
    }

    func removeFullScreenView() {
        fullScreenView.backgroundColor = .clear
        fullScreenView.isUserInteractionEnabled = false
        fullScreenView.removeContentView()
    }
}

class FullScreenView: UIView {
    let containerView = UIView()
    var isVisible: Bool = false
    init() {
        super.init(frame: CGRect.zero)
        addSubview(containerView)
        containerView.set(.fillSuperView(self))
        setEdgeConstants()
    }

    func set(contentView: UIView) {
        isVisible = true
        containerView.addSubview(contentView)
        contentView.set(.fillSuperView(containerView))
    }

    func removeContentView() {
        isVisible = true
        for subview in containerView.subviews {
            subview.removeFromSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        setEdgeConstants()
    }

    private func setEdgeConstants() {
        containerView.get(.leading)?.constant = safeAreaInsets.left
        containerView.get(.trailing)?.constant = -safeAreaInsets.right
        containerView.get(.top)?.constant = safeAreaInsets.top
        containerView.get(.bottom)?.constant = -safeAreaInsets.bottom
    }
}

extension ActiveSpeakerMeetingViewController: ActiveSpeakerMeetingControlBarDelegate {
    func settingClick(button: RtkControlBarButton) {
        resetContentViewState()
        let controller = RtkSettingViewController(nameTag: meeting.localUser.name, meeting: meeting, completion: {
            self.refreshMeetingGridTile(participant: self.meeting.localUser)
            button.isSelected = false
        })
        controller.view.backgroundColor = view.backgroundColor
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
    }

    func chatClick(button: RtkControlBarButton) {
        resetContentViewState()
        if button.isSelected {
            let controller = RtkChatViewController(meeting: meeting)
            splitContentBaseView.addSubview(controller.view)
            controller.topBar.leftButton.addTarget(self, action: #selector(chatButtonTapped(button:)), for: .touchUpInside)
            controller.view.set(.fillSuperView(splitContentBaseView))
            splitContentViewController = controller
        }
    }

    @objc func chatButtonTapped(button: RtkControlBarButton) {
        bottomBar.onChatClick(button: button)
    }

    func pollsClick(button: RtkControlBarButton) {
        resetContentViewState()
        if button.isSelected {
            let controller = RtkShowPollsViewController(meeting: meeting)
            controller.shouldShowTopBar = false
            splitContentBaseView.addSubview(controller.view)
            controller.view.set(.fillSuperView(splitContentBaseView))
            splitContentViewController = controller
        }
    }

    private func resetContentViewState() {
        splitContentViewController?.view.removeFromSuperview()
        var showPluginView = isPluginOrScreenShareActive
        if meeting.participants.currentPageNumber > 0 {
            showPluginView = false
        }
        showPluginViewAsPerOrientation(show: showPluginView, activeSplitContentView: bottomBar.isSplitContentButtonSelected())
        refreshGrid(showPlugin: showPluginView, showSplitContent: bottomBar.isSplitContentButtonSelected(), isLandscape: UIScreen.isLandscape())
    }

    private func refreshGrid(showPlugin: Bool, showSplitContent _: Bool, isLandscape: Bool) {
        if isLandscape {
            if showPlugin == false {
                refreshMeetingGrid(forRotation: true, animation: false) {}
            }
        }
    }
}
