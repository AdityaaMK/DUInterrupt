//
//  StatsContentViewController.swift
//  Cardiologic
//  Displays selected day's heart rate info with graph
//
//  Created by Ben Zimring on 5/31/18.
//  Copyright © 2018 pulseApp. All rights reserved.
//

import UIKit
import HealthKit
import Charts
import MessageUI

class StatsContentViewController: UIViewController {

    // label outlets
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var maxHRLabel: UILabel!
    @IBOutlet weak var minHRLabel: UILabel!
    @IBOutlet weak var avgHRLabel: UILabel!
    @IBOutlet weak var restHRLabel: UILabel!
    @IBOutlet weak var nextArrow: UIButton!
    
    // image outlets
    @IBOutlet weak var maxHRImage: UIImageView!
    @IBOutlet weak var minHRImage: UIImageView!
    @IBOutlet weak var avgHRImage: UIImageView!
    @IBOutlet weak var restHRImage: UIImageView!
    
    // chart outlet
    @IBOutlet weak var lineChart: LineChartView!

    let hkm = HealthKitManager()
    
    var numDaysBeforeToday: Int?
    var minXAxisIndex = -1
    var swipeDirection: Int?
    var hasAnimated = false
    let chartData = LineChartData()

    override func viewDidLoad() {
        print("viewDidLoad")
        super.viewDidLoad()
        
        // chart data
        lineChart.data = chartData
        lineChart.delegate = self

        let images = [maxHRImage, avgHRImage, minHRImage, restHRImage]
        let labels = [maxHRLabel, avgHRLabel, minHRLabel, restHRLabel]
        for i in 0..<images.count {
            labels[i]?.text = "--"
            labels[i]?.alpha = 0
            images[i]?.alpha = 0
        }

        // Do any additional setup after loading the view.
        if hkm.isHealthDataAvailable() {
            requestAuthorization()
        }
        formatChart()
        setDateLabel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let images = [maxHRImage, avgHRImage, minHRImage, restHRImage]
        let labels = [maxHRLabel, avgHRLabel, minHRLabel, restHRLabel]
        let direction = [convertFromCATransitionSubtype(CATransitionSubtype.fromLeft), convertFromCATransitionSubtype(CATransitionSubtype.fromRight)]
        if swipeDirection == -1 {
            // if Today, fade in.. otherwise nothing
            if numDaysBeforeToday == 0 {
                for i in 0..<images.count {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)*0.1) {
                        UIView.animate(withDuration: 0.1, animations: {
                            images[i]?.alpha = 1
                            labels[i]?.alpha = 1
                        })
                    }
                }
            }
            return
        }

        // gives a bit of a parallax effect
        if !hasAnimated {
            for i in 0..<images.count {
                labels[i]?.pushTransition(direction: direction[swipeDirection!], duration: 0.3)
                images[i]?.pushTransition(direction: direction[swipeDirection!], duration: 0.3)
            }
            hasAnimated = true
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(false)
        swipeDirection = -1
    }

    /* HealthKit auth */
    func requestAuthorization() {
        let readingTypes:Set<HKObjectType> = [.heartRateType, .restingHeartRateType, .workoutType()]

        //auth request
        hkm.requestAuthorization(readingTypes: readingTypes, writingTypes: nil) {
            self.getDayHeartRate()
            self.getDayRHR()
            self.getDayWorkouts()
            print("auth success")
        }
        
        // loop refresh every minute for Today
        if self.numDaysBeforeToday! == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                self.requestAuthorization()
            }
        }
    }

    /* header date */
    func setDateLabel() {
        if numDaysBeforeToday! == 0 { nextArrow.isEnabled = false }
        switch numDaysBeforeToday! {
        case 0:
            dateLabel.text = "Today"
        case -1:
            dateLabel.text = "Yesterday"
        default:
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let startDay = calendar.startOfDay(for: calendar.date(byAdding: .day, value: numDaysBeforeToday!, to: today)!)
            let dayText = DateFormatter.localizedString(from: startDay, dateStyle: .long, timeStyle: .none)
            dateLabel.text = dayText
        }
    }

    // nav
    @IBAction func didTouchNextArrow(_ sender: Any) {
        NotificationCenter.default.post(name: AppDelegate.kNextNotification, object: self)
    }
    @IBAction func didTouchPrevArrow(_ sender: Any) {
        NotificationCenter.default.post(name: AppDelegate.kPrevNotification, object: self)
    }
}

