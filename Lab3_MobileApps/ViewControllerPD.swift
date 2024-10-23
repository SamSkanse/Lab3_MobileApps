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

    // MARK: - Navigation Control
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "showGameSegue" {
            if didMeetGoalYesterday {
                // Allow the segue to occur
                return true
            } else {
                // Inform the user they haven't met their goal
                let alert = UIAlertController(title: "Goal Not Met", message: "You need to meet your step goal from yesterday to play the game.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
                // Prevent the segue from occurring
                return false
            }
        }
        return true
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
            let todayTotalSteps = pedData.numberOfSteps.intValue
            // Update steps today label
            self.stepsTodayLabel.text = "Steps Today: \(todayTotalSteps)"

            // Update progress bar safely
            if self.numStepsGoal > 0 {
                let progress = Float(todayTotalSteps) / self.numStepsGoal
                self.progressBar.progress = min(progress, 1.0) // Ensure progress doesn't exceed 1.0

                // Update steps remaining
                let stepsRemaining = max(0, Int(self.numStepsGoal) - todayTotalSteps)
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
