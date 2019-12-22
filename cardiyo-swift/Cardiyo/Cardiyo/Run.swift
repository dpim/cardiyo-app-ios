//
//  Run.swift
//  Cardioh
//
//  Created by Dmitry Pimenov on 11/28/16.
//  Copyright © 2016 Dmitry. All rights reserved.
//

import Foundation
import CoreData

class Run: NSManagedObject {
    @NSManaged var image: NSData
    @NSManaged var duration: NSNumber
    @NSManaged var distance: NSNumber
    @NSManaged var timestamp: Date
    @NSManaged var locations: NSOrderedSet
    
}
