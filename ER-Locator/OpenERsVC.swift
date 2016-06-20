//
//  OpenERsVC.swift
//  ER-Locator
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
    
    var erProvider: ERProviding = ERProvider.sharedInstance
    var scheduleDayProvider: ScheduleDayProviding = ScheduleDayProvider.sharedInstance
    var persistenceProvider: PersistenceProviding = PersistenceProvider.sharedInstance
    
    // MARK: - Outlets
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var schedulerButton: UIBarButtonItem!
    
    @IBOutlet var toolbarView: UIView!
    @IBOutlet var toolbarLabel: UILabel!
    @IBOutlet var syncStatusLabel: UILabel!
    @IBOutlet var syncStatusActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet var tableViewTopMapViewCenterConstraint: NSLayoutConstraint!
    
    // MARK: - Properties
    
    let locationManager = CLLocationManager()
    let minLocationAccuracy: Double = 5000
    
    var shouldUpdateUIOnUserLocationUpdate = true
    var showTableView = true
    
    private var nearestOpenERs = [ER]()
    private var additionalOpenERs = [ER]()
    private var possiblyClosedERs = [ER]()
    
    private var allERs: [ER] {
        get { return nearestOpenERs + additionalOpenERs + possiblyClosedERs }
        set {
            // Sort ERs into mutually exclusing collections.
            self.additionalOpenERs = newValue.isOpenNow
            
            // Attempt to move nearestOpenER.
            if additionalOpenERs.isEmpty {
                self.nearestOpenERs.removeAll()
            } else {
                self.nearestOpenERs = [self.additionalOpenERs.removeFirst()]
            }
            
            self.possiblyClosedERs = newValue.possiblyClosed
        }
    }
    
    var error: ErrorType?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.requestWhenInUseAuthorization()
        
        possiblyClosedERs = erProvider.ers.sort { $0.name < $1.name }
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(reloadERs),
            name: Notification.LocalDatastoreUpdatedWithNewData,
            object: nil
        )
        
        schedulerButton.enabled = false
        setupTableView()
        refreshSyncStatusLabel()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        determineScheduleAccess()
        
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
    
    /// Confirm user currently signed into iCloud on device has Scheduler role to access Scheduler; enabling and disabling the Scheduler button accordingly.
    func determineScheduleAccess() {
        persistenceProvider.determineSchedulerAccess(completionQueue: NSOperationQueue.mainQueue()) { access in
            self.schedulerButton.enabled = access
        }
    }
    
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
        refreshMapViewAnnotations(animated: animated)
        refreshTableView()
        refreshSyncStatusLabel()
    }
    
    func refreshMapViewAnnotations(animated animated: Bool) {
        // TODO: Improve experience or reloading
        
        // Remove existing annotations from map.
        let previousERAnnotations = mapView.annotations.filter { $0 is ER }
        mapView.removeAnnotations(previousERAnnotations)
        
        // Add annotations to the map.
        mapView.addAnnotations(allERs)
        
        // Adjust region to show annotations and user's current location.
        let userLocation = mapView.userLocation
        
        // Show isOpenNow ERs if possible falling back to nearest closed
        var annotationsToShow: [MKAnnotation] = allERs.isOpenNow.nearestLocation(userLocation.location).limit(3)
        if annotationsToShow.isEmpty { annotationsToShow = allERs.nearestLocation(userLocation.location).limit(3) }
        
        annotationsToShow.append(userLocation)
        mapView.adjustRegionToDisplayAnnotations(annotationsToShow, animated: true)
    }
    
    func refreshTableView() {
        let range = NSRange(0..<sections.count)
        let sectionIndexSet = NSIndexSet(indexesInRange: range)
        tableView.reloadSections(sectionIndexSet, withRowAnimation: .Fade)
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
    
    func erForIndexPath(indexPath: NSIndexPath) -> ER? {
        let ers: [ER]
        
        switch sections[indexPath.section] {
        case .NearestOpen:
            ers = nearestOpenERs
            
        case .AdditionalOpen:
            ers = additionalOpenERs
            
        case .PossiblyClosed:
            ers = possiblyClosedERs
        }
        
        return ers.isEmpty ? nil : ers[indexPath.row]
    }
    
    func indexPath(for er: ER) -> NSIndexPath? {
        if let
            section = sections.indexOf(.NearestOpen),
            row = nearestOpenERs.indexOf(er)
        {
            return NSIndexPath(forRow: row, inSection: section)
            
        } else if let
            section = sections.indexOf(.AdditionalOpen),
            row = additionalOpenERs.indexOf(er)
        {
            return NSIndexPath(forRow: row, inSection: section)
            
        } else if let
            section = sections.indexOf(.PossiblyClosed),
            row = possiblyClosedERs.indexOf(er)
        {
            return NSIndexPath(forRow: row, inSection: section)
            
        } else {
            // ER not found
            return nil
        }
    }
    
    // MARK: - UITableView Datasource
    
    enum Section: String {
        case NearestOpen = "Nearest Open Now"
        case AdditionalOpen = "Additional Open Now"
        case PossiblyClosed = "Possibly Closed"
    }
    
    var sections: [Section] = [
        .NearestOpen,
        .AdditionalOpen,
        .PossiblyClosed
    ]
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch sections[section] {
        case .NearestOpen:
            return nearestOpenERs.isEmpty ? nil : Section.NearestOpen.rawValue
        
        case .AdditionalOpen:
            return additionalOpenERs.isEmpty ? nil : Section.AdditionalOpen.rawValue
            
        case .PossiblyClosed:
            return possiblyClosedERs.isEmpty ? nil : Section.PossiblyClosed.rawValue
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .NearestOpen:
            return nearestOpenERs.isEmpty ? 0 : nearestOpenERs.count
            
        case .AdditionalOpen:
            return additionalOpenERs.isEmpty ? 0 : additionalOpenERs.count
            
        case .PossiblyClosed:
            return possiblyClosedERs.isEmpty ? 1 : possiblyClosedERs.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if allERs.isEmpty {
            let cell = tableView.dequeueReusableCellWithIdentifier("messageCell", forIndexPath: indexPath) as! MessageCell
            
            if persistenceProvider.syncing {
                cell.messageLabel.text = "Finding emergency rooms..."
                cell.activityIndicatorView.startAnimating()
            } else {
                cell.messageLabel.text = "Strange... there doesn't seem to be any emergency rooms in our records?"
                cell.activityIndicatorView.stopAnimating()
            }
            
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("erCell", forIndexPath: indexPath) as! ERCell
            
            let er = erForIndexPath(indexPath)!
            cell.configure(for: er, relativeTo: mapView.userLocation.location)
            
            return cell
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return allERs.isEmpty ? tableView.frame.height : UITableViewAutomaticDimension
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        guard shouldUpdateUIOnUserLocationUpdate else { return }
        guard let location = userLocation.location where location.horizontalAccuracy < minLocationAccuracy else { return }
        
        shouldUpdateUIOnUserLocationUpdate = false
        
        refreshUI(animated: true)
        
        erProvider.fetchERsWithTodaysScheduleDayNearestLocation(
            location,
            limitTo: nil,
            resultQueue: NSOperationQueue.mainQueue())
        { result in
            switch result {
            case .Failure(let error):
                self.error = error
                
            case .Success(let ers):
                self.error = nil
                self.allERs = ers
            }
            
            self.refreshUI(animated: true)
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        guard let er = annotation as? ER else { return nil }
        
        let reuseIdentifier = "pinAnnotationView"
        
        let pinAnnotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseIdentifier) as? MKPinAnnotationView ?? MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        pinAnnotationView.canShowCallout = true
        pinAnnotationView.animatesDrop = false
        
        // Color
        pinAnnotationView.pinTintColor = er.isOpenNow ?
            UIColor.pinColorForOpenER() : UIColor.pinColorForClosedER()
        
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
        guard let indexPath = indexPath(for: er) else {
            print("Could not find indexPath for ER.")
            return
        }
        
        // Select indexPath in table; required for segue... poor design.
        tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .None)
        
        // Trigger segue
        performSegueWithIdentifier("showERDetail", sender: view)
    }
    
    // MARK: - Actions
    
    @IBAction func toolbarTapped(sender: AnyObject) {
        self.view.layoutIfNeeded()
        
        let animationClosure: () -> Void = {
            self.showTableView = !self.showTableView
            
            self.toolbarLabel.text = self.showTableView ? "Hide List" : "Show List"
            
            self.tableViewTopMapViewCenterConstraint.active = self.showTableView
            self.view.layoutIfNeeded()
            self.adjustMapViewLayoutMargins()
            
            self.refreshMapViewAnnotations(animated: true)
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
        scheduleDayProvider.clearInMemoryCache()
        persistenceProvider.syncLocalDatastoreWithRemote(NSOperationQueue.mainQueue(), result: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showERDetail" {
            
            guard let vc = segue.destinationViewController as? ERDetailVC else {
                return // Should and will probably crash.
            }
            
            // Triggered by MapView
            if let
                annotationView = sender as? MKAnnotationView,
                er = annotationView.annotation as? ER
            {
                vc.er = er
                
            } else if let indexPath = tableView.indexPathForSelectedRow {
                vc.er = erForIndexPath(indexPath)
            }
        }
    }
}

