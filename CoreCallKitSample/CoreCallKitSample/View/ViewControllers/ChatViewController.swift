//
//  ChatViewController.swift
//  iosApp
//
//  Created by Shaunak Jagtap on 18/08/22.
//  Copyright © 2022 orgName. All rights reserved.
//

import MobileCoreServices
import RealtimeKit
import UIKit
import UniformTypeIdentifiers

class ChatViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate {
    @IBOutlet var imageButton: UIButton!
    fileprivate var messages: [ChatMessage]!
    fileprivate var messageTextViewOriginalYPosition: CGFloat!
    fileprivate var messageTextViewOriginalHeight: CGFloat!
    fileprivate var keyboardHeight: CGFloat?
    fileprivate let textViewHeight: CGFloat = 50
    fileprivate var messageContainerViewOriginalHeight: CGFloat!
    var rtkClient: RealtimeKitClient?
    var meetingViewModel: MeetingViewModel?

    @IBOutlet var messageContainerView: UIView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var messageTextView: UITextView!
    @IBOutlet var sendMessageButton: UIButton!
    @IBOutlet var textViewBottomConstraint: NSLayoutConstraint!
    let imagePickerVC = UIImagePickerController()
    @IBOutlet var textViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet var realTextViewHeightConstraint: NSLayoutConstraint!

    @IBAction func sendMessageButtonTapped(_: AnyObject) {
        if !messageTextView.text.isEmpty {
            let spacing = CharacterSet.whitespacesAndNewlines
            let message = messageTextView.text.trimmingCharacters(in: spacing)

            rtkClient?.chat.sendTextMessage(message: message)

            // reset textview height to original
            messageTextView.text = ""
            realTextViewHeightConstraint.constant = messageTextViewOriginalHeight

            tableView.contentInset.bottom = messageContainerViewOriginalHeight + (keyboardHeight ?? 0)
            tableView.verticalScrollIndicatorInsets.bottom = messageContainerViewOriginalHeight + (keyboardHeight ?? 0)

            // messageTextView.frame.origin.y = messageTextViewOriginalYPosition
            // messageTextView.frame.size.height = messageTextViewOriginalHeight
            // textViewHeightConstraint.constant = textViewHeight
            sendMessageButton.isEnabled = false
        }
    }

    @IBAction func closeAction(_: Any) {
        dismiss(animated: true)
    }

    @objc func dismissKeyboard(_: UITapGestureRecognizer) {
        messageTextView.resignFirstResponder()
    }

    @IBAction func pickImageAction(_: Any) {
        imagePickerVC.delegate = self
        imagePickerVC.sourceType = .photoLibrary
        present(imagePickerVC, animated: true)
    }

    @IBAction func attachFileAction(_: Any) {
        var iMenu: UIDocumentPickerViewController?
        if #available(iOS 14, *) {
            // iOS 14 & later
            let supportedTypes: [UTType] = [.pdf, .text, .rtf, .spreadsheet]
            iMenu = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        } else {
            let types = [kUTTypePDF, kUTTypeText, kUTTypeRTF, kUTTypeSpreadsheet]
            iMenu = UIDocumentPickerViewController(documentTypes: types as [String], in: .import)
        }

        if let importMenu = iMenu {
            if #available(iOS 11.0, *) {
                importMenu.allowsMultipleSelection = true
            }

            importMenu.delegate = self
            importMenu.modalPresentationStyle = .formSheet

