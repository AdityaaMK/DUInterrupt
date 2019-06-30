//
//  ViewController.swift
//  DUInterrupt
//
//  Created by Aditya Bose on 2/24/19.
//  Copyright © 2019 Aditya Bose. All rights reserved.
//

import UIKit
import WatchKit
import Lottie
import HealthKit
import WatchConnectivity

class ViewController: UIViewController {
    
    
    @IBOutlet weak var main_animation: LOTAnimationView!
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
        //return UIStatusBarStyle.default   // Make dark again
    }
    
    let hkm = HealthKitManager()
    private var recievedHeartRate = 0
    private let session = WCSession.default
    var ref = false
    // outlets
    @IBOutlet weak var hrlabel: UILabel!
    @IBOutlet weak var watchWarningLabel: UILabel!
    @IBOutlet weak var maxHRLabel: UILabel!
    @IBOutlet weak var minHRLabel: UILabel!
    @IBOutlet weak var avgHRLabel: UILabel!
    @IBOutlet weak var restHRLabel: UILabel!
    @IBOutlet weak var hasWorkedOutLabel: UILabel!
    @IBOutlet weak var greetingLabel: UILabel!
    @IBOutlet weak var reactionTimeLabel: UILabel!
    
    var heartRate = -1
    var mostRecentTime: Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        main_animation.setAnimation(named: "heart")
        main_animation.animationSpeed = 1
        main_animation.loopAnimation = true
        main_animation.contentMode = .scaleAspectFill
        main_animation.play()
        if hkm.isHealthDataAvailable() {
            requestAuthorization()
        }
        session.delegate = self
        session.activate()
        print("Session activated in iOS")
        setGreetingLabel()
        //liveHeartRateLabel.alpha = 0
        watchWarningLabel.alpha = 0
        
        // refresh to get most recent data
        if hkm.isHealthDataAvailable() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.requestAuthorization()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if self.heartRate != -1 {
            // delayed refresh to gather most recent data
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.requestAuthorization()
            }
        }
    }
    
    @IBAction func didTouchRefreshButton(_ sender: Any) {
        requestAuthorization()
        print("TOUCHED")
        let calendar = Calendar.current
        
        // create 1-day range
        let today = calendar.startOfDay(for: Date())
        // most recent
        hkm.heartRate(from: today, to: Date()) { (results) in
            if results.isEmpty {
                print("Results are empty")
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 4, animations: {
                        self.watchWarningLabel.alpha = 1
                    })
                }
            } else {
                print("Processing results")
                self.processDayHR(results)
            }
        }
    }
    
    @IBAction func didTouchWorkoutButton(_ sender: Any) {
        //        if let workoutsViewController = storyboard?.instantiateViewController(withIdentifier: "WorkoutsViewController") {
        //            present(workoutsViewController, animated: true)
        //        }
    }
}

// MARK: - HealthKit functions
extension ViewController {
    
