//
//  DetailTableCellView.swift
//  Cardioh
//
//  Created by Dmitry Pimenov on 1/21/17.
//  Copyright © 2017 Dmitry. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import HealthKit

class DetailTableCellView : UITableViewCell
{
    var detailDelegate: DetailCellDelegate?
    @IBOutlet var nameLabel: UILabel?
    @IBOutlet var likesLabel: UILabel?
    @IBOutlet var likeButton: UIButton?
    @IBOutlet var distanceLabel: UILabel?
    @IBOutlet var durationLabel: UILabel?
    @IBOutlet var captionLabel: UILabel?
    @IBOutlet var dateLabel: UILabel?
    @IBOutlet var primary_imageView: UIImageView?
    @IBOutlet var mapView: MKMapView?
    @IBOutlet var icon_imageView: UIImageView?
    @IBOutlet var reactionButton: UIButton?
    @IBOutlet var containerView: UIView?
    
    @IBAction func buttonTap(sender: UIButton) {
        let title = sender.accessibilityLabel
        if let delegate = detailDelegate {
            if (title == "like"){
                delegate.likeCellTapped(cell: self)
            } else if (title=="comment") {
                delegate.commentCellTapped(cell: self)
            }
        }
    }
    
    @IBAction func reactionButtonPressed(sender: UIButton){
        print("reaction button pressed")
        if let delegate = detailDelegate {
            delegate.reactionButtonPressed(cell: self)
        }
    }
}

protocol DetailCellDelegate {
    func likeCellTapped(cell: DetailTableCellView)
    func commentCellTapped(cell: DetailTableCellView)
    func reactionButtonPressed(cell: DetailTableCellView)
}