            present(importMenu, animated: true)
        }
    }

    func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for file in urls {
            view.showActivityIndicator()
            rtkClient?.chat.sendFileMessage(fileURL: file) { error in
                if let error = error {
                    print("Error: \(error.message)")
                }
            }
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        view.showActivityIndicator()
        imagePickerVC.dismiss(animated: true, completion: { [weak self] in
            if let url = info[UIImagePickerController.InfoKey.imageURL] as? URL {
                self?.rtkClient?.chat.sendImageMessage(imageURL: url) { error in
                    if let error = error {
                        print("Error: \(error.message)")
                    }
                }
                DispatchQueue.main.async {
                    self?.view.hideActivityIndicator()
                }
            }
        })
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        imageButton.setTitle("", for: .normal)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(_:)))
        view.addGestureRecognizer(tapGesture)

        meetingViewModel?.chatDelegate = self
        if let msgs = rtkClient?.chat.messages as? [ChatMessage] {
            messages = msgs
        }

        // setup delegates
        tableView.dataSource = self
        tableView.delegate = self
        messageTextView.delegate = self

        // initial setup
        messageContainerViewOriginalHeight = messageContainerView.frame.height
        sendMessageButton.isEnabled = false
        messageTextView.layer.cornerRadius = 16

        tableView.contentInset.bottom = messageContainerViewOriginalHeight
        tableView.verticalScrollIndicatorInsets.bottom = messageContainerViewOriginalHeight

        tableView.estimatedRowHeight = 60.0
        tableView.rowHeight = UITableView.automaticDimension

        // initialize variables
        messageTextViewOriginalYPosition = messageTextView.frame.origin.y
        messageTextViewOriginalHeight = messageTextView.frame.height

        messageTextView.textContainerInset.left = 6
        tableView.register(UINib(nibName: "MessageTableViewCell", bundle: nil), forCellReuseIdentifier: "MessageTableViewCell")
        tableView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startObservingKeyboardEvents()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopObservingKeyboardEvents()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Setup Keyboard Observers

    fileprivate func startObservingKeyboardEvents() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ChatViewController.keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ChatViewController.keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil
        )
    }

    fileprivate func stopObservingKeyboardEvents() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // MARK: - Keyboard Observer Methods

    @objc fileprivate func keyboardWillShow(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            if let keyboardSize: CGSize = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue?.size {
                keyboardHeight = keyboardSize.height

                UIView.animate(withDuration: 0.4, animations: { [weak self] in
                    self?.tableView.contentInset.bottom = keyboardSize.height + (self?.messageContainerView.frame.height ?? 0)
                    self?.tableView.verticalScrollIndicatorInsets.bottom = keyboardSize.height + (self?.messageContainerView.frame.height ?? 0)
                    self?.tableView.layoutIfNeeded()
                })

                // move up texview
                textViewBottomConstraint.constant = keyboardSize.height
                view.layoutIfNeeded()

                if messages.count > 1 {
                    // scroll to bottom
                    let indexPath = IndexPath(row: messages.count - 1, section: 0)
                    tableView.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.middle, animated: true)
                }
            }
        }
    }

    @objc fileprivate func keyboardWillHide(_: Notification) {
        tableView.contentInset.bottom = messageContainerViewOriginalHeight
        tableView.verticalScrollIndicatorInsets.bottom = messageContainerViewOriginalHeight

        textViewBottomConstraint.constant = 0
        view.layoutIfNeeded()
    }
}

extension ChatViewController: UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "MessageTableViewCell", for: indexPath) as? MessageTableViewCell {
            cell.message = messages[indexPath.row]
            return cell
        }

        return UITableViewCell(frame: .zero)
    }
}

extension ChatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension ChatViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let spacing = CharacterSet.whitespacesAndNewlines
        if !messageTextView.text.trimmingCharacters(in: spacing).isEmpty {
            sendMessageButton.isEnabled = true
        } else {
            sendMessageButton.isEnabled = false
        }

        // TODO: - set max height

        let newSize = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        realTextViewHeightConstraint.constant = newSize.height

        let difference = newSize.height - textView.frame.height
        tableView.contentInset.bottom += difference
        tableView.verticalScrollIndicatorInsets.bottom += difference

//        // This should not always be called.
//        if messages.count > 1 {
//            let indexPath = IndexPath(row: messages.count-1, section: 0)
//            tableView.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.middle, animated: true)
//        }
    }
}

extension ChatViewController: ChatDelegate {
    func refreshMessages() {
        view.hideActivityIndicator()
        if let msgs = rtkClient?.chat.messages as? [ChatMessage] {
            messages = msgs
        }

        if messages.count > 0 {
            tableView.reloadData(completion: {
                DispatchQueue.main.async { [weak self] in
                    let indexPath = IndexPath(row: (self?.messages.count ?? 1) - 1, section: 0)
                    self?.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                }
            })
        }
    }
}
