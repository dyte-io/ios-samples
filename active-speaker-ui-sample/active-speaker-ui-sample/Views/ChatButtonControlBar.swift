//
//  ChatButtonControlBar.swift
//  active-speaker-ui-sample
//
//  Created by Dyte on 23/01/24.
//

import DyteiOSCore
import DyteUiKit

class ChatButtonControlBar: DyteControlBarButton {
    private let mobileClient: DyteMobileClient
    private var dyteSelfListner: DyteEventSelfListner
    private let onClick: ((ChatButtonControlBar) -> Void)?

    init(meeting: DyteMobileClient, onClick: ((ChatButtonControlBar) -> Void)? = nil, appearance: DyteControlBarButtonAppearance = AppTheme.shared.controlBarButtonAppearance) {
        mobileClient = meeting
        self.onClick = onClick
        dyteSelfListner = DyteEventSelfListner(mobileClient: mobileClient)
        super.init(image: DyteImage(image: ImageProvider.image(named: "icon_chat")), title: "", appearance: appearance)
        selectedStateTintColor = dyteSharedTokenColor.brand.shade500
        addTarget(self, action: #selector(onClick(button:)), for: .touchUpInside)
        NotificationCenter.default.addObserver(self, selector: #selector(clearChatNotification), name: Notification.Name("NotificationAllChatsRead"), object: nil)
    }

    @objc
    func clearChatNotification() {
        notificationBadge.isHidden = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc open func onClick(button: ChatButtonControlBar) {
        onClick?(button)
    }

    deinit {
        self.dyteSelfListner.clean()
    }
}
