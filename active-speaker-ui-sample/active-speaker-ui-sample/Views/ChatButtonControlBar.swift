//
//  ChatButtonControlBar.swift
//  active-speaker-ui-sample
//
//  Created by Dyte on 23/01/24.
//

import DyteUiKit
import DyteiOSCore

class  ChatButtonControlBar: DyteControlBarButton {
private let mobileClient: DyteMobileClient
private var dyteSelfListner: DyteEventSelfListner
private let onClick: ((ChatButtonControlBar)->Void)?

public init(meeting: DyteMobileClient, onClick:((ChatButtonControlBar)->Void)? = nil, appearance: DyteControlBarButtonAppearance = AppTheme.shared.controlBarButtonAppearance) {
    self.mobileClient = meeting
    self.onClick = onClick
    self.dyteSelfListner = DyteEventSelfListner(mobileClient: mobileClient)
    super.init(image: DyteImage(image: ImageProvider.image(named: "icon_chat")), title: "", appearance: appearance)
    self.selectedStateTintColor = dyteSharedTokenColor.brand.shade500
    self.addTarget(self, action: #selector(onClick(button:)), for: .touchUpInside)
    NotificationCenter.default.addObserver(self, selector: #selector(self.clearChatNotification), name: Notification.Name("NotificationAllChatsRead"), object: nil)
}

@objc
public  func clearChatNotification() {
    self.notificationBadge.isHidden = true
}

required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
}

@objc open func onClick(button: ChatButtonControlBar) {
    self.onClick?(button)
}

deinit {
    self.dyteSelfListner.clean()
}

}

