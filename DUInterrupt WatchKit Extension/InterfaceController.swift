//
//  InterfaceController.swift
//  DUInterrupt WatchKit Extension
//
//  Created by Aditya Bose on 2/24/19.
//  Copyright © 2019 Aditya Bose. All rights reserved.
//

import WatchKit
import WatchConnectivity
import Foundation
import HealthKit
import Dispatch


class InterfaceController: WKInterfaceController, HKWorkoutSessionDelegate, WorkoutManagerDelegate {
    
    //private let wc_session = WCSession.default
    private let wcSession = WCSession.default
    var timerTest = Timer()
    var counterTest = 0.0
    var bruh = 0.0
    var ticker = true
    
    @IBOutlet var heartRateLabel: WKInterfaceLabel!
    @IBOutlet var ecgImage: WKInterfaceImage!
    @IBOutlet var button: WKInterfaceButton!
    
    let healthStore = HKHealthStore()
    let heartRateUnit = HKUnit(from: "count/min")
    let heartRateSampleType = HKObjectType.quantityType(forIdentifier: .heartRate)
    let workoutConfiguration = HKWorkoutConfiguration()
    
    var workoutActive = false
    var session: HKWorkoutSession?
    var currentQuery: HKQuery?
    var heartRate: Double = -1
    var wristRaised = false
    
    let workoutManager = WorkoutManager()
    var active = false
    
    var gravityStr = ""
    var attitudeStr = ""
    var userAccelStr = ""
    var rotationRateStr = ""
    var timer = Timer()
    var counter = 0.0
    
    // MARK: Interface Properties
    
    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    @IBOutlet weak var gravityLabel: WKInterfaceLabel!
    @IBOutlet weak var userAccelLabel: WKInterfaceLabel!
    @IBOutlet weak var rotationLabel: WKInterfaceLabel!
    @IBOutlet weak var attitudeLabel: WKInterfaceLabel!
    
    override init() {
        // This method runs FIRST at runtime
        print("interfaceController: init")
        super.init()
        wcSession.delegate = self
        wcSession.activate()
        print("wcSession activated")
        
        workoutManager.delegate = self
        
        workoutConfiguration.activityType = .mixedCardio
        workoutConfiguration.locationType = .indoor
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        // Configure interface objects here.
        //heartRateLabel.setText("--")
        ecgImage.setImageNamed("ecg_red-")
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        print("About to activate")
        guard HKHealthStore.isHealthDataAvailable() == true else { return }
        print("health data avail")
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        print("quantityType init")
        let dataTypes = Set(arrayLiteral: quantityType)
        healthStore.requestAuthorization(toShare: nil, read: dataTypes) { (success, error) in
            if !success { print("healthStore auth req error") }
        }
        active = true
        // On re-activation, update with the cached values.
        updateLabels()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        active = false
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        case .running: workoutDidStart()
        case .ended: workoutDidEnd()
        default: print("unexpected workout state change")
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("workoutSession failure")
    }
    
    func workoutDidStart() {
        print("workoutDidStart")
        // if query in progress, stop
        if currentQuery != nil {
            healthStore.stop(currentQuery!)
        }
        
        // new query
        currentQuery = HKObserverQuery(sampleType: heartRateSampleType!, predicate: nil) { (_, _, error) in
            if let error = error {
                print("currentQuery error: \(error.localizedDescription)")
                return
            }
            
            self.fetchLatestHeartRateSample() { (sample) in
                DispatchQueue.main.async {
                    let heartRate = sample.quantity.doubleValue(for: self.heartRateUnit)
                    print("Heart Rate Sample: \(heartRate)")
                    self.wcSession.transferUserInfo(["message": heartRate])
                    if self.workoutActive {
                        self.updateHeartRate(value: heartRate)
                    }
                }
            }
        }
        
        currentQuery != nil ? healthStore.execute(currentQuery!) : print("error: currentQuery nil")
    }
    
    func workoutDidEnd() {
        print("workoutDidEnd")
        heartRateLabel.setText("--")
        self.wcSession.transferUserInfo(["message": 000])
        heartRate = -1
    }
    
    func fetchLatestHeartRateSample(completionHandler: @escaping (_ sample: HKQuantitySample) -> Void) {
        guard let sampleType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: [sortDescriptor]) { (_, results, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            if (results?.isEmpty)! { print("empty results array"); return }
            completionHandler(results?[0] as! HKQuantitySample)
            
        }
        healthStore.execute(query)
    }
    
    func updateHeartRate(value: Double) {
        self.heartRateLabel.setText(String(Int(value)))
        
        // update animation if HR moves outside of current bounds
        let hrRange = heartRate - 3...heartRate + 3
        if !hrRange.contains(value) {
            heartRate = value
            ecgAnimation()
        }
    }
    
