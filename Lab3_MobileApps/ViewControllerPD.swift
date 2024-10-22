//
//  ViewController.swift
//  Commotion
//
//  Created by Eric Larson on 9/6/16.
//  Copyright © 2016 Eric Larson. All rights reserved.
//

import UIKit
import CoreMotion

class ViewControllerPD: UIViewController, UITextFieldDelegate{
    
    let motionModel = MotionModel()

    // MARK: =====UI Outlets=====
    @IBOutlet weak var activityLabel: UILabel!
    //@IBOutlet weak var debugLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var stepsTodayLabel: UILabel!
    @IBOutlet weak var stepsYesterdayLabel: UILabel!
    var numStepsGoal:Float? = nil
    
    @IBOutlet weak var settableStepsGoal: UITextField!
    let userDefaults = UserDefaults.standard
   
    
    @IBOutlet weak var goalLabel: UILabel!
    //@IBAction func whenTextTapped(_ sender: UITapGestureRecognizer) {
   //     sender.view?.becomeFirstResponder()
    //}
    
    
    // MARK: =====UI Lifecycle=====
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let retrievednumStepsGoal = userDefaults.float(forKey: "numStepsGoal")
        numStepsGoal = retrievednumStepsGoal
            
    
       
        
        self.motionModel.delegate = self
        if numStepsGoal == nil{
            goalLabel.text = "0"
        } else {
            goalLabel.text = String(Int(numStepsGoal!))
        }
      //  settableStepsGoal.delegate = self
      //  settableStepsGoal.keyboardType = .numberPad
        
        self.motionModel.startActivityMonitoring()
        self.motionModel.startPedometerMonitoring()
    }
    
    
   func setGoal() {
       
        if let goal = Int(self.settableStepsGoal.text!){
            numStepsGoal = Float(goal)
            goalLabel.text = String(Int(numStepsGoal!))
        } else {
            print("Not a valid input")
        }
    }
    
    @IBAction func setGoalButton(_ sender: UIButton) {
        setGoal()
        // Example integer value to store
        userDefaults.set(numStepsGoal, forKey: "numStepsGoal")
    }
    
    
}

extension ViewControllerPD: MotionDelegate{
    // MARK: =====Motion Delegate Methods=====
    
    func activityUpdated(activity:CMMotionActivity){
        
        if(activity.walking){
            self.activityLabel.text = "🚶 Walking"
        } else if(activity.running){
            self.activityLabel.text = "🏃 Running"
        } else if(activity.unknown){
            self.activityLabel.text = "❓ Unknown"
        } else if(activity.stationary){
            self.activityLabel.text = "🧍 Stationary"
        } else if(activity.cycling){
            self.activityLabel.text = "🚴 Cycling"
        } else if(activity.automotive){
            self.activityLabel.text = "🚗 Automotive"
        }
        
       // self.activityLabel.text = "🚶: \(activity.walking), 🏃: \(activity.running), ？: \(activity.unknown), 🧍: \(activity.stationary), 🚴: \(activity.cycling), 🚗: \(activity.automotive)"

    }
    
    func pedometerUpdated(pedData:CMPedometerData){

        // display the output directly on the phone
        DispatchQueue.main.async {
            // this goes into the large gray area on view
          //  self.debugLabel.text = "\(pedData.description)"
            
            // this updates the progress bar with number of steps, assuming 100 is the maximum for the steps
            self.stepsTodayLabel.text = "\(pedData.numberOfSteps)" //ATTENTION: Test if works
            self.progressBar.progress = pedData.numberOfSteps.floatValue / self.numStepsGoal!
        }
    }
}

