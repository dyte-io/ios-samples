//
//  ViewController.swift
//  DyteiOSUIKitExample
//
//  Created by sudhir kumar on 27/01/23.
//

import UIKit
import DyteUiKit
import DyteiOSCore
import AVKit

class RadioView: UIView {
    let radioButton = UIButton()
    let selectionView = UIView()
    
    let selectionRaidus:CGFloat = 13
    init() {
        super.init(frame: .zero)
        setUpUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUpUI() {
        self.addSubview(radioButton)
        radioButton.set(.fillSuperView(self))
        radioButton.backgroundColor = .systemBlue
        selectionView.backgroundColor = .systemGreen
        radioButton.addSubViews(selectionView)
        selectionView.set( .top(radioButton,2, .greaterThanOrEqual),
                           .centerView(radioButton),
                           .leading(radioButton, 2, .greaterThanOrEqual),
                          .size(CGSize(width: selectionRaidus, height: selectionRaidus)))
        self.layer.cornerRadius = selectionRaidus/2.0
        selectionView.layer.cornerRadius = selectionRaidus/2.0
        self.layer.masksToBounds = true
        
    }
    
    func setSelected(isSelect: Bool) {
        self.isHidden = isSelect ? false : true
    }
}

class RadioSelectionTableViewCell: UITableViewCell {
    
    let padding: CGFloat = 12
    let radioView = {
        let view = RadioView()
        view.isUserInteractionEnabled = false
        return view
    }()
    
    
    let title: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.numberOfLines = 0
        return label
    }()
    
    
    var click: (()->Void)? = nil

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpUi()
    }
    
    func configure(model: SelectionModel) {
        radioView.setSelected(isSelect: model.isSelected)
        title.text = model.title
    }
    
    func setUpUi() {
        self.contentView.addSubViews(radioView,title)
        radioView.set(.leading(contentView, padding),
                      .centerY(contentView),
                      .size(20, 20))
        title.set(.after(radioView, padding*2),
                  .centerY(self.contentView),
                  .top(self.contentView, padding, .greaterThanOrEqual),
                  .trailing(self.contentView,padding))
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapCLick(gesture:)))
        contentView.addGestureRecognizer(tapGesture)
    }
    
   @objc func tapCLick(gesture: UITapGestureRecognizer) {
        self.click?()
    }
    
    required  public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



protocol SelectionModel: AnyObject {
    var isSelected: Bool {get set}
    var title: String {get}
    var id: String {get}

}

class PresetSelectionModel: SelectionModel {
    var isSelected: Bool = false
    var title: String = ""
    var id: String
    
    init(isSelected: Bool, title: String, id: String) {
        self.isSelected = isSelected
        self.title = title
        self.id = id
    }
}

class EnvironmentSelectionModel: SelectionModel {
    var isSelected: Bool = false
    var demoAppUrl: String = ""
    var title: String  {
        get {
            return self.demoAppUrl
        }
    }
    var id: String
    var dyteServerUrl: String = ""
    
    init(isSelected: Bool, demoAppUrl: String, id: String, dyteServerUrl: String) {
        self.isSelected = isSelected
        self.demoAppUrl = demoAppUrl
        self.id = id
        self.dyteServerUrl = dyteServerUrl
    }
    
}

class SelectionView <T: SelectionModel> : UIView, UITableViewDataSource, UITableViewDelegate {
   
