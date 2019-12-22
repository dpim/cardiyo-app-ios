//
//  PersonalHistoryViewController.swift
//  Cardioh
//
//  Created by Dmitry Pimenov on 10/10/16.
//  Copyright © 2016 Dmitry. All rights reserved.
//

import Foundation
import UIKit
import FacebookLogin
import FacebookCore
import Alamofire
import AlamofireImage
import SwiftyJSON
import HealthKit

class HistoryViewController: UITableViewController, CardCellDelegate {
    var cells: [Any]?
    var activityIndicatorView: UIActivityIndicatorView?
    var pinchRecognizer: UIPinchGestureRecognizer?
    let meterToMileConv = 0.000621371
    let blobStoragePrefix = "https://cyobinstorage.blob.core.windows.net/images/"
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.navigationItem.title = "Feed"
        self.navigationItem.title = "Feed"
        self.pinchRecognizer?.isEnabled = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.makeCellRequest(refresh:false);
        self.tableView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 44.0, right: 0.0);
        self.tableView.delaysContentTouches = true
        self.tableView.refreshControl?.backgroundColor = UIColor.clear
        self.tableView.refreshControl?.tintColor = UIColor.black
        self.tableView.refreshControl?.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.tableView.refreshControl?.addTarget(self, action:#selector(self.refresh), for: UIControl.Event.valueChanged)
        
        let activityIndicatorView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
        self.tableView.backgroundView = activityIndicatorView
        self.activityIndicatorView = activityIndicatorView
        self.activityIndicatorView?.hidesWhenStopped = true
        activityIndicatorView.startAnimating()        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CardCell", for: indexPath) as! CardTableCellView
        cell.tag = indexPath.row //for delegates to work correctly
        cell.segmentedControl?.selectedSegmentIndex = 0 //reset segmented control
        
        cell.primary_imageView?.isHidden = false //reset views
        cell.primary_imageView?.image = nil
        cell.map_imageView?.image = nil
        
        cell.likesLabel?.text = nil
        cell.durationLabel?.text = nil
        cell.distanceLabel?.text = nil
        cell.nameLabel?.text = nil
        
        if (cells != nil){
            
            let current_cell = cells![indexPath.row]
            let cell_dict = current_cell as! NSDictionary
            
            let name = cell_dict["name"] as! String
            let caption = cell_dict["caption"] as! String
            let duration = cell_dict["duration"] as! Int
            let distance = cell_dict["distance"] as! Int
            let likeCount = cell_dict["countLikes"] as! Int
            let prim_str = cell_dict["primary_image"] as! String
            let map_str = cell_dict["map_image"] as! String
            let prim_path = self.blobStoragePrefix+prim_str
            let map_path = self.blobStoragePrefix+map_str
            
            if let prim_url = URL.init(string:prim_path), let map_url = URL.init(string:map_path){
                cell.primary_imageView?.af_setImage( withURL: prim_url,
                                                     placeholderImage: nil,
                                                     filter: nil,
                                                     imageTransition: .crossDissolve(0.2))
                
                cell.map_imageView?.af_setImage(withURL: map_url)
            }
            
            let distanceQuantity = HKQuantity(unit: HKUnit.meter(), doubleValue: Double(distance))
            let rawDist = distanceQuantity.doubleValue(for: HKUnit.meter())*meterToMileConv
            let trueDist = self.roundTo(value:rawDist,places:2)
            
            let didLike  = cell_dict["didLike"] as! Int
            
            if (didLike == 0){
                cell.likeButton?.isSelected = false
            } else {
                cell.likeButton?.isSelected = true
            }
            
            let (hours,minutes,seconds) = secondsToHoursMinutesSeconds(seconds: duration)
            
            cell.nameLabel?.text = truncateName(name: name)
            cell.captionLabel?.text = caption.characters.count == 0 ? "-" : caption
            cell.durationLabel?.text = "\(hours):\(minutes):\(seconds)"
            cell.distanceLabel?.text = "\(trueDist) miles"
            cell.likesLabel?.text = "\(likeCount)"
            
        } else {
            //do nothing
        }
        
        if cell.cardDelegate == nil {
            cell.cardDelegate = self
        }
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("selected at \(indexPath)")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        print("asking for number of sections")
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("asking for number of rows")
        if (cells != nil){
            self.activityIndicatorView?.stopAnimating()
            return cells!.count
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    
    func likeCellTapped(cell: CardTableCellView) {
        if (cells != nil){
            let current_cell = cells![cell.tag]
            let cell_dict = current_cell as! NSDictionary
            
            let recordId = cell_dict["record_id"] as! Int
            
            print(recordId)
            
            var updatedCount = Int((cell.likesLabel?.text)!)
            if (updatedCount != nil){
                //do something
            } else {
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
                Alamofire.request("https://cyoapp.azurewebsites.net/v1/records/\(recordId)/like", method: .delete, headers: headers)
                
            } else {
                cell.likeButton?.isSelected = true
                cell.likesLabel?.text = "\(updatedCount!+1)"
                Alamofire.request("https://cyoapp.azurewebsites.net/v1/records/\(recordId)/like", method: .post, headers: headers)
            }
        }
    }
    
    func cellPinched(cell:CardTableCellView){
        self.pinchRecognizer?.isEnabled = false
        self.performSegue(withIdentifier: "FeedToDetails", sender: cell)
    }
    
    func detailsButtonTapped(cell: CardTableCellView) {
        self.performSegue(withIdentifier: "FeedToDetails", sender: cell)
    }
    
    func commentCellTapped(cell: CardTableCellView) {
        //print("comment cell tapped: \(cell.tag)")
    }
    
    func segmentChanged(cell: CardTableCellView) {
        let currIdx = cell.segmentedControl?.selectedSegmentIndex
        if (currIdx == 1){
            cell.primary_imageView?.isHidden = true
        } else if (currIdx == 0){
            cell.primary_imageView?.isHidden = false
        }
    }
    
    func truncateName(name: String)->String{
        var result = ""
        var parts = name.characters.split{$0 == " "}.map(String.init)
        let part1: String = parts[0]
        let part2: String = parts[1]
        let index = part2.index(part2.startIndex, offsetBy: 1)
        result = part1 + " " + part2.substring(to: index)+"."
        return result
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
        return (value * divisor).rounded() / (divisor)
    }
    
    @objc func doubleTap(sender:UITapGestureRecognizer){
        let tapLocation = sender.location(in: self.tableView)
        let indexPath = self.tableView.indexPathForRow(at: tapLocation)
        let cell = self.tableView.cellForRow(at: indexPath!)
        likeCellTapped(cell: cell as! CardTableCellView)
    }
    
    @objc func pinch(sender:UIPinchGestureRecognizer){
        if(sender.state == UIGestureRecognizer.State.ended) {
            let pinchLocation = sender.location(in: self.tableView)
            let indexPath = self.tableView.indexPathForRow(at: pinchLocation)
            let cell = self.tableView.cellForRow(at: indexPath!)
            cellPinched(cell: cell as! CardTableCellView)
        }
    }
    
    func makeCellRequest(refresh: Bool){
        if AccessToken.current == nil {
            //show error experience
            print("no access token")
        } else {
            print("making history req")
            let token = AccessToken.current!.authenticationToken
            let headers: HTTPHeaders = [
                "access_token": token,
                "Accept": "application/json"
            ]
            
            print("Request sent!")
            Alamofire.request("https://cyoapp.azurewebsites.net/v1/feed/0", method: .get, headers: headers).responseJSON
                { response in
                    do {
                        print("Response received")
                        if (response.data != nil){
                            if ((response.data?.count)! > 0){
                                if let json = try? JSONSerialization.jsonObject(with: response.data!, options: []){
                                    let arr = json as! NSArray
                                    self.cells = arr as? [Any]
                                    self.tableView.reloadData()
                                }
                            }
                        }
                        if (self.refreshControl?.isRefreshing)!{
                            self.refreshControl?.endRefreshing()
                        }
                        if (refresh == true){
                            //
                        } else {
                            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.doubleTap))
                            tapGesture.numberOfTapsRequired = 2
                            self.tableView?.addGestureRecognizer(tapGesture)
                            
                            self.pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(self.pinch))
                            self.tableView?.addGestureRecognizer(self.pinchRecognizer!)
                        }
                
                    }
            }
        }
    }
    
    @objc func refresh(sender:AnyObject) {
        // Code to refresh table view
        self.makeCellRequest(refresh:true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "FeedToDetails" {
            let cell = sender as! CardTableCellView
            let destinationVC = segue.destination as! ActivityDetailsViewController
            destinationVC.cellData = self.cells?[cell.tag]
            destinationVC.reactionImg = cell.primary_imageView?.image
            destinationVC.cellData = self.cells?[cell.tag]
            destinationVC.reactionImg = cell.primary_imageView?.image
            destinationVC.caption = cell.captionLabel?.text
            destinationVC.name = cell.nameLabel?.text
            destinationVC.distanceStr = cell.distanceLabel?.text
            destinationVC.durationStr = cell.durationLabel?.text
            destinationVC.countLikesStr = cell.likesLabel?.text
                
            
            if (cell.primary_imageView?.isHidden)!{
                destinationVC.viewingMap = true
            } else {
                destinationVC.viewingMap = false
            }
            
            if (cell.likeButton?.isSelected)!{
                destinationVC.didLike = 1
            } else {
                destinationVC.didLike = 0
            }
        }
    }
}
