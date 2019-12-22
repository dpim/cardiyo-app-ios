//
//  StatsViewController.swift
//  Cardioh
//
//  Created by Dmitry Pimenov on 1/21/17.
//  Copyright © 2017 Dmitry. All rights reserved.
//

import Foundation
import UIKit
import FacebookLogin
import FacebookCore
import Alamofire
import AlamofireImage
import SwiftyJSON
import HealthKit

class StatsViewController: UITableViewController {
    
    var fetchedResults = false
    var statsDict = 
    [
        "fastest": "TBD", 
        "longest":"TBD",
         "week": "0", 
         "month":"0", 
         "ever": "0",
         "week_mileage": "0", 
         "month_mileage": "0", 
         "ever_mileage": "0"
    ]
    let recordsSection = 0
    let freqSection = 1
    let mileageSection = 2
    let meterToMileConv = 0.000621371
    let metersInAMile = 1609.34
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title="Stats"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetchRecords()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
        if fetchedResults == true {
            let row = indexPath.row
            if indexPath.section == recordsSection {
                if (row == 0){
                    cell.textLabel?.text       = "Fastest mile pace"
                    cell.detailTextLabel?.text = statsDict["fastest"]

                } else if (row == 1){
                    cell.textLabel?.text       = "Longest run"
                    cell.detailTextLabel?.text = statsDict["longest"]

                }
            } else if (indexPath.section == freqSection){
                if (row == 0){
                    cell.textLabel?.text       = "Runs this week"
                    cell.detailTextLabel?.text = statsDict["week"]

                } else if (row == 1){
                    cell.textLabel?.text       = "Runs this month"
                    cell.detailTextLabel?.text = statsDict["month"]

                } else if (row == 2){
                    cell.textLabel?.text       = "Runs ever"
                    cell.detailTextLabel?.text = statsDict["ever"]

                }
            } else if (indexPath.section == mileageSection){
                    if (row == 0){
                        cell.textLabel?.text       = "Miles this week"
                        cell.detailTextLabel?.text = statsDict["week_mileage"]
                        
                    } else if (row == 1){
                        cell.textLabel?.text       = "Miles this month"
                        cell.detailTextLabel?.text = statsDict["month_mileage"]
                        
                    } else if (row == 2){
                        cell.textLabel?.text       = "Miles ever"
                        cell.detailTextLabel?.text = statsDict["ever_mileage"]
                        
                    }

            }
            
        } else {
            let row = indexPath.row
            if indexPath.section == recordsSection {
                if (row == 0){
                    cell.textLabel?.text       = "Fastest mile pace"
                    cell.detailTextLabel?.text = "..."
                    
                } else if (row == 1){
                    cell.textLabel?.text       = "Longest run"
                    cell.detailTextLabel?.text = "..."
                    
                }
            } else if (indexPath.section == freqSection){
                if (row == 0){
                    cell.textLabel?.text       = "Runs this week"
                    cell.detailTextLabel?.text = "..."
                    
                } else if (row == 1){
                    cell.textLabel?.text       = "Runs this month"
                    cell.detailTextLabel?.text = "..."
                    
                } else if (row == 2){
                    cell.textLabel?.text       = "Runs ever"
                    cell.detailTextLabel?.text = "..."
                    
                }
            } else if (indexPath.section == mileageSection){
                if (row == 0){
                    cell.textLabel?.text       = "Miles this week"
                    cell.detailTextLabel?.text = "..."
                    
                } else if (row == 1){
                    cell.textLabel?.text       = "Miles this month"
                    cell.detailTextLabel?.text = "..."
                    
                } else if (row == 2){
                    cell.textLabel?.text       = "Miles ever"
                    cell.detailTextLabel?.text = "..."
                    
                }
            }

        }
        return cell
    }
    
   

    
    func fetchRecords(){
        let token = AccessToken.current!.authenticationToken
        let headers: HTTPHeaders = [
            "access_token": token,
            "Accept": "application/json"
        ]
        Alamofire.request("https://cyoapp.azurewebsites.net/v1/personalRecords", method: .get, headers: headers).responseJSON
            { response in
                do {
                    //print(response)
                    if (response.data != nil){
                        if ((response.data?.count)! > 0){
                            let json = try? JSONSerialization.jsonObject(with: response.data!, options: [])
                            if (json != nil){
                                let arr = json as! NSArray
                                let dict = arr[0] as! NSDictionary
                                //print(dict)
                                let alltime = dict["alltime"]
                                let month = dict["month"]
                                let week = dict["week"]
                            
                                if let id = dict["fastest"] as? NSNull {
                                    print("recieved null")
                                }
                                
                                else if (dict["fastest"] != nil && dict["longest"] != nil){
                                    let fastest = dict["fastest"] as? Double
                                    let longest = dict["longest"] as? Double
                                    
                                    if (fastest != nil){
                                        if (fastest! < 40){
                                            let time = self.metersInAMile/(0.000001+fastest!)
                                            let fastest_conv = self.getTimeStr(duration: time)
                                            self.statsDict["fastest"] = fastest_conv
                                        } else {
                                            self.statsDict["fastest"] = "TBD"
                                        }
                                    }
                                    if (longest != nil){
                                        let longest_conv = self.getDistStr(distance: longest!)
                                        self.statsDict["longest"] = longest_conv
                                    }
                                    
                                    let alltime_mileage = dict["alltime_mileage"] as? Double
                                    let month_mileage = dict["month_mileage"] as? Double
                                    let week_mileage = dict["week_mileage"] as? Double
                                    
                                    let week_conv = week_mileage != nil ? self.getDistStr(distance: week_mileage!) : "0 miles"
                                    let month_conv = month_mileage != nil ? self.getDistStr(distance: month_mileage!) : "0 miles"
                                    let ever_conv = alltime_mileage != nil ? self.getDistStr(distance: alltime_mileage!) : "0 miles "
                                    
                                    self.statsDict["week_mileage"] = "\(week_conv)"
                                    self.statsDict["month_mileage"] = "\(month_conv)"
                                    self.statsDict["ever_mileage"] = "\(ever_conv)"

                                }
                                self.statsDict["ever"] = "\(alltime!)"
                                self.statsDict["month"] = "\(month!)"
                                self.statsDict["week"] = "\(week!)"
                                

                                self.fetchedResults = true
                                self.tableView.reloadData()
                        }
                    }
                }
            }
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
    
    func roundTo(value:Double, places:Int)->Double {
        let divisor = pow(10.0, Double(places))
        return (value * divisor).rounded() / divisor
    }

    
    func getDistStr(distance:Double) -> String{
        var result = ""
        let distanceQuantity = HKQuantity(unit: HKUnit.meter(), doubleValue: distance)
        let rawDist = distanceQuantity.doubleValue(for: HKUnit.meter())*meterToMileConv
        let trueDist = self.roundTo(value:rawDist,places:2)
        result = "\(trueDist) miles"
        return result
    }
    
   
    func getTimeStr(duration:Double) -> String {
        var result = ""
        let (hrs, mins, secs) = secondsToHoursMinutesSeconds(seconds: Int(duration))
        result = "\(hrs):\(mins):\(secs)"
        return result
    }
}
