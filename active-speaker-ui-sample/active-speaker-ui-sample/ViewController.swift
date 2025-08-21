//
//  ViewController.swift
//  active-speaker-ui-sample
//
//  Created by Dyte on 23/01/24.
//

import DyteiOSCore
import DyteUiKit
import UIKit

class TextFieldView: UIView {
    let paddingSpace: CGFloat = 12
    let veticalPaddingSpace: CGFloat = 14

    var title: UILabel = {
        let lable = UILabel()
        lable.textAlignment = .center
        lable.font = UIFont.boldSystemFont(ofSize: 16)
        lable.textColor = .black
        return lable
    }()

    var titleTextField1: UILabel = {
        let lable = UILabel()
        lable.textAlignment = .left
        lable.font = UIFont.boldSystemFont(ofSize: 10)
        lable.textColor = .black
        return lable
    }()

    var textField1: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        return textField
    }()

    var titleTextField2: UILabel = {
        let lable = UILabel()
        lable.textAlignment = .left
        lable.font = UIFont.boldSystemFont(ofSize: 10)
        lable.textColor = .black
        return lable
    }()

    lazy var textField2: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect

        return textField
    }()

    var button: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemBlue
        return button
    }()

    var separatorView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    private var textField2PlaceHolder: String!

    init(title: String, textField1: String?, textField2: String?, button: String) {
        let textField1 = (textField1 ?? "").count < 1 ? nil : textField1
        let textField2 = (textField2 ?? "").count < 1 ? nil : textField2

        self.title.text = title
        self.textField1.placeholder = textField1
        titleTextField1.text = textField1
        titleTextField2.text = textField2
        textField2PlaceHolder = textField2
        self.button.setTitle(button, for: .normal)
        super.init(frame: .zero)
        self.textField2.placeholder = textField2
        setUp()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setUp() {
        addSubViews(separatorView, title)

        separatorView.set(.sameLeadingTrailing(self),
                          .top(self),
                          .height(1.0))
        title.set(.below(separatorView, paddingSpace),
                  .sameLeadingTrailing(self, paddingSpace))

        if textField2PlaceHolder != nil, textField1.placeholder != nil {
            textField2.placeholder = textField2PlaceHolder
            addSubViews(titleTextField1, textField1, titleTextField2, textField2, button)

            titleTextField1.set(.below(title, veticalPaddingSpace),
                                .sameLeadingTrailing(self, paddingSpace))

            textField1.set(.below(titleTextField1, veticalPaddingSpace / 2),
                           .sameLeadingTrailing(self, paddingSpace))

            titleTextField2.set(.below(textField1, veticalPaddingSpace),
                                .sameLeadingTrailing(self, paddingSpace))

            textField2.set(.below(titleTextField2, veticalPaddingSpace / 2),
                           .sameLeadingTrailing(self, paddingSpace))

            button.set(.below(textField2, veticalPaddingSpace * 2),
                       .sameLeadingTrailing(self, paddingSpace * 4),
                       .bottom(self))
        } else if textField2PlaceHolder != nil, textField1.placeholder == nil {
            textField2.placeholder = textField2PlaceHolder
            addSubViews(titleTextField2, textField2, button)

            titleTextField2.set(.below(title, veticalPaddingSpace),
                                .sameLeadingTrailing(self, paddingSpace))
            textField2.set(.below(titleTextField2, veticalPaddingSpace / 2.0),
                           .sameLeadingTrailing(self, paddingSpace))
            button.set(.below(textField2, veticalPaddingSpace * 2),
                       .sameLeadingTrailing(self, paddingSpace * 4),
                       .bottom(self))

        } else if textField2PlaceHolder == nil, textField1.placeholder == nil {
            textField2.placeholder = textField2PlaceHolder
            addSubViews(button)
            button.set(.below(title, veticalPaddingSpace * 2),
                       .sameLeadingTrailing(self, paddingSpace * 4),
                       .bottom(self))
        } else {
            addSubViews(titleTextField1, textField1, button)
            titleTextField1.set(.below(title, veticalPaddingSpace),
                                .sameLeadingTrailing(self, paddingSpace))
            textField1.set(.below(titleTextField1, veticalPaddingSpace / 2.0),
                           .sameLeadingTrailing(self, paddingSpace))
            button.set(.below(textField1, veticalPaddingSpace * 2),
                       .sameLeadingTrailing(self, paddingSpace * 4),
                       .bottom(self))
        }
        button.set(.width(150, .greaterThanOrEqual))
    }
}

class ViewController: UIViewController {
    private var dyteUikit: DyteUiKit!

    private let joinThroughAuthTokenMeetingView: TextFieldView = {
        // let view = TextFieldView(title: "Join Meeting", textField1: "Enter Base Url", textField2: "Enter participant Authtoken", button: "Start")
        let view = TextFieldView(title: "Join Meeting", textField1: "Base URL", textField2: "Auth Token", button: "Start")
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        addAuthoTokenTextField()
        joinThroughAuthTokenMeetingView.textField2.text = MeetingConfig.AUTH_TOKEN
        joinThroughAuthTokenMeetingView.textField1.text = MeetingConfig.BASE_URL
    }

    func addAuthoTokenTextField() {
        joinThroughAuthTokenMeetingView.button.addTarget(self, action: #selector(buttonClick(button:)), for: .touchUpInside)
        view.addSubview(joinThroughAuthTokenMeetingView)
        joinThroughAuthTokenMeetingView.set(.top(view, 100),
                                            .trailing(view, 20, .greaterThanOrEqual),
                                            .leading(view, 20, .greaterThanOrEqual))
    }

    @objc
    func buttonClick(button _: UIButton) {
        startMeeting()
    }

    private func startMeeting() {
        guard let baseUrl = joinThroughAuthTokenMeetingView.textField1.text, let authToken = joinThroughAuthTokenMeetingView.textField2.text else { return }
        dyteUikit = DyteUiKit(meetingInfoV2: DyteMeetingInfoV2(authToken: authToken, enableAudio: true, enableVideo: true, baseUrl: baseUrl), flowDelegate: self)
        let controller = dyteUikit.startMeeting {
            [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true)
        }
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
    }
}

// return nil in case you want to use DyteUiKit's UI
extension ViewController: DyteUIKitFlowCoordinatorDelegate {
    func showGroupCallMeetingScreen(meeting: DyteMobileClient, completion: @escaping () -> Void) -> UIViewController? {
        let controller = ActiveSpeakerMeetingViewController(meeting: meeting, completion: completion)
        return controller
    }

    func showWebinarMeetingScreen(meeting: DyteMobileClient, completion: @escaping () -> Void) -> UIViewController? {
        dyteUikit.mobileClient.participants.disableCache()
        let controller = ActiveSpeakerWebinarMeetingViewController(meeting: meeting, completion: completion)
        return controller
    }

    func showSetUpScreen(completion _: () -> Void) -> SetupViewControllerDataSource? {
        return nil
    }
}
