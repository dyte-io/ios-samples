//
//  PollsButtonControlBar.swift
//  active-speaker-ui-sample
//
//  Created by Dyte on 23/01/24.
//

import DyteiOSCore
import DyteUiKit

open class PollsButtonControlBar: DyteControlBarButton {
    private let mobileClient: DyteMobileClient
    private var dyteSelfListner: DyteEventSelfListner
    private let onClick: ((PollsButtonControlBar) -> Void)?

    public init(meeting: DyteMobileClient, onClick: ((PollsButtonControlBar) -> Void)? = nil, appearance: DyteControlBarButtonAppearance = AppTheme.shared.controlBarButtonAppearance) {
        mobileClient = meeting
        self.onClick = onClick
        dyteSelfListner = DyteEventSelfListner(mobileClient: mobileClient)
        super.init(image: DyteImage(image: ImageProvider.image(named: "icon_polls")), title: "Polls", appearance: appearance)
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
        self.dyteSelfListner.clean()
    }
}
