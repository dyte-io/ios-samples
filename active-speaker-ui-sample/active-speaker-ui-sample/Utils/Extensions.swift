//
//  Extensions.swift
//  active-speaker-ui-sample
//
//  Created by Dyte on 23/01/24.
//

import DyteiOSCore
import UIKit

extension UIScreen {
    static var deviceOrientation: UIDeviceOrientation {
        switch UIApplication.shared.statusBarOrientation {
        case .portrait:
            return .portrait

        case .portraitUpsideDown:
            return .portraitUpsideDown

        case .landscapeLeft:
            return .landscapeLeft

        case .landscapeRight:
            return .landscapeRight

        case .unknown:
            return .unknown

        @unknown default:
            return .unknown
        }
    }

    static func isLandscape() -> Bool {
        if UIScreen.deviceOrientation == .landscapeLeft || UIScreen.deviceOrientation == .landscapeRight {
            return true
        }
        return false
    }
}

extension DyteMobileClient {
    func getWaitlistCount() -> Int {
        return participants.waitlisted.count
    }

    func getWebinarCount() -> Int {
        return 0
    }

    func getPendingParticipantCount() -> Int {
        return getWebinarCount() + getWaitlistCount()
    }
}

let toastTag = 5555

extension UIView {
    func removeToast() {
        viewWithTag(toastTag)?.removeFromSuperview()
    }

    func showToast(toastMessage: String, duration: CGFloat, uiBlocker: Bool = true, showInBottom: Bool = false, bottomSpace: CGFloat = 0) {
        DispatchQueue.main.async {
            // View to blur bg and stopping user interaction
            self.removeToast()
            let toastView = self.createToastView(toastMessage: toastMessage, duration: duration, uiBlocker: uiBlocker, bottom: showInBottom, bottomSpace: bottomSpace)
            toastView.tag = toastTag
            self.addSubview(toastView)
            toastView.set(.fillSuperView(self))
        }
    }

    private func createToastView(toastMessage: String, duration: CGFloat, uiBlocker: Bool, bottom: Bool, bottomSpace: CGFloat) -> UIView {
        let bgView = UIView(frame: frame)
        bgView.backgroundColor = UIColor(red: CGFloat(255.0 / 255.0), green: CGFloat(255.0 / 255.0), blue: CGFloat(255.0 / 255.0), alpha: CGFloat(0.1))
        // Label For showing toast text
        let lblMessage = UILabel()
        lblMessage.numberOfLines = 2
        lblMessage.lineBreakMode = .byWordWrapping
        lblMessage.textColor = .white
        lblMessage.textAlignment = .center
        lblMessage.font = UIFont(name: "Helvetica Neue", size: 17)
        lblMessage.text = toastMessage
        lblMessage.layer.cornerRadius = 8
        lblMessage.layer.masksToBounds = true
        let baseLabelView = lblMessage.wrapperView()
        bgView.addSubview(baseLabelView)
        baseLabelView.addSubview(lblMessage)
        lblMessage.set(.fillSuperView(baseLabelView, 8))
        baseLabelView.layer.cornerRadius = 8
        baseLabelView.layer.masksToBounds = true
        baseLabelView.backgroundColor = UIColor(red: CGFloat(0.0), green: CGFloat(0.0), blue: CGFloat(0.0), alpha: CGFloat(0.8))

        baseLabelView.set(.leading(bgView, 16, .greaterThanOrEqual), .centerX(bgView))
        if bottom == false {
            baseLabelView.set(.centerY(bgView))
        } else {
            baseLabelView.set(.bottom(bgView, 16 + bottomSpace))
        }

        if duration >= 0 {
            UIView.animate(withDuration: 2.5, delay: TimeInterval(duration)) {
                baseLabelView.alpha = 0
                bgView.alpha = 0
            } completion: { _ in
                bgView.removeFromSuperview()
            }
        }
        bgView.isUserInteractionEnabled = uiBlocker
        return bgView
    }
}

extension CGFloat {
    func getMinimum(value2: CGFloat) -> CGFloat {
        if self < value2 {
            return self
        } else {
            return value2
        }
    }
}
