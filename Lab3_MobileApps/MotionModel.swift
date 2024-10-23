import CoreMotion

// Setup a protocol for the ViewController to be delegate for
protocol MotionDelegate {
    // Define delegate functions
    func activityUpdated(activity: CMMotionActivity)
    func pedometerUpdated(pedData: CMPedometerData, stepsToNow: Int)
    func stepsYesterdayUpdated(steps: Int) // New delegate method
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
            // Start updating the pedometer from the current date and time
            let calendar = Calendar.current
            let now = Date()
            let startOfToday = calendar.startOfDay(for: now)
            var stepsToday = queryStepsToday(from: startOfToday, to: now)
            pedometer.startUpdates(from: Date()) { (pedData: CMPedometerData?, error: Error?) in
                // If no errors, update the delegate
                if let unwrappedPedData = pedData,
                   let delegate = self.delegate {
                    delegate.pedometerUpdated(pedData: unwrappedPedData, stepsToNow: stepsToday)
                }
            }
        }
    }
    
    // New method to query steps from a date range
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
    
    func queryStepsToday(from startDate: Date, to endDate: Date) -> Int{
        var steps = 0
        if CMPedometer.isStepCountingAvailable() {
            pedometer.queryPedometerData(from: startDate, to: endDate) { [weak self] (data, error) in
                if let error = error {
                    print("Error querying steps: \(error.localizedDescription)")
                } else if let data = data,
                          let delegate = self?.delegate {
                    steps = data.numberOfSteps.intValue
                    
                }
            }
        }
        return steps
    }
}






/*

//
//  MotionModel.swift
//  Commotion
//
//  Created by Eric Cooper Larson on 10/2/24.
//  Copyright © 2024 Eric Larson. All rights reserved.
//

import CoreMotion

// setup a protocol for the ViewController to be delegate for
protocol MotionDelegate {
    // Define delegate functions
    func activityUpdated(activity:CMMotionActivity)
    func pedometerUpdated(pedData:CMPedometerData)
}

class MotionModel{
    
    // MARK: =====Class Variables=====
    private let activityManager = CMMotionActivityManager()
    private let pedometer = CMPedometer()
    var delegate:MotionDelegate? = nil
    
    // MARK: =====Motion Methods=====
    func startActivityMonitoring(){
        // is activity is available
        if CMMotionActivityManager.isActivityAvailable(){
            // update from this queue (should we use the MAIN queue here??.... )
            self.activityManager.startActivityUpdates(to: OperationQueue.main)
            {(activity:CMMotionActivity?)->Void in
                // unwrap the activity and send to delegate
                // using the real time pedometer might influences how often we get activity updates...
                // so these updates can come through less often than we may want
                if let unwrappedActivity = activity,
                   let delegate = self.delegate {
                    // Print if we are walking or running
                    print("%@",unwrappedActivity.description)
                    
                    // Call delegate function
                    delegate.activityUpdated(activity: unwrappedActivity)
                    
                }
            }
        }
        
    }
    
    func startPedometerMonitoring(){
        // check if pedometer is okay to use
        if CMPedometer.isStepCountingAvailable(){
            // start updating the pedometer from the current date and time
            pedometer.startUpdates(from: Date())
            {(pedData:CMPedometerData?, error:Error?)->Void in
                
                // if no errors, update the delegate
                if let unwrappedPedData = pedData,
                   let delegate = self.delegate {
                    
                    delegate.pedometerUpdated(pedData:unwrappedPedData)
                }

            }
        }
    }
    
    
}

*/
