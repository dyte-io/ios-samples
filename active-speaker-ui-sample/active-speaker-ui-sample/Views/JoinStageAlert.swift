import UIKit
import DyteiOSCore
import DyteUiKit

class JoinStageAlert: UIView, ConfigureWebinerAlertView, AdaptableUI {

    internal var portraitConstraints = [NSLayoutConstraint]()
    internal var landscapeConstraints = [NSLayoutConstraint]()
    
    private let baseView = UIView()
    private let borderRadiusType: BorderRadiusToken.RadiusType = AppTheme.shared.cornerRadiusTypePeerView ?? .rounded
    private lazy var dyteSelfListner: DyteEventSelfListner = {
        return DyteEventSelfListner(mobileClient: self.meeting)
    }()
    
    private let lblTop: DyteText = {
        let lbl = DyteUIUTility.createLabel(text: "Join Stage" , alignment: .center)
        lbl.numberOfLines = 0
        lbl.font = UIFont.systemFont(ofSize: 16)
        return lbl
    }()
    
    private let selfPeerView: DyteParticipantTileView
    private var meeting: DyteMobileClient
    
    private let btnVideo: DyteButton = {
        let button = DyteButton(style: .iconOnly(icon: DyteImage(image: ImageProvider.image(named: "icon_video_enabled"))), dyteButtonState: .active)
        button.normalStateTintColor = DesignLibrary.shared.color.textColor.onBackground.shade1000
        button.setImage(ImageProvider.image(named: "icon_video_disabled")?.withRenderingMode(.alwaysTemplate), for: .selected)
        button.selectedStateTintColor = DesignLibrary.shared.color.status.danger
        button.backgroundColor = dyteSharedTokenColor.background.shade900
        return button
    }()
    
    private let btnMic: DyteButton = {
        let button =  DyteButton(style: .iconOnly(icon: DyteImage(image: ImageProvider.image(named: "icon_mic_enabled"))), dyteButtonState: .active)
        button.normalStateTintColor = DesignLibrary.shared.color.textColor.onBackground.shade1000
        button.selectedStateTintColor = DesignLibrary.shared.color.status.danger
        button.setImage(ImageProvider.image(named: "icon_mic_disabled")?.withRenderingMode(.alwaysTemplate), for: .selected)
        button.backgroundColor = dyteSharedTokenColor.background.shade900
        return button
    }()
    
    private  let lblBottom: DyteText = {
        let lbl = DyteUIUTility.createLabel(text: "You are about to join stage. Your Video and audio will be visible as previewed here to all the participants", alignment: .center)
        lbl.font = UIFont.systemFont(ofSize: 12)
        lbl.numberOfLines = 0
        return lbl
    }()
    
    let confirmAndJoinButton: DyteButton = {
        let button = DyteUIUTility.createButton(text: "Join Stage")
        return button
    }()
    
    public let cancelButton: DyteButton = {
        let button = DyteUIUTility.createButton(text: "Cancel")
        button.backgroundColor = dyteSharedTokenColor.background.shade800
        return button
    }()
    
    init(meetingClient: DyteMobileClient, participant: DyteJoinedMeetingParticipant) {
        self.meeting = meetingClient
        selfPeerView = DyteParticipantTileView(viewModel: VideoPeerViewModel(mobileClient: meeting, participant: participant, showSelfPreviewVideo: true))
        super.init(frame: .zero)
        setupSubview()
        NotificationCenter.default.addObserver(self, selector: #selector(onRotationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
  }

deinit {
   NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
}

 @objc private func onRotationChange() {
     applyConstraintAsPerOrientation()
 }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func clickMic(button: DyteButton) {
        button.showActivityIndicator()
        dyteSelfListner.toggleLocalAudio(completion: { [weak self] isEnabled in
            guard let self = self else {return}
            button.hideActivityIndicator()
            self.selfPeerView.nameTag.refresh()
            button.isSelected = !isEnabled
        })
        
    }
    
    @objc func clickVideo(button: DyteButton) {
        button.showActivityIndicator()
        dyteSelfListner.toggleLocalVideo(completion: { [weak self] isEnabled  in
            guard let self = self else {return}
            button.hideActivityIndicator()
            button.isSelected = !isEnabled
            self.loadSelfVideoView()
        })
    }
    
  
}

extension JoinStageAlert {
    
