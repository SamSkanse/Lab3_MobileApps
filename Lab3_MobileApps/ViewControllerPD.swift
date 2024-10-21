//
//  ViewController.swift
//  Commotion
//
//  Created by Eric Larson on 9/6/16.
//  Copyright © 2016 Eric Larson. All rights reserved.
//

import UIKit
import CoreMotion

class ViewController: UIViewController  {
    
    let motionModel = MotionModel()

    // MARK: =====UI Outlets=====
    @IBOutlet weak var activityLabel: UILabel!
    @IBOutlet weak var debugLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    
    // MARK: =====UI Lifecycle=====
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.motionModel.delegate = self
        
        self.motionModel.startActivityMonitoring()
        self.motionModel.startPedometerMonitoring()
    }


    


}

extension ViewController: MotionDelegate{
    // MARK: =====Motion Delegate Methods=====
    
    func activityUpdated(activity:CMMotionActivity){
        
        self.activityLabel.text = "🚶: \(activity.walking), 🏃: \(activity.running)"

    }
    
    func pedometerUpdated(pedData:CMPedometerData){

        // display the output directly on the phone
        DispatchQueue.main.async {
            // this goes into the large gray area on view
            self.debugLabel.text = "\(pedData.description)"
            
            // this updates the progress bar with number of steps, assuming 100 is the maximum for the steps
            
            self.progressBar.progress = pedData.numberOfSteps.floatValue / 100
        }  
    }
}
