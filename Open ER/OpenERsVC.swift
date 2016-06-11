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
    var emergencyRoomProvider: EmergencyRoomProvider = EmergencyRoomService.sharedInstance
    var persistenceProvider: PersistenceProvider = PersistenceService.sharedInstance
    
    // MARK: - Outlets
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var toolbarView: UIView!
    @IBOutlet var toolbarLabel: UILabel!
    @IBOutlet var syncStatusLabel: UILabel!
    @IBOutlet var syncStatusActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet var tableViewTopMapViewCenterConstraint: NSLayoutConstraint!
    
    typealias AnimationClosure = () -> Void
    
    // MARK: - Properties
    
    let locationManager = CLLocationManager()
    let minLocationAccuracy: Double = 5000
    
    var shouldUpdateUIOnUserLocationUpdate = true
    var showTableView = true
    
    var ers = [ER]()
    var error: ErrorType?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.requestWhenInUseAuthorization()
        
        ers = emergencyRoomProvider.emergencyRooms.sort { $0.name < $1.name }
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(reloadERs),
            name: Notification.LocalDatastoreUpdatedWithNewData,
            object: nil
        )
        
        setupTableView()
        refreshSyncStatusLabel()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        setupMapView()
    }
    
    deinit {
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
        // Cause the mapview delegate to immediately receive a location update.
        mapView.showsUserLocation = false
        shouldUpdateUIOnUserLocationUpdate = true
        mapView.showsUserLocation = true
    }
    
    func refreshUI(animated animated: Bool) {
        refreshMapViewAnnotations(animated)
        refreshTableView()
        refreshSyncStatusLabel()
    }
    
    func refreshMapViewAnnotations(animated: Bool) {
        // Remove existing annotations from map.
        let previousERAnnotations = mapView.annotations.filter { $0 is ER }
        mapView.removeAnnotations(previousERAnnotations)
        
        // Add annotations to the map, adjusting to show annotations and user's current location.
        var annotationsToShow: [MKAnnotation] = ers
        annotationsToShow.append(mapView.userLocation)
        mapView.showAnnotations(annotationsToShow, animated: animated)
    }
    
    func refreshTableView() {
        let sections = NSIndexSet(index: 0)
        tableView.reloadSections(sections, withRowAnimation: .Fade)
    }
    
    func refreshSyncStatusLabel() {
        if persistenceProvider.syncing {
            syncStatusLabel.text = "Updating..."
            syncStatusActivityIndicator.startAnimating()
            
        } else if let error = error {
            // TODO: Give more meaningful message.
            syncStatusLabel.text = "Uh oh... \(error)"
            syncStatusActivityIndicator.stopAnimating()
            
        } else if let lastSuccessfulSyncAt = persistenceProvider.lastSuccessSyncAt {
            syncStatusLabel.text =  "Updated \(lastSuccessfulSyncAt.time)"
            syncStatusActivityIndicator.stopAnimating()
            
        } else {
            syncStatusLabel.text =  "🐶"
            syncStatusActivityIndicator.stopAnimating()
        }
    }
    
    // MARK: - UITableView Datasource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ers.isEmpty ? 1 : ers.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if ers.isEmpty {
            let cell = tableView.dequeueReusableCellWithIdentifier("messageCell", forIndexPath: indexPath) as! MessageCell

            if persistenceProvider.syncing {
                cell.messageLabel.text = "Finding emergency rooms..."
                cell.activityIndicatorView.startAnimating()
            } else {
                cell.messageLabel.text = "Strange... there doesn't seem to be any Emergency Rooms in our records?"
                cell.activityIndicatorView.stopAnimating()
            }
            
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("erCell", forIndexPath: indexPath) as! ERCell
            
            let er = ers[indexPath.row]
            cell.configureER(er, fromLocation: mapView.userLocation.location)
            
            return cell
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return ers.isEmpty ? tableView.frame.height : UITableViewAutomaticDimension
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        guard shouldUpdateUIOnUserLocationUpdate else { return }
        guard let location = userLocation.location where location.horizontalAccuracy < minLocationAccuracy else { return }
        
        shouldUpdateUIOnUserLocationUpdate = false
        
        refreshUI(animated: true)
        
        emergencyRoomProvider.fetchERsWithTodaysScheduleDayNearestLocation(
            location,
            limitTo: nil,
            resultQueue: NSOperationQueue.mainQueue())
        { result in
            switch result {
            case .Failure(let error):
                self.error = error
                
            case .Success(let ers):
                self.error = nil
                self.ers = ers
            }
            
            self.refreshUI(animated: true)
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is ER else { return nil }
        
        let reuseIdentifier = "pinAnnotationView"
        
        let pinAnnotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseIdentifier) as? MKPinAnnotationView ?? MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        pinAnnotationView.canShowCallout = true
        pinAnnotationView.animatesDrop = false
        
        // Info Button
        let infoButton = UIButton(type: .DetailDisclosure)
        pinAnnotationView.rightCalloutAccessoryView = infoButton
        
        return pinAnnotationView
    }
    
    func mapView(
        mapView: MKMapView,
        annotationView view: MKAnnotationView,
        calloutAccessoryControlTapped control: UIControl)
    {
        guard let er = view.annotation as? ER else {
            print("Could not access ER from annotationView.")
            return
        }
        
        // Get indexPath for ER
        guard let indexPath = indexPathForER(er) else {
            print("Could not find indexPath for ER.")
            return
        }
        
        // Select indexPath in table; required for segue... poor design.
        tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .None)
        
        // Trigger segue
        performSegueWithIdentifier("showERDetail", sender: self)
    }
    
    func indexPathForER(er: ER) -> NSIndexPath? {
        for (row, nearbyOpenER) in ers.enumerate() {
            if nearbyOpenER == er {
                // No point in continuing, return indexPath for this row.
                return NSIndexPath(forRow: row, inSection: 0)
            }
        }
        
        // ER was not found in list
        return nil
    }
    
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
            var annotationsToShow: [MKAnnotation] = self.ers
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
        PersistenceService.sharedInstance.syncLocalDatastoreWithRemote(NSOperationQueue.mainQueue(), result: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showERDetail" {
            if let
                indexPath = tableView.indexPathForSelectedRow,
                vc = segue.destinationViewController as? ERDetailVC
            {
                let er = ers[indexPath.row]
                vc.er = er
            }
        }
    }
}

