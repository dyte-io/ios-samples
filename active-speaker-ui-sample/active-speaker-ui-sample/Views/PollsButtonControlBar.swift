//
//  PollsButtonControlBar.swift
//  active-speaker-ui-sample
//
//  Created by Dyte on 23/01/24.
//

import Foundation
import RealtimeKit
import RealtimeKitUI

open class PollsButtonControlBar: RtkControlBarButton {
    private let rtkClient: RealtimeKitClient
    private var selfListener: RtkEventSelfListener
    private let onClick: ((PollsButtonControlBar) -> Void)?

    public init(meeting: RealtimeKitClient, onClick: ((PollsButtonControlBar) -> Void)? = nil, appearance: RtkControlBarButtonAppearance = AppTheme.shared.controlBarButtonAppearance) {
        rtkClient = meeting
        self.onClick = onClick
        selfListener = RtkEventSelfListener(rtkClient: meeting)
        super.init(image: RtkImage(image: ImageProvider.image(named: "icon_polls")), title: "Polls", appearance: appearance)
        addTarget(self, action: #selector(onClick(button:)), for: .touchUpInside)
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc open func onClick(button: PollsButtonControlBar) {
        onClick?(button)
    }

    deinit {
        self.selfListener.clean()
    }
}
