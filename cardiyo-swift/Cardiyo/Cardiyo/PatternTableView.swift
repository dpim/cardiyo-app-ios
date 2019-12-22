//
//  PatternTableView.swift
//  Cardioh
//
//  Created by Dmitry Pimenov on 2/8/17.
//  Copyright © 2017 Dmitry. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class PatternTableView: UITableView {
   
    override func awakeFromNib() {
        super.awakeFromNib()
        self.addPattern()
    }
    
    override func prepareForInterfaceBuilder() {
        self.addPattern()
    }
    
    func addPattern(){
    }
}
