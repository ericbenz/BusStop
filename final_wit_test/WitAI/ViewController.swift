//
//  ViewController.swift
//  WitAI
//
//  Created by Julian Abentheuer on 10.01.15.
//  Copyright (c) 2015 Aaron Abentheuer. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, WitDelegate {
    
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var entityLabel: UILabel!
    var witButton : WITMicButton?
    
    @IBOutlet weak var curLocation: UILabel!
    
    @IBOutlet weak var navMap: MKMapView!
    var locationManager = CLLocationManager()
    
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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // set the WitDelegate object
        Wit.sharedInstance().delegate = self
        
        // create the button
        let screen : CGRect = UIScreen.mainScreen().bounds
        let w : CGFloat = 100
        let rect : CGRect = CGRectMake(screen.size.width/2 - w/2, 40, w, 100)
        witButton = WITMicButton(frame: rect)
        self.view.addSubview(witButton!)
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        navMap.delegate = self
        navMap.showsUserLocation = true
        navMap.showsPointsOfInterest = true
        navMap.showsCompass = true
        
    }
    
    func witDidGraspIntent(outcomes: [AnyObject]!, messageId: String!, customData: AnyObject!, error e: NSError!) {
        if ((e) != nil) {
            print("\(e.localizedDescription)")
            return
        }
        
        let outcomes : NSArray = outcomes!
        let firstOutcome : NSDictionary = outcomes.objectAtIndex(0) as! NSDictionary
        let text : String = firstOutcome["_text"] as! String
        //let intent : String = firstOutcome["intent"] as! String
        let entityDict : NSDictionary = firstOutcome["entities"] as! NSDictionary
        let location : NSArray = entityDict["location"] as! NSArray
        let test : NSDictionary = location.objectAtIndex(0) as! NSDictionary
        let entity: String = test["value"] as! String
       
        textLabel!.text = text
        textLabel!.sizeToFit()
        
        entityLabel!.text = entity
        entityLabel!.sizeToFit()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation = locations[0]
        curLocation.text = "\(locations[0])"
        
        locationManager.stopUpdatingLocation()
        
        let location = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        
        let span = MKCoordinateSpanMake(0.05, 0.05)
        
        let region = MKCoordinateRegion(center: location, span: span)
        
        navMap.setRegion(region, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

