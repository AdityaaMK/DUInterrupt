//
//  AppDelegate.swift
//  Cardiologic
//
//  Created by Ben Zimring on 5/31/18.
//  Copyright © 2018 pulseApp. All rights reserved.
//

/**
 UserDefaults formatting:
 - TODO: userName: String
 - userBirthDict: ["month": Int, "date": Int, "year": Int]
 - userWeight: Int
 - userHeight: Int (inches)
 - userGender: String
 */

import UIKit
import HealthKit
import DropDown

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    static let kNextNotification = Notification.Name("kNextNotification")
    static let kPrevNotification = Notification.Name("kPrevNotification")
    static let kHideLogoNotification = Notification.Name("kHideLogoNotification")
    static let kShowLogoNotification = Notification.Name("kShowLogoNotification")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        //self.window = UIWindow(frame: UIScreen.main.bounds)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let hasLaunched = UserDefaults.standard.bool(forKey: "hasLaunched")
        
        print("hasLaunched: \(hasLaunched.description)")
        if !hasLaunched {
            let onboardViewController = storyboard.instantiateViewController(withIdentifier: "OnboardViewController")
            self.window?.rootViewController = onboardViewController
            self.window?.makeKeyAndVisible()
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}
extension HKWorkoutActivityType {
    var getString: String {
        switch self {
        case HKWorkoutActivityType.americanFootball:
            return "AmericanFootball";
        case HKWorkoutActivityType.archery:
            return "Archery";
        case HKWorkoutActivityType.australianFootball:
            return "AustralianFootball";
        case HKWorkoutActivityType.badminton:
            return "Badminton";
        case HKWorkoutActivityType.baseball:
            return "Baseball";
        case HKWorkoutActivityType.basketball:
            return "Basketball";
        case HKWorkoutActivityType.bowling:
            return "Bowling";
        case HKWorkoutActivityType.boxing:
            return "Boxing";
        case HKWorkoutActivityType.climbing:
            return "Climbing";
        case HKWorkoutActivityType.cricket:
            return "Cricket";
        case HKWorkoutActivityType.crossTraining:
            return "CrossTraining";
        case HKWorkoutActivityType.curling:
            return "Curling";
        case HKWorkoutActivityType.cycling:
            return "Cycling";
        case HKWorkoutActivityType.dance:
            return "Dance";
        case HKWorkoutActivityType.danceInspiredTraining:
            return "DanceInspiredTraining";
        case HKWorkoutActivityType.elliptical:
            return "Elliptical";
        case HKWorkoutActivityType.equestrianSports:
            return "EquestrianSports";
        case HKWorkoutActivityType.fencing:
            return "Fencing";
        case HKWorkoutActivityType.fishing:
            return "Fishing";
        case HKWorkoutActivityType.functionalStrengthTraining:
            return "FunctionalStrengthTraining";
        case HKWorkoutActivityType.golf:
            return "Golf";
        case HKWorkoutActivityType.gymnastics:
            return "Gymnastics";
        case HKWorkoutActivityType.handball:
            return "Handball";
        case HKWorkoutActivityType.hiking:
            return "Hiking";
        case HKWorkoutActivityType.hockey:
            return "Hockey";
        case HKWorkoutActivityType.hunting:
            return "Hunting";
        case HKWorkoutActivityType.lacrosse:
            return "Lacrosse";
        case HKWorkoutActivityType.martialArts:
            return "MartialArts";
        case HKWorkoutActivityType.mindAndBody:
            return "MindAndBody";
        case HKWorkoutActivityType.mixedMetabolicCardioTraining:
            return "MixedMetabolicCardioTraining";
        case HKWorkoutActivityType.paddleSports:
            return "PaddleSports";
        case HKWorkoutActivityType.play:
            return "Play";
        case HKWorkoutActivityType.preparationAndRecovery:
            return "PreparationAndRecovery";
        case HKWorkoutActivityType.racquetball:
            return "Racquetball";
        case HKWorkoutActivityType.rowing:
            return "Rowing";
        case HKWorkoutActivityType.rugby:
            return "Rugby";
        case HKWorkoutActivityType.running:
            return "Running";
        case HKWorkoutActivityType.sailing:
            return "Sailing";
        case HKWorkoutActivityType.skatingSports:
            return "SkatingSports";
        case HKWorkoutActivityType.snowSports:
            return "SnowSports";
        case HKWorkoutActivityType.soccer:
            return "Soccer";
        case HKWorkoutActivityType.softball:
            return "Softball";
        case HKWorkoutActivityType.squash:
            return "Squash";
        case HKWorkoutActivityType.stairClimbing:
            return "StairClimbing";
        case HKWorkoutActivityType.surfingSports:
            return "SurfingSports";
        case HKWorkoutActivityType.swimming:
            return "Swimming";
        case HKWorkoutActivityType.tableTennis:
            return "TableTennis";
        case HKWorkoutActivityType.tennis:
            return "Tennis";
        case HKWorkoutActivityType.trackAndField:
            return "TrackAndField";
        case HKWorkoutActivityType.traditionalStrengthTraining:
            return "TraditionalStrengthTraining";
        case HKWorkoutActivityType.volleyball:
            return "Volleyball";
        case HKWorkoutActivityType.walking:
            return "Walking";
        case HKWorkoutActivityType.waterFitness:
            return "WaterFitness";
        case HKWorkoutActivityType.waterPolo:
            return "WaterPolo";
        case HKWorkoutActivityType.waterSports:
            return "WaterSports";
        case HKWorkoutActivityType.wrestling:
            return "Wrestling";
        case HKWorkoutActivityType.yoga:
            return "Yoga";
        case HKWorkoutActivityType.other:
            return "Other";
        default:
            fatalError("Unknown type, number: \(self.rawValue)")
        }
    }
}


extension UIColor {
    static let heartColor = UIColor(red: 127/255, green: 24/255, blue: 27/255, alpha: 1)
}

extension UIView {
    func pushTransition(direction: String?, duration:CFTimeInterval) {
        self.alpha = 1 // start at alpha 0 to make things smooth
        let animation:CATransition = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name:
            CAMediaTimingFunctionName.easeInEaseOut)
        animation.type = CATransitionType.push
        animation.subtype = convertToOptionalCATransitionSubtype(direction)
        animation.duration = duration
        layer.add(animation, forKey: convertFromCATransitionType(CATransitionType.push))
    }
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalCATransitionSubtype(_ input: String?) -> CATransitionSubtype? {
	guard let input = input else { return nil }
	return CATransitionSubtype(rawValue: input)
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromCATransitionType(_ input: CATransitionType) -> String {
	return input.rawValue
}