    let padding:CGFloat = 12
    
    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.estimatedRowHeight = 50
        tableView.allowsSelection = true
        tableView.rowHeight = UITableView.automaticDimension
        return tableView
    }()
    
    let doneButton: UIButton = {
        let button = UIButton(type: .roundedRect)
        button.setTitle("Done", for: .normal)
        return button
    }()
    
    let cancelButton: UIButton = {
        let button = UIButton(type: .roundedRect)
        button.setTitle("Cancel", for: .normal)
        return button
    }()
    
    private var completion: (T) -> Void
    fileprivate let selectId: String
    
    init(model:[[T]], selectionId:String, completion:@escaping(T) -> Void) {
        self.completion = completion
        self.selectId = selectionId
        self.model = model
        super.init(frame: .zero)
        setUpUi()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
   
    fileprivate var model : [[SelectionModel]]
    
    func setUpUi() {
        self.tableView.layer.borderColor = UIColor.black.cgColor
        self.tableView.layer.borderWidth = 1.0
        self.tableView.layer.cornerRadius = 10
        self.tableView.layer.masksToBounds = true
        self.tableView.clipsToBounds = true
        self.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        self.addSubViews(cancelButton,doneButton,tableView)
        cancelButton.set(.top(self),
                         .leading(self))
        doneButton.set(.trailing(self),
                       .top(self))
        tableView.set(.below(cancelButton, padding),
                      .sameLeadingTrailing(self, padding),
                      .bottom(self, padding*20))
        tableView.register(RadioSelectionTableViewCell.self)
        tableView.dataSource = self
        tableView.delegate = self
        cancelButton.addTarget(self, action:#selector(cancelButtonClick(button:)), for: .touchUpInside)
        doneButton.addTarget(self, action:#selector(doneButtonClick(button:)), for: .touchUpInside)
    }
    
   @objc func cancelButtonClick(button: UIButton) {
        self.removeFromSuperview()
    }
    
    @objc func doneButtonClick(button: UIButton) {
        self.removeFromSuperview()
        if let selectionModel = getSelectedModel() {
            self.completion(selectionModel)
        }
    }
    
    func getSelectedModel() -> T? {
        var result: T? = nil
        model.forEach { sectionModel in
           result = sectionModel.first { selectModel in
                return selectModel.isSelected
            } as? T
        }
        return result
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return model.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = model[indexPath.section][indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: RadioSelectionTableViewCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? RadioSelectionTableViewCell {
            cell.configure(model: model)
            cell.click = {
                self.tableView(tableView, didSelectRowAt: indexPath)
            }
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectModel(indexPath: indexPath)
        tableView.reloadData()
    }
}

extension SelectionView {
    func selectModel(indexPath: IndexPath) {
        model[indexPath.section].forEach { selectModel in
            selectModel.isSelected = false
        }
        model[indexPath.section][indexPath.row].isSelected = true
    }
}



class PresetSelectionView<T:PresetSelectionModel>: SelectionView<T> {
    var activityIndicator = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.startAnimating()
        return indicator
    }()
    override func setUpUi() {
        super.setUpUi()
        self.addSubview(activityIndicator)
        activityIndicator.set(.centerView(self))
       loadPresets()
    }
    
    func loadPresets() {
        ApiService().getPresets() { presets in
           let result = presets.compactMap { preset in
               return PresetSelectionModel(isSelected: false, title: preset.name, id: preset.id)
            }
            self.model = [result]
            self.model.forEach { sectionModels in
                if let model = sectionModels.first(where: { selectModel in
                    return selectModel.id == self.selectId
                }) {
                  model.isSelected = true
              }
            }
            self.activityIndicator.stopAnimating()
            self.tableView.reloadData()
        } failure: { error in
            print("error \(error)")
        }

    }
}

class EnvironmentSelectionView<T: EnvironmentSelectionModel>: SelectionView<T> {

    override func setUpUi() {
        super.setUpUi()
        model.forEach { sectionModels in
            if let model = sectionModels.first(where: { selectModel in
                return selectModel.id == selectId
            }) {
              model.isSelected = true
          }
        }
       
        tableView.reloadData()
    }
    
}


class TitleLabelView: UIView {
    let paddingSpace: CGFloat = 12
    let verticalPaddingSpace: CGFloat = 12
    
    var title: UILabel = {
        let lable = UILabel()
        lable.textColor = .white
        lable.font = UIFont.boldSystemFont(ofSize: 16)
        return lable
    }()
    
    var titleValue: UILabel = {
        let lable = UILabel()
        lable.textColor = .white
        lable.font = UIFont.systemFont(ofSize: 14)
        lable.isUserInteractionEnabled = true
        return lable
    }()
    
    private var click: (UILabel)->Void

    init(title: String, titleValue: String, click:@escaping(UILabel)->Void) {
        self.title.text = title
        self.titleValue.text = titleValue
        self.click = click
        super.init(frame: .zero)
        self.setUp()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate var tapGesture: UITapGestureRecognizer!
    
    func setUp() {
        self.addSubViews(title,titleValue)
        title.set(.sameLeadingTrailing(self, paddingSpace),
                  .top(self))
        titleValue.set(.sameLeadingTrailing(self, paddingSpace),
                  .bottom(self),
                  .below(title, verticalPaddingSpace))
        let tapGesture = getTapGesture()
        titleValue.addGestureRecognizer(tapGesture)
        self.tapGesture = tapGesture
    }
    
    func getTapGesture() -> UITapGestureRecognizer {
       return UITapGestureRecognizer(target: self, action: #selector(tapCLick(gesture:)))
    }
    
   @objc func tapCLick(gesture: UITapGestureRecognizer) {
        self.click(titleValue)
    }
}

class PresetLabelView: TitleLabelView {
    private var onLoad: ([SelectionModel])->Void
   
    init(title: String, titleValue: String, onLoad:@escaping([SelectionModel])->Void, click:@escaping(UILabel)->Void) {
        self.onLoad = onLoad
        super.init(title: title, titleValue: titleValue, click: click)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func setUp() {
        super.setUp()
        refresh()
    }
    
    func refresh(completion:(()->Void)? = nil) {
        titleValue.text = "Loading..."
        titleValue.removeGestureRecognizer(self.tapGesture)
        ApiService().getPresets() { presets in
           let result = presets.compactMap { preset in
               return PresetSelectionModel(isSelected: false, title: preset.name, id: preset.id)
            }

            if result.count >= 0 {
                result[0].isSelected = true
                self.titleValue.text = result[0].title
                self.tapGesture = self.getTapGesture()
                self.titleValue.addGestureRecognizer(self.tapGesture)
                self.onLoad(result)
            }
            completion?()

        } failure: { error in
            print("error \(error)")
            completion?()
        }
    }
}

class TextFieldView: UIView {
    let paddingSpace: CGFloat = 12
    let veticalPaddingSpace: CGFloat = 12

    var title: UILabel = {
        let lable = UILabel()
        lable.textAlignment = .center
        lable.font = UIFont.boldSystemFont(ofSize: 16)
        lable.textColor = .white
        return lable
    }()
    var textField1: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        return textField
    }()
    
   lazy var textField2: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect

        return textField
    }()
    var button : UIButton = {
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
    
    init(title: String, textField1: String, textField2: String?, button: String) {
        self.title.text = title
        self.textField1.placeholder = textField1
        self.textField2PlaceHolder = textField2
        self.button.setTitle(button, for: .normal)
        super.init(frame: .zero)
        setUp()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUp() {
        if self.textField2PlaceHolder != nil {
            textField2.placeholder = self.textField2PlaceHolder
            self.addSubViews(separatorView ,title, textField1, textField2, button)
        }else {
            self.addSubViews(separatorView ,title, textField1, button)

        }
        separatorView.set(.sameLeadingTrailing(self),
                          .top(self),
                          .height(1.0))
        title.set(.below(separatorView, paddingSpace),
                  .sameLeadingTrailing(self, paddingSpace))
        textField1.set(.below(title, veticalPaddingSpace),
                       .sameLeadingTrailing(self, paddingSpace))
        if self.textField2PlaceHolder != nil {
            textField2.set(.below(textField1, veticalPaddingSpace),
                           .sameLeadingTrailing(self, paddingSpace))
            button.set(.below(textField2, veticalPaddingSpace*2),
                           .sameLeadingTrailing(self, paddingSpace*4),
                       .bottom(self))
        }else {
            button.set(.below(textField1, veticalPaddingSpace*2),
                           .sameLeadingTrailing(self, paddingSpace*4),
                       .bottom(self))
        }
        
    }
}






class ViewController: UIViewController, KeyboardObservable {
    
    
    static var showPresetSelector = true
    
    public var keyboardObserver: KeyboardObserver?
    
    private var presetSelectionId = "0"
    private var environmentSelectionId = "0"

     var joinMeetingCodeTextField: UITextField {
        get {
            return joinMeetingView.textField1
        }
    }
     
    var createMeetingNameTextField: UITextField {
        get {
            return createMeetingView.textField1
        }
    }
    
    var createMeetingUserNameTextField: UITextField {
        get {
            return createMeetingView.textField2
        }
    }
    
    var joinMeetingUserNameTextField: UITextField {
        get {
            return joinMeetingView.textField2
        }
    }
    
    var joinMeetingAuthTokenTextField: UITextField {
        get {
            return joinThroughAuthTokenMeetingView.textField1
        }
    }
    
    private var meetingSetupViewModel =  MeetingSetupViewModel()
    
    private var dyteUikit: DyteUiKit!
    
    private let createMeetingView: TextFieldView = {
        let view = TextFieldView(title: "Create Meeting", textField1: "Meeting Name", textField2: "Your Name", button: "Start Meeting")
        return view
    }()
    
    private let joinMeetingView: TextFieldView = {
        let view = TextFieldView(title: "Join Meeting", textField1: "Enter Meeting Code", textField2: "Your Name", button: "Join Meeting")
       
        return view
    }()
    
    private let joinThroughAuthTokenMeetingView: TextFieldView = {
        let view = TextFieldView(title: "Join Meeting", textField1: "Enter participant Authtoken", textField2: nil, button: "Join Meeting")
       
        return view
    }()
    
    let topPadding: CGFloat = 80
    
    private lazy var presetName: PresetLabelView = {
        
    let model = [[PresetSelectionModel]]()
        
        let view = PresetLabelView(title: "Preset", titleValue: "Loading...", onLoad: { models in
            Constants.PRESET_NAME = models[0].title
            self.presetSelectionId = models[0].id
        }) { [weak self] label in
            guard let self = self else {return}
            self.dismissKeyboard()
            let selectionView = PresetSelectionView (model: model,selectionId: self.presetSelectionId) { [weak self] model in
                guard let self = self else {return}
                label.text = model.title
                Constants.PRESET_NAME = model.title

                self.presetSelectionId = model.id
            }
            self.view.addSubview(selectionView)
            selectionView.set(.sameLeadingTrailing(self.view),
                              .top(self.view, self.topPadding),
                              .bottom(self.view)) }
        return view
    }()
    
    let environMentSelectModel = [[EnvironmentSelectionModel(isSelected: false, demoAppUrl: "https://app.dyte.io/api/v2", id: "0", dyteServerUrl: "https://api.cluster.dyte.in/v2"),
                  EnvironmentSelectionModel(isSelected: false, demoAppUrl: "https://demo.dyte.io/api/v2", id: "1", dyteServerUrl: "https://api.cluster.dyte.in/v2"),
                  EnvironmentSelectionModel(isSelected: false, demoAppUrl: "https://ai.dyte.app/api/v2", id: "2", dyteServerUrl: "https://api.devel.dyte.io/v2"),
                  EnvironmentSelectionModel(isSelected: false, demoAppUrl: "https://meet.dyte.io/api/v2", id: "3", dyteServerUrl: "https://api.cluster.dyte.in/v2"),
                                   EnvironmentSelectionModel(isSelected: false, demoAppUrl: "https://app.devel.dyte.io/api/v2", id: "4", dyteServerUrl: "https://api.devel.dyte.io/v2"),
                                   EnvironmentSelectionModel(isSelected: false, demoAppUrl: "https://app.preprod.dyte.io/api/v2", id: "5", dyteServerUrl: "https://api.preprod.dyte.io/v2")]]
    
    
    
    private lazy var enivornmentName: TitleLabelView = {
       
        let model = environMentSelectModel
        let environmentName = model[0][0].title
        Constants.BASE_URL = environmentName
        Constants.BASE_URL_INIT = model[0][0].dyteServerUrl
        let view = TitleLabelView(title: "Environment", titleValue: environmentName) {[weak self] label in
            guard let self = self else {return}
            let selectionView = EnvironmentSelectionView(model: model, selectionId: self.environmentSelectionId) { [weak self] model in
                guard let self = self else {return}
                self.dismissKeyboard()
                self.environmentSelectionId = model.id
                label.text = model.title
                Constants.BASE_URL = model.title
                Constants.BASE_URL_INIT = model.dyteServerUrl
                // Meeting Id and AuthToken can be old so cleaning text field
                joinMeetingCodeTextField.text = nil
                joinMeetingAuthTokenTextField.text = nil
                
                self.view.isUserInteractionEnabled = false
                self.presetName.refresh() {
                    self.view.isUserInteractionEnabled = true
                }
            }
            self.view.addSubview(selectionView)
            selectionView.set(.sameLeadingTrailing(self.view),
                              .top(self.view, self.topPadding),
                              .bottom(self.view)) }

        return view
    }()
    
    func selectEnvironment(url: String) {
        if let index = environMentSelectModel[0].firstIndex(where: { model in
            if model.demoAppUrl.contains(url) {
                return true
            }
            return false
        }) {
            Constants.BASE_URL = environMentSelectModel[0][index].demoAppUrl
            Constants.BASE_URL_INIT = environMentSelectModel[0][index].dyteServerUrl
            self.environmentSelectionId = environMentSelectModel[0][index].id
            self.enivornmentName.titleValue.text = Constants.BASE_URL
            self.view.isUserInteractionEnabled = false
            self.presetName.refresh() {
                self.view.isUserInteractionEnabled = true
            }
        }
    }
    
    private let stackView = {
        let stackView = BaseStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.spacing = 20
        return stackView
    }()
    
    private let scrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboard()
        refresh()
    }
    
    func refresh() {
        if let meetingId = UserDefaults.standard.value(forKey: UserDefaults.Keys.meetingId.rawValue) as? String {
            joinMeetingCodeTextField.text = meetingId
        }
        
        if let authToken = UserDefaults.standard.value(forKey: UserDefaults.Keys.authToken.rawValue) as? String {
            joinMeetingAuthTokenTextField.text = authToken
        }
        
        if let host = UserDefaults.standard.value(forKey: UserDefaults.Keys.hostUrl.rawValue) as? String {
            selectEnvironment(url: host)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                self.displayAlert(alertTitle: "Select", message: "Please select presets of your choice")
            })
        }
        
        UserDefaults.standard.reset()
    }
    
    private func displayAlert(defaultActionTitle: String? = "OK", alertTitle: String, message: String) {

        let alertController = UIAlertController(title: alertTitle, message: message, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: defaultActionTitle, style: .default, handler: nil)
        alertController.addAction(defaultAction)

        guard var topController = UIApplication.shared.windows.first?.rootViewController else {
            fatalError("keyWindow has no rootViewController")
        }
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        topController.present(alertController, animated: true, completion: nil)
    }
    
    
    private func setupUI() {
        
        self.view.addSubview(scrollView)
        scrollView.set(.top(self.view, 100), .bottom(self.view),
                       .sameLeadingTrailing(self.view))
        scrollView.addSubview(stackView)
        stackView.set(.fillSuperView(scrollView))
        scrollView.set(.equateAttribute(.width, toView: stackView, toAttribute: .width, withRelation: .equal))
        
        if ViewController.showPresetSelector {
            stackView.addArrangedSubviews(enivornmentName ,presetName ,createMeetingView,joinMeetingView, joinThroughAuthTokenMeetingView)
            joinThroughAuthTokenMeetingView.button.addTarget(self, action: #selector(joinMeetingThroughAuthToken(button:)), for: .touchUpInside)
        }else {
            stackView.addArrangedSubviews(createMeetingView,joinMeetingView)
        }
        //set delegate to catch pest action
        joinMeetingCodeTextField.delegate = self
        joinMeetingUserNameTextField.delegate = self
        joinMeetingAuthTokenTextField.delegate = self
        createMeetingNameTextField.delegate = self
        createMeetingUserNameTextField.delegate = self
        
        meetingSetupViewModel.meetingSetupDelegate = self
        
        createMeetingView.button.addTarget(self, action: #selector(startMeeting(button:)), for: .touchUpInside)
        joinMeetingView.button.addTarget(self, action: #selector(joinMeeting(button:)), for: .touchUpInside)
       

        //Handle keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        joinMeetingCodeTextField.text = Constants.MEETING_ROOM_NAME
        
        NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: nil, using: routeChange)
    }
    
    private func routeChange(_ notification: Notification) {
        guard let info = notification.userInfo,
                let value = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
                let reason = AVAudioSession.RouteChangeReason(rawValue: value) else { return }

            switch reason {
            case .categoryChange:
                try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
            case .oldDeviceUnavailable:
                try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
            default:
                print("Error: other reason for speaker route change!")
            }
    }
    
   
    @IBAction func startMeeting(button: UIButton) {

        createMeetingNameTextField.resignFirstResponder()
        if let text = createMeetingNameTextField.text, !text.isEmpty {
            self.view.showActivityIndicator()
            let req = CreateMeetingRequest(title: createMeetingNameTextField.text ?? "" , preferred_region: "ap-south-1")
            meetingSetupViewModel.startMeeting(request: req)
            createMeetingNameTextField.text = ""
        } else {
            Utils.displayAlert(alertTitle: "Error", message: "Meeting Name Required")
        }
    }
    
    @IBAction func joinMeeting(button: UIButton) {
        joinMeetingCodeTextField.resignFirstResponder()
        
        if let text = joinMeetingCodeTextField.text, !text.isEmpty {
            self.view.showActivityIndicator()
            var displayName = joinMeetingUserNameTextField.text ?? "Join as XYZ"
             if displayName.isEmpty == true {
                 displayName = "Join as XYZ"
             }
            
            if let meetingId = joinMeetingCodeTextField.text {
                if meetingId.contains("https://app.dyte.io/v2/meeting?id=") {
                    if let meeting = meetingId.components(separatedBy:"=").last {
                        self.meetingSetupViewModel.joinCreatedMeeting(displayName: displayName, meetingID: meeting)
                    }
                } else {
                    self.meetingSetupViewModel.joinCreatedMeeting(displayName: displayName, meetingID: meetingId)
                }
                joinMeetingCodeTextField.text = ""
            }
        } else {
            Utils.displayAlert(alertTitle: "Error", message: "Invalid Meeting")
        }
    }
    
    
   @objc func joinMeetingThroughAuthToken(button: UIButton) {
        joinMeetingAuthTokenTextField.resignFirstResponder()
        if let text = joinMeetingAuthTokenTextField.text, !text.isEmpty {
            self.view.showActivityIndicator()
            goToMeetingRoom(authToken: text)
            
        } else {
            Utils.displayAlert(alertTitle: "Error", message: "Please input autho token generated as a resultant of add participant")
        }
    }
    
    func goToMeetingRoom(authToken: String) {
        self.dyteUikit = DyteUiKit.init(meetingInfoV2: DyteMeetingInfoV2(authToken: authToken, enableAudio: true, enableVideo: false, baseUrl: Constants.BASE_URL_INIT))
        let controller =  self.dyteUikit.startMeeting {
            [weak self] in
           guard let self = self else {return}
            self.dismiss(animated: true)
            self.view.hideActivityIndicator()
        }
        controller.modalPresentationStyle = .fullScreen
        self.present(controller, animated: true)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func setupKeyboard() {
        self.startKeyboardObserving { [weak self] keyboardFrame in
            guard let self = self else {return}
            self.scrollView.get(.bottom)?.constant = -keyboardFrame.height
        } onHide: { [weak self] in
            guard let self = self else {return}
            self.scrollView.get(.bottom)?.constant = 0
        }
    }
}

extension ViewController: MeetingSetupDelegate {
    
    func createParticipantSuccess(authToken: String, meetingID: String) {
        self.goToMeetingRoom(authToken: authToken)
    }
    
    func startMeetingSuccess(createMeetingResponse: CreateMeetingResponse) {
        if let meetingId = createMeetingResponse.id {
           var displayName = createMeetingUserNameTextField.text ?? "Join as XYZ"
            if displayName.isEmpty == true {
                displayName = "Join as XYZ"
            }
            
            self.meetingSetupViewModel.joinCreatedMeeting(displayName: displayName, meetingID: meetingId)
        }
    }
    
    func hideActivityIndicator() {
        self.view.hideActivityIndicator()
    }
}

extension ViewController: UITextFieldDelegate {
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if let paste = UIPasteboard.general.string, text == paste {
            joinMeetingCodeTextField.text = paste
        }
        return true
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}

extension UserDefaults {

    enum Keys: String, CaseIterable {

        case meetingId
        case authToken
        case hostUrl

    }

    func reset() {
        Keys.allCases.forEach { removeObject(forKey: $0.rawValue) }
    }

}
