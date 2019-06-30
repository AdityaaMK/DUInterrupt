import UIKit
import HealthKit

class HealthKitManager: NSObject {
    
    static let health:         HKHealthStore  = HKHealthStore()
    static let heartRateUnit:  HKUnit         = HKUnit(from: "count/min")
    static let heartRateType:  HKQuantityType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    static var heartRateQuery: HKSampleQuery?
    
    class func authorizeHealthKit() {
        health.requestAuthorization(toShare: nil, read: [heartRateType]) { (success, error) in
            guard error == nil else { print(error?.localizedDescription ?? "Error nil"); return }
            print(success)
        }
    }
    
    class func getTodaysHeartRates(completion: @escaping (Double) ->()) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year,.month,.day], from: Date())

        guard let startDate: Date = calendar.date(from: components) else { return }
        
        let endDate: Date? = calendar.date(byAdding: .day, value: 1, to: startDate)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let sortDescriptors = [ NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false) ]
        
        heartRateQuery = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 25, sortDescriptors: sortDescriptors) { (query, sampleArray, error) in
            guard error == nil else { print(error?.localizedDescription ?? "Error nil"); return }
            
            for result: HKSample in sampleArray ?? [] {
                guard let currData = result as? HKQuantitySample else { return }
                completion(currData.quantity.doubleValue(for: heartRateUnit))
                break
            }
        }

        health.execute(heartRateQuery!)
    }

}
