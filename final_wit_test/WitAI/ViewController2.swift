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
import AVFoundation

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, WitDelegate {
    
    
    @IBOutlet weak var showDirections: UIBarButtonItem!
    
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
    var synth = AVSpeechSynthesizer()
    
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
        
        //self.entityLabel!.text = ""
        //self.textLabel!.text = ""
        
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
        let confidence : Float = firstOutcome["confidence"] as! Float
        print(intent)
        
        // add conditional logic for each intent here
        // this should address each intent's internal form and their own specific function calls
        if confidence > 0.5{
            if intent == "RouteToLocation" {
                let entityDict : NSDictionary = firstOutcome["entities"] as! NSDictionary
                if entityDict["location"] == nil {
                    let location : NSDictionary = entityDict["local_search_query"]!.objectAtIndex(0) as! NSDictionary
                    let entity: String = location["value"] as! String
                    getDestination(entity)
                }
                else{
                    let location : NSDictionary = entityDict["location"]!.objectAtIndex(0) as! NSDictionary
                    let entity: String = location["value"] as! String
                    let utterance: String = "Getting directions to " + entity
                    textToSpeech(utterance)
                    getDestination(entity)
                }
            }
        
            if intent == "stopNav" {
                clearNav()
            }
        
            // Set the ASR reco label to the text
            self.textLabel!.text = text
            self.textLabel!.sizeToFit()
        }
        else{
            self.textLabel!.text = "Sorry, didn't catch that"
            self.textLabel!.sizeToFit()
        }
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
                //self.getDirections(destinationCoords)
                let startlat = String(self.navMap.userLocation.coordinate.latitude)
                let startlon = String(self.navMap.userLocation.coordinate.longitude)
                let endlat = String(destinationCoords.latitude)
                let endlon = String(destinationCoords.longitude)

                
                let GoogURL = "https://maps.googleapis.com/maps/api/directions/json?origin=" + startlat + "," + startlon + "+&destination=" + endlat + "," + endlon + "&mode=transit&alternatives=true&key=AIzaSyAin3j3P5jwRY6fPdPbMTfeqLU_jHwWWG0"
                
                print(GoogURL)
                
                let request = NSMutableURLRequest(URL: NSURL(string: GoogURL)!)
                
                self.httpGet(request){
                    (data, error) -> Void in
                    if (error != ""){
                        print("error")
                        print(error)
                    } else{
                        print("json")
                        let routes = self.getPossibleBusRoutesFromGoogle(data)
                        print(routes.count)
                        if routes.count > 0 {
                            let eta = self.getETAForBusRoute(routes[0])
                            print(eta)
                            let dt = self.getDepartureTimeForBusRoute(routes[0])
                            print(dt)
                            let polyline = self.getOverviewPolyline(routes[0])
                            //print(polyline)
                            let route_number = self.getBusRoute(routes[0])
                            print(route_number)
                            self.getDirections(destinationCoords, route: routes[0])
                        }
                    }
                }
                
            }
        })
    }
    
    // getDirections
    // input: destination -> CLLocationCoordinate2D
    // Takes a coordinate and calculates the directions from the user's current location to the destination coordinates and calls the overlay renderer to render the path on the map
    func getDirections(destination : CLLocationCoordinate2D, route: NSDictionary) {
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
                    let encodedString = self.getOverviewPolyline(route)
                    let polylineString = self.polyLineWithEncodedString(encodedString)
                    self.navMap.addOverlay(polylineString, level: MKOverlayLevel.AboveRoads)
                }
            }
        }
    }
    
    func polyLineWithEncodedString(encodedString: String) -> MKPolyline {
        let bytes = (encodedString as NSString).UTF8String
        let length = encodedString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        var idx: Int = 0
        
        var count = length / 4
        var coords = UnsafeMutablePointer<CLLocationCoordinate2D>.alloc(count)
        var coordIdx: Int = 0
        
        var latitude: Double = 0
        var longitude: Double = 0
        
        while (idx < length) {
            var byte = 0
            var res = 0
            var shift = 0
            
            repeat {
                byte = bytes[idx++] - 0x3F
                res |= (byte & 0x1F) << shift
                shift += 5
            } while (byte >= 0x20)
            
            let deltaLat = ((res & 1) != 0x0 ? ~(res >> 1) : (res >> 1))
            latitude += Double(deltaLat)
            
            shift = 0
            res = 0
            
            repeat {
                byte = bytes[idx++] - 0x3F
                res |= (byte & 0x1F) << shift
                shift += 5
            } while (byte >= 0x20)
            
            let deltaLon = ((res & 1) != 0x0 ? ~(res >> 1) : (res >> 1))
            longitude += Double(deltaLon)
            
            let finalLat: Double = latitude * 1E-5
            let finalLon: Double = longitude * 1E-5
            
            let coord = CLLocationCoordinate2DMake(finalLat, finalLon)
            coords[coordIdx++] = coord
            
            if coordIdx == count {
                let newCount = count + 10
                let temp = coords
                coords.dealloc(count)
                coords = UnsafeMutablePointer<CLLocationCoordinate2D>.alloc(newCount)
                for index in 0..<count {
                    coords[index] = temp[index]
                }
                temp.destroy()
                count = newCount
            }
            
        }
        
        let polyLine = MKPolyline(coordinates: coords, count: coordIdx)
        coords.destroy()
        
        return polyLine
    }
    
    
    //make a REST API call
    //we will be doing this to get info from the MBTA realtime API
    //returns a NSDictionary object that can then be parsed
    func httpGet(request: NSURLRequest!, callback: (NSDictionary, String) -> Void) {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
        let task = session.dataTaskWithRequest(request,
            completionHandler: {(data, response, error) in
            if error != nil {
                let emptyDict: NSDictionary = [:]
                callback(emptyDict, (error?.localizedDescription)!)
            } else {
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                    //print(json)
                    callback(json as! NSDictionary, "")
                } catch {
                    print("error serializing JSON: \(error)")
                }
            }
        });
        task.resume()
        
    }
    
    // Parses JSON-formatted directions from Google
    func getPossibleBusRoutesFromGoogle(data : NSDictionary) -> [NSDictionary] {
        var bus_routes = [NSDictionary]()
        let routes = data["routes"] as! [NSDictionary]
        print("number of routes")
        print(routes.count)
        for route in routes {
            var isValidRoute = true
            for leg in route["legs"] as! [NSDictionary] {
                for step in leg["steps"] as! [NSDictionary] {
                    if let travel_mode = step["travel_mode"] {
                        if travel_mode as! String == "TRANSIT" {
                            let type = step["transit_details"]!["line"]!!["vehicle"]!!["type"] as! String
                            print(type)
                            if type != "BUS" {
                                isValidRoute = false
                                break
                            }
                        }
                    }
                }
            }
            if isValidRoute {
                bus_routes.append(route)
            }
        }
        return bus_routes
    }
    
    // Returns the ETA as a string for a particular bus route
    func getETAForBusRoute(route : NSDictionary) -> String {
        var eta = String()
        for leg in route["legs"] as! [NSDictionary] {
            if let arrival_time = leg["arrival_time"] {
                if let txt = arrival_time["text"] {
                    eta = txt as! String
                }
            }
        }
        return eta
    }
    
    // Returns the departure time as a string for a particular bus route
    func getDepartureTimeForBusRoute(route : NSDictionary) -> String {
        var dt = String()
        for leg in route["legs"] as! [NSDictionary] {
            for step in leg["steps"] as! [NSDictionary] {
                if let tmode = step["travel_mode"] {
                    if tmode as! String == "TRANSIT" {
                        if let departure_time = leg["departure_time"] {
                            if let txt = departure_time["text"] {
                                dt = txt as! String
                            }
                        }
                        break
                    }
                }
            }
        }
        return dt
    }
    
    // Returns the bus route number
    func getBusRoute(route : NSDictionary) -> String {
        var route_number = String()
        for leg in route["legs"] as! [NSDictionary] {
            for step in leg["steps"] as! [NSDictionary] {
                if let travel_mode = step["travel_mode"] {
                    if travel_mode as! String == "TRANSIT" {
                        let name = step["transit_details"]!["line"]!!["short_name"] as! String
                        route_number = name
                        break
                    }
                }
            }
        }
        return route_number
    }

    // Returns the overview polyline as a string
    func getOverviewPolyline(route : NSDictionary) -> String {
        var polyline = String()
        if let poly = route["overview_polyline"] {
            polyline = poly["points"] as! String
        }
        return polyline
    }
    
    
    func clearNav(){
        self.navMap.removeOverlays(self.navMap.overlays)
        self.entityLabel!.text = ""
    }
    
    // mapView delegate
    // takes in an MKOverlay and renders it on the map
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        
        renderer.strokeColor = UIColor.blueColor()
        renderer.lineWidth = 5.0
        return renderer
    }
    
    func textToSpeech(utterance: String) {
        let myUtterance = AVSpeechUtterance(string: utterance)
        myUtterance.rate = 0.5
        synth.speakUtterance(myUtterance)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}