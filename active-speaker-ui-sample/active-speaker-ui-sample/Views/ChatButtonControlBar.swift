//
//  ChatButtonControlBar.swift
//  active-speaker-ui-sample
//
//  Created by Dyte on 23/01/24.
//

import Foundation
import RealtimeKit
import RealtimeKitUI

class ChatButtonControlBar: RtkControlBarButton {
    private let rtkClient: RealtimeKitClient
    private var selfListener: RtkEventSelfListener
    private let onClick: ((ChatButtonControlBar) -> Void)?

    init(meeting: RealtimeKitClient, onClick: ((ChatButtonControlBar) -> Void)? = nil, appearance: RtkControlBarButtonAppearance = AppTheme.shared.controlBarButtonAppearance) {
        rtkClient = meeting
        self.onClick = onClick
        selfListener = RtkEventSelfListener(rtkClient: meeting)
        super.init(image: RtkImage(image: ImageProvider.image(named: "icon_chat")), title: "", appearance: appearance)
        selectedStateTintColor = rtkSharedTokenColor.brand.shade500
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
        self.selfListener.clean()
    }
}
