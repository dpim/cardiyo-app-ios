//
//  ActivityInfo.swift
//  Cardioh
//
//  Created by Dmitry Pimenov on 12/27/16.
//  Copyright © 2016 Dmitry. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import HealthKit

class ActivityInfo {
    var duration: Int
    var distance: Int
    var timestamp: Date
    var primaryImage: UIImage?
    var takenWithFrontCamera: Bool? = true
    var isFbImage:Bool? = false
    var mapImage: UIImage?
    var points: [CLLocation]
    var caption: String?
    let meterToMileConv = 0.000621371
    
    
    init(duration: Int, distance: Int, points:[CLLocation], timestamp:Date){
        self.duration = duration
        self.distance = distance
        self.points = points
        self.timestamp = timestamp
        self.primaryImage = nil
        self.mapImage = nil
    }
    
    func getDistStr() -> String{
        var result = ""
        let distanceQuantity = HKQuantity(unit: HKUnit.meter(), doubleValue: Double(self.distance))
        let rawDist = distanceQuantity.doubleValue(for: HKUnit.meter())*meterToMileConv
        let trueDist = roundTo(value:rawDist,places:2)
        result = "\(trueDist) miles"
        return result
    }
    
    func getTimeStr() -> String {
        var result = ""
        //print(duration)
        let (hrs, mins, secs) = secondsToHoursMinutesSeconds(seconds: self.duration)
        result = "\(hrs):\(mins):\(secs)"
        return result
    }
    
    func getPaceStr() -> String {
        var result = ""
        let distVal = 0.001 + Double(self.distance)
        let distanceQuantity = HKQuantity(unit: HKUnit.meter(), doubleValue: distVal) //offset to provide NaN
        let rawDist = distanceQuantity.doubleValue(for: HKUnit.meter())*meterToMileConv
        let pace = (Double(self.duration))/rawDist
        var (p_hr, p_min, p_sec) = self.secondsToHoursMinutesSeconds(seconds: Int(pace))
        if (p_hr == "00"){
            let checkIndex = p_min.index(p_min.startIndex, offsetBy: 0)
            let replacementIndex = p_min.index(p_min.startIndex, offsetBy:1)
            if (p_min[checkIndex] == "0"){
                p_min = "\(p_min[replacementIndex])"
            }
            result = "\(p_min):\(p_sec)"
        } else {
            let checkInt:Int? = Int(p_hr)
            if (checkInt! > 24){
                result="very slow"
            } else {
                result = "\(p_hr):\(p_min):\(p_sec)"
            }
        }
        return result
    }
    
    func getShortForm() -> (String, String, String, String, UIImage?, UIImage?) {
        var pts_short = [Point]()
        if (points.count == 0){
        //do something
        } else {
            let first = points.first
            let firstPoint = Point(longitude: (first?.coordinate.longitude)!, latitude: (first?.coordinate.latitude)!, altitude: (first?.altitude)!, timestamp: (first?.timestamp)!)
            pts_short.append(firstPoint)
            var count = 1
            let max_count = 140
            let len = self.points.count
            let interval = Int(len/max_count)
            for point in self.points {
                if (len > max_count){
                    //sample some points
                    if (count%interval==0){
                        let nextPoint = Point(longitude: point.coordinate.longitude, latitude: point.coordinate.latitude, altitude: point.altitude, timestamp: point.timestamp)
                        pts_short.append(nextPoint)
                    }
                    count = count+1
                } else {
                    let nextPoint = Point(longitude: point.coordinate.longitude, latitude: point.coordinate.latitude, altitude: point.altitude, timestamp: point.timestamp)
                    pts_short.append(nextPoint)
                }
            }
        }
        
        var pt_str = ""
        var idx = 0
        for point in pts_short {
            let dateFormatter = ISO8601DateFormatter()
            let timeStr = dateFormatter.string(from: point.timestamp)
            //print(timeStr)
            if (idx == 0){
                pt_str = pt_str+"(\(point.latitude), \(point.longitude), \(point.altitude), \(timeStr))"
            } else {
                pt_str = pt_str+", (\(point.latitude), \(point.longitude), \(point.altitude), \(timeStr))"
            }
            idx += 1
        }
        
        let dur_str = "\(self.duration)"
        let dist_str =  "\(self.distance)"
        
        
        if (self.caption == nil){
            self.caption = ""
        }
        if self.isFbImage! == false && self.takenWithFrontCamera!{
            let imageRotated = self.primaryImage?.rotated(by: 270, flipped: true)
            return (dur_str, dist_str, self.caption!, pt_str, imageRotated, self.mapImage)
        } else if (self.isFbImage)!{
            print("is fb image")
            let imageRotated = self.primaryImage?.rotated(by: 0, flipped: false)
            return (dur_str, dist_str, self.caption!, pt_str, imageRotated, self.mapImage)
        } else {
            let imageRotated = self.primaryImage?.rotated(by: 90, flipped: false)
            return (dur_str, dist_str, self.caption!, pt_str, imageRotated, self.mapImage)
        }
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
    
    func roundTo(value: Double, places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (value * divisor).rounded() / divisor
    }
    
    func leftPad(value: Int) -> String {
        var valueStr = "\(value)"
        if (value/10 == 0){
            valueStr = "0\(valueStr)"
        }
        return valueStr
    }
}

class Point {
    var latitude: Double
    var longitude: Double
    var altitude: Double
    let timestamp: Date
    
    init(longitude: Double, latitude: Double, altitude: Double, timestamp: Date){
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.timestamp = timestamp
    }
    
}


extension Double {
    func toRadians() -> CGFloat {
        return CGFloat(self * .pi / 180.0)
    }
}

extension UIImage {
    func rotated(by degrees: Double, flipped: Bool = false) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        
        let transform = CGAffineTransform(rotationAngle: degrees.toRadians())
        var rect = CGRect(origin: .zero, size: self.size).applying(transform)
        rect.origin = .zero
        
        let renderer = UIGraphicsImageRenderer(size: rect.size)
        return renderer.image { renderContext in
            renderContext.cgContext.translateBy(x: rect.midX, y: rect.midY)
            renderContext.cgContext.rotate(by: degrees.toRadians())
            renderContext.cgContext.scaleBy(x: flipped ? -1.0 : 1.0, y: -1.0)
            
            let drawRect = CGRect(origin: CGPoint(x: -self.size.width/2, y: -self.size.height/2), size: self.size)
            renderContext.cgContext.draw(cgImage, in: drawRect)
        }
    }
}

