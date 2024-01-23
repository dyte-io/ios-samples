//
//  PollsButtonControlBar.swift
//  active-speaker-ui-sample
//
//  Created by Dyte on 23/01/24.
//

import DyteUiKit
import DyteiOSCore

open class  PollsButtonControlBar: DyteControlBarButton {
    private let mobileClient: DyteMobileClient
    private var dyteSelfListner: DyteEventSelfListner
    private let onClick: ((PollsButtonControlBar)->Void)?

    public init(meeting: DyteMobileClient, onClick:((PollsButtonControlBar)->Void)? = nil, appearance: DyteControlBarButtonAppearance = AppTheme.shared.controlBarButtonAppearance) {
        self.mobileClient = meeting
        self.onClick = onClick
        self.dyteSelfListner = DyteEventSelfListner(mobileClient: mobileClient)
        super.init(image: DyteImage(image: ImageProvider.image(named: "icon_polls")), title: "Polls", appearance: appearance)
        self.addTarget(self, action: #selector(onClick(button:)), for: .touchUpInside)
       
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc open func onClick(button: PollsButtonControlBar) {
        self.onClick?(button)
    }
    
    deinit {
        self.dyteSelfListner.clean()
    }
  
}
