//
//  ERDetailVC.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-04-25.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import UIKit
import MapKit

class ERDetailVC: UIViewController {
    
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
        mapView.showAnnotations([er], animated: false)
    }
    
    // MARK: - Actions
    
    @IBAction func callRowTapped(sender: AnyObject) {
        let sharedApp = UIApplication.sharedApplication()
        let phoneNumber = er.phone.stringByRemovingNonNumericCharacters()
        let phoneCallURL = NSURL(string: "tel://\(phoneNumber)")!
        
        guard sharedApp.canOpenURL(phoneCallURL) else {
            print("Cannot open tel:// urls on this device.")
            return
        }
        
        sharedApp.openURL(phoneCallURL)
    }
    
    @IBAction func directionsRowTapped(sender: AnyObject) {
        print(#function)
        
        let placemark = MKPlacemark(coordinate: er.coordinate, addressDictionary: er.addressDictionary)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = er.name
        
        mapItem.openInMapsWithLaunchOptions([
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}
