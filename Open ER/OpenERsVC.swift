//
//  OpenERsVC.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-04-02.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import UIKit
import MapKit

class OpenERsVC: UIViewController,
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
    @IBOutlet var toolbarDetailLabel: UILabel!
    
    @IBOutlet var tableViewTopMapViewCenterConstraint: NSLayoutConstraint!
    
    // MARK: - Properties
    let locationManager = CLLocationManager()
    var shouldUpdateMapAnnotationsOnUserLocationUpdate = true
    let minLocationAccuracy: Double = 5000
    var nearbyOpenERs = [ER]()
    var showTableView = true
    
    typealias AnimationClosure = () -> Void
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.requestWhenInUseAuthorization()
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(reloadERs),
            name: UIApplicationDidBecomeActiveNotification,
            object: nil
        )
        
        setupTableView()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        setupMapView()
        
        // Reload ER's if view is reappearing as data may have changed.
        if !shouldUpdateMapAnnotationsOnUserLocationUpdate {
            reloadERs()
        }
    }
    
    deinit {
        print(#function)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Helpers
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.estimatedRowHeight = 63
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // Blur tableView background
        let visualEffect = UIBlurEffect(style: .ExtraLight)
        let visualEffectView = UIVisualEffectView(effect: visualEffect)
        tableView.backgroundView = visualEffectView
    }
    
    func setupMapView() {
        mapView.delegate = self
        adjustMapViewLayoutMargins()
    }
    
    func adjustMapViewLayoutMargins() {
        mapView.layoutMargins.bottom = tableView.frame.height + toolbarView.frame.height
    }
    
    func reloadERs() {
        // I think this will cause the mapview to immediately receive a location update
        // even if the system already has one.
        mapView.showsUserLocation = false
        shouldUpdateMapAnnotationsOnUserLocationUpdate = true
        mapView.showsUserLocation = true
    }
    
    // MARK: - UITableView Datasource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nearbyOpenERs.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("erCell", forIndexPath: indexPath) as! ERCell
        
        let er = nearbyOpenERs[indexPath.row]
        cell.configureER(er, fromLocation: mapView.userLocation.location)
        
        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        guard let cell = cell as? ERCell else {
            print("Not ERCell; nothing to do.")
            return
        }
        
        // Async fetch ScheduleDay
        let er = nearbyOpenERs[indexPath.row]
        erService.fetchScheduleDayForER(er, onDate: NSDate.now) { result in
            switch result {
            case .Failure(let error):
                print(error)
                
            case .Success(let scheduleDay):
                guard let
                    scheduleDay = scheduleDay,
                    firstOpen = scheduleDay.firstOpen,
                    firstClose = scheduleDay.firstClose else
                {
                    print("Could not access ScheduleDay or firstOpen or firstClose; this should never occur.")
                    return
                }
                
                cell.hoursLabel.text = "\(firstOpen.time) - \(firstClose.time)"
            }
        }
    }
    
    // MARK: - UITableViewDelegate
    
    
    // MARK: - MKMapViewDelegate
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        guard shouldUpdateMapAnnotationsOnUserLocationUpdate else { return }
        guard let location = userLocation.location where location.horizontalAccuracy < minLocationAccuracy else { return }
        
        shouldUpdateMapAnnotationsOnUserLocationUpdate = false
        
        erService.fetchOpenERsNearestLocation(location) { result in
            switch result {
            case .Failure(let error):
                print(error)
                
            case .Success(let ers):
                self.showERsOnMap(ers, animated: true)
            }
        }
    }
    
    func showERsOnMap(ers: [ER], animated: Bool) {
        // Remove existing annotations from map.
        mapView.removeAnnotations(nearbyOpenERs)
        
        // Get new annotations.
        nearbyOpenERs = ers
        
        // Add annotations to the map, adjusting to show annotations and user's current location.
        var annotationsToShow: [MKAnnotation] = nearbyOpenERs
        annotationsToShow.append(mapView.userLocation)
        mapView.showAnnotations(annotationsToShow, animated: animated)
        
        // Show results in tableView.
        tableView.reloadData()
    }
    
//    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
//        guard annotation is ER else { return nil }
//        
//        let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pinAnnotationView")
//        pinAnnotationView.pinTintColor = tableView.tintColor
//        
//        return pinAnnotationView
//    }
    
    // MARK: - Actions
    
    @IBAction func toolbarTapped(sender: AnyObject) {
        self.view.layoutIfNeeded()
        
        let animationClosure: AnimationClosure = {
            self.showTableView = !self.showTableView
            
            self.toolbarLabel.text = self.showTableView ? "Hide List" : "Show List"
            
            self.tableViewTopMapViewCenterConstraint.active = self.showTableView
            self.view.layoutIfNeeded()
            self.adjustMapViewLayoutMargins()
            
            // Adjust visible region of map to enclose all annotations.
            var annotationsToShow: [MKAnnotation] = self.nearbyOpenERs
            annotationsToShow.append(self.mapView.userLocation)
            self.mapView.adjustRegionToDisplayAnnotations(annotationsToShow, animated: true)
        }
        
        UIView.animateWithDuration(
            0.3,
            delay: 0.0,
            usingSpringWithDamping: 1.0,
            initialSpringVelocity: 1.0,
            options: [],
            animations: animationClosure,
            completion: nil
        )
    }
    
    // MARK: - Segues
    
    @IBAction func unwindToOpenERsVC(segue: UIStoryboardSegue) {
        print(#function)
    }
}