    func ecgAnimation() {
        print("animating")
        if 30...210 ~= heartRate {
            //new animation with updated HR
            ecgImage.stopAnimating()
            ecgImage.startAnimatingWithImages(in: NSMakeRange(1, 130), duration: 60.0/heartRate, repeatCount: 0)
        } else {
           ecgImage.stopAnimating()
       }
    }
    
    @IBAction func didTouchStartButton() {
        if self.workoutActive {
            // finish the current session
            workoutActive = false
            button.setTitle("Start")
            heartRateLabel.setText("--")
            ecgImage.stopAnimating()
            session?.stopActivity(with: Date())
            session?.end()
        } else {
            // start a new session
            workoutActive = true
            button.setTitle("Stop")
            // Configure the workout session.
            
            do {
                session = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
                session?.delegate = self
            } catch {
                fatalError("Failed to create a workout session object")
            }
            session?.startActivity(with: Date())
        }
    }
    // MARK: Interface Bindings
    func didUpdateTimerTest(_ manager: WorkoutManager, timerTest: Timer, counterTest: Double) {
        DispatchQueue.main.async {
            self.timerTest = timerTest
            self.counterTest = counterTest
        }
    }
    var doit = false
    @IBAction func start() {
        titleLabel.setText("Tracking...")
        //self.wcSession.transferUserInfo(["reflex" : 7])
        doit = false
        workoutManager.startTest()
        //print(deviceMotion.attitude.pitch);
    }
    
    @IBAction func stop() {
        titleLabel.setText("Stopped Recording")
        workoutManager.stopWorkout()
        print("Workout stopped")
        timerTest.invalidate();
        print(counter)
    }
    

    @objc func UpdateTimer() {
        //let reaction_time = "Time: "
        if(ticker){
            let recorded_time = (String)(counterTest)
            let pretty_string = ("Time: \(recorded_time)")
            self.titleLabel.setText(pretty_string)
            counterTest = counterTest + 0.1
        }
        else{
            self.titleLabel.setText("DONE")
            self.titleLabel.setText((String)(counterTest))
            self.wcSession.transferUserInfo(["reflex" : (Int)(counterTest)])
        }
        //timeLabel.text = String(format: "%.1f", counter)
    }
    
    // MARK: WorkoutManagerDelegate
    func didUpdateMotion(_ manager: WorkoutManager, gravityStr: String, rotationRateStr: String, userAccelStr: String, attitudeStr: String) {
        DispatchQueue.main.async {
            print("IN didUpdate motion")
            print("GRAVBONG", gravityStr)
            let abc = gravityStr.components(separatedBy: " ")
            print("components", gravityStr.components(separatedBy: " "))
            print("z-value", abc[(abc.firstIndex(of: "Z") ?? 0) + 5])
            self.gravityStr = gravityStr
            self.userAccelStr = userAccelStr
            self.rotationRateStr = rotationRateStr
            self.attitudeStr = attitudeStr
            self.updateLabels();
            print("IN UPDATE, WRIST RAISED: ", self.wristRaised)
            self.titleLabel.setText((String)(self.counterTest))
            
            if(abc[(abc.firstIndex(of: "Z") ?? 0) + 5] == "-0.3"){
                print("IN FIRST IF")
                self.wristRaised = true;
                self.titleLabel.setText("STARTING TIMER")
                self.timerTest = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.UpdateTimer), userInfo: nil, repeats: true)
            }
            if(abc[(abc.firstIndex(of: "Z") ?? 0) + 5] == "-1.0"){
                if(self.wristRaised){
                    self.wristRaised = false
                    self.titleLabel.setText((String)(self.counterTest))
                    self.button.setTitle((String)(self.wristRaised))
                    print("IN SECOND")
                    self.workoutManager.stopWorkout()
                    self.titleLabel.setText("Stopped workout")
                    self.titleLabel.setText((String)(self.counterTest))
                    self.timerTest.invalidate()
                    //print("Counter: ", self.counterTest)
                    self.timerTest.invalidate()
                    self.ticker = false
                    self.titleLabel.setText("INvalidated")
                    
                }
            }
        }
    }
    
    // MARK: Convenience
    func updateLabels() {
        if active {
            gravityLabel.setText(gravityStr)
            userAccelLabel.setText(userAccelStr)
            rotationLabel.setText(rotationRateStr)
            attitudeLabel.setText(attitudeStr)
        }
    }
    
}


/* watch delegation */
extension InterfaceController: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            print("wcSession: activated")
        } else {
            guard let error = error else { return }
            print("wcSession: activation error - \(error.localizedDescription)")
        }
    }
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("wcSession: message received")
        if let _ = message["startWorkout"] {
            print("starting workout")
            didTouchStartButton()
        } else { print("unknown message") }
    }
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        print("wcSession: userInfo received")
        print(userInfo)
    }
}
