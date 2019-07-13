//
//  ChartFormatters.swift
//  Cardiologic
//
//  Created by Adityaa Magesh Kumar on 8/1/19.
//  Copyright © 2019 Adityaa Magesh Kumar. All rights reserved.
//

import Foundation
import Charts

/**
 VariabilityValueFormatter
 - Parameter value: input double to format
 - Returns: string of input stripped of decimals, appends "ms"
 */
class VariabilityValueFormatter : NSObject, IValueFormatter {
    func stringForValue(_ value: Double,
                        entry: ChartDataEntry,
                        dataSetIndex: Int,
                        viewPortHandler: ViewPortHandler?) -> String {
    
        return "\(Int(value))"
    }
}

/**
 DigitValueFormatter
 - Parameter value: input double to format
 - Returns: formatted string stripped of decimals, appends K if in 1000s
 */
class DigitValueFormatter : NSObject, IValueFormatter {
    func stringForValue(_ value: Double,
                        entry: ChartDataEntry,
                        dataSetIndex: Int,
                        viewPortHandler: ViewPortHandler?) -> String {
        let n = Int(value)
        return n >= 1000 ? "\(n/1000)K" : "\(n)"
    }
}

/**
 DayValueFormatter
 - Parameter value: number of days from now to get string
 - Returns: 2char prefix string of day of the week
 */
class DayValueFormatter : NSObject, IAxisValueFormatter {
    func stringForValue(_ value: Double, axis _: AxisBase?) -> String {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: Int(value), to: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let str = formatter.string(from: day!)
        return String(str.prefix(2))
    }
}

/**
 WorkoutValueFormatter
 - Parameter value: time (minutes) of workout
 - Returns: string formatted for minutes/hours
 */
class WorkoutValueFormatter : NSObject, IValueFormatter {
    func stringForValue(_ value: Double,
                        entry: ChartDataEntry,
                        dataSetIndex: Int,
                        viewPortHandler: ViewPortHandler?) -> String {
    
        return "\(Int(value))"
    }
}

