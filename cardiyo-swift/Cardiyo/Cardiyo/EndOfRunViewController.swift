//
//  EndOfRunViewController.swift
//  Cardioh
//
//  Created by Dmitry Pimenov on 11/30/16.
//  Copyright © 2016 Dmitry. All rights reserved.
//

import UIKit
import CoreData
import MapKit
import HealthKit
import SkyFloatingLabelTextField
import Alamofire
import FacebookCore
import FacebookLogin

class EndOfRunViewController: UIViewController, MKMapViewDelegate, UITextFieldDelegate {
    
    @IBOutlet var distanceLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var paceLabel: UILabel!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var captionTextField: UITextField!
    
    @IBOutlet var publicLabel: UILabel!
    @IBOutlet var publicSwitch: UISwitch!
        
    @IBOutlet var completeLabel: UILabel!
    @IBOutlet var bgView: UIView!
    @IBOutlet var lineLabelUpper: UILabel!
    @IBOutlet var lineLabelLower: UILabel!

    @IBOutlet var scrollView: UIScrollView!
    
    var isPublic: Bool? = true
    var keyboardHeight: CGFloat? //due to ios issue
    var activityInfo: ActivityInfo?
    var managedObjectContext: NSManagedObjectContext? = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated);
        self.navigationItem.title="Summary"
        self.showAllUI()
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewDidLoad() {
        // Add a custom login button to your app
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveRun))

        self.title = "Summary"
        self.imageView.image = self.activityInfo?.primaryImage;
        //show distance
        self.distanceLabel.text = self.distanceLabel.text?.appending(self.activityInfo!.getDistStr());
        //show pace
        self.paceLabel.text = self.paceLabel.text?.appending(self.activityInfo!.getPaceStr());
        //show time
        self.timeLabel.text = self.timeLabel.text?.appending(self.activityInfo!.getTimeStr());
        
        self.mapView.delegate = self;
        //load map, polyline
        self.loadMap()
        
        NotificationCenter.default.addObserver(self, selector: #selector(EndOfRunViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(EndOfRunViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        //add text
        self.activityInfo?.caption = textField.text
        return true
    }
    
    @IBAction func saveRun(){
        //make API calls
        //self.saveButton.isEnabled = false
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        //var count = 0 //to post just once
        takeSnapshot(mapView: self.mapView, withCallback:{(image: UIImage?, error: NSError?) in
            if (image != nil && error == nil){
                self.activityInfo?.mapImage = image
                self.saveToService()
                UIView.animate(withDuration: 0.5, animations: {
                    self.hideAllUI()
                })
            }
        });
    }
 
    @IBAction func segmentedControlAction(sender: AnyObject) {
        if(self.segmentedControl.selectedSegmentIndex == 0)
        {
            showImage();
        }
        else if(self.segmentedControl.selectedSegmentIndex == 1)
        {
            showMap();
        }
    }
    
    @IBAction func changedSwitchValue(sender: AnyObject) {
        self.isPublic = self.publicSwitch.isOn
    }
    
    func saveToService(){
        let (dur_str, dist_str, caption_str, pt_str, primary_image, map_image) = (self.activityInfo?.getShortForm())!
        if let base64String_primary = primary_image!.jpegData(compressionQuality: 0.65)?.base64EncodedString(){
            if let base64String_map = map_image!.jpegData(compressionQuality: 0.65)?.base64EncodedString(){
                var isPublicInt = 0
                if (self.isPublic == true){
                    isPublicInt = 1
                }
                
                if AccessToken.current == nil {
                    //show error experience
                    //print("no access token")
                } else {
                    let token = AccessToken.current!.authenticationToken
                    let headers: HTTPHeaders = [
                        "access_token": token,
                        "Accept": "application/json"
                    ]
                    let parameters = [
                        "caption": caption_str,
                        "points": pt_str,
                        "duration": Int(dur_str)!,
                        "distance": Int(dist_str)!,
                        "p_image_encoded": base64String_primary,
                        "m_image_encoded": base64String_map,
                        "ispublic": isPublicInt
                    ] as [String : Any]
                
                    print("making request")
                    Alamofire.request("https://cyoapp.azurewebsites.net/v1/records", method:.post, parameters: parameters, headers: headers).response
                        { response in
                            print(response)
                            if let status = response.response?.statusCode {
                                switch(status){
                                default:
                                    let loginViewController = self.storyboard!.instantiateViewController(withIdentifier: "primary")
                                    UIApplication.shared.keyWindow?.rootViewController = loginViewController
                                    let tabViewController = loginViewController.children[0] as! UITabBarController
                                    tabViewController.selectedIndex = 1
                            }
                        }
                    }
                }
            }
        }
    }
    
    func showImage(){
        self.imageView.isHidden = false;
    }
    
    func showMap(){
        self.imageView.isHidden = true;
    }
    
    func addPtsToMap(){
        //add location pts and spline to map
    }
    
    func mapRegion() -> MKCoordinateRegion {
        let pts = self.activityInfo?.points
        
        let initialLoc = pts!.first
        
        var minLat = initialLoc!.coordinate.latitude
        var minLng = initialLoc!.coordinate.longitude
        var maxLat = minLat
        var maxLng = minLng
        
        for pt in pts! {
            let currLat = pt.coordinate.latitude
            let currLon = pt.coordinate.longitude
            minLat = min(minLat,currLat)
            minLng = min(minLng,currLon)
            maxLat = max(maxLat,currLat)
            maxLng = max(maxLng,currLon)
        }

        let centerLat = (minLat + maxLat)/2.0
        let centerLon = (minLng + maxLng)/2.0
        let latDelta =  (maxLat - minLat)/0.85
        let lonDelta = (maxLng - minLng)/0.85
        
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat,
                                           longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: latDelta,
                                   longitudeDelta: lonDelta))
    }
    
    
    func mapView(_ mapView: MKMapView,
                 rendererFor overlay: MKOverlay) -> MKOverlayRenderer{
            
        if (overlay is MKPolyline) == false {
            return MKOverlayRenderer.init()
        }
        
        let polyline = overlay as! MKPolyline
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.strokeColor = UIColor(hexString: "#0080FF")
        renderer.lineWidth = 4
        return renderer
    }

    func polyline() -> MKPolyline {
        let pts = self.activityInfo?.points
        var coords = [CLLocationCoordinate2D]()
        for pt in pts! {
            coords.append(CLLocationCoordinate2D(latitude: pt.coordinate.latitude,
                                                 longitude: pt.coordinate.longitude))
        }
        return MKPolyline(coordinates: &coords, count: pts!.count)
    }
    
    func loadMap() {
        let pts = self.activityInfo?.points
        if pts!.count > 0 {
            // Set the map bounds
            self.mapView.region = mapRegion()
            // Make the line(s!) on the map
            self.mapView.addOverlay(polyline())
        } else {
            //print("no points")
        }
    }
    
    func hideAllUI(){
        self.setRandomLabel()
        self.mapView.alpha = 0.0
        self.imageView.alpha = 0.0        
        self.publicLabel.alpha = 0.0
        self.publicSwitch.alpha = 0.0
        self.segmentedControl.alpha = 0.0
        self.paceLabel.alpha = 0.0
        self.distanceLabel.alpha = 0.0
        self.timeLabel.alpha = 0.0
        self.captionTextField.alpha = 0.0
        self.lineLabelUpper.alpha = 0.0
        self.lineLabelLower.alpha = 0.0

        self.bgView.backgroundColor = UIColor.white
        self.completeLabel.isHidden = false
    }
    
    func showAllUI(){
        self.mapView.alpha = 1.0
        self.imageView.alpha = 1.0
        self.publicLabel.alpha = 1.0
        self.publicSwitch.alpha = 1.0
        self.segmentedControl.alpha = 1.0
        self.paceLabel.alpha = 1.0
        self.distanceLabel.alpha = 1.0
        self.timeLabel.alpha = 1.0
        self.captionTextField.alpha = 1.0
        self.lineLabelUpper.alpha = 1.0
        self.lineLabelLower.alpha = 1.0
        self.bgView.backgroundColor = UIColor.init(hexString: "#E6E6E6")
        self.completeLabel.isHidden = true
    }
    
    func setRandomLabel(){
        let phrases = ["👍", "🙌", "💪", "🏃", "🐎", "⚡️", "💫", "🎽", "🏅", "🏆"]
        let rand = Int(arc4random_uniform(UInt32(phrases.count)))
        let phrase = phrases[rand]
        self.completeLabel.text = phrase
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0{ 
                if (self.keyboardHeight == nil && keyboardSize.height > 0){
                    self.keyboardHeight = keyboardSize.height
                } else if (self.keyboardHeight == nil){
                    self.keyboardHeight = 300
                }
                self.view.frame.origin.y -= (self.keyboardHeight! - 80)
                self.publicLabel.alpha = 0.0
                self.publicSwitch.alpha = 0.0
                self.segmentedControl.alpha = 0.0
                self.lineLabelLower.alpha = 0.0

            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if (self.view.frame.height < 560){
            self.distanceLabel.isHidden = true
            self.timeLabel.isHidden = true
            self.paceLabel.isHidden = true
            self.lineLabelUpper.isHidden = true
        }
        
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0{
                if (self.keyboardHeight == nil){
                    self.keyboardHeight = 300
                }
                self.view.frame.origin.y += (self.keyboardHeight! - 80)
                self.publicLabel.alpha = 1.0
                self.publicSwitch.alpha = 1.0
                self.segmentedControl.alpha = 1.0
                self.lineLabelLower.alpha = 1.0
            }
        }

    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        
        let newLength = text.characters.count + string.characters.count - range.length
        return newLength <= 70 // Bool
    }
    
    func takeSnapshot(mapView: MKMapView, withCallback: @escaping (UIImage?, NSError?) -> ()) {
        let options = MKMapSnapshotter.Options()

        options.region = mapView.region
        options.size = mapView.frame.size
        options.scale = UIScreen.main.scale
        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start() { snapshot, error in
            guard snapshot != nil else {
                withCallback(nil, error as NSError?)
                return
            }
            
            if let image = snapshot?.image{
                //add polyline
                UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale);
                let context = UIGraphicsGetCurrentContext()
                image.draw(at: CGPoint.init(x: 0, y: 0))
                context?.setStrokeColor(UIColor(hexString: "#0080FF").cgColor)
                context?.setLineWidth(5.0)
                context?.setLineCap(CGLineCap.round)
                context?.setBlendMode(CGBlendMode.normal)
                context?.beginPath()
                var firstPt = true
                
                for overlay in self.mapView.overlays {
                    if (overlay is MKPolyline){
                        let polyLinePoints = self.activityInfo?.points
                        for pt in polyLinePoints!{
                            let coordinatePt = CLLocationCoordinate2DMake(pt.coordinate.latitude, pt.coordinate.longitude)
                            let currPoint = snapshot?.point(for: coordinatePt)
                            if (firstPt){
                                context?.move(to: currPoint!)
                                firstPt = false
                            } else {
                                context?.addLine(to: currPoint!)
                            }
                        }
                        let polyLinePointRev = polyLinePoints?.reversed() //run this in reverse so close path does not create issues
                        for pt in polyLinePointRev!{
                            let coordinatePt = CLLocationCoordinate2DMake(pt.coordinate.latitude, pt.coordinate.longitude)
                            let currPoint = snapshot?.point(for: coordinatePt)
                            context?.addLine(to: currPoint!)
                        }

                    }
                }
                context?.closePath()
                context?.strokePath()
                let updated = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                withCallback(updated, nil)
            }
        }
    }
}
