//
//  AboutViewController.swift
//  Cardioh
//
//  Created by Dmitry Pimenov on 1/31/17.
//  Copyright © 2017 Dmitry. All rights reserved.
//

import Foundation
import UIKit

class AboutViewController: UIViewController {
    
    @IBAction func termsButtonPressed(){
        self.performSegue(withIdentifier: "AboutToTerms", sender: self);
    }
    
}
