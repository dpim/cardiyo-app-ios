//
//  Location.swift
//  Cardioh
//
//  Created by Dmitry Pimenov on 11/28/16.
//  Copyright © 2016 Dmitry. All rights reserved.
//

import Foundation
import CoreData

class Location: NSManagedObject {
    @NSManaged var timestamp: NSDate
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var elevation: NSNumber
    @NSManaged var run: Run
    
}
