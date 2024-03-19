//
//  ActiveSpeakerMeetingViewController.swift
//  active-speaker-ui-sample
//
//  Created by Dyte on 23/01/24.
//


import DyteUiKit
import DyteiOSCore
import UIKit

struct Animations {
    static let gridViewAnimationDuration = 0.3
}


public class ActiveSpeakerMeetingViewController: DyteBaseViewController {
    private var gridView: GridView<DyteParticipantTileContainerView>!
    let pluginView: DytePluginView
    var activePeerView: DyteParticipantTileView?
    var activePeerBaseView: UIView?

    var panGesture = UIPanGestureRecognizer()
    let gridBaseView = UIView()
    private let pluginBaseView = UIView()
    private let splitContentBaseView = UIView()

    private var fullScreenView: FullScreenView!
    
    let baseContentView = UIView()
    
    
    private var isPluginOrScreenShareActive = false
    
    let fullScreenButton: DyteControlBarButton = {
        let button = DyteControlBarButton(image: DyteImage(image: ImageProvider.image(named: "icon_show_fullscreen")))
        button.setSelected(image:  DyteImage(image: ImageProvider.image(named: "icon_hide_fullscreen")))
        button.backgroundColor = dyteSharedTokenColor.background.shade800
        return button
    }()
    let viewModel: ActiveSpeakerMeetingViewModel
    
    private var topBar: DyteMeetingHeaderView!
    private var bottomBar: ActiveSpeakerMeetingControlBar!
    
    internal let onFinishedMeeting: ()->Void
    private var viewWillAppear = false
    
    internal var moreButtonBottomBar: DyteControlBarButton?
    
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

    public init(meeting: DyteMobileClient, completion:@escaping()->Void) {
        //TODO: Check the local user passed now
        self.pluginView = DytePluginView(videoPeerViewModel:VideoPeerViewModel(mobileClient: meeting, participant: meeting.localUser, showSelfPreviewVideo: false, showScreenShareVideoView: true))
        self.onFinishedMeeting = completion
        self.viewModel = ActiveSpeakerMeetingViewModel(dyteMobileClient: meeting)
        super.init(dyteMobileClient: meeting)
        self.viewModel.notificationDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        self.topBar.setContentTop(offset: self.view.safeAreaInsets.top)
        if UIScreen.isLandscape() {
            self.bottomBar.setWidth()
        }else {
            self.bottomBar.setHeight()
        }
        setLeftPaddingContraintForBaseContentView()
    }
    
    private func setLeftPaddingContraintForBaseContentView() {
        if UIScreen.deviceOrientation == .landscapeLeft {
            self.baseContentView.get(.top)?.constant = self.view.safeAreaInsets.top
            self.baseContentView.get(.bottom)?.constant = -self.view.safeAreaInsets.bottom
            self.baseContentView.get(.leading)?.constant = self.view.safeAreaInsets.bottom
        }else if UIScreen.deviceOrientation == .landscapeRight {
            self.baseContentView.get(.bottom)?.constant = -self.view.safeAreaInsets.bottom
            self.baseContentView.get(.leading)?.constant = self.view.safeAreaInsets.right
            self.baseContentView.get(.top)?.constant = self.view.safeAreaInsets.top
        }
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        resetConstraints()
    }
        
    public override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = true
        self.view.accessibilityIdentifier = "Meeting_Base_View"
        self.view.backgroundColor = DesignLibrary.shared.color.background.shade1000
        createTopbar()
        createBottomBar()
        createSubView()
        setInitialsConfiguration()
        setupNotifications()
        self.viewModel.delegate = self
        
