//
//  ER.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-04-02.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import MapKit

class ER: NSObject, MKAnnotation {
    
    // MARK: - Properties
    var name: String
    var location: CLLocation
    
    // MARK: MKAnnotation
    var coordinate: CLLocationCoordinate2D { return self.location.coordinate }
    var title: String? { return self.name }
    
    init(name: String, location: CLLocation) {
        self.name = name
        self.location = location
    }
}