    /* query HealthKit for today's HR data */
    func getDayHR() {
        print("getDayHeartRate")
        let calendar = Calendar.current
        
        // create 1-day range
        let today = calendar.startOfDay(for: Date())
        hkm.heartRate(from: today, to: Date()) { (results) in
            if results.isEmpty {
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 4, animations: {
                        self.watchWarningLabel.alpha = 1
                    })
                }
            } else {
                self.processDayHR(results)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 120, execute: {
            self.getDayHR()
        })
    }
    
    func processDayHR(_ results: [HKQuantitySample]) {
        // average
        var total = 0.0
        var max = 0.0
        var min = 230.0
        for result in results {
            let hr = result.quantity.doubleValue(for: .heartRateUnit)
            if hr > max { max = hr }
            if hr < min { min = hr }
            total += result.quantity.doubleValue(for: .heartRateUnit)
        }
        let average = Int(total)/results.count
        
        // most recent
        let lastIndex = results.count - 1
        let lastMeasurement = results[lastIndex]
        let newHeartRate = Int(lastMeasurement.quantity.doubleValue(for: .heartRateUnit))
        DispatchQueue.main.async {
            if self.watchWarningLabel.alpha == 1 {
                UIView.animate(withDuration: 0.2, animations: {
                    self.watchWarningLabel.alpha = 0
                })
            }
            
            self.maxHRLabel.text = "Max - " + String(Int(max))
            self.minHRLabel.text = "Min - " + String(Int(min))
            self.avgHRLabel.text = "Avg - " + (String)(average)
            
            //self.liveHeartRateLabel.countingMethod = .easeOut
            //self.liveHeartRateLabel.count(from: Float(self.heartRate), to: Float(newHeartRate))
            print("New: ", newHeartRate)
            print("New: ", newHeartRate)
            self.heartRate = newHeartRate
        }
    }
    
    /* query HealthKit for resting HR data */
    func getDayRHR() {
        print("getDayRHR")
        // samples from today
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: Date())
        hkm.restingHeartRate(from: startDay, to: Date()) { (results) in
            if results.isEmpty {
                NSLog("no RHR samples")
                DispatchQueue.main.async {
                    self.restHRLabel.text = "--"
                }
                return
            } else {
                // found sample(s)
                DispatchQueue.main.async {
                    self.processDayRHR(results)
                }
            }
        }
    }
    
    func processDayRHR(_ results: [HKQuantitySample]) {
        let idx = results.count-1
        let RHR = results[idx].quantity.doubleValue(for: .heartRateUnit)
        restHRLabel.text = "Resting - \(Int(RHR))"
    }
    
    /* query HealthKit for workout data */
    func getDayWorkouts() {
        // workouts from today
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: Date())
        
        hkm.workouts(from: startDay, to: Date()) { (results) in
            DispatchQueue.main.async {
                self.processDayWorkouts(results)
            }
        }
    }
    
    func processDayWorkouts(_ results: [HKWorkout]) {
    }
    
    /* query HealthKit for step data */
    func getDaySteps() {
        // steps from today
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        
        // HealthKit query
        hkm.dailySteps { (results) in
            results.enumerateStatistics(from: startDate, to: Date()) { statistics, stop in
                if let sum = statistics.sumQuantity() {
                    DispatchQueue.main.async {
                        self.processDaySteps(sum.doubleValue(for: .count()))
                    }
                } else {
                    DispatchQueue.main.async {
                        self.processDaySteps(0)
                    }
                }
            }
        }
    }
    
    func processDaySteps(_ sum: Double) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        
        let steps = NSNumber(value: Int(sum))
        //switch steps {
        //case 0:
            //self.numStepsLabel.text = "You haven't taken\nany steps yet today."
        //default:
            //self.numStepsLabel.text = "You've taken\n\(formatter.string(from: steps)!) steps today."
        //}
    }
    
    /* HealthKit auth */
    func requestAuthorization() {
        let readingTypes:Set<HKObjectType> = [.heartRateType,
                                              .restingHeartRateType,
                                              .workoutType,
                                              .stepsType,
                                              .variabilityType,
                                              .genderType,
                                              .weightType,
                                              .heightType,
                                              .dateOfBirthType]
        
        // auth request
        hkm.requestAuthorization(readingTypes: readingTypes, writingTypes: nil) {
            DispatchQueue.main.async {
                self.getDayHR()
                self.getDayRHR()
                self.getDayWorkouts()
                self.getDaySteps()
                self.setGreetingLabel()
            }
            print("auth success")
        }
    }
}

// MARK: - misc functions
extension ViewController {
    /* time-based greeting label */
    func setGreetingLabel() {
        if let name = UserDefaults.standard.string(forKey: "userName") {
            let hour = Calendar.current.component(.hour, from: Date())
            DispatchQueue.main.async {
                switch hour {
                case 0..<12:
                    self.greetingLabel.text = "Good morning, \(name)!"
                case 12..<17:
                    self.greetingLabel.text = "Good afternoon, \(name)!"
                default:
                    self.greetingLabel.text = "Good evening, \(name)!"
                }
            }
        }
    }
}

extension ViewController: WCSessionDelegate {
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("Session inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("Session deactivated")
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("in session")
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        print("Recieved message")
        print("REFLEXGAY: ", userInfo["reflex"] as? Int ?? 0)
        DispatchQueue.main.async {
            if((userInfo["reflex"] as? Int ?? 0) != 0){
                self.reactionTimeLabel.text = (String)(userInfo["reflex"] as? Int ?? 0)
            }
        }
        if(userInfo["reflex"] as? Int == nil){
            print("NULL")
            ref = false
        }
        else{
            ref = true
            DispatchQueue.main.async {
                self.hrlabel.text = (String)(userInfo["reflex"] as? Int ?? 0)
            }
        }
        //print("REFLEXGAY: ", userInfo["reflex"] as! Int)
        //print("REFLEXGAY: ", userInfo["reflex"] as! Int)
        if(userInfo["message"] as? Int == nil){
            print("No heart rate detected")
        }
        else{
            //print("NEW HEART RATE: ", userInfo["message"] as? String ?? "NULL")
            print("NEW HEART RATE: ", userInfo["message"] as! Int)
            print("NEW HEART RATE: ", userInfo["message"] as! Int)
            print("NEW HEART RATE: ", userInfo["message"] as! Int)
            DispatchQueue.main.async {
                self.hrlabel.text = (String)(userInfo["message"] as! Int)
                print("HR: ", (String)(userInfo["message"] as! Int))
                print("Setting label to new heart rate")
            }
        }
    }
}
