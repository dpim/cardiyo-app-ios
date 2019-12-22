//
//  CardViewController.swift
//  Cardioh
//
//  Created by Dmitry Pimenov on 12/28/16.
//  Copyright © 2016 Dmitry. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import HealthKit

class CardViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var likesLabel: UILabel!
    @IBOutlet var likeButton: UIButton!
    @IBOutlet var distanceLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var segmentedControl: UISegmentedControl!
    
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
    
    func showImage(){
        self.imageView.isHidden = false;
    }
    
    func showMap(){
        self.imageView.isHidden = true;
    }
}
