//
//  Extensions.swift
//  active-speaker-ui-sample
//
//  Created by Dyte on 23/01/24.
//

import UIKit
import DyteiOSCore
extension UIScreen {
   static var deviceOrientation:UIDeviceOrientation {
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
        return self.participants.waitlisted.count
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
        self.viewWithTag(toastTag)?.removeFromSuperview()
    }
    
    
    func showToast(toastMessage: String, duration: CGFloat, uiBlocker: Bool = true, showInBottom: Bool = false, bottomSpace: CGFloat = 0) {
        DispatchQueue.main.async {
            // View to blur bg and stopping user interaction
            self.removeToast()
            let toastView = self.createToastView(toastMessage: toastMessage, duration: duration, uiBlocker: uiBlocker, bottom: showInBottom, bottomSpace: bottomSpace)
            toastView.tag = toastTag
            self.addSubview(toastView)
        }
    }
    
    private func createToastView(toastMessage: String, duration: CGFloat, uiBlocker: Bool, bottom: Bool, bottomSpace: CGFloat) -> UIView {
        let bgView = UIView(frame: self.frame)
        bgView.backgroundColor = UIColor(red: CGFloat(255.0/255.0), green: CGFloat(255.0/255.0), blue: CGFloat(255.0/255.0), alpha: CGFloat(0.1))
        
        // Label For showing toast text
        let lblMessage = UILabel()
        lblMessage.numberOfLines = 2
        lblMessage.lineBreakMode = .byWordWrapping
        lblMessage.textColor = .white
        lblMessage.backgroundColor =  UIColor(red: CGFloat(0.0), green: CGFloat(0.0), blue: CGFloat(0.0), alpha: CGFloat(0.8))
        lblMessage.textAlignment = .center
        lblMessage.font = UIFont.init(name: "Helvetica Neue", size: 17)
        lblMessage.text = toastMessage
        
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.startAnimating()
        
        // calculating toast label frame as per message content
        let maxSizeTitle: CGSize = CGSize(width: self.bounds.size.width-16, height: self.bounds.size.height)
        var expectedSizeTitle: CGSize = lblMessage.sizeThatFits(maxSizeTitle)
        // UILabel can return a size larger than the max size when the number of lines is 1
        expectedSizeTitle = CGSize(width: maxSizeTitle.width.getMinimum(value2: expectedSizeTitle.width), height: maxSizeTitle.height.getMinimum(value2: expectedSizeTitle.height))
        DispatchQueue.main.async {
            if bottom == true {
                lblMessage.frame = CGRect(x:((self.bounds.size.width)/2) - ((expectedSizeTitle.width+16)/2), y: (self.bounds.size.height - (expectedSizeTitle.height+16+bottomSpace)), width: expectedSizeTitle.width+16, height: expectedSizeTitle.height+16)
            }else {
                lblMessage.frame = CGRect(x:((self.bounds.size.width)/2) - ((expectedSizeTitle.width+16)/2), y: (self.bounds.size.height/2) - ((expectedSizeTitle.height+16)/2), width: expectedSizeTitle.width+16, height: expectedSizeTitle.height+16)
            }
            
        }
        
        lblMessage.layer.cornerRadius = 8
        lblMessage.layer.masksToBounds = true
        bgView.addSubview(lblMessage)
        if duration >= 0 {
            UIView.animate(withDuration: 2.5, delay: TimeInterval(duration)) {
                lblMessage.alpha = 0
                bgView.alpha = 0
            } completion: { finish in
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
        } else
        {
            return value2
        }
    }
}
