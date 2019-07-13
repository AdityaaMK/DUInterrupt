/*
 Abstract:
 This class manages the CoreMotion interactions and 
         provides a delegate to indicate changes in data.
 */

import Foundation
import CoreMotion
import WatchKit
import os.log
//import HealthKit
/**
 `MotionManagerDelegate` exists to inform delegates of motion changes.
 These contexts can be used to enable application specific behavior.
 */
protocol MotionManagerDelegate: class {
    func didUpdateMotion(_ manager: MotionManager, gravityStr: String, rotationRateStr: String, userAccelStr: String, attitudeStr: String)
}

extension Date {
    var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
}

class MotionManager{
    // MARK: Properties
    
    let motionManager = CMMotionManager()
    let queue = OperationQueue()
    let wristLocationIsLeft = WKInterfaceDevice.current().wristLocation == .left

    // MARK: Application Specific Constants
    
    // The app is using 50hz data and the buffer is going to hold 1s worth of data.
    let sampleInterval = 1.0 / 50
    let rateAlongGravityBuffer = RunningBuffer(size: 50)
    
    weak var delegate: MotionManagerDelegate?
    
    var gravityStr = ""
    var rotationRateStr = ""
    var userAccelStr = ""
    var attitudeStr = ""
    var timer = Timer()
    var counter = 0.0
    
    var recentDetection = false

    // MARK: Initialization
    
    init() {
        // Serial queue for sample handling and calculations.
        queue.maxConcurrentOperationCount = 1
        queue.name = "MotionManagerQueue"
       // let instanceOfUser = User()
        //instanceOfUser.startTest()
    }

    // MARK: Motion Manager

    func startUpdates() {
        if !motionManager.isDeviceMotionAvailable {
            print("Device Motion is not available.")
            return
        }
        
        os_log("Start Updates");
        motionManager.deviceMotionUpdateInterval = sampleInterval
        motionManager.startDeviceMotionUpdates(to: queue) { (deviceMotion: CMDeviceMotion?, error: Error?) in
            if error != nil {
                print("Encountered error: \(error!)")
            }

            if deviceMotion != nil {
                self.processDeviceMotion(deviceMotion!)
            }
        }
    }

    func stopUpdates() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.stopDeviceMotionUpdates()
        }
    }

    // MARK: Motion Processing
    func didUpdateTimer(_ manager: WorkoutManager, timer: Timer, counter: Double) {
        DispatchQueue.main.async {
            self.timer = timer
            self.counter = counter
        }
    }
    //var session: HKWorkoutSession?
    @objc func UpdateTimer() {
        counter = counter + 0.1
        //timeLabel.text = String(format: "%.1f", counter)
    }
    
    
    //let workoutManager = WorkoutManager()

    func processDeviceMotion(_ deviceMotion: CMDeviceMotion) {
        gravityStr = String(format: "X: %.1f Y: %.1f Z: %.1f" ,
                            deviceMotion.gravity.x,
                            deviceMotion.gravity.y,
                            deviceMotion.gravity.z)
        print(deviceMotion.gravity.z)
        userAccelStr = String(format: "X: %.1f Y: %.1f Z: %.1f" ,
                           deviceMotion.userAcceleration.x,
                           deviceMotion.userAcceleration.y,
                          deviceMotion.userAcceleration.z)
        rotationRateStr = String(format: "X: %.1f Y: %.1f Z: %.1f" ,
                              deviceMotion.rotationRate.x,
                              deviceMotion.rotationRate.y,
                              deviceMotion.rotationRate.z)
        attitudeStr = String(format: "r: %.1f p: %.1f y: %.1f" ,
                                 deviceMotion.attitude.roll,
                                 deviceMotion.attitude.pitch,
                                 deviceMotion.attitude.yaw)
        
        let timestamp = Date().millisecondsSince1970
        
        os_log("Motion: %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@",
        //os_log("Motion:  %@",
               String(timestamp),
               String(deviceMotion.gravity.x),
               String(deviceMotion.gravity.y),
               String(deviceMotion.gravity.z),
               String(deviceMotion.userAcceleration.x),
               String(deviceMotion.userAcceleration.y),
               String(deviceMotion.userAcceleration.z),
               String(deviceMotion.rotationRate.x),
               String(deviceMotion.rotationRate.y),
               String(deviceMotion.rotationRate.z),
               String(deviceMotion.attitude.roll),
               String(deviceMotion.attitude.pitch),
               String(deviceMotion.attitude.yaw))
        print(deviceMotion.gravity.z);
        updateMetricsDelegate();
        //if(deviceMotion.gravity.z <= -0.3){
          //  startTest()
        //}
        if(deviceMotion.gravity.z <= -0.95){
           //workoutManager.stopWorkout()
            print("Test is completed")
            //motionManager.stopDeviceMotionUpdates()
            timer.invalidate();
            print(counter)
        }
    }

    // MARK: Data and Delegate Management
    
    func updateMetricsDelegate() {
        delegate?.didUpdateMotion(self,gravityStr:gravityStr, rotationRateStr: rotationRateStr, userAccelStr: userAccelStr, attitudeStr: attitudeStr)
    }
}