/* HealthKit querying */
extension StatsContentViewController {
    
    /* query HealthKit for HR data */
    func getDayHeartRate() {
        print("getDayHeartRate")
        let calendar = Calendar.current
        
        // create 1-day range
        let today = calendar.startOfDay(for: Date())
        let startDay = numDaysBeforeToday! == 0 ? today : calendar.startOfDay(for: calendar.date(byAdding: .day, value: numDaysBeforeToday!, to: today)!)
        let endDay = numDaysBeforeToday! == 0 ? Date() : calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: startDay)!)
        
        hkm.heartRate(from: startDay, to: endDay) { (results) in
            if results.isEmpty {
                DispatchQueue.main.async {
                    self.lineChart.data = nil // chart displays "No data"
                }
            } else {
                self.graphHeartRateInfo(results)
            }
        }
    }
    
    /* query HealthKit for RHR data */
    func getDayRHR() {
        print("getDayRHR")
        
        // samples from today
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDay = numDaysBeforeToday! == 0 ? today : calendar.startOfDay(for: calendar.date(byAdding: .day, value: numDaysBeforeToday!, to: today)!)
        let endDay = numDaysBeforeToday! == 0 ? Date() : calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: startDay)!)
        
        hkm.restingHeartRate(from: startDay, to: endDay) { (results) in
            if results.isEmpty {
                DispatchQueue.main.async {
                    self.restHRLabel.text = "--"
                }
            } else {
                // found sample(s)
                DispatchQueue.main.async {
                    self.processDayRHR(results)
                }
            }
        }
    }
    
    func processDayRHR(_ samples: [HKQuantitySample]) {
        print("found samples")
        let idx = samples.count-1
        let RHR = samples[idx].quantity.doubleValue(for: .heartRateUnit)
        restHRLabel.text = "\(Int(RHR))"
    }
    
    /* query HealthKit for workout data */
    func getDayWorkouts() {
        
        // bounds are this View Controller's day
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDay = numDaysBeforeToday! == 0 ? today : calendar.startOfDay(for: calendar.date(byAdding: .day, value: numDaysBeforeToday!, to: today)!)
        let endDay = numDaysBeforeToday! == 0 ? Date() : calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: startDay)!)
        
        // HealthKit query
        hkm.workouts(from: startDay, to: endDay) { (results) in
            if !results.isEmpty {
                // found workout(s)
                DispatchQueue.main.async {
                    self.graphWorkouts(results)
                }
            }
        }
    }
}

/* chart stuff */
extension StatsContentViewController: IAxisValueFormatter, ChartViewDelegate {
    /* chart visuals */
    func formatChart() {
        lineChart.legend.enabled = false
        lineChart.chartDescription = nil
        lineChart.backgroundColor = .clear
        lineChart.scaleYEnabled = false
        lineChart.noDataText = "No data"
        lineChart.noDataTextColor = .black
        lineChart.noDataFont = UIFont(descriptor: .init(name: "Avenir Book", size: 17), size: 17)

        lineChart.xAxis.drawGridLinesEnabled = false
        lineChart.xAxis.avoidFirstLastClippingEnabled = true
        lineChart.xAxis.labelPosition = .bottom
        lineChart.xAxis.granularityEnabled = true
        lineChart.xAxis.granularity = 1
        lineChart.xAxis.axisMaximum = 12
        lineChart.xAxis.valueFormatter = self
        lineChart.xAxis.labelTextColor = .black

        lineChart.rightAxis.drawGridLinesEnabled = false
        lineChart.rightAxis.drawAxisLineEnabled = false
        lineChart.rightAxis.drawLabelsEnabled = false
        lineChart.rightAxis.axisMinimum = 30
        lineChart.rightAxis.axisMaximum = 210

        lineChart.leftAxis.drawGridLinesEnabled = false
        lineChart.leftAxis.axisMinimum = 30
        lineChart.leftAxis.axisMaximum = 210
        lineChart.leftAxis.labelTextColor = .black
    }
    
