//
//  CardTableCellView.swift
//  Cardioh
//
//  Created by Dmitry Pimenov on 12/28/16.
//  Copyright © 2016 Dmitry. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import HealthKit

class CardTableCellView : UITableViewCell
{
    var cardDelegate: CardCellDelegate?
    @IBOutlet var nameLabel: UILabel?
    @IBOutlet var likesLabel: UILabel?
    @IBOutlet var likeButton: UIButton?
    @IBOutlet var distanceLabel: UILabel?
    @IBOutlet var durationLabel: UILabel?
    @IBOutlet var captionLabel: UILabel?
    @IBOutlet var primary_imageView: UIImageView?
    @IBOutlet var map_imageView: UIImageView?
    @IBOutlet var icon_imageView: UIImageView?
    @IBOutlet var segmentedControl: UISegmentedControl?
    @IBOutlet var containerView: UIView?
    @IBOutlet var detailsButton: UIButton?
    
    @IBAction func buttonTap(sender: UIButton) {
        let title = sender.accessibilityLabel
        if let delegate = cardDelegate {
            if (title == "like"){
                delegate.likeCellTapped(cell: self)
            } else if (title=="comment") { //TO DO: Refactor this into a different func
                delegate.commentCellTapped(cell: self)
            }
        }
    }
    
    @IBAction func detailsButtonTap(sender: UIButton) {
        if let delegate = cardDelegate {
            delegate.detailsButtonTapped(cell:self)
        }
    }
    
    @IBAction func segmentChanged(sender: UISegmentedControl){
        if let delegate = cardDelegate {
            delegate.segmentChanged(cell: self)
        }
    }
}

protocol CardCellDelegate {
    func likeCellTapped(cell: CardTableCellView)
    func commentCellTapped(cell: CardTableCellView)
    func segmentChanged(cell: CardTableCellView)
    func detailsButtonTapped(cell: CardTableCellView)
}
