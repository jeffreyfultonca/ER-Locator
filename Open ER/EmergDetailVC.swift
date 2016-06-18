//
//  EmergDetailVC.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-04-25.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import UIKit
import MapKit

class EmergDetailVC: UIViewController,
    MKMapViewDelegate
{
    // MARK: - Outlets
    @IBOutlet var mapView: MKMapView!
    
    // MARK: - Properties
    var emerg: Emerg!

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard emerg != nil else { fatalError("Emerg dependency not met in EmergDetailVC") }
        
        setupNavBar()
        setupMapView()
    }
    
    // MARK: - Helpers
    
    func setupNavBar() {
        navigationItem.title = emerg.name
    }
    
    func setupMapView() {
        mapView.delegate = self
        mapView.showAnnotations([emerg], animated: false)
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        guard let emerg = annotation as? Emerg else { return nil }
        
        let reuseIdentifier = "pinAnnotationView"
        
        let pinAnnotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseIdentifier) as? MKPinAnnotationView ?? MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        pinAnnotationView.canShowCallout = true
        pinAnnotationView.animatesDrop = false
        
        // Color
        pinAnnotationView.pinTintColor = emerg.isOpenNow ?
            UIColor.pinColorForOpenEmerg() : UIColor.pinColorForClosedEmerg()
        
        return pinAnnotationView
    }
    
    // MARK: - Actions
    
    @IBAction func callRowTapped(sender: AnyObject) {
        let sharedApp = UIApplication.sharedApplication()
        let phoneNumber = emerg.phone.stringByRemovingNonNumericCharacters()
        let phoneCallURL = NSURL(string: "tel://\(phoneNumber)")!
        
        guard sharedApp.canOpenURL(phoneCallURL) else {
            print("Cannot open tel:// urls on this device.")
            return
        }
        
        sharedApp.openURL(phoneCallURL)
    }
    
    @IBAction func directionsRowTapped(sender: AnyObject) {
        print(#function)
        
        let placemark = MKPlacemark(coordinate: emerg.coordinate, addressDictionary: emerg.addressDictionary)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = emerg.name
        
        mapItem.openInMapsWithLaunchOptions([
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}
