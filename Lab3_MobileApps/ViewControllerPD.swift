// ViewControllerPD.swift
import UIKit
import CoreMotion

class ViewControllerPD: UIViewController, UITextFieldDelegate {

    let motionModel = MotionModel()

    // MARK: - UI Outlets
    @IBOutlet weak var activityLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var stepsTodayLabel: UILabel!
    @IBOutlet weak var stepsYesterdayLabel: UILabel!
    @IBOutlet weak var settableStepsGoal: UITextField!
    @IBOutlet weak var goalLabel: UILabel!
    @IBOutlet weak var stepsRemainingLabel: UILabel!
    @IBOutlet weak var playGameButton: UIButton! // Outlet for Play Game button

    let userDefaults = UserDefaults.standard
    var numStepsGoal: Float = 0.0
    var stepsYesterday: Int = 0
    var didMeetGoalYesterday: Bool = false

    // Variables for activity detection sensitivity
    var lastActivityType: String?
    var activityUpdateTimestamp: Date?
    let activityMinDuration: TimeInterval = 1.0 // Minimum duration to confirm activity

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        // Retrieve saved goal or default to 0.0
        numStepsGoal = userDefaults.float(forKey: "numStepsGoal")

        // Set up UI elements
        if numStepsGoal == 0.0 {
            goalLabel.text = "Goal: 0"
        } else {
            goalLabel.text = "Goal: \(Int(numStepsGoal))"
        }

        // Set up text field
        settableStepsGoal.delegate = self
        settableStepsGoal.keyboardType = .numberPad

        // Add tap gesture recognizer to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)

        // Start motion updates
        self.motionModel.delegate = self
        self.motionModel.startActivityMonitoring()
        self.motionModel.startPedometerMonitoring()

        // Query steps from yesterday
        queryStepsYesterday()

        // Update game access based on initial values
        updateGameAccess()
    }

    // MARK: - Keyboard Handling
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }

    // Dismiss keyboard when pressing Return key (if keyboard has Return key)
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    // MARK: - Goal Setting
    func setGoal() {
        if let goalText = self.settableStepsGoal.text, let goal = Float(goalText), goal > 0 {
            numStepsGoal = goal
            goalLabel.text = "Goal: \(Int(numStepsGoal))"
            userDefaults.set(numStepsGoal, forKey: "numStepsGoal")
            userDefaults.synchronize()

            // Clear the text field and dismiss keyboard
            self.settableStepsGoal.text = ""
            self.settableStepsGoal.resignFirstResponder()

            // Re-evaluate if the goal was met with the new goal
            checkIfGoalMet()
            updateGameAccess()
        } else {
            print("Not a valid input")
            // Optionally, display an alert to the user
            let alert = UIAlertController(title: "Invalid Input", message: "Please enter a valid number greater than 0.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }

    @IBAction func setGoalButton(_ sender: UIButton) {
        setGoal()
    }

    // MARK: - Query Steps from Yesterday
    func queryStepsYesterday() {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        guard let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday),
              let endOfYesterday = calendar.date(byAdding: .second, value: -1, to: startOfToday) else {
            return
        }

        self.motionModel.querySteps(from: startOfYesterday, to: endOfYesterday)
    }

    // MARK: - Update Game Access
    func updateGameAccess() {
        if didMeetGoalYesterday {
            // Indicate game is accessible
            playGameButton.alpha = 1.0
        } else {
            // Indicate game is not accessible
            playGameButton.alpha = 0.5
        }
    }

    func checkIfGoalMet() {
        if self.numStepsGoal > 0 && Float(self.stepsYesterday) >= self.numStepsGoal {
            self.didMeetGoalYesterday = true
        } else {
            self.didMeetGoalYesterday = false
        }
    }

    // MARK: - Play Game Action
    @IBAction func playGameButtonTapped(_ sender: UIButton) {
        if didMeetGoalYesterday {
            // Proceed to show the game
            performSegue(withIdentifier: "showGameSegue", sender: self)
        } else {
            // Inform the user they haven't met their goal
            let alert = UIAlertController(title: "Goal Not Met", message: "You need to meet your step goal from yesterday to play the game.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}

// MARK: - Motion Delegate Extension
extension ViewControllerPD: MotionDelegate {

    // MARK: - Motion Delegate Methods

    func activityUpdated(activity: CMMotionActivity) {
        DispatchQueue.main.async {
            // Determine the current activity type
            let currentActivityType = self.activityType(from: activity)

            if let lastActivity = self.lastActivityType, let lastTimestamp = self.activityUpdateTimestamp {
                if currentActivityType == lastActivity {
                    // Same activity, update timestamp
                    self.activityUpdateTimestamp = Date()
                } else {
                    // Different activity, check duration
                    let timeElapsed = Date().timeIntervalSince(lastTimestamp)
                    if timeElapsed >= self.activityMinDuration {
                        // Update UI and last activity
                        self.updateActivityLabel(with: currentActivityType)
                        self.lastActivityType = currentActivityType
                        self.activityUpdateTimestamp = Date()
                    }
                    // Else, ignore the change
                }
            } else {
                // First time setting activity
                self.updateActivityLabel(with: currentActivityType)
                self.lastActivityType = currentActivityType
                self.activityUpdateTimestamp = Date()
            }
        }
    }

    func activityType(from activity: CMMotionActivity) -> String {
        if activity.walking {
            return "Walking"
        } else if activity.running {
            return "Running"
        } else if activity.cycling {
            return "Cycling"
        } else if activity.automotive {
            return "Automotive"
        } else if activity.stationary {
            return "Stationary"
        } else {
            return "Unknown"
        }
    }

    func updateActivityLabel(with activityType: String) {
        switch activityType {
        case "Walking":
            self.activityLabel.text = "🚶 Walking"
        case "Running":
            self.activityLabel.text = "🏃 Running"
        case "Cycling":
            self.activityLabel.text = "🚴 Cycling"
        case "Automotive":
            self.activityLabel.text = "🚗 Automotive"
        case "Stationary":
            self.activityLabel.text = "🧍 Stationary"
        default:
            self.activityLabel.text = "❓ Unknown"
        }
    }

    func pedometerUpdated(pedData: CMPedometerData) {
        DispatchQueue.main.async {
            // Update steps today label
            self.stepsTodayLabel.text = "Steps Today: \(pedData.numberOfSteps)"

            // Update progress bar safely
            if self.numStepsGoal > 0 {
                let progress = pedData.numberOfSteps.floatValue / self.numStepsGoal
                self.progressBar.progress = min(progress, 1.0) // Ensure progress doesn't exceed 1.0

                // Update steps remaining
                let stepsRemaining = max(0, Int(self.numStepsGoal) - pedData.numberOfSteps.intValue)
                self.stepsRemainingLabel.text = "Steps Remaining: \(stepsRemaining)"
            } else {
                self.progressBar.progress = 0.0
                self.stepsRemainingLabel.text = "Set a goal to track progress"
            }
        }
    }

    func stepsYesterdayUpdated(steps: Int) {
        self.stepsYesterday = steps
        DispatchQueue.main.async {
            self.stepsYesterdayLabel.text = "Steps Yesterday: \(steps)"
        }
        userDefaults.set(steps, forKey: "stepsYesterday")

        // Check if the goal was met
        checkIfGoalMet()
        updateGameAccess()
    }
}





/*

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

*/
