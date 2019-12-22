//
//  ActivityDetailsViewController.swift
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
import MapKit
import CoreLocation
import HealthKit
import FacebookCore
import FacebookLogin
import PopupDialog

class ActivityDetailsViewController: UITableViewController, MKMapViewDelegate, DetailCellDelegate {

    var viewingMap: Bool?
    var cellData: Any?
    var caption: String?
    var didLike: Int?
    var countLikesStr: String?
    var distanceStr: String? // representation
    var durationStr: String? //representation
    var name: String?
    var reactionImg: UIImage?
    var datetimeStr: String?
    var points: [CLLocation]?
    var isViewersImage: Bool = false //is the viewer the creator of the activity?
    var isPublic: Bool = false
    
    let mainSection = 0
    let paceSection = 1
    let socialSection = 2
    let etcSection = 3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 200 //Set this to any value that works for you.
        self.tableView.contentInset = UIEdgeInsets(top: -32, left: 0, bottom: 0, right: 0);
        self.points = []
        self.updateData()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "...", style: .plain, target: self, action: #selector(showPopUp))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title="Details"
    }
    
    func updateData(){
        //figure out did-like, datetime str, map drawing

        if (self.cellData != nil){
            let cellDict = cellData as! [String: Any?]
            //print(cellDict)
            let activityUserId =  "\(cellDict["user_id"]! as! Int)"
            let currentUserId = UserProfile.current?.userId
            
            let isPostPublic = cellDict["ispublic"]! as! Int
            if (isPostPublic == 1){
                self.isPublic = true
            } else {
                self.isPublic = false
            }
            
            if activityUserId == currentUserId {
                self.isViewersImage = true
            }
        
            let dateTimeCreated = cellDict["datetime_created"] as! String?
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            let date = formatter.date(from:dateTimeCreated!)
            if (date != nil){
                formatter.dateStyle = .short
                formatter.timeStyle = .short
                let dateStr = formatter.string(from:date!)
                //print(dateStr)
                self.datetimeStr = dateStr
            }
            self.mapPoints(pts_str: cellDict["points_serialized"] as! String)
        }
    }
    
    func mapPoints(pts_str: String){
        //draw points to map
        if pts_str.characters.count > 3 {
            let pts_str_trimmed = pts_str.replacingOccurrences(of: " ", with: "")
            let parts = pts_str_trimmed.components(separatedBy: "),")
            for part in parts {
             //extract lat, lon
                let parts_bracket = part.components(separatedBy: "(")
                if (parts_bracket.count > 1){
                    let nums = parts_bracket[1]
                    let parts_nums = nums.components(separatedBy: ",")
                    if (parts_nums.count > 2){
                        let lat = Double(parts_nums[0])
                        let lon = Double(parts_nums[1])
                        var point = CLLocation.init()
                        if (parts_nums.count > 3){
                            let altitude = Double(parts_nums[2])
                            let time = parts_nums[3]
                            let dateFormatter = ISO8601DateFormatter()
                            let date = dateFormatter.date(from: time)
                            if (date != nil){
                                point = CLLocation.init(coordinate: CLLocationCoordinate2D.init(latitude: lat!, longitude: lon!), altitude: altitude!, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: date!)
                            }
                        } else {
                            point = CLLocation.init(latitude: lat!, longitude: lon!)
                        }
                        self.points?.append(point)
                    }
                }
            }
        }
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
        let pts = self.points
        //print("points below:")
        var coords = [CLLocationCoordinate2D]()
        for pt in pts! {
            coords.append(CLLocationCoordinate2D(latitude: pt.coordinate.latitude,
                                                 longitude: pt.coordinate.longitude))
        }
        return MKPolyline(coordinates: &coords, count: pts!.count)
    }
    
    func mapRegion() -> MKCoordinateRegion {
        let pts = self.points
        
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
    
    @objc func showPopUp() {
        let title = "What would you like to do?"
        let message = ""
        
        let popup = PopupDialog(title: title, message: message) //, image: image)
        setGlobalPopupSettings()
        let cancelButton = CancelButton(title: "Cancel") {}
        
        if (self.isViewersImage){
            let buttonOne = DefaultButton(title: "Delete") {
                self.showDeleteButtonAlert()
            }
            if (self.isPublic){
                let buttonTwo = DefaultButton(title: "Make Private"){
                    self.showChangeVisbilityAlert(makePrivate: true)
                }
                popup.addButtons([buttonTwo, buttonOne, cancelButton])
            } else {
                let buttonTwo = DefaultButton(title: "Make Public"){
                    self.showChangeVisbilityAlert(makePrivate: false)
                }
                popup.addButtons([buttonOne, buttonTwo, cancelButton])
            }
        } else {
        let buttonOne = DefaultButton(title: "Report") {
            self.showReportButtonAlert()
        }
        popup.addButtons([buttonOne, cancelButton])
            
        }
        self.present(popup, animated: true, completion: nil)
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DetailsToLikes" {
            if (self.cellData != nil){
                let cellDict = cellData as! [String: Any?]
                let recordId = cellDict["record_id"] as! Int
                let destinationVC = segue.destination as! LikedByViewController
                destinationVC.recordId = "\(recordId)"
            }
        } else if segue.identifier == "DetailsToSplits" {
            let destinationVC = segue.destination as! SplitsViewController
            destinationVC.points = self.points
        }
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.section == socialSection){
            if (indexPath.row == 0){
                self.performSegue(withIdentifier: "DetailsToLikes", sender: nil)
            } else if (indexPath.row == 1){
                self.tableView.deselectRow(at: indexPath, animated: true)
                self.saveReactionImage()
            }
        }
        if (indexPath.section == paceSection){
            if (indexPath.row == 0){
                self.performSegue(withIdentifier: "DetailsToSplits", sender: nil)
            }
        }
        if (indexPath.section == etcSection){
            self.tableView.deselectRow(at: indexPath, animated: true)
            if (self.isViewersImage){
                if (indexPath.row == 1){
                    //delete
                    self.showDeleteButtonAlert()
                } else if (indexPath.row == 0) {
                    //change visibility
                    self.showChangeVisbilityAlert(makePrivate: self.isPublic)
                } else {
                    //do nothing
                }
            } else {
                if (indexPath.row == 0){
                    //report
                    self.showReportButtonAlert()
                }
                else {
                    //do nothing
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.section == mainSection){
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "detail", for: indexPath) as! DetailTableCellView
            
            let pts = self.points
            if (pts != nil){
                cell.mapView?.delegate = self
                //print("pts")
                if pts!.count > 0 {
                    // Set the map bounds
                    cell.mapView?.region = mapRegion()
                    // Make the line(s!) on the map
                    cell.mapView?.addOverlay(self.polyline())
                } else {
                    //print("no points")
                }
            }
            
            cell.distanceLabel?.text = self.distanceStr
            cell.durationLabel?.text = self.durationStr
            cell.nameLabel?.text = self.name
            cell.captionLabel?.text = self.caption
            cell.dateLabel?.text = self.datetimeStr
            cell.likesLabel?.text = self.countLikesStr
            cell.primary_imageView?.image = self.reactionImg
            
            if (self.didLike == 1){
                cell.likeButton?.isSelected = true
            } else {
                cell.likeButton?.isSelected = false
            }
            
            
            cell.selectionStyle = .none

            if cell.detailDelegate == nil {
                cell.detailDelegate = self
            }
            return cell
        } else if (indexPath.section == socialSection){ 
            if (indexPath.row == 0){
                return defaultTextCell(text: "Liked by")
            } else if (indexPath.row == 1){
                return defaultTextCell(text: "Save feeling")
            } else {
                return defaultTextCell(text: "-")
            }
        } else if (indexPath.section == paceSection){
            return defaultTextCell(text: "Pace analysis")
        } else {
             if (indexPath.row == 0){
                // Report or delete, depending on whether viewer is owner
                var labelStr = "Report"
                if (self.isViewersImage){
                    labelStr = "Make Public"
                    if (self.isPublic){
                        labelStr = "Make Private"
                    }
                }
                return defaultTextCell(text: labelStr)
            } else if (indexPath.row == 1){
                //if owner, this cell allows them to change the visiblity of the
                return defaultTextCell(text: "Delete")
            } else {
                //generic follow up
                return defaultTextCell(text: "-")
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == mainSection{
            return 500
        } else {
            return 40
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == mainSection {
            return 1
        } else if section == socialSection {
           return 2
        } else if (section == etcSection){
            if (self.isViewersImage){
                return 2
            } else {
                return 1
            }
        } else if (section == paceSection){
            return 1
        } else {
            return 0
        }
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    //delegate
    
    func likeCellTapped(cell: DetailTableCellView) {
        if (self.cellData != nil){
            let cell_dict = self.cellData as! NSDictionary
            let recordId = cell_dict["record_id"] as! Int
                        
            var updatedCount = Int((cell.likesLabel?.text)!)
            if (updatedCount == nil){
                updatedCount = 0
            }
            
            let isSelected = cell.likeButton?.isSelected
            let token = AccessToken.current!.authenticationToken
            let headers: HTTPHeaders = [
                "access_token": token,
                "Accept": "application/json"
            ]
            if (isSelected)!{ //unlike
                cell.likeButton?.isSelected = false
                cell.likesLabel?.text = "\(updatedCount!-1)"
                Alamofire.request("https://cyoapp.azurewebsites.net/v1/records/\(recordId)/like", method: .delete, headers: headers).responseJSON
                    { response in
                        //print(response)
                }
            } else {
                cell.likeButton?.isSelected = true
                cell.likesLabel?.text = "\(updatedCount!+1)"
                Alamofire.request("https://cyoapp.azurewebsites.net/v1/records/\(recordId)/like", method: .post, headers: headers).responseJSON
                    { response in
                       // print(response)
                }
            }
        }
    }

    func commentCellTapped(cell: DetailTableCellView){
        
    }
    func reactionButtonPressed(cell: DetailTableCellView){
        if cell.primary_imageView?.isHidden == true {
            cell.reactionButton?.setTitle("Hide Feeling", for: .normal)
            cell.primary_imageView?.isHidden = false
        } else {
            cell.reactionButton?.setTitle("Show Feeling", for: .normal)
            cell.primary_imageView?.isHidden = true
        }
    }
    
    func showReportButtonAlert(){
        let alert = UIAlertController(title: "Report", message: "Is this content abusive or offensive?", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler:nil))
        alert.addAction(UIAlertAction(title: "Yes, report", style: UIAlertAction.Style.default, handler:{ (UIAlertAction)in
                    self.reportPost()
        }))
        self.present(alert, animated: true, completion: {
            //print("completion block")
        })    
    }
    
   func showDeleteButtonAlert() {
    let alert = UIAlertController(title: "Delete", message: "Are you sure you want to delete this post? This cannot be undone.", preferredStyle: UIAlertController.Style.alert)
    alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler:nil))
    alert.addAction(UIAlertAction(title: "Yes, delete", style: UIAlertAction.Style.default, handler:{ (UIAlertAction)in
                self.deletePost()
        }))
        self.present(alert, animated: true, completion: {
            //print("completion block")
        })
    }
    
    func showChangeVisbilityAlert(makePrivate: Bool) {
        if (makePrivate){
            let alert = UIAlertController(title: "Make private", message: "Are you sure you want to make this post private?", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler:nil))
            alert.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.default, handler:{ (UIAlertAction)in
                    self.makePrivate()
            }))
            self.present(alert, animated: true, completion: {
               // print("completion block")
            })
        } else {
            let alert = UIAlertController(title: "Make public", message: "Are you sure you want to make this post public?", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler:nil))
            alert.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.default, handler:{ (UIAlertAction)in
                    self.makePublic()
            }))
            self.present(alert, animated: true, completion: {
                //print("completion block")
            })
        }
    }
    
    func makePrivate() {
        print("make private")
        if (self.cellData != nil){
            
            self.isPublic = false
            self.tableView.reloadData()
            
            let cell_dict = self.cellData as! NSDictionary
            let recordId = cell_dict["record_id"] as! Int
            let token = AccessToken.current!.authenticationToken
            let headers: HTTPHeaders = [
                "access_token": token,
                "Accept": "application/json"
            ]
            Alamofire.request("https://cyoapp.azurewebsites.net/v1/records/\(recordId)/makePrivate", method: .post, headers: headers).responseJSON
                { response in
                    //print(response)
            }
        }
    }
    
    func makePublic() {
        print("make public")
        if (self.cellData != nil){
            
            self.isPublic = true
            self.tableView.reloadData()
            
            let cell_dict = self.cellData as! NSDictionary
            let recordId = cell_dict["record_id"] as! Int
            let token = AccessToken.current!.authenticationToken
            let headers: HTTPHeaders = [
                "access_token": token,
                "Accept": "application/json"
            ]
            Alamofire.request("https://cyoapp.azurewebsites.net/v1/records/\(recordId)/makePublic", method: .post, headers: headers).responseJSON
                { response in
                   //print(response)
            }
        }
    }
    
    func deletePost() {
        print("delete")
        if (self.cellData != nil){
            let cell_dict = self.cellData as! NSDictionary
            let recordId = cell_dict["record_id"] as! Int
            let token = AccessToken.current!.authenticationToken
            let headers: HTTPHeaders = [
                "access_token": token,
                "Accept": "application/json"
            ]
            Alamofire.request("https://cyoapp.azurewebsites.net/v1/records/\(recordId)", method: .delete, headers: headers).responseJSON
                { response in
                    self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func reportPost() {
        print("report")
        if (self.cellData != nil){
            let cell_dict = self.cellData as! NSDictionary
            let recordId = cell_dict["record_id"] as! Int
            let token = AccessToken.current!.authenticationToken
            let headers: HTTPHeaders = [
                "access_token": token,
                "Accept": "application/json"
            ]
            Alamofire.request("https://cyoapp.azurewebsites.net/v1/records/\(recordId)/report", method: .post, headers: headers).responseJSON
                { response in
                    //print(response)
            }
        }
    }
    
    func saveReactionImage(){
        if let reactionImage = self.reactionImg {
            UIImageWriteToSavedPhotosAlbum(reactionImage, nil, nil, nil);
        }
    }
    
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
    
    func defaultTextCell(text: String) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
        cell.selectionStyle = .blue
        cell.textLabel?.text = text
        cell.textLabel?.font = UIFont.systemFont(ofSize: 14.0)
        cell.textLabel?.textColor = UIColor.darkGray
        return cell
    }
    
}

