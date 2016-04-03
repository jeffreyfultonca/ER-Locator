//
//  ERsVC.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-04-02.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import UIKit
import MapKit

class ERsVC: UIViewController,
    UITableViewDelegate,
    UITableViewDataSource,
    MKMapViewDelegate
{
    // MARK: - Dependencies
    var erService = ERService.sharedInstance
    
    // MARK: - Outlets
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var toolbarView: UIView!
    @IBOutlet var toolbarLabel: UILabel!
    
    // MARK: - Properties
    let locationManager = CLLocationManager()
    var shouldUpdateMapAnnotationsOnUserLocationUpdate = true
    let minLocationAccuracy: Double = 5000
    var nearbyOpenERs = [ER]()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.requestWhenInUseAuthorization()
        
        setupTableView()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        setupMapView()
    }
    
    // MARK: - Helpers
    
    func setupTableView() {
        // Blur tableView background
        let visualEffect = UIBlurEffect(style: .ExtraLight)
        let visualEffectView = UIVisualEffectView(effect: visualEffect)
        tableView.backgroundView = visualEffectView
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func setupMapView() {
        mapView.layoutMargins.bottom = tableView.frame.height + toolbarView.frame.height
        mapView.delegate = self
    }
    
    // MARK: - UITableView Datasource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nearbyOpenERs.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("erCell", forIndexPath: indexPath)
        let er = nearbyOpenERs[indexPath.row]
        cell.textLabel?.text = er.name
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    
    // MARK: - MKMapViewDelegate
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        guard shouldUpdateMapAnnotationsOnUserLocationUpdate else { return }
        guard let location = userLocation.location where location.horizontalAccuracy < minLocationAccuracy else { return }
        
        shouldUpdateMapAnnotationsOnUserLocationUpdate = false
        
        erService.fetchOpenERsNearestLocation(location) { result in
            switch result {
            case .Success(let ers):
                self.showERsOnMap(ers)
                
            case .Failure(let error):
                print(error)
            }
        }
    }
    
    func showERsOnMap(ers: [ER]) {
        // Remove existing annotations from map.
        mapView.removeAnnotations(nearbyOpenERs)
        
        // Get new annotations.
        nearbyOpenERs = ers
        
        // Add annotations to the map, adjusting to show annotations and user's current location.
        var annotationsToShow: [MKAnnotation] = nearbyOpenERs
        annotationsToShow.append(mapView.userLocation)
        mapView.showAnnotations(annotationsToShow, animated: true)
        
        // Show results in tableView.
        tableView.reloadData()
    }
}

