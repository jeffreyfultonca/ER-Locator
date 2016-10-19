//
//  ERDetailVC.swift
//  ER-Locator
//
//  Created by Jeffrey Fulton on 2016-04-25.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import UIKit
import MapKit

class ERDetailVC: UIViewController,
    MKMapViewDelegate
{
    // MARK: - Outlets
    @IBOutlet var mapView: MKMapView!
    
    // MARK: - Properties
    var er: ER!

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard er != nil else { fatalError("ER dependency not met in ERDetailVC") }
        
        setupNavBar()
        setupMapView()
    }
    
    // MARK: - Helpers
    
    func setupNavBar() {
        navigationItem.title = er.name
    }
    
    func setupMapView() {
        mapView.delegate = self
        mapView.showAnnotations([er], animated: false)
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let er = annotation as? ER else { return nil }
        
        let reuseIdentifier = "pinAnnotationView"
        
        let pinAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? MKPinAnnotationView ?? MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        pinAnnotationView.canShowCallout = true
        pinAnnotationView.animatesDrop = false
        
        // Color
        pinAnnotationView.pinTintColor = er.isOpenNow ?
            UIColor.pinColorForOpenER() : UIColor.pinColorForClosedER()
        
        return pinAnnotationView
    }
    
    // MARK: - Actions
    
    @IBAction func callRowTapped(_ sender: AnyObject) {
        let sharedApp = UIApplication.shared
        let phoneNumber = er.phone.stringByRemovingNonNumericCharacters()
        let phoneCallURL = URL(string: "tel://\(phoneNumber)")!
        
        guard sharedApp.canOpenURL(phoneCallURL) else {
            print("Cannot open tel:// urls on this device.")
            return
        }
        
        sharedApp.openURL(phoneCallURL)
    }
    
    @IBAction func directionsRowTapped(_ sender: AnyObject) {
        print(#function)
        
        let placemark = MKPlacemark(coordinate: er.coordinate, addressDictionary: er.addressDictionary)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = er.name
        
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}
