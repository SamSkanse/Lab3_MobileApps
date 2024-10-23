import CoreMotion

// Setup a protocol for the ViewController to be delegate for
protocol MotionDelegate {
    // Define delegate functions
    func activityUpdated(activity: CMMotionActivity)
    func pedometerUpdated(pedData: CMPedometerData)
    func stepsYesterdayUpdated(steps: Int)
}

class MotionModel {

    // MARK: - Class Variables
    private let activityManager = CMMotionActivityManager()
    private let pedometer = CMPedometer()
    var delegate: MotionDelegate? = nil

    // MARK: - Motion Methods
    func startActivityMonitoring() {
        // Check if activity monitoring is available
        if CMMotionActivityManager.isActivityAvailable() {
            // Update from the main queue
            self.activityManager.startActivityUpdates(to: OperationQueue.main) { (activity: CMMotionActivity?) in
                // Unwrap the activity and send to delegate
                if let unwrappedActivity = activity,
                   let delegate = self.delegate {
                    // Print activity description
                    print("%@", unwrappedActivity.description)

                    // Call delegate function
                    delegate.activityUpdated(activity: unwrappedActivity)
                }
            }
        }
    }

    func startPedometerMonitoring() {
        // Check if pedometer is available
        if CMPedometer.isStepCountingAvailable() {
            // Start updating the pedometer from the start of today
            let calendar = Calendar.current
            let now = Date()
            let startOfToday = calendar.startOfDay(for: now)
            pedometer.startUpdates(from: startOfToday) { (pedData: CMPedometerData?, error: Error?) in
                // If no errors, update the delegate
                if let unwrappedPedData = pedData,
                   let delegate = self.delegate {
                    delegate.pedometerUpdated(pedData: unwrappedPedData)
                }
            }
        }
    }

    // Method to query steps from a date range
    func querySteps(from startDate: Date, to endDate: Date) {
        if CMPedometer.isStepCountingAvailable() {
            pedometer.queryPedometerData(from: startDate, to: endDate) { [weak self] (data, error) in
                if let error = error {
                    print("Error querying steps: \(error.localizedDescription)")
                } else if let data = data,
                          let delegate = self?.delegate {
                    let steps = data.numberOfSteps.intValue
                    // Notify delegate on the main thread
                    DispatchQueue.main.async {
                        delegate.stepsYesterdayUpdated(steps: steps)
                    }
                }
            }
        }
    }
}
