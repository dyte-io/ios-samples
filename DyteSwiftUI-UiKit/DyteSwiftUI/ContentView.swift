//
//  ContentView.swift
//  DyteSwiftUI
//
//  Created by Shaunak Jagtap on 31/05/23.
//
import SwiftUI
import UIKit

struct ContentView: View {
    let viewController = ViewController() // Instantiate your existing ViewController
    
    var body: some View {
        // Wrap the UIKit view controller
        UIKitView(viewController: viewController)
            .edgesIgnoringSafeArea(.all)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

