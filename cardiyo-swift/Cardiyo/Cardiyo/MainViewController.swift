//
//  MainViewController.swift
//  Cardioh
//
//  Created by Dmitry Pimenov on 10/10/16.
//  Copyright © 2016 Dmitry. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import FacebookCore
import FacebookLogin
import PopupDialog
import CoreLocation
import HealthKit
import Alamofire
import SwiftySensors

class MainViewController: UIViewController {
    
    @IBOutlet var distanceLabel: UILabel!
    @IBOutlet var paceLabel: UILabel!
    @IBOutlet var timeLabelHr: UILabel!
    @IBOutlet var timeLabelMin: UILabel!
    @IBOutlet var timeLabelSec: UILabel!
    @IBOutlet var timerButton: UIButton!
    @IBOutlet var timerView: UIView!
    @IBOutlet var hrLabel: UILabel!

    var managedObjectContext: NSManagedObjectContext? = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext
    var run : Run!
    
    var activityInfo: ActivityInfo?
    
    var timer = Timer()
    var timing: Bool = false
    var counter: Int = 0
    var distance: Double = 0.0001 //to prevent NaN
    
    let meterToMileConv = 0.000621371
    
    lazy var locationManager: CLLocationManager = {
        var _locationManager = CLLocationManager()
        _locationManager.delegate = self
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest
        _locationManager.activityType = .fitness
        
        // Movement threshold for new events
        _locationManager.distanceFilter = 10.0
        return _locationManager
    }()
    lazy var locations = [CLLocation]()

    
    @IBAction func changedState(sender: UIButton) { //when button is pressed
        if (checkPermissions() == true){
            if (self.timing){
                showPopUp()
            } else {
                //begin timing
                startLocationUpdates()
                timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
                self.timing = true;
                timerButton.backgroundColor = UIColor.red
                //timerButton.setTitle("Stop", for: UIControlState.normal)
                timerButton.setImage(UIImage(named:"stopwhite.png"), for:UIControl.State.normal)
                distance = 0.0
                locations.removeAll(keepingCapacity: false)
                locationManager.allowsBackgroundLocationUpdates = true
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.attemptAuth()
        if AccessToken.current == nil {
            //show login prompt
            let vc : AnyObject! = self.storyboard!.instantiateViewController(withIdentifier: "loginVC")
            self.show(vc as! UIViewController, sender: vc)
        }
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            if let sensor = appDelegate.currentSensor {
                guard let hrService = sensor.service() else { return }
                guard let measurement: HeartRateService.Measurement = hrService.characteristic() else { return }
                measurement.onValueUpdated.subscribe(on: self){ characteristic in
                    if let heartRate = measurement.currentMeasurement?.heartRate {
                        if (heartRate > 0){
                            self.hrLabel.isHidden = false
                            self.hrLabel.text = "\(heartRate)"
                        } else {
                            self.hrLabel.isHidden = true
                        }
                    } else {
                        self.hrLabel.isHidden = true
                    }
                }
            } else {
                self.hrLabel.isHidden = true
            }
        }
        
        self.tabBarController?.navigationItem.title="New Activity"
        self.navigationItem.title="New Activity"

        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        locationManager.requestAlwaysAuthorization()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if (self.timing == false){
            self.clear()
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "MainToCamera" {
            if let destinationVC = segue.destination as? CameraViewController {
                destinationVC.activityInfo = self.activityInfo
            }
        }
    }
    
    @objc func timerAction() {
        
        counter += 1
        let (hr, min, sec) = self.secondsToHoursMinutesSeconds(seconds: counter)
        timeLabelHr.text = hr;
        timeLabelMin.text = min;
        timeLabelSec.text = sec;
        let distVal = 0.001 + distance
        let distanceQuantity = HKQuantity(unit: HKUnit.meter(), doubleValue: distVal)
        let rawDist = distanceQuantity.doubleValue(for: HKUnit.meter())*meterToMileConv
        let trueDist = roundTo(value:rawDist,places:2)
        distanceLabel.text = "\(trueDist)"
        
        UIView.animate(withDuration: 1.0, delay: 0, options: [.curveEaseInOut, .repeat, .autoreverse], animations: {
            self.timerView.alpha = 0.9
        }, completion: nil)

        
        if (counter > 30 && rawDist > 0){
            let pacePrefix = ""
            var paceStr = ""
            let pace = (Double(counter))/rawDist
            if (counter > 30){
                var (p_hr, p_min, p_sec) = self.secondsToHoursMinutesSeconds(seconds: Int(pace))
                if (p_hr == "00"){
                    let checkIndex = p_min.index(p_min.startIndex, offsetBy: 0)
                    let replacementIndex = p_min.index(p_min.startIndex, offsetBy:1)
                    if (p_min[checkIndex] == "0"){
                        p_min = "\(p_min[replacementIndex])"
                    }
                    paceStr = "\(p_min):\(p_sec)"
                } else {
                    let checkInt:Int? = Int(p_hr)
                    if (checkInt! > 24){
                        paceStr = "very slow"
                    } else {
                        paceStr = "\(p_hr):\(p_min):\(p_sec)"
                    }
                }
                paceLabel.text = pacePrefix+paceStr
            }
        }
    }
    
    func showPopUp() {
        let title = "Have you finished?"
        let message = ""
        
        let popup = PopupDialog(title: title, message: message) //, image: image)
        let buttonOne = DefaultButton(title: "Yes, I'm done") {
            self.finishActivity();
        }
        
        setGlobalPopupSettings()
        
        let buttonTwo = CancelButton(title: "Cancel") {
            //print("cancelled")
        }
        
        popup.addButtons([buttonOne, buttonTwo])
        self.present(popup, animated: true, completion: nil)
    }

    func finishActivity(){
        //serialize run data
        //open image taker
        self.activityInfo = saveRun()
        self.timer.invalidate()
        self.counter = 0;
        self.timing = false;
        performSegue(withIdentifier:"MainToCamera", sender: self)
    }
    
    func startLocationUpdates() {
        locationManager.startUpdatingLocation()
    }
    
    //helper function for setting up popup
    func setGlobalPopupSettings(){
        let popUpSetupDefault = PopupDialogDefaultView.appearance()
        popUpSetupDefault.titleFont = UIFont.systemFont(ofSize: 24, weight: UIFont.Weight.semibold)
        popUpSetupDefault.titleColor = UIColor.white
        popUpSetupDefault.messageFont          = UIFont.systemFont(ofSize: 24)
        popUpSetupDefault.messageColor         = UIColor(white: 1, alpha: 1)
        popUpSetupDefault.backgroundColor = UIColor.clear
        
        let popUpSetup = PopupDialogContainerView.appearance()
        popUpSetup.backgroundColor = UIColor.clear
        
        let overlayAppearance = PopupDialogOverlayView.appearance()
        overlayAppearance.liveBlur    = false
        overlayAppearance.backgroundColor = UIColor.lightGray
        overlayAppearance.opacity     = 0.85
        
        let buttonAppearance = DefaultButton.appearance()
        buttonAppearance.titleFont      = UIFont.systemFont(ofSize: 24, weight: UIFont.Weight.semibold)
        buttonAppearance.titleColor     = UIColor(hexString: "#0080FF")
        buttonAppearance.buttonColor    = UIColor.clear
        buttonAppearance.separatorColor = UIColor.clear
        
        let cancelAppearance = CancelButton.appearance()
        cancelAppearance.titleFont      = UIFont.systemFont(ofSize: 24, weight: UIFont.Weight.semibold)
        cancelAppearance.titleColor     = UIColor.red
        cancelAppearance.buttonColor    = UIColor.clear
        cancelAppearance.separatorColor = UIColor.lightGray
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
    
    func clear(){
        self.timerView.alpha = 1.0
        self.timeLabelHr.text = "00"
        self.timeLabelMin.text = "00"
        self.timeLabelSec.text = "00"
        self.distanceLabel.text = "0.0"
        self.paceLabel.text = "00:00"
        self.timing = false;
        timerButton.backgroundColor = UIColor(hexString: "#009966")
        //timerButton.setTitle("Start", for: UIControlState.normal)
        timerButton.setImage(UIImage(named:"nextaltwhite.png"), for:UIControl.State.normal)
        distance = 0.0
        self.locations.removeAll(keepingCapacity: false)
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    func roundTo(value:Double, places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (value * divisor).rounded() / divisor
    }
    
    func leftPad(value:Int) -> String {
        var valueStr = "\(value)"
        if (value/10 == 0){
            valueStr = "0\(valueStr)"
        }
        return valueStr
    }
    
    func saveRun() -> ActivityInfo{
        let timestamp = NSDate() as Date
        return ActivityInfo(duration: counter, distance: Int(self.distance), points: locations, timestamp: timestamp)
    }
    
    func checkPermissions() -> Bool {
        var result = false;
        
        if CLLocationManager.locationServicesEnabled() {
            switch(CLLocationManager.authorizationStatus()) {
            case .notDetermined, .restricted, .denied:
                presentErrorModal()
            case .authorizedAlways, .authorizedWhenInUse:
                result = true;
            }
        } else {
            presentErrorModal()
        }
        return result;
    }
    
    func presentErrorModal(){
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "errorVC") as! ErrorViewController
        vc.shouldCheckLocationPermissions = true;
        present(vc, animated: true, completion: nil)
    }
    
    func attemptAuth(){
        if AccessToken.current == nil {
            //show login prompt
        } else {
            let token = AccessToken.current!.authenticationToken
            let headers: HTTPHeaders = [
                "access_token": token,
                "Accept": "application/json"
            ]
            
            Alamofire.request("https://cyoapp.azurewebsites.net/v1/auth", method: .post,
                              headers: headers).responseJSON { response in
                               // print(response)
            }
        }
    }
}


extension MainViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            if location.horizontalAccuracy < 70 {
                //update distance
                if self.locations.count > 0 {
                    let delta = location.distance(from:self.locations.last!);
                    if (delta < 40){ //under a reasonable limit of meters/s
                        distance += delta
                    } else {
                        //print("updating with delta: \(delta)")
                    }
                }

                //save location
                self.locations.append(location)
            } else {
                //print("too much \(location.horizontalAccuracy)")
            }
        }
    }
}

extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.characters.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