    /* plot heart rate data on chart */
    func graphHeartRateInfo(_ results: [HKSample]) {
        // max/min/avg
        var maxHR: Double = 0
        var minHR: Double = 999
        var avgHR: Double = 0
        
        // sort HR data from start of day
        var entries = [ChartDataEntry]()
        if results.isEmpty { print("empty results"); return }
        let startOfDay = Calendar.current.startOfDay(for: results[0].startDate)
        for result in results {
            guard let currData = result as? HKQuantitySample else { return }
            let x = currData.startDate.timeIntervalSince(startOfDay)/7200 // normalized to 12 because x-axis labels
            let y = currData.quantity.doubleValue(for: .heartRateUnit)
            avgHR += y
            if y > maxHR { maxHR = y }
            if y < minHR { minHR = y }
            entries.append(ChartDataEntry(x: x, y: y))
        }
        
        // split HR data into separate series
        var dataSets = [LineChartDataSet]()
        dataSets.append(LineChartDataSet())
        var currentSet = 0
        for i in 0..<entries.count {
            if i == 0 { continue }
            if entries[i].x - entries[i-1].x > 1200/7200 { // 1200 == 10min
                currentSet += 1
                dataSets.append(LineChartDataSet())
                let _ = dataSets[currentSet].addEntry(entries[i])
            } else {
                let _ = dataSets[currentSet].addEntry(entries[i])
            }
        }
        
        // smooth data using averages
        var averagedSets = [LineChartDataSet]()
        let n = 2 // average every 'n' points
        currentSet = 0
        for set in dataSets {
            averagedSets.append(LineChartDataSet())
            var currentEntry = 0
            while currentEntry < set.entryCount {
                var localAvgHR = 0.0
                var avgX = 0.0
                var entries = 0.0
                for i in currentEntry..<currentEntry + n {
                    if i == set.entryCount { break }
                    guard let ent = set.entryForIndex(i) else { continue }
                    localAvgHR += ent.y
                    avgX += ent.x
                    entries += 1
                }
                localAvgHR /= entries; avgX /= entries
                let _ = averagedSets[currentSet].addEntry(ChartDataEntry(x: avgX, y: localAvgHR))
                currentEntry += Int(entries)
            }
            currentSet += 1
        }
        
        // chart settings
        let gradientColors = [UIColor.white.cgColor, UIColor.heartColor.cgColor] as CFArray
        let colorLocations:[CGFloat] = [0.4, 0.6] // gradient positioning (max, min)
        let gradient = CGGradient.init(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors, locations: colorLocations) // Gradient Object
        for set in averagedSets {
            set.mode = .cubicBezier
            set.drawCirclesEnabled = false
            set.drawValuesEnabled = false
            set.lineWidth = 2
            set.fill = Fill.fillWithLinearGradient(gradient!, angle: 90)
            set.drawFilledEnabled = true
            set.highlightColor = .clear
            set.colors = [.heartColor]
            self.chartData.addDataSet(set)
        }
        
        // calculate avg HR
        avgHR = avgHR/Double(entries.count)
        let ll = ChartLimitLine(limit: avgHR)
        ll.lineColor = .lightGray
        ll.lineWidth = 0.5
        ll.lineDashLengths = [3]
        
        // UI elements
        DispatchQueue.main.async {
            self.lineChart.notifyDataSetChanged()
            self.lineChart.setVisibleXRange(minXRange: 1, maxXRange: 12)
            self.lineChart.leftAxis.addLimitLine(ll)
            self.maxHRLabel.text = "\(Int(maxHR))"
            self.minHRLabel.text = "\(Int(minHR))"
            self.avgHRLabel.text = "\(Int(avgHR))"
        }
    }
    
