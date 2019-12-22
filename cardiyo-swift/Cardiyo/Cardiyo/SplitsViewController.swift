//
//  File.swift
//  Cardioh
//
//  Created by Dmitry Pimenov on 10/7/17.
//  Copyright © 2017 Dmitry. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import SwiftChart

class SplitsViewController: UITableViewController, ChartDelegate {
    var points: [CLLocation]?
    var paceDict: [Date: Double] = [Date: Double]()
    var distDict: [Double: Double] = [Double: Double]()
    var data: [(x: Double, y: Double)]?
    var avgPace: Float = 0
    var trimmedStart: Bool = false //trim start of run

    let meterToMileConv = 0.000621371
    let chartSection = 0
    let splitSection = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let (pace, dist) = processPoints(points: self.points!){
            self.paceDict = pace
            self.distDict = dist
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == chartSection){
            return "Pace"
        } else if (section == splitSection){
            return "Splits"
        } else {
            return ""
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.section == chartSection){ //chart
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "chartCell", for: indexPath) as! ChartTableCellView
            if let (xLabels, yLabels, data) = reshapePaceDict(dict: paceDict){
                self.data = data
                let series = ChartSeries(data: data)
                series.colors = (
                    above: ChartColors.darkGreenColor(),
                    below: ChartColors.greenColor(),
                    zeroLevel: self.avgPace
                )
                
                print("zero level: \(self.avgPace)")
                cell.chart!.labelColor = UIColor.gray
                cell.chart!.gridColor = UIColor.gray
                cell.chart!.showXLabelsAndGrid = false
                cell.chart!.yLabels = yLabels
                cell.chart!.yLabelsFormatter = { String(Int(round($1)))+" min/mil" }
                cell.chart!.add(series)
                cell.chart!.delegate = self
            }
            return cell            
        } else if (indexPath.section == splitSection){
            let sortedArr = Array(distDict).sorted(by: { $0.0 < $1.0 })
            if (sortedArr.count <= 1){
                return UITableViewCell()
            }
            let rowAdjusted = indexPath.row+1
            let totalTime = sortedArr[rowAdjusted].value - sortedArr[rowAdjusted-1].value
            let (hour, minute, second) = secondsToHoursMinutesSeconds(seconds: Int(totalTime))
            var diff = sortedArr[rowAdjusted].key
            if (rowAdjusted+1 == sortedArr.count){
                let trim = Double(Int(sortedArr[rowAdjusted].key))
                if (sortedArr[rowAdjusted-1].key < trim){
                    diff = trim
                } else if (diff-trim < 0.1){
                    diff = 0.1
                } else {
                    diff = diff - trim
                }
            }
            let trimmedDiff = (Double(Int(diff*10)))/10.0
            return defaultTextCell(text: "Mile \(trimmedDiff) in: \(hour):\(minute):\(second)")
        } else  {
            return UITableViewCell()
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
        
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == chartSection){
            return 1
        } else if (section == splitSection){
            return distDict.count-1 //remove entry for 0
        } else {
            return 0
        }
    }
    
    func reshapePaceDict(dict: [Date: Double]) -> ([Float], [Float], [(x: Double, y: Double)])? {
        var result = [(x: Double, y: Double)]()
        var yLabels:[Float] = [6.0, 12.0]
        var xLabels:[Float] = [Float]()
        let cutOff = 30.0
        let maxNumPoints = 20
        var sampleRate = dict.keys.count / maxNumPoints
        if (sampleRate <= 0){
            sampleRate = 1
        }
        var hitCutOff = false
        if (dict.keys.count > 1){
            let start = dict.first!.key
            var i = 0
            for key in dict.keys {
                let timeElapsed = (key.timeIntervalSince(start)/60)
                let value = 1/(60*dict[key]!)
                if (value <= cutOff && i % sampleRate == 0){ //sample one of every 10 pts
                    result.append((x: Double(i), y: value))
                } else if (value > cutOff && i % sampleRate == 0){
                    result.append((x: timeElapsed, y: cutOff))
                    hitCutOff = true
                }
                i = i + 1
            }
            if (hitCutOff){
                yLabels = yLabels + [ 18.0, 24.0, 30.0]
            }
            xLabels = result.map({Float($0.x)})
            result.sort { $0.x < $1.x } //sort tuples by start time
            return (xLabels, yLabels, result)
        } else {
            return nil
        }
    }
    
    func processPoints(points: [CLLocation]?) -> ([Date: Double], [Double: Double])? {
        var pace = [Date: Double]()
        var distOrder:[Double] = []
        var dist = [Double: Double]()
        if (points == nil){
            return nil
        } else if (points!.count <= 1){
          return nil
        } else {
            var past = points![0]
            var overallTimeInSeconds = 0.0
            var overallDistance = 0.0
            for i in 1..<points!.count {
                let curr = points![i]
                let distance = curr.distance(from: past)
                let mileDist = distance * meterToMileConv
                let interval = curr.timestamp.timeIntervalSince(past.timestamp)
                let timeDiffInSeconds = interval
                if (timeDiffInSeconds > 0.01){
                    if (!trimmedStart && Double(timeDiffInSeconds) > 30 && overallTimeInSeconds < 30){
                        //reset - discongruency due to gps
                        self.trimmedStart = true
                        overallTimeInSeconds = 0.0
                        overallDistance = 0.0
                        pace = [Date: Double]()
                        dist = [Double: Double]()
                    } else {
                        pace[curr.timestamp] = (mileDist/timeDiffInSeconds)
                        overallTimeInSeconds = overallTimeInSeconds + Double(timeDiffInSeconds)
                        overallDistance = overallDistance + mileDist
                    }
                }
                if (i == points!.count - 1){
                    dist[overallDistance] = overallTimeInSeconds
                } else {
                    let truncatedDist = Double(Int(overallDistance))
                    if (!dist.keys.contains(truncatedDist)){ //passed a new mile marker
                        dist[truncatedDist] = overallTimeInSeconds
                    }
                }
                past = curr
            }
            
            self.avgPace = Float(
                (overallTimeInSeconds/60)/(overallDistance)
            )
            
            print("overall time: \(overallTimeInSeconds)")
            print("overall dist: \(overallDistance)")

            //times not serialized
            if (overallTimeInSeconds < 1){
                self.showInformationalAlert(text: "Splits are not available for this run")
            }
    
            return (pace, dist)
        }
    }
    
    //CHART delegate
    func didTouchChart(_ chart: Chart, indexes: [Int?], x: Float, left: CGFloat) {
        for (seriesIndex, dataIndex) in indexes.enumerated() {
            if dataIndex != nil {
                if let value = chart.valueForSeries(seriesIndex, atIndex: dataIndex){
                    let (hour, minute, second) = secondsToHoursMinutesSeconds(seconds: Int(Double(value)*60))
                    let idxPath = IndexPath(row: 0, section: 0)
                    let cell = self.tableView.cellForRow(at: idxPath) as! ChartTableCellView
                    cell.paceLabel.text = "Mile pace: \(hour):\(minute):\(second)"
                }
            }
        }
    }
    
    func didFinishTouchingChart(_ chart: Chart) {

    }
    
    func didEndTouchingChart(_ chart: Chart) {
        let idxPath = IndexPath(row: 0, section: 0)
        let cell = self.tableView.cellForRow(at: idxPath) as! ChartTableCellView
        cell.paceLabel.text = ""
    }
    
    
    func defaultTextCell(text: String) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
        cell.selectionStyle = .blue
        cell.textLabel?.text = text
        cell.textLabel?.font = UIFont.systemFont(ofSize: 14.0)
        cell.textLabel?.textColor = UIColor.darkGray
        return cell
    }
    
    func showInformationalAlert(text: String){
        let alertController = UIAlertController(title: "Oops",
                                                message: text,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok",
                                                style: .default,
                                                handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func secondsToHoursMinutesSeconds (seconds : Int) -> (String, String, String) {
        var hrStr = "", minStr = "", secStr = ""
        var register = seconds
        let hr = register / 3600
        register = register - hr * 3600
        let min = register / 60
        register = register - min * 60
        let sec = register % 60
        
        if (hr/10 == 0){
            hrStr = "0\(hr)"
        } else {
            hrStr = "\(hr)"
        }
        if (min/10 == 0){
            minStr = "0\(min)"
        } else {
            minStr = "\(min)"
        }
        if (sec/10 == 0){
            secStr = "0\(sec)"
        } else {
            secStr = "\(sec)"
        }
        return (hrStr, minStr, secStr)
    }
}