    private func setupSubview() {
        createSubview()
        btnMic.isSelected = !self.meeting.localUser.audioEnabled
        btnVideo.isSelected = !self.meeting.localUser.videoEnabled
        btnMic.addTarget(self, action: #selector(clickMic(button:)), for: .touchUpInside)
        btnVideo.addTarget(self, action: #selector(clickVideo(button:)), for: .touchUpInside)
    }
    
    private func createSubView(baseView: UIView) {
        let btnStackView = DyteUIUTility.createStackView(axis: .horizontal, spacing: dyteSharedTokenSpace.space1)
        btnStackView.addArrangedSubviews(btnMic, btnVideo)
        selfPeerView.addSubview(btnStackView)
        
        selfPeerView.nameTag.isHidden = true
        
        let btnBottomStackView = DyteUIUTility.createStackView(axis: .horizontal, spacing: dyteSharedTokenSpace.space1)
        btnBottomStackView.addArrangedSubviews(confirmAndJoinButton, cancelButton)
        btnBottomStackView.axis = .horizontal
        btnBottomStackView.distribution = .fillEqually
        
        baseView.addSubViews(lblTop, selfPeerView, lblBottom, btnBottomStackView)
        
        lblTop.set(.sameLeadingTrailing(baseView),
                   .centerX(baseView),
                   .top(baseView, dyteSharedTokenSpace.space2))
        
        
        selfPeerView.clipsToBounds = true
        
        selfPeerView.set(.below(lblTop, dyteSharedTokenSpace.space2, .greaterThanOrEqual),
                         .centerX(baseView))
        
        let portraitPeerViewWidth =  ConstraintCreator.Constraint.equate(viewAttribute: .width, toView: baseView, toViewAttribute: .width, relation: .equal, constant: 0, multiplier: 0.6).getConstraint(for: selfPeerView)
        let portraitPeerViewHeight =  ConstraintCreator.Constraint.equate(viewAttribute: .height, toView: baseView, toViewAttribute: .width, relation: .equal, constant: 0, multiplier: 0.7).getConstraint(for: selfPeerView)
        portraitConstraints.append(contentsOf:[portraitPeerViewWidth,
                                                portraitPeerViewHeight])
        
        let landScapePeerViewWidth =  ConstraintCreator.Constraint.equate(viewAttribute: .width, toView: baseView, toViewAttribute: .width, relation: .equal, constant: 0, multiplier: 0.6).getConstraint(for: selfPeerView)
        let landScapePeerViewHeight =  ConstraintCreator.Constraint.equate(viewAttribute: .height, toView: baseView, toViewAttribute: .width, relation: .equal, constant: 0, multiplier: 0.4).getConstraint(for: selfPeerView)
        landscapeConstraints.append(contentsOf:[landScapePeerViewWidth,
                                    landScapePeerViewHeight])

        
        btnStackView.set(.bottom(selfPeerView, dyteSharedTokenSpace.space2),
                         .trailing(selfPeerView, dyteSharedTokenSpace.space2))
        btnStackView.set(.height(32))
        landscapeConstraints.append(btnStackView.get(.height)!)
        
        lblBottom.set(.sameLeadingTrailing(baseView, dyteSharedTokenSpace.space2),
                      .below(selfPeerView, dyteSharedTokenSpace.space2, .greaterThanOrEqual))
        
        btnBottomStackView.set(.below(lblBottom, dyteSharedTokenSpace.space4),
                               .centerX(baseView),
                               .bottom(baseView,dyteSharedTokenSpace.space2))
    }
    
    private func createSubview() {
        baseView.layer.cornerRadius = DesignLibrary.shared.borderRadius.getRadius(size: .two, radius: borderRadiusType)
        baseView.layer.masksToBounds = true
        
        self.addSubview(baseView)
        self.createSubView(baseView: baseView)
        baseView.backgroundColor = dyteSharedTokenColor.background.shade900
        self.backgroundColor = dyteSharedTokenColor.background.shade1000.withAlphaComponent(0.9)
        addConstraintForBaseView()
        applyConstraintAsPerOrientation()
    }
    
    private func addConstraintForBaseView() {
        addPortaitConstraintsForBaseView()
        addLandscapeConstraintForBaseView()
    }
    
    private func addPortaitConstraintsForBaseView() {
        let equalWidthConstraintBaseView =  ConstraintCreator.Constraint.equate(viewAttribute: .width, toView: self, toViewAttribute: .width, relation: .equal, constant: 10, multiplier: 0.8).getConstraint(for: baseView)
        
        baseView.set(.centerView(self),
                     .top(self, dyteSharedTokenSpace.space8, .greaterThanOrEqual))
        
        portraitConstraints.append(contentsOf: [baseView.get(.top)!,
                                                baseView.get(.centerY)!,
                                                baseView.get(.centerX)!,
                                                equalWidthConstraintBaseView])
        
    }
    
    private func addLandscapeConstraintForBaseView() {
        let equalWidthConstraintBaseView =  ConstraintCreator.Constraint.equate(viewAttribute: .width, toView: self, toViewAttribute: .width, relation: .equal, constant: 10, multiplier: 0.5).getConstraint(for: baseView)
        
        baseView.set(.centerView(self),
                     .top(self, dyteSharedTokenSpace.space8, .greaterThanOrEqual))
        landscapeConstraints.append(contentsOf: [baseView.get(.top)!,
                                                baseView.get(.centerY)!,
                                                baseView.get(.centerX)!,
                                                 equalWidthConstraintBaseView])
    }
    
    private func loadSelfVideoView() {
        selfPeerView.refreshVideo()
    }
}
