//
//  Extensions.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-04-02.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import MapKit

extension MKMapView {
    func adjustRegionToDisplayAnnotations(annotations: [MKAnnotation], animated: Bool) {
        var zoomRect = MKMapRectNull
        
        for annotation in annotations {
            let annotationPoint = MKMapPointForCoordinate(annotation.coordinate)
            let pointRect = MKMapRect(origin: annotationPoint, size: MKMapSize() )
            
            if MKMapRectIsNull(zoomRect) {
                zoomRect = pointRect
            } else {
                zoomRect = MKMapRectUnion(zoomRect, pointRect)
            }
        }
        
        let padding = UIEdgeInsets(top: 75, left: 50, bottom: 50, right: 50)
        self.setVisibleMapRect(zoomRect, edgePadding: padding, animated: animated)
    }
}
