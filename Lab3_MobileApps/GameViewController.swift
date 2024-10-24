//
//  GameViewController.swift
//  Lab3_MobileApps
//
//  Created by Keaton Harvey on 10/21/24.
//


import UIKit
import SpriteKit

class GameViewController: UIViewController {
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            return .portrait
        }

    override var shouldAutorotate: Bool {
            return false
        }

    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //setup game scene
        let scene = GameScene(size: view.bounds.size)
        let skView = view as! SKView // the view in storyboard must be an SKView
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
    }
    


}
