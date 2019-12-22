//
//  PatternView.swift
//  Cardioh
//
//  Created by Dmitry Pimenov on 2/8/17.
//  Copyright © 2017 Dmitry. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class PatternView: UIView {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.addPattern()
    }
    
    override func prepareForInterfaceBuilder() {
        self.addPattern()
    }
    
    func addPattern(){
        let image = UIImage(named: "ep_naturalwhite.png")
        if let pattern = image {
            self.backgroundColor = UIColor(patternImage: pattern)
        }
    }
}