        self.viewModel.dyteSelfListner.observeSelfRemoved { [weak self] success in
            guard let self = self else {return}
            
            func showWaitingRoom(status: WaitListStatus, time:TimeInterval, onComplete:@escaping()->Void) {
                if status != .none {
                    let waitingView = WaitingRoomView(automaticClose: true, onCompletion: onComplete)
                    waitingView.backgroundColor = self.view.backgroundColor
                    self.view.addSubview(waitingView)
                    waitingView.set(.fillSuperView(self.view))
                    self.view.endEditing(true)
                    waitingView.show(status: status)
                }
            }
            //self.dismiss(animated: true)
            showWaitingRoom(status: .rejected, time: 2) { [weak self] in
                guard let self = self else {return}
                self.viewModel.clean()
                self.onFinishedMeeting()
            }
        }
        self.viewModel.dyteSelfListner.observePluginScreenShareTabSync(update: { id in
            self.selectPluginOrScreenShare(id: id)
        })
        
       
        if self.meeting.localUser.permissions.waitingRoom.canAcceptRequests {
            self.viewModel.waitlistEventListner.participantJoinedCompletion = {[weak self] participant in
                guard let self = self else {return}
                
                self.view.showToast(toastMessage: "\(participant.name) has requested to join the call ", duration: 2.0, uiBlocker: false)
                if self.meeting.getWaitlistCount() > 0 {
                    self.moreButtonBottomBar?.notificationBadge.isHidden = false
                }else {
                    self.moreButtonBottomBar?.notificationBadge.isHidden = false
                }
                NotificationCenter.default.post(name: Notification.Name("Notify_ParticipantListUpdate"), object: nil, userInfo: nil)

            }
            
            self.viewModel.waitlistEventListner.participantRequestRejectCompletion = {[weak self] participant in
                guard let self = self else {return}
                if self.meeting.getWaitlistCount() > 0 {
                    self.moreButtonBottomBar?.notificationBadge.isHidden = false
                }else {
                    self.moreButtonBottomBar?.notificationBadge.isHidden = false
                }
            }
            self.viewModel.waitlistEventListner.participantRequestAcceptedCompletion = {[weak self] participant in
                guard let self = self else {return}
                if self.meeting.getWaitlistCount() > 0 {
                    self.moreButtonBottomBar?.notificationBadge.isHidden = false
                }else {
                    self.moreButtonBottomBar?.notificationBadge.isHidden = false
                }
            }
            self.viewModel.waitlistEventListner.participantRemovedCompletion = {[weak self] participant in
                guard let _ = self else {return}

                NotificationCenter.default.post(name: Notification.Name("Notify_ParticipantListUpdate"), object: nil, userInfo: nil)
            }
        }
        addWaitingRoom { [weak self] in
            guard let self = self else {return}
            self.viewModel.clean()
            self.onFinishedMeeting()
        }
        setUpReconnection { [weak self] in
            guard let self = self else {return}
            self.viewModel.clean()
            self.onFinishedMeeting()
        } success: {  [weak self] in
            guard let self = self else {return}
            self.refreshMeetingGrid() { [weak self] in
                guard let self = self else {return}
                self.refreshPluginsView() {}
            }
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if viewWillAppear == false {
            viewWillAppear = true
            self.viewModel.refreshActiveParticipants() { [weak self] in
                guard let self = self else {return}
                self.viewModel.trackOnGoingState()
            }
        }
    }
    
