//
//  CustomNavigationController.swift
//  Lab3_MobileApps
//
//  Created by Keaton Harvey on 10/23/24.
//


import UIKit

class CustomNavigationController: UINavigationController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return topViewController?.supportedInterfaceOrientations ?? .portrait
    }

    override var shouldAutorotate: Bool {
        return topViewController?.shouldAutorotate ?? true
    }
}