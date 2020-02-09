import UIKit
import DJISDK
import DJIWidget
import MapKit
import CoreLocation
import DJIUXSDK

class DJIRootViewController: UIViewController {
    
    
    // lat and log variables
    let currentLat = 45.307067  // newberg ore
    let currentLong = -122.96015
    // the region of the map that's it automatically zoomed into.
    let regionRadius: CLLocationDistance = 200
    // the mission for the to add thw waypoints to
    let mission1:DJIMutableWaypointMission = DJIMutableWaypointMission.init()
    
    // to get the users location
    
//    // Ask for Authorisation from the User.
//    self.locationManager.requestAlwaysAuthorization()

    // For use in foreground
//    self.locationManager.requestWhenInUseAuthorization()


    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let initialLocation = CLLocation(latitude: currentLat, longitude: currentLong)
         centerMapOnLocation(location: initialLocation)
    }
    
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
                                                  latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
        // make that map satellite view
        mapView.mapType = MKMapType.satellite
    }
    
//
//    @IBAction func DroneSurvey(_ sender: Any) {
//        let alert = UIAlertController(title: "My Alert", message: "This is an alert.", preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
//        NSLog("The \"OK\" alert occured.")
//        }))
//        self.present(alert, animated: true, completion: nil)
//    }

    
    
    // when the map get a long press, it adds a waypoint.
    @IBAction func longPressAddWayPoint(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == UIGestureRecognizer.State.began {
            let touchPoint: CGPoint = gestureRecognizer.location(in: mapView)
            let newCoordinate: CLLocationCoordinate2D = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            addAnnotationOnLocation(pointedCoordinate: newCoordinate)
            
            // create the waypoint
            let wayPoint:DJIWaypoint = DJIWaypoint.init(coordinate: newCoordinate)
            // add the new waypoint
            mission1.add(wayPoint)
  
        }
    }
    
    func showAlertViewWithTitle(title:String, withMessage message:String ) {
        let alert:UIAlertController = UIAlertController(title:title, message:message, preferredStyle:UIAlertController.Style.alert)
        let okAction:UIAlertAction = UIAlertAction(title:"Ok", style:UIAlertAction.Style.`default`, handler:nil)
        alert.addAction(okAction)
        self.present(alert, animated:true, completion:nil)
    }
    

    @IBAction func runMission(_ sender: Any) {
        guard let missionControl = DJISDKManager.missionControl() else {
            showAlertViewWithTitle(title: "Error", withMessage: "Couldn't get mission control!")
            return
        }
        
        guard let missionOperator:DJIWaypointMissionOperator = missionControl.waypointMissionOperator() else {
            showAlertViewWithTitle(title: "Error", withMessage: "Couldn't get waypoint operator!")
            return
        }
        
        // "make sure the internal state of the mission plan is valid."
        if let err = mission1.checkParameters() {
            self.showAlertViewWithTitle(title: "Mission not valid", withMessage: err.localizedDescription)
        } else {
            // print the current state of the mission to the phone screen
            /*var state: String = "<other>"
            
            if missionOperator.currentState == .disconnected {
                state = "disconnected"
            } else if missionOperator.currentState == .executing {
                state = "executing"
            } else if missionOperator.currentState == .executionPaused {
                state = "executionPaused"
            } else if missionOperator.currentState == .notSupported {
                state = "notSupported"
            }*/
            
            self.showAlertViewWithTitle(title: "Mission operator state:", withMessage: String(describing: (missionOperator.currentState)))
            // load the mission
            if let loadErr = missionOperator.load(mission1) {
                self.showAlertViewWithTitle(title: "Error loading mission", withMessage: loadErr.localizedDescription)
            } else {
                
                print("loaded mission: %@" , missionOperator.loadedMission)
                
                print("mission load: ", missionOperator.currentState)
                
                // upload misssion to the product
                missionOperator.uploadMission(completion: {(error:NSError?) -> () in
                    
                    if let uploadErr = error {
                        DispatchQueue.main.async {
                            self.showAlertViewWithTitle(title: "Error uploading mission", withMessage: uploadErr.localizedDescription)
                        }
                    } else {
                        print("mission uploadMission: ", missionOperator.currentState)
                        
                        // start the mission
                        missionOperator.startMission(completion: {(error:NSError?) -> () in
                            
                            if let startErr = error {
                                DispatchQueue.main.async {
                                    self.showAlertViewWithTitle(title: "Error starting mission", withMessage: startErr.localizedDescription)
                                }
                            } else {
                                print("mission startMission: %@", missionOperator.currentState)
                                
                                print("lastest Execution Progress: %@", missionOperator.latestExecutionProgress)
                            }
                            
                        } as? DJICompletionBlock)
                    }
                    
                    
                    
                    
                    
                } as? DJICompletionBlock)
            }
            
        }
        
        
        
        
        
        
        
    }
    
    
    // adds the waypoint symbol on the map
    func addAnnotationOnLocation(pointedCoordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = pointedCoordinate
        annotation.title = "waypoint"
        mapView.addAnnotation(annotation)
    }
}
