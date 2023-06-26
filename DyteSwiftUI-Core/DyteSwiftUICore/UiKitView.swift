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
    
    let viewController: HomeViewController
    
    func makeUIViewController(context: Context) -> UIViewController {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Storyboard", bundle:nil)
        let viewController = storyBoard.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Update the view controller if needed
    }
}

