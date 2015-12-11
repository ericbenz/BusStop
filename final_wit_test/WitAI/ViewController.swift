//
//  ViewController.swift
//  BusStop
//
// Brandeis University COSI 136 Automated Speech Recognition Final Project
// Project members:
//   Eric Benzschawel
//   Adam Berger
//   Suzanne Blackley
//   Swini Garimella
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, WitDelegate {
    
    
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var entityLabel: UILabel!
    @IBOutlet weak var curLocation: UILabel!
    @IBOutlet weak var navMap: MKMapView!
    @IBOutlet weak var toggleView: UISegmentedControl!
    
    @IBAction func mapViewChanged(sender: UISegmentedControl) {
        
        switch toggleView.selectedSegmentIndex
            
        {
        case 0:
            navMap.mapType = MKMapType.Standard
        case 1:
            navMap.mapType = MKMapType.Satellite
        case 2:
            navMap.mapType = MKMapType.Hybrid
        default:
            navMap.mapType = MKMapType.Standard
        }
    }
    
    var witButton : WITMicButton?
    var locationManager = CLLocationManager()
    var destination : CLLocationCoordinate2D!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set the WitDelegate object
        Wit.sharedInstance().delegate = self
        
        // create the microphone button
        let screen : CGRect = UIScreen.mainScreen().bounds
        let w : CGFloat = 100
        let rect : CGRect = CGRectMake(screen.size.width/2 - w/2, 40, w, 100)
        witButton = WITMicButton(frame: rect)
        self.view.addSubview(witButton!)
        
        // request user for location tracking and start tracking
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        // initialize the map
        navMap.delegate = self
        navMap.showsUserLocation = true
        navMap.showsPointsOfInterest = true
        navMap.showsCompass = true // allow user to re-orient to North if they move the map at all
        
        // begin tracking the user
        navMap.setUserTrackingMode(MKUserTrackingMode.Follow, animated: true)
        
        // center the map on the user location
        //let userLocation = CLLocationCoordinate2D(latitude: navMap.userLocation.coordinate.latitude, longitude: navMap.userLocation.coordinate.longitude)
        navMap.setCenterCoordinate(navMap.userLocation.coordinate, animated: true)
    }
    
    // witDidGraspIntent
    // general function essentially unmodified from original source
    func witDidGraspIntent(outcomes: [AnyObject]!, messageId: String!, customData: AnyObject!, error e: NSError!) {
        if ((e) != nil) {
            print("\(e.localizedDescription)")
            return
        }
        
        // get the wit.ai results and store to outcomes
        let outcomes : NSArray = outcomes!
        let firstOutcome : NSDictionary = outcomes.objectAtIndex(0) as! NSDictionary
        let text : String = firstOutcome["_text"] as! String
        let intent : String = firstOutcome["intent"] as! String
        print(intent)
        
        // add conditional logic for each intent here
        // this should address each intent's internal form and their own specific function calls
        if intent == "RouteToLocation" {
            let entityDict : NSDictionary = firstOutcome["entities"] as! NSDictionary
            let location : NSDictionary = entityDict["location"]!.objectAtIndex(0) as! NSDictionary
            let entity: String = location["value"] as! String
            getDestination(entity)
        }
        
        // Set the ASR reco label to the text
        self.textLabel!.text = text
        self.textLabel!.sizeToFit()
    }
    
    // locationManager
    // functions related to the locationManager which is triggered if the user location is updated
    // output: updates the curLocation field with a string form of the user's current location
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.curLocation.text = "\(locations[0])"
    }
    
    // getDestionation
    // input: string -> destination
    // Takes a destination returned from wit.ai and sets the destination field as this location's coordinate
    func getDestination(destination : String) {
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(destination, completionHandler: {(placemarks, error) -> Void in
            if let placemark = placemarks?.first {
                let destinationCoords: CLLocationCoordinate2D = placemark.location!.coordinate
                self.destination = destinationCoords
                self.entityLabel!.text = "\(destinationCoords.latitude), \(destinationCoords.longitude)"
                self.getDirections(destinationCoords)
            }
        })
    }
    
    // getDirections
    // input: destinatino -> CLLocationCoordinate2D
    // Takes a coordinate and calculates the directions from the user's current location to the destination coordinates and calls the overlay renderer to render the path on the map
    func getDirections(destination : CLLocationCoordinate2D) {
        let request = MKDirectionsRequest()
        // set the source as the user's current location
        let source = MKMapItem(placemark: MKPlacemark(coordinate: navMap.userLocation.coordinate, addressDictionary: nil))
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: destination, addressDictionary: nil))
        
        request.source = source
        request.destination = destination
        
        // we'll need to change the transit type to 'Transit' later, but for now this is working
        request.transportType = MKDirectionsTransportType.Walking
        
        // using the first returned route, print the steps to the console and add a map overlay
        let directions = MKDirections(request: request)
        directions.calculateDirectionsWithCompletionHandler { response, error in
            if error == nil {
                if let r = response {
                    for step in r.routes[0].steps {
                        print(step.instructions)
                    }
                    // remove any pre-existing overlays
                    self.navMap.removeOverlays(self.navMap.overlays)
                    // add the new overlay
                    self.navMap.addOverlay(r.routes[0].polyline, level: MKOverlayLevel.AboveRoads)
                }
            }
        }
    }

    // mapView delegate
    // takes in an MKOverlay and renders it on the map
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        
        renderer.strokeColor = UIColor.blueColor()
        renderer.lineWidth = 5.0
        return renderer
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

