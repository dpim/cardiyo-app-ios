//
//  ErrorViewController.swift
//  Cardioh
//
//  Created by Dmitry Pimenov on 12/21/16.
//  Copyright © 2016 Dmitry. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import AVFoundation

class ErrorViewController: UIViewController {
    
    var shouldCheckLocationPermissions:Bool?
    var shouldCheckImagePermissions:Bool?
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated);
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        NotificationCenter.default.addObserver(self, selector: #selector(checkPermissions), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc func checkPermissions(){
        var result = true;
        if (self.shouldCheckImagePermissions == true){
            result = result && checkImagePermissions();
        }
        if (self.shouldCheckLocationPermissions == true){
            result = result && checkLocationPermissions();
        }
        if (result == true){
            NotificationCenter.default.removeObserver(self);
            self.dismiss(animated: true, completion: nil);
        }
    }
    
    func checkImagePermissions() -> Bool {
        var result = false
        let cameraMediaType = AVMediaType.video
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: cameraMediaType)
        
        switch cameraAuthorizationStatus {
        case .denied: return false
        case .authorized: return true
        case .restricted: return false
            
        case .notDetermined:
            // Prompting user for the permission to use the camera.
            AVCaptureDevice.requestAccess(for: cameraMediaType) { granted in
                if granted {
                    //print("Granted access to \(cameraMediaType)")
                    result = true
                } else {
                   // print("Denied access to \(cameraMediaType)")
                    result = false
                }
            }
        }
        return result
    }
    
    func checkLocationPermissions() -> Bool {
        var result = false;
        if CLLocationManager.locationServicesEnabled() {
            switch(CLLocationManager.authorizationStatus()) {
            case .notDetermined, .restricted, .denied:
               // print("No access")
                result = false
            case .authorizedAlways, .authorizedWhenInUse:
               // print("Access")
                result = true
            }
        } else {
           // print("Location services are not enabled")
            result = false
        }
        return result;
    }
    

    
}
