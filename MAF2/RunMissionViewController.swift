import UIKit
import DJISDK
import DJIWidget
import MapKit
import DJIUXSDK

class RunMissionViewController: UIViewController, CLLocationManagerDelegate {
    
    let operatorStateNames = [
        "Disconnected",
        "Recovering",
        "Not Supported",
        "Ready to Upload",
        "Uploading",
        "Ready to Execute",
        "Executing",
        "Execution Paused"
    ]
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var operatorStateLabel: UILabel!
    @IBOutlet weak var logTextField: UITextField!
    
    var uiUpdateTimer: Timer!
    
    // lat and log variables
    let currentLat = 45.307067  // newberg ore
    let currentLong = -122.96015
    // the region of the map that's it automatically zoomed into.
    let regionRadius: CLLocationDistance = 200
    // the mission for the to add the waypoints to
    let mission:DJIMutableWaypointMission = DJIMutableWaypointMission.init()
    
    // to zoom in on user location
    let locationManager = CLLocationManager()

    func debugPrint(_ text: String) {
        DispatchQueue.main.async {
            //logTextField.text += text + "\n"
            self.logTextField.text = (self.logTextField.text ?? "") + text + "\n"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let initialLocation = CLLocation(latitude: currentLat, longitude: currentLong)
        centerMapOnLocation(location: initialLocation)
        
        
        
        // call the method to zoom into the users current location
//        zoomUserLocation(locationManager)
//
//        // to get user location
//        locationManager.requestAlwaysAuthorization()
//        locationManager.requestWhenInUseAuthorization()
//        if CLLocationManager.locationServicesEnabled() {
//            locationManager.delegate = self
//            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
//            locationManager.startUpdatingLocation()
//        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        uiUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {_ in
            guard let missionControl = DJISDKManager.missionControl() else { return }
            guard let missionOperator:DJIWaypointMissionOperator = missionControl.waypointMissionOperator() else { return }
            
            DispatchQueue.main.async {
                self.operatorStateLabel.text = String(format: "Operator State: %@",
                                                      self.operatorStateNames[missionOperator.currentState.rawValue])
            }
        })
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        uiUpdateTimer.invalidate()
    }
    
    // zoom the map in to the location that we choose. Right now it is hard coded for newberg OR
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)

        // make that map satellite view
        mapView.mapType = MKMapType.satellite
    }

    
    func zoomUserLocation(_ manager: CLLocationManager) {
        guard let currentLocation: CLLocationCoordinate2D = manager.location?.coordinate else {
            return
        }

        mapView.setCenter(currentLocation, animated: true)
    }
    
    

    // when the map gets a long press, it adds a waypoint.
    @IBAction func longPressAddWayPoint(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == UIGestureRecognizer.State.began {
            let touchPoint: CGPoint = gestureRecognizer.location(in: mapView)
            let newCoordinate: CLLocationCoordinate2D = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            addAnnotationOnLocation(pointedCoordinate: newCoordinate)
            
            // create the waypoint
            let wayPoint:DJIWaypoint = DJIWaypoint.init(coordinate: newCoordinate)
            // set the altitde, auto speed and max speed
            wayPoint.altitude = 50
            wayPoint.speed = 10
            // add the new waypoint
            if (CLLocationCoordinate2DIsValid(wayPoint.coordinate)) {
                mission.add(wayPoint)
            } else {
                print("Waypoint not valid")
            }
            
  
        }
    }
    
    // set the waypoint altitude, auto flight speed and max flight speed
    
    
    // after the waypoints are added to the map, it takes the coordinates and loads the mission, uploads the mission then starts it.
    @IBAction func runMission(_ sender: Any) {
        guard let missionControl = DJISDKManager.missionControl() else {
            showAlertViewWithTitle(title: "Error", withMessage: "Couldn't get mission control!")
            return
        }
        
        
//        // start the timeline
//        missionControl.startTimeline();
//        print("IsTimeLineRunning")
//        print(missionControl.isTimelineRunning)

        guard let missionOperator:DJIWaypointMissionOperator = missionControl.waypointMissionOperator() else {
            showAlertViewWithTitle(title: "Error", withMessage: "Couldn't get waypoint operator!")
            return
        }
        
        print("waypointCount: ", self.mission.waypointCount)
        
        // set the auto flight speed
        missionOperator.setAutoFlightSpeed(0.1, withCompletion: {(error:NSError?) -> () in

            if let speedError = error {
                DispatchQueue.main.async {
                    self.showAlertViewWithTitle(title: "Error setting auto flight speed", withMessage: speedError.localizedDescription)
                }
            } else {
                self.showAlertViewWithTitle(title: "Auto speed set successfully", withMessage: "good job")
            }

        } as? DJICompletionBlock)
        
        

        // "make sure the internal state of the mission plan is valid."
        if let err = mission.checkParameters() {
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

            //self.showAlertViewWithTitle(title: "Mission operator state:", withMessage: String(describing: (missionOperator.currentState.rawValue)))
            print("currentState.rawValue", missionOperator.currentState.rawValue)
            
            // load the mission
            if let loadErr = missionOperator.load(mission) {
                print(loadErr.localizedDescription)
                self.showAlertViewWithTitle(title: "Error loading mission", withMessage: loadErr.localizedDescription)
            } else {

                print("loaded mission: %@" , missionOperator.loadedMission)

                print("mission load: ", missionOperator.currentState)

                debugPrint("uploading...")
                // upload misssion to the product
                missionOperator.uploadMission(completion: {(error:Optional<Error>) -> () in

                    if let uploadErr = error {
                        self.debugPrint("upload failed")
                        DispatchQueue.main.async {
                            self.showAlertViewWithTitle(title: "Error uploading mission", withMessage: uploadErr.localizedDescription)
                        }
                    } else {
                        self.debugPrint("upload succeeded")
                        print("mission uploadMission: ", missionOperator.currentState)

                        // start the mission
                        self.debugPrint("starting...")
                        missionOperator.startMission(completion: {(error:Optional<Error>) -> () in

                            if let startErr = error {
                                // Getting 'Command cannot be executed'
                                self.debugPrint("start failed")
                                DispatchQueue.main.async {
                                    self.showAlertViewWithTitle(title: "Error starting mission", withMessage: startErr.localizedDescription)
                                }
                            } else {
                                self.debugPrint("start succeeded")
                                print("mission startMission: %@", missionOperator.currentState)

                                print("lastest Execution Progress: %@", missionOperator.latestExecutionProgress)
                            }

                        } as DJICompletionBlock)
                    }





                } as DJICompletionBlock)
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
    
    // show the message as a pop up window in the app
    func showAlertViewWithTitle(title:String, withMessage message:String ) {
        let alert:UIAlertController = UIAlertController(title:title, message:message, preferredStyle:UIAlertController.Style.alert)
        let okAction:UIAlertAction = UIAlertAction(title:"Ok", style:UIAlertAction.Style.`default`, handler:nil)
        alert.addAction(okAction)
        self.present(alert, animated:true, completion:nil)
    }
}