    public func refreshMeetingGrid(forRotation: Bool = false, animation: Bool = true, completion:@escaping()->Void) {
        self.meetingGridPageBecomeVisible()
        
        let arrModels = self.viewModel.arrGridParticipants
        
        func prepareGridViewsForReuse() {
            self.gridView.prepareForReuse { peerView in
                peerView.prepareForReuse()
            }
        }
        
        if self.meeting.participants.currentPageNumber == 0 {
            self.showPluginView(show: isPluginOrScreenShareActive, animation: false) { [weak self] finish in
                guard let self = self else {return}
               
            }
            self.loadGrid(fullScreen: !self.isPluginOrScreenShareActive, animation: animation, completion: {
                if forRotation == false {
                    prepareGridViewsForReuse()
                    populateGridChildViews(models: arrModels)
                }
                completion()
            })
        }
        else {
            self.showPluginView(show: false, animation: false) { finish in
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
            for i in 0..<models.count {
                if let peerContainerView = self.gridView.childView(index: i) {
                    peerContainerView.setParticipant(meeting: self.meeting, participant: models[i].participant)
                }
            }
            
        }
    }
    
    private func createBottomBar() {
        self.bottomBar = getBottomBar()
        self.moreButtonBottomBar = self.bottomBar.moreButton
        self.view.addSubview(self.bottomBar)
        addBottomBarConstraint()
    }
    
   internal func getBottomBar() -> ActiveSpeakerMeetingControlBar {
       
       let controlBar =  ActiveSpeakerMeetingControlBar(meeting: self.meeting, delegate: nil, presentingViewController: self) {
            [weak self] in
            guard let self = self else {return}
            self.refreshMeetingGridTile(participant: self.meeting.localUser)
        } onLeaveMeetingCompletion: {
            [weak self] in
            guard let self = self else {return}
            self.leaveMeeting()
           
        }
        controlBar.clickDelegate = self
        controlBar.accessibilityIdentifier = "Meeting_ControlBottomBar"
        return controlBar
    }
    
  private  func addBottomBarConstraint() {
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
        self.bottomBar.set(.sameLeadingTrailing(self.view),
                       .bottom(self.view))
        portraitConstraints.append(contentsOf: [self.bottomBar.get(.leading)!,
                                                self.bottomBar.get(.trailing)!,
                                                self.bottomBar.get(.bottom)!])
    }
    
    private func addLandscapeContraintBottombar() {
        self.bottomBar.set(.trailing(self.view),
                           .sameTopBottom(self.view))
        landscapeConstraints.append(contentsOf: [self.bottomBar.get(.trailing)!,
                                                 self.bottomBar.get(.top)!,
                                                 self.bottomBar.get(.bottom)!])
    }

    deinit {
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    private func resetConstraints() {
        self.presentedViewController?.dismiss(animated: false)
        
        bottomBar.moreButton.hideBottomSheet()
        if UIScreen.isLandscape() {
            bottomBar.moreButton.superview?.isHidden = true
        }else {
            bottomBar.moreButton.superview?.isHidden = false
        }
        
        self.applyConstraintAsPerOrientation {
            self.fullScreenButton.isHidden = true
            self.closefullscreen()
        } onLandscape: {
            self.fullScreenButton.isSelected = false
            self.fullScreenButton.isHidden = false
        }
        
        self.showPluginViewAsPerOrientation(show: isPluginOrScreenShareActive, activeSplitContentView: self.bottomBar.isSplitContentButtonSelected())
        self.setLeftPaddingContraintForBaseContentView()
        DispatchQueue.main.async {
            self.refreshMeetingGrid(forRotation: true, completion: {})
        }
        
    }
}

extension ActiveSpeakerMeetingViewController {
    @objc func draggedView(_ sender:UIPanGestureRecognizer) {
        if let activePeerView = self.activePeerBaseView {
            let translation = sender.translation(in: activePeerView.superview!)
            var newCenter =  CGPoint(x: activePeerView.center.x + translation.x, y: activePeerView.center.y + translation.y)
            let halfWidth = activePeerView.frame.width / 2.0
            if newCenter.x <= halfWidth {
                newCenter.x = halfWidth
            }
            if newCenter.y <= halfWidth {
                newCenter.y = halfWidth
            }
            let parentView = activePeerView.superview!
            
            if newCenter.x >= (parentView.frame.width - halfWidth)  {
                newCenter.x = parentView.frame.width - halfWidth
            }
            
            if newCenter.y >= (parentView.frame.height - halfWidth)  {
                newCenter.y = parentView.frame.height - halfWidth
            }
            activePeerView.center = newCenter
            sender.setTranslation(CGPoint.zero, in: self.view)
        }
       
    }

}

private extension ActiveSpeakerMeetingViewController {
           
    private func setInitialsConfiguration() {
       // self.topBar.setInitialConfiguration()
    }
    
    private func createSubView() {
        splitContentBaseView.clipsToBounds = true
        self.view.addSubview(baseContentView)
        baseContentView.addSubview(pluginBaseView)
        baseContentView.addSubview(gridBaseView)
        baseContentView.addSubview(splitContentBaseView)
        
        pluginBaseView.accessibilityIdentifier = "Grid_Plugin_View"
        
        gridView = GridView(showingCurrently: 9, getChildView: {
            return DyteParticipantTileContainerView()
        })
        gridBaseView.addSubview(gridView)
        pluginBaseView.addSubview(pluginView)
        
        pluginView.addSubview(fullScreenButton)
        fullScreenButton.set(.trailing(pluginView, dyteSharedTokenSpace.space1),
                   .bottom(pluginView,dyteSharedTokenSpace.space1))
        fullScreenButton.addTarget(self, action: #selector(buttonClick(button:)), for: .touchUpInside)
        self.fullScreenButton.isHidden = !UIScreen.isLandscape()
        fullScreenButton.isSelected = false
       
        addPortraitConstraintForSubviews()
        addLandscapeConstraintForSubviews()
        applyConstraintAsPerOrientation(isLandscape: UIScreen.isLandscape())
        showPluginViewAsPerOrientation(show: isPluginOrScreenShareActive, activeSplitContentView: self.bottomBar.isSplitContentButtonSelected())
    }
    
    @objc func buttonClick(button: DyteButton) {
        if UIScreen.isLandscape() {
            if button.isSelected == false {
                pluginView.removeFromSuperview()
                self.addFullScreenView(contentView: pluginView)
            }else {
                closefullscreen()
            }
            button.isSelected = !button.isSelected
        }
    }
    private func closefullscreen() {
        if fullScreenView?.isVisible == true {
            self.pluginBaseView.addSubview(self.pluginView)
            self.pluginView.set(.fillSuperView(self.pluginBaseView))
            self.removeFullScreenView()
        }
    }
    
    private func showPluginViewAsPerOrientation(show: Bool, activeSplitContentView: Bool, animation: Bool = false) {
        self.splitContentBaseView.isHidden = !activeSplitContentView
        layoutPortraitContraintPluginBaseVariableHeight.isActive = false
        layoutPortraitContraintPluginBaseZeroHeight.isActive = false
       
        //layoutLandscapeContraintPluginBaseNonZeroWidth.isActive = false
        layoutLandscapeContraintPluginBaseZeroWidth.isActive = false
        
        layoutLandscapeContraintSplitContentViewZeroWidth.isActive = false
        layoutLandscapeContraintSplitContentViewNonZeroWidth.isActive = false
        
        layoutLandscapeContraintGridZeroWidth.isActive = false
        layoutPortraitContraintSplitContentViewZeroHeight.isActive = false
        if UIScreen.isLandscape() {
            
            if show {
                self.addActivePeerViewTitle()
                self.refreshActiveTitleView()
            }
            
            if activeSplitContentView {
                layoutLandscapeContraintSplitContentViewNonZeroWidth.isActive = true
                if show {
                    //show Plugin. So no need to show Grid view
                    layoutLandscapeContraintGridZeroWidth.isActive = true
                }else {
                    // Show Grid View instead of plugin and separate GridTile
                    layoutLandscapeContraintPluginBaseZeroWidth.isActive = true
                }

            } else {
                layoutPortraitContraintSplitContentViewZeroHeight.isActive = true
                layoutLandscapeContraintSplitContentViewZeroWidth.isActive = true
                if show {
                    // show PluginView
                    layoutLandscapeContraintGridZeroWidth.isActive = true
                }else {
                    layoutLandscapeContraintPluginBaseZeroWidth.isActive = true
                }
            }
        }else {
            layoutPortraitContraintSplitContentViewZeroHeight.isActive = true
            layoutPortraitContraintPluginBaseVariableHeight.isActive = show
            layoutPortraitContraintPluginBaseZeroHeight.isActive = !show
            self.removeActivePeerViewTile()
        }
        if animation {
            UIView.animate(withDuration: Animations.gridViewAnimationDuration) {
                self.baseContentView.layoutIfNeeded()
            }
        } else {
            self.baseContentView.layoutIfNeeded()
        }
    }
    
    private func addActivePeerViewTitle() {
        if self.activePeerBaseView == nil {
            self.activePeerBaseView = UIView()
            let tileBaseView = self.activePeerBaseView!
            pluginView.addSubview(tileBaseView)
            pluginView.bringSubviewToFront(tileBaseView)
            tileBaseView.set(.bottom(pluginView),.leading(pluginView), .equateAttribute(.width, toView: pluginView, toAttribute: .height, withRelation: .equal, multiplier: 0.27), .equateAttribute(.height, toView: pluginView, toAttribute: .height, withRelation: .equal, multiplier: 0.27))
            
            panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.draggedView(_:)))
            tileBaseView.addGestureRecognizer(panGesture)
            tileBaseView.isUserInteractionEnabled = true
        }
    }
    
    private func removeActivePeerViewTile() {
        self.activePeerBaseView?.removeFromSuperview()
        self.activePeerBaseView = nil

    }
    
    private func refreshActiveTitleView() {
        guard let titleBaseView = self.activePeerBaseView else {return}
        // All action should only takePlace when activeTileView is present on the screen, And It should definitely be present when Plugin/ScreenShare is active and in Landscape mode.
        var tileVisible = true
        if let pinnedUser = self.meeting.participants.pinned {
            self.activePeerView = DyteParticipantTileView(mobileClient: self.meeting, participant: pinnedUser, isForLocalUser: pinnedUser.userId == self.meeting.localUser.userId)
        } else if let active = self.meeting.participants.activeSpeaker {
            self.activePeerView = DyteParticipantTileView(mobileClient: self.meeting, participant: active, isForLocalUser: active.userId == self.meeting.localUser.userId)
        } else if self.meeting.localUser.stageStatus == StageStatus.onStage {
            self.activePeerView = DyteParticipantTileView(mobileClient: self.meeting, participant: self.meeting.localUser, isForLocalUser: true)
        } else if let active = self.meeting.participants.active.first {
            self.activePeerView = DyteParticipantTileView(mobileClient: self.meeting, participant: active, isForLocalUser: active.userId == self.meeting.localUser.userId)
        } else {
            tileVisible = false
        }
        
        if let tile = self.activePeerView, tileVisible {
            tile.isUserInteractionEnabled = true
            titleBaseView.addSubview(tile)
            tile.set(.fillSuperView(titleBaseView))
        }
    }
        
    private func addPortraitConstraintForSubviews() {
        
        baseContentView.set(.sameLeadingTrailing(self.view),
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
        pluginView.set(.fillSuperView(pluginBaseView))
        portraitConstraints.append(contentsOf: [pluginView.get(.leading)!,
                                                pluginView.get(.trailing)!,
                                                pluginView.get(.top)!,
                                                pluginView.get(.bottom)!])
    }
    
    private func addLandscapeConstraintForSubviews() {
        baseContentView.set(.leading(self.view),
                            .below(self.topBar),
                            .bottom(self.view),
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
        
        pluginView.set(.fillSuperView(pluginBaseView))
        landscapeConstraints.append(contentsOf: [pluginView.get(.leading)!,
                                                pluginView.get(.trailing)!,
                                                pluginView.get(.top)!,
                                                pluginView.get(.bottom)!])
    }

    private func createTopbar() {
        let topbar = DyteMeetingHeaderView(meeting: self.meeting)
        self.view.addSubview(topbar)
        topbar.accessibilityIdentifier = "Meeting_ControlTopBar"
        self.topBar = topbar
        addPotraitContraintTopbar()
        addLandscapeContraintTopbar()
    }
    
    private func addPotraitContraintTopbar() {
        self.topBar.set(.sameLeadingTrailing(self.view), .top(self.view))
        portraitConstraints.append(contentsOf: [self.topBar.get(.leading)!,
                                                self.topBar.get(.trailing)!,
                                                self.topBar.get(.top)!])
        setPortraitContraintAsDeactive()
    }
    
    private func addLandscapeContraintTopbar() {
        self.topBar.set(.sameLeadingTrailing(self.view) , .top(self.view))

        self.topBar.set(.height(0))
        landscapeConstraints.append(contentsOf: [self.topBar.get(.leading)!,
                                                 self.topBar.get(.trailing)!,
                                                 self.topBar.get(.top)!,
                                                 self.topBar.get(.height)!])
        setLandscapeContraintAsDeactive()
    }
}

extension ActiveSpeakerMeetingViewController : ActiveSpeakerMeetingViewModelDelegate {
    func leaveMeeting() {
        self.viewModel.clean()
        self.onFinishedMeeting()
    }
    
   
    func newPollAdded(createdBy: String) {
         self.view.showToast(toastMessage: "New poll created by \(createdBy)", duration: 2.0, uiBlocker: false)
    }
    
    func participantJoined(participant: DyteMeetingParticipant) {
        // Uncomment if you want to show toast
        // self.view.showToast(toastMessage: "\(participant.name) just joined", duration: 2.0, uiBlocker: false)
    }
    
    func participantLeft(participant: DyteMeetingParticipant) {
         // Uncomment if you want to show toast
         // self.view.showToast(toastMessage: "\(participant.name) left", duration: 2.0, uiBlocker: false)
    }

    func activeSpeakerChanged(participant: DyteMeetingParticipant) {
        //For now commenting out the functionality of Active Speaker, It's Not working as per our expectation
        refreshActiveTitleView()
    }
    
    func pinnedChanged(participant: DyteMeetingParticipant) {
//No need to do here, Because we are refreshing whole Screen when we get a callback from Core, Which we will automatically pin participant if exist at zero position.
        refreshActiveTitleView()
    }
    
    func activeSpeakerRemoved() {
        //For now commenting out the functionality of Active Speaker, It's Not working as per our expectation
        refreshActiveTitleView()
    }
    
    func pinnedParticipantRemoved(participant: DyteMeetingParticipant) {
        refreshActiveTitleView()
       updatePin(show: false, participant: participant)
    }
    
    
    private func getScreenShareTabButton(participants: [ParticipantsShareControl]) -> [ScreenShareTabButton] {
        var arrButtons = [ScreenShareTabButton]()
        for participant in participants {
            var image: DyteImage?
            if let _ = participant as? ScreenShareModel {
                //For
                image = DyteImage(image: ImageProvider.image(named: "icon_screen_share"))
            }else {
                if let strUrl = participant.image , let imageUrl = URL(string: strUrl) {
                    image = DyteImage(url: imageUrl)
                }
            }
            
            let button = ScreenShareTabButton(image: image, title: participant.name, id: participant.id)
            // TODO:Below hardcoding is not needed, We also need to scale down the image as well.
            button.btnImageView?.set(.height(20),
                                     .width(20))
            arrButtons.append(button)
        }
        return arrButtons
    }
    
    private func handleClicksOnPluginsTab(model: PluginButtonModel, at index: Int) {
        self.pluginView.show(pluginView:  model.plugin.getPluginView())
        self.viewModel.screenShareViewModel.selectedIndex = (UInt(index), model.id)
    }
    
    private func handleClicksOnScreenShareTab(model: ScreenShareModel, index: Int) {
        self.pluginView.showVideoView(participant: model.participant)
        self.pluginView.pluginVideoView.viewModel.refreshNameTag()
        self.viewModel.screenShareViewModel.selectedIndex = (UInt(index), model.id)
    }
    
    public func selectPluginOrScreenShare(id: String) {
        var index: Int = -1
        for button in self.pluginView.activeListView.buttons {
            index = index + 1
            if button.id == id {
                self.pluginView.selectForAutoSync(button: button)
                break
            }
        }
    }
    
    func refreshPluginsButtonTab(pluginsButtonsModels: [ParticipantsShareControl], arrButtons: [ScreenShareTabButton])  {
        if arrButtons.count >= 1 {
            var selectedIndex: Int?
            if let index = self.viewModel.screenShareViewModel.selectedIndex?.0 {
                selectedIndex = Int(index)
            }
            self.pluginView.setButtons(buttons: arrButtons, selectedIndex: selectedIndex) { [weak self] button, isUserClick in
                guard let self = self else {return}
                if let plugin = pluginsButtonsModels[button.index] as? PluginButtonModel {
                    if self.pluginView.syncButton?.isSelected == false && isUserClick {
                        //This is send only when Syncbutton is on and Visible
                        self.meeting.meta.syncTab(id: plugin.id, tabType: .plugin)
                    }
                    self.handleClicksOnPluginsTab(model: plugin, at: button.index)
                    
                }else if let screenShare = pluginsButtonsModels[button.index] as? ScreenShareModel {
                    if self.pluginView.syncButton?.isSelected == false && isUserClick {
                        //This is send only when Syncbutton is on and Visible
                        self.meeting.meta.syncTab(id: screenShare.id, tabType: .screenshare)
                    }
                    self.handleClicksOnScreenShareTab(model: screenShare, index: button.index)
                }
                for (index, element) in arrButtons.enumerated() {
                    element.isSelected = index == button.index ? true : false
                }
            }
        }
        self.pluginView.showAndHideActiveButtonListView(buttons: arrButtons)
    }
        
    func refreshPluginsView(completion: @escaping()->Void) {
        let participants = self.viewModel.screenShareViewModel.arrScreenShareParticipants
        let arrButtons = self.getScreenShareTabButton(participants: participants)
        self.refreshPluginsButtonTab(pluginsButtonsModels: participants, arrButtons: arrButtons)
        var onCompletion = {
            self.meetingGridPageBecomeVisible()
            completion()
        }
        if arrButtons.count >= 1 {
            var selectedIndex: Int?
            if let index = self.viewModel.screenShareViewModel.selectedIndex?.0 {
                selectedIndex = Int(index)
            }
            if let index = selectedIndex {
                if let pluginModel = participants[index] as? PluginButtonModel {
                    self.pluginView.show(pluginView: pluginModel.plugin.getPluginView())
                }
               else if let screenShare = participants[index] as? ScreenShareModel {
                    self.pluginView.showVideoView(participant: screenShare.participant)
                }
                self.showPlugInView() {
                    onCompletion()
                }
            }
        } else {
            self.hidePlugInView(tab: arrButtons) {
                onCompletion()
            }
        }
    }
    
    private func showPluginView(show: Bool, animation: Bool,  completion: @escaping((Bool) -> Void)) {
        self.showPluginViewAsPerOrientation(show: show, activeSplitContentView: self.bottomBar.isSplitContentButtonSelected())
        pluginBaseView.isHidden = !show
        if animation {
            UIView.animate(withDuration: Animations.gridViewAnimationDuration, animations: {
                self.view.layoutIfNeeded()
            }, completion: completion)
        }else {
            self.view.layoutIfNeeded()
            completion(true)
        }
    }
    
    private func loadGrid(fullScreen: Bool, animation: Bool, completion:@escaping()->Void) {
        let arrModels = self.viewModel.arrGridParticipants
        if fullScreen == false {
            if UIScreen.isLandscape() {
                self.gridView.settingFramesForPluginsActiveInLandscapeMode(visibleItemCount: UInt(arrModels.count), animation: animation) { finish in
                    completion()
                }
            }else {
                self.gridView.settingFramesForPluginsActiveInPortraitMode(visibleItemCount: UInt(arrModels.count), animation: animation) { finish in
                    completion()
                }
            }
            
        }else {
            if UIScreen.isLandscape() {
                self.gridView.settingFramesForLandScape(visibleItemCount: UInt(arrModels.count), animation: animation) { finish in
                    completion()
                }
            }else {
                self.gridView.settingFrames(visibleItemCount: UInt(arrModels.count), animation: animation) { finish in
                    completion()
                }
            }
           
        }
    }
    
    private func showPlugInView(completion:@escaping()->Void) {
        // We need to move gridview to Starting View
        isPluginOrScreenShareActive = true
        if self.meeting.participants.currentPageNumber == 0 {
            //We have to only show PluginView on page == 0 only
            self.showPluginView(show: true, animation: true) { finish in
                self.loadGrid(fullScreen: false, animation: true, completion: completion)
            }
        }else {
            completion()
        }
    }
    
    private func hidePlugInView(tab buttons: [ScreenShareTabButton], completion: @escaping()->Void) {
        // No need to show any plugin or share view
        isPluginOrScreenShareActive = false
        self.pluginView.setButtons(buttons: buttons, selectedIndex: nil) {_,_  in}
        self.showPluginView(show: false, animation: true) { finish in
            if self.meeting.participants.currentPageNumber == 0 {
                self.loadGrid(fullScreen: true, animation: true, completion: completion)
            }else {
                completion()
            }
        }
    }
    
    func updatePin(show:Bool, participant: DyteMeetingParticipant) {
        let arrModels = self.viewModel.arrGridParticipants
        var index = -1
        for model in arrModels {
            index += 1
            if model.participant.userId == participant.userId {
                if let peerView = self.gridView.childView(index: index)?.tileView {
                    peerView.pinView(show: show)
                }
            }
        }
        
    }
    
    /* This method is used to refresh (Mainly to reload video view) Single grid tile associated with participant passed*/
    func refreshMeetingGridTile(participant: DyteMeetingParticipant) {
        let arrModels = self.viewModel.arrGridParticipants
        var index = -1
        for model in arrModels {
            index += 1
            if model.participant.userId == participant.userId {
                if let peerContainerView = self.gridView.childView(index: index) {
                    peerContainerView.setParticipant(meeting: self.meeting, participant: arrModels[index].participant)
                    return
                }
            }
        }
    }
   
    private func meetingGridPageBecomeVisible() {
        
        if let participant = meeting.participants.pinned {
            self.refreshMeetingGridTile(participant: participant)
        }
        self.topBar.refreshNextPreviouButtonState()
    }
}



extension ActiveSpeakerMeetingViewController: DyteNotificationDelegate {
   
    public func didReceiveNotification(type: DyteNotificationType) {
        switch type {
        case .Chat(let message):
            viewModel.dyteNotification.playNotificationSound(type: type)
            if  message.isEmpty == false {
                self.view.showToast(toastMessage: message, duration: 2.0, uiBlocker: false, showInBottom: true, bottomSpace: self.bottomBar.bounds.height)
            }
            NotificationCenter.default.post(name: Notification.Name("Notify_NewChatArrived"), object: nil, userInfo: nil)
            self.moreButtonBottomBar?.notificationBadge.isHidden = false
        case .Poll:
            NotificationCenter.default.post(name: Notification.Name("Notify_NewPollArrived"), object: nil, userInfo: nil)
            viewModel.dyteNotification.playNotificationSound(type: .Poll)
            self.moreButtonBottomBar?.notificationBadge.isHidden = false
        case .Joined:
            // Uncomment if you want to play sound
           // viewModel.dyteNotification.playNotificationSound(type: .Joined)
            break;

        case .Leave:
            // Uncomment if you want to play sound
           // viewModel.dyteNotification.playNotificationSound(type: .Leave)
            break;

        }

    }
    
    public func clearChatNotification() {
        self.moreButtonBottomBar?.notificationBadge.isHidden = true
    }
}

extension ActiveSpeakerMeetingViewController {
    func setupNotifications() {
           NotificationCenter.default.addObserver(self, selector: #selector(self.onEndMettingForAllButtonPressed), name: DyteLeaveDialog.onEndMeetingForAllButtonPress, object: nil)
       }
       // MARK: Notification Setup Functionality
       @objc private func onEndMettingForAllButtonPressed(notification: Notification) {
           self.viewModel.dyteSelfListner.observeSelfRemoved(update: nil)
       }
}


extension ActiveSpeakerMeetingViewController {
    func addFullScreenView(contentView: UIView) {
            if fullScreenView == nil {
                fullScreenView =  FullScreenView()
                self.view.addSubview(fullScreenView)
                fullScreenView.set(.fillSuperView(self.view))
            }
            fullScreenView.backgroundColor = self.view.backgroundColor
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
        self.addSubview(self.containerView)
        self.containerView.set(.fillSuperView(self))
        self.setEdgeConstants()
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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        setEdgeConstants()
    }
    
    private func setEdgeConstants() {
        self.containerView.get(.leading)?.constant = self.safeAreaInsets.left
        self.containerView.get(.trailing)?.constant = -self.safeAreaInsets.right
        self.containerView.get(.top)?.constant = self.safeAreaInsets.top
        self.containerView.get(.bottom)?.constant = -self.safeAreaInsets.bottom
    }
    
}



extension ActiveSpeakerMeetingViewController: ActiveSpeakerMeetingControlBarDelegate {
  
    func settingClick(button: DyteControlBarButton) {
         resetContentViewState()
        let controller = SettingViewController(nameTag: self.meeting.localUser.name, dyteMobileClient: self.meeting, completion:{
            self.refreshMeetingGridTile(participant: self.meeting.localUser)
            button.isSelected = false
        })
        controller.view.backgroundColor = self.view.backgroundColor
        controller.modalPresentationStyle = .fullScreen
        self.present(controller, animated: true)
    }
    
    func chatClick(button: DyteControlBarButton) {
        resetContentViewState()
        if button.isSelected {
            let controller = ChatViewController(dyteMobileClient: self.meeting)
            self.splitContentBaseView.addSubview(controller.view)
            controller.view.set(.fillSuperView(self.splitContentBaseView))
            self.splitContentViewController = controller
        }

    }
        
    func pollsClick(button: DyteControlBarButton) {
        resetContentViewState()
        if button.isSelected {
            let controller = ShowPollsViewController(dyteMobileClient: self.meeting)
            controller.shouldShowTopBar = false
            self.splitContentBaseView.addSubview(controller.view)
            controller.view.set(.fillSuperView(self.splitContentBaseView))
            self.splitContentViewController = controller
        }
    }
    
    private func resetContentViewState() {
        self.splitContentViewController?.view.removeFromSuperview()
        var showPluginView = isPluginOrScreenShareActive
        if self.meeting.participants.currentPageNumber > 0 {
            showPluginView = false
        }
        self.showPluginViewAsPerOrientation(show: showPluginView, activeSplitContentView: self.bottomBar.isSplitContentButtonSelected())
        self.refreshGrid(showPlugin: showPluginView, showSplitContent: self.bottomBar.isSplitContentButtonSelected(), isLandscape: UIScreen.isLandscape())
    }
    
    private func refreshGrid(showPlugin:Bool, showSplitContent: Bool, isLandscape: Bool) {
        if isLandscape {
            if showPlugin == false {
                self.refreshMeetingGrid(forRotation: true, animation: false) {}
            }
        }
    }
}
