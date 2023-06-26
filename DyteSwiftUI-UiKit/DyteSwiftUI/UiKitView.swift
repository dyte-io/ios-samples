//
//  UiKitView.swift
//  DyteSwiftUI
//
//  Created by Shaunak Jagtap on 31/05/23.
//

import SwiftUI
import UIKit

struct UIKitView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController
    
    let viewController: ViewController
    
    func makeUIViewController(context: Context) -> UIViewController {
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Update the view controller if needed
    }
}

