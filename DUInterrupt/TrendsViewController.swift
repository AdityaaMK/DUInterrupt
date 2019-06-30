//
//  TrendsViewController.swift
//  Cardiologic
//  Displays static graphs of past week's heart rate data
//
//  Created by Ben Zimring on 7/25/18.
//  Copyright © 2018 pulseApp. All rights reserved.
//

import UIKit
import HealthKit
import Charts
import DropDown

class TrendsViewController: UIViewController, ChartViewDelegate {

    let hkm = HealthKitManager()

    @IBOutlet weak var rhrLineChart: LineChartView!
    let rhrChartData = LineChartData()

    
    @IBOutlet weak var stepLineChart: LineChartView!
    let stepChartData = LineChartData()
    
    @IBOutlet weak var variabilityLineChart: LineChartView!
    let variabilityChartData = LineChartData()
    @IBOutlet weak var aboutVariabilityButton: UIButton!
    
    @IBOutlet weak var workoutLineChart: LineChartView!
    let workoutChartData = LineChartData()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configureCharts()
        graphRestingHeartRate()
        graphDailySteps()
        graphVariability()
        graphWorkoutTime()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func graphRestingHeartRate() {
        let calendar = Calendar.current
        let startDay = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: Date()))
        hkm.restingHeartRate(from: startDay!, to: Date()) { samples in
            if samples.count < 2 {
                print("graphRestingHeartRate: not enough data")
                DispatchQueue.main.async {
                    self.rhrLineChart.data = nil
                    self.rhrLineChart.notifyDataSetChanged()
                }
                return
            }
            // create chart entries for each data point
            var entries = [ChartDataEntry]()
            for sample in samples {
                let exactDate = sample.startDate
                let day = calendar.startOfDay(for: exactDate)
                let x = Double(Int(day.timeIntervalSinceNow/86400))
                let y = sample.quantity.doubleValue(for: .heartRateUnit)
                entries.append(ChartDataEntry(x: x, y: y))
            }
            
            // create data set of those points
            let dataSet = LineChartDataSet()
            for entry in entries {
                let _ = dataSet.addEntry(entry)
            }
            
            // dataset settings
            dataSet.mode = .cubicBezier
            dataSet.drawCirclesEnabled = true
            dataSet.circleRadius = 2
            dataSet.circleColors = [.red]
            dataSet.circleHoleColor = .red
            dataSet.colors = [.red]
            dataSet.drawValuesEnabled = true
            dataSet.valueFont = UIFont(name: "Avenir", size: 12)!
            dataSet.valueFormatter = DigitValueFormatter()
            dataSet.lineWidth = 2
            dataSet.highlightColor = .clear
            self.rhrChartData.addDataSet(dataSet)
            DispatchQueue.main.async {
                self.rhrLineChart.xAxis.axisMinimum = -7
                self.rhrLineChart.xAxis.axisMaximum = 0
                self.rhrLineChart.xAxis.labelCount = dataSet.entryCount
                self.rhrLineChart.xAxis.valueFormatter = DayValueFormatter()
                self.rhrLineChart.leftAxis.axisMaximum = dataSet.yMax + 10
                self.rhrLineChart.notifyDataSetChanged()
            }
        }
    }
    
    func graphDailySteps() {
        hkm.dailySteps(handler: { (results) in
            let calendar = Calendar.current
            let endDate = Date()
            let startDate = calendar.date(byAdding: .day, value: -7, to: endDate, wrappingComponents: false)
            let dataSet = LineChartDataSet()
            results.enumerateStatistics(from: startDate!, to: endDate) { statistics, stop in
                if let quantity = statistics.sumQuantity() {
                    let exactDate = statistics.startDate
                    let day = calendar.startOfDay(for: exactDate)
                    let x = Double(Int(day.timeIntervalSinceNow/86400))
                    let y = quantity.doubleValue(for: .count())
                    let entry = ChartDataEntry(x: x, y: y)
                    let _ = dataSet.addEntry(entry)
                }
            }
            
            if dataSet.entryCount < 2 {
                print("graphDailySteps: not enough data")
                DispatchQueue.main.async {
                    self.stepLineChart.data = nil
                    self.stepLineChart.notifyDataSetChanged()
                }
                return
            }
            let darkGreen = UIColor(red: 0, green: 128/255, blue: 0, alpha: 1)
            // dataset settings
            dataSet.mode = .cubicBezier
            dataSet.drawCirclesEnabled = true
            dataSet.circleRadius = 2
            dataSet.circleColors = [darkGreen]
            dataSet.circleHoleColor = darkGreen
            dataSet.colors = [darkGreen]
            dataSet.drawValuesEnabled = true
            dataSet.valueFont = UIFont(name: "Avenir", size: 12)!
            dataSet.valueFormatter = DigitValueFormatter()
            dataSet.lineWidth = 2
            dataSet.highlightColor = .clear
            self.stepChartData.addDataSet(dataSet)
            DispatchQueue.main.async {
                self.stepLineChart.xAxis.axisMinimum = -7
                self.stepLineChart.xAxis.axisMaximum = 0
                self.stepLineChart.xAxis.valueFormatter = DayValueFormatter()
                self.stepLineChart.leftAxis.axisMaximum = dataSet.yMax + 3000
                self.stepLineChart.notifyDataSetChanged()
            }
            
        })
    }
    
    func graphVariability() {
        let calendar = Calendar.current
        let startDay = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: Date()))!
        hkm.variability(from: startDay, to: Date()) { (samples) in
            var results = [Double: (Double, Int)]()
            for sample in samples {
                let exactDate = sample.startDate
                let day = calendar.startOfDay(for: exactDate)
                let x = Double(Int(day.timeIntervalSinceNow/86400))
                let y = sample.quantity.doubleValue(for: .variabilityUnit)
                if results[x] == nil {
                    results[x] = (y, 1)
                } else {
                    results[x]!.0 += y
                    results[x]!.1 += 1
                }
            }
            
            let dataSet = LineChartDataSet()
            for i in -7...0 {
                if let result = results[Double(i)] {
                    let x = Double(i)
                    let y = result.0/Double(result.1)
                    let entry = ChartDataEntry(x: x, y: y)
                    let _ = dataSet.addEntry(entry)
                }
            }
            
            if dataSet.entryCount < 2 {
                print("graphVariability: not enough data")
                DispatchQueue.main.async {
                    self.variabilityLineChart.data = nil
                    self.variabilityLineChart.notifyDataSetChanged()
                }
                return
            }
            
            // dataset settings
            dataSet.mode = .cubicBezier
            dataSet.drawCirclesEnabled = true
            dataSet.circleRadius = 2
            dataSet.circleColors = [.purple]
            dataSet.circleHoleColor = .purple
            dataSet.colors = [.purple]
            dataSet.drawValuesEnabled = true
            dataSet.valueFont = UIFont(name: "Avenir", size: 12)!
            dataSet.valueFormatter = VariabilityValueFormatter()
            dataSet.lineWidth = 2
            dataSet.highlightColor = .clear
            self.variabilityChartData.addDataSet(dataSet)
            DispatchQueue.main.async {
                self.variabilityLineChart.xAxis.axisMinimum = -7
                self.variabilityLineChart.xAxis.axisMaximum = 0
                self.variabilityLineChart.xAxis.valueFormatter = DayValueFormatter()
                self.variabilityLineChart.leftAxis.axisMaximum = dataSet.yMax + 20
                self.variabilityLineChart.notifyDataSetChanged()
            }
        }
    }
    
    func graphWorkoutTime() {
        let calendar = Calendar.current
        let startDay = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: Date()))!
        hkm.workouts(from: startDay, to: Date()) { (samples) in
            var results = [Double: (Double, Int)]()
            for sample in samples {
                let exactDate = sample.startDate
                let day = calendar.startOfDay(for: exactDate)
                let x = Double(Int(day.timeIntervalSinceNow/86400))
                let y = sample.duration/60
                if results[x] == nil {
                    results[x] = (y, 1)
                } else {
                    results[x]!.0 += y
                    results[x]!.1 += 1
                }
            }

            let dataSet = LineChartDataSet()
            for i in -7...0 {
                if let result = results[Double(i)] {
                    let x = Double(i)
                    let y = result.0/Double(result.1)
                    let entry = ChartDataEntry(x: x, y: y)
                    let _ = dataSet.addEntry(entry)
                }
            }
            
            if dataSet.entryCount < 2 {
                print("graphWorkoutTime: not enough data")
                DispatchQueue.main.async {
                    self.workoutLineChart.data = nil
                    self.workoutLineChart.notifyDataSetChanged()
                }
                return
            }
            let steelBlue = UIColor(red: 70/255, green: 130/255, blue: 180/255, alpha: 1)
            // dataset settings
            dataSet.mode = .cubicBezier
            dataSet.drawCirclesEnabled = true
            dataSet.circleRadius = 2
            dataSet.circleColors = [steelBlue]
            dataSet.circleHoleColor = steelBlue
            dataSet.colors = [steelBlue]
            dataSet.drawValuesEnabled = true
            dataSet.valueFont = UIFont(name: "Avenir", size: 12)!
            dataSet.valueFormatter = WorkoutValueFormatter()
            dataSet.lineWidth = 2
            dataSet.highlightColor = .clear
            self.workoutChartData.addDataSet(dataSet)
            DispatchQueue.main.async {
                self.workoutLineChart.xAxis.axisMinimum = -7
                self.workoutLineChart.xAxis.axisMaximum = 0
                self.workoutLineChart.xAxis.spaceMin = 0.2
                self.workoutLineChart.xAxis.spaceMax = 0.2
                self.workoutLineChart.xAxis.valueFormatter = DayValueFormatter()
                self.workoutLineChart.leftAxis.axisMaximum = dataSet.yMax + 15
                self.workoutLineChart.notifyDataSetChanged()
            }
        }
    }
    
    // master chart settings
    func configureCharts() {
        rhrLineChart.data = rhrChartData
        rhrLineChart.delegate = self
        
        stepLineChart.data = stepChartData
        stepLineChart.delegate = self
        
        variabilityLineChart.data = variabilityChartData
        variabilityLineChart.delegate = self
        
        workoutLineChart.data = workoutChartData
        workoutLineChart.delegate = self
        
        let charts = [rhrLineChart, stepLineChart, variabilityLineChart, workoutLineChart]
        for chart in charts {
            chart?.legend.enabled = false
            chart?.chartDescription = nil
            chart?.backgroundColor = .clear
            chart?.scaleYEnabled = false
            chart?.noDataText = "Not enough data"
            chart?.noDataTextColor = .black
            chart?.noDataFont = UIFont(descriptor: .init(name: "Avenir Book", size: 17), size: 17)

            chart?.xAxis.drawGridLinesEnabled = false
            chart?.xAxis.labelPosition = .bottom
            chart?.xAxis.labelTextColor = .black
            chart?.xAxis.granularity = 1

            chart?.rightAxis.drawGridLinesEnabled = false
            chart?.rightAxis.drawAxisLineEnabled = false
            chart?.rightAxis.drawLabelsEnabled = false
            
            chart?.leftAxis.drawAxisLineEnabled = false
            chart?.leftAxis.drawGridLinesEnabled = false
            chart?.leftAxis.drawLabelsEnabled = false
            chart?.leftAxis.labelTextColor = .black
        }
    }
}

/* misc */
extension TrendsViewController {
}
