/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This class manages the HealthKit interactions and provides a delegate 
         to indicate changes in data.
 */

import Foundation
import HealthKit
import AVFoundation
import CoreAudio
//import AudioToolbox

/**
 `WorkoutManagerDelegate` exists to inform delegates of swing data changes.
 These updates can be used to populate the user interface.
 */
protocol WorkoutManagerDelegate: class {
    func didUpdateMotion(_ manager: WorkoutManager, gravityStr: String, rotationRateStr: String, userAccelStr: String, attitudeStr: String)
}

class WorkoutManager: MotionManagerDelegate {
    
    // MARK: Properties
    let motionManager = MotionManager()
    let healthStore = HKHealthStore()

    weak var delegate: WorkoutManagerDelegate?
    var session: HKWorkoutSession?

    // MARK: Initialization
    
    init() {
        motionManager.delegate = self
    }
    var counter = 0.0
    var timer = Timer()
    var isPlaying = false
    // MARK: WorkoutManager
    @objc func UpdateTimer() {
        counter = counter + 0.1
        //timeLabel.text = String(format: "%.1f", counter)
    }
    
    func startTest() {
        // If we have already started the workout, then do nothing.
       // AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
       
        
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(UpdateTimer), userInfo: nil, repeats: true)

        if (session != nil) {
            return
        }

        // Configure the workout session.
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .tennis
        workoutConfiguration.locationType = .outdoor

        do {
            session = try HKWorkoutSession(configuration: workoutConfiguration)
        } catch {
            fatalError("Unable to create the workout session!")
        }

        // Start the workout session and device motion updates.
        healthStore.start(session!)
        motionManager.startUpdates()
    }

    func stopWorkout() {
        // If we have already stopped the workout, then do nothing.
        timer.invalidate();
        print(counter)
        if (session == nil) {
            return
        }

        // Stop the device motion updates and workout session.
        motionManager.stopUpdates()
        healthStore.end(session!)
        //print(counter)
        // Clear the workout session.
        session = nil
    }

    // MARK: MotionManagerDelegate
    
    func didUpdateMotion(_ manager: MotionManager, gravityStr: String, rotationRateStr: String, userAccelStr: String, attitudeStr: String) {
        delegate?.didUpdateMotion(self, gravityStr: gravityStr, rotationRateStr: rotationRateStr, userAccelStr: userAccelStr, attitudeStr: attitudeStr)
    }
}