    /* plot workout data on chart */
    func graphWorkouts(_ workouts: [HKWorkout]) {
        if workouts.count == 0 { return }
        let startOfDay = Calendar.current.startOfDay(for: workouts[0].startDate)
        
        var workoutSets = [LineChartDataSet()]
        var currentSet = 0
        workoutSets.append(LineChartDataSet())
        
        // plot start & end times
        for workout in workouts {
            let startTime = workout.startDate.timeIntervalSince(startOfDay)/7200
            let endTime = workout.endDate.timeIntervalSince(startOfDay)/7200
            // y=30 so line is graphed at bottom
//            let image = UIImage(named: workout.workoutActivityType.getString)?.withRenderingMode(.alwaysTemplate)
//            let imgView = UIImageView()
//            imgView.tintColor = .black
//            imgView.image = image
            
            let _ = workoutSets[currentSet].addEntry(ChartDataEntry(x: startTime, y: 30, icon: nil))
            let _ = workoutSets[currentSet].addEntry(ChartDataEntry(x: endTime, y: 30, icon: nil))
            currentSet += 1
        }
        
        for set in workoutSets {
            set.mode = .linear
            set.circleRadius = 2
            set.circleColors = [.red]
            set.drawCirclesEnabled = false
            set.drawValuesEnabled = false
            set.drawIconsEnabled = true
            set.lineWidth = 5
            set.highlightEnabled = false
            set.colors = [.red]
            self.chartData.addDataSet(set)
        }
        
        // notify chart data changed
        DispatchQueue.main.async {
            self.lineChart.notifyDataSetChanged()
        }
    }
    
    /* delegates */
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        //
    }
    func chartScaled(_ chartView: ChartViewBase, scaleX: CGFloat, scaleY: CGFloat) {
        //
    }
    

    // TODO: this still doesn't work
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let times = ["12\n\u{263E}\u{fe0e}", "2\n", "4\n", "6\n", "8\n", "10\n", "12\n\u{2600}\u{fe0e}", "2\n", "4\n", "6\n", "8\n", "10\n", "12\n\u{263E}\u{fe0e}"]
        return times[Int(value)]
    }
}

/* sharing data */
extension StatsContentViewController: MFMailComposeViewControllerDelegate {
    // export day graph as CSV
    @IBAction func didTouchShareButton(_ sender: Any) {
        if !MFMailComposeViewController.canSendMail() { return }
        if chartData.dataSets.isEmpty { return }
        
        // date stuff init
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDay = calendar.startOfDay(for: calendar.date(byAdding: .day, value: numDaysBeforeToday!, to: today)!)
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        
        var dateHeader = "HR Data"  // default
        var haveDateHeader = false
        
        // create CSV
        let output = NSMutableString()
        output.append("Date,BPM\n")
        for set in chartData.dataSets {
            for i in 0..<set.entryCount {
                if let entry = set.entryForIndex(i) {
                    let date = calendar.date(byAdding: .second, value: Int(entry.x*7200), to: startDay)!
                    let dateString = formatter.string(from: date)
                    output.append("\(dateString),\(Int(entry.y))\n")
                    
                    // grab date header on first run through
                    if !haveDateHeader {
                        dateHeader = dateString.components(separatedBy: " ")[0]
                        haveDateHeader = true
                    }
                }
            }
        }
        
        // format for mailing
        if let data = output.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false) {
            let emailViewController = csvEmailController(header: dateHeader, data: data)
            self.present(emailViewController, animated: true, completion: nil)
        }
        
    }
    
    func csvEmailController(header: String, data: Data) -> MFMailComposeViewController {
        let emailController = MFMailComposeViewController()
        emailController.mailComposeDelegate = self
        emailController.setSubject("[Cardiologic] \(header)")
        emailController.setMessageBody("", isHTML: false)
        
        // Attaching the .CSV file to the email.
        emailController.addAttachmentData(data, mimeType: "text/csv", fileName: "\(header).csv")
        
        return emailController
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromCATransitionSubtype(_ input: CATransitionSubtype) -> String {
	return input.rawValue
}
