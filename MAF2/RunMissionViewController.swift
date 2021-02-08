import UIKit
import DJISDK
import DJIWidget
import MapKit
import CoreLocation
import DJIUXSDK

class RunMissionViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // the states based on the raw values
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
    
    @IBOutlet weak var missionType: UIPickerView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var operatorStateLabel: UILabel!
    @IBOutlet weak var logTextView: UITextView!
    @IBOutlet weak var clearTheWaypoints: RoundButton!
    @IBOutlet weak var loadTheMission: RoundButton!
    @IBOutlet weak var startTheMission: RoundButton!
    var pickerData: [String] = [String]()
    var uiUpdateTimer: Timer!
    
    // lat and log variables
    var currentLat = 45.307067  // newberg ore
    var currentLong = -122.96015
    // the region of the map that's it automatically zoomed into.
    let regionRadius: CLLocationDistance = 200
    // the mission for the to add the waypoints to
    let mission:DJIMutableWaypointMission = DJIMutableWaypointMission.init()
    
    // to zoom in on user location
    var locationManager = CLLocationManager()
    
    // print out info to a text box inside the app
    func debugPrint(_ text: String) {
        DispatchQueue.main.async {
            //logTextField.text += text + "\n"
            self.logTextView.text = (self.logTextView.text ?? "") + text + "\n"
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        let initialLocation = CLLocation(latitude: currentLat, longitude: currentLong)
        centerMapOnLocation(location: initialLocation)
        //Hide the start button until the mission has loaded
        self.startTheMission.isHidden = true
        
        pickerData = ["Altitude: 50ft", "Altitude: 100ft", "Altitude: 200ft"]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Output the state to the app updating it every second
        uiUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {_ in
            guard let missionControl = DJISDKManager.missionControl() else { return }
            let missionOperator:DJIWaypointMissionOperator = missionControl.waypointMissionOperator()
            
            DispatchQueue.main.async {
                self.operatorStateLabel.text = String(format: "Operator State: %@",
                                                      self.operatorStateNames[missionOperator.currentState.rawValue])
            }
        })
        
        // Inform the user how to add a waypoint
        self.showAlertViewWithTitle(title: "Add waypoint", withMessage: "Long press the map where you want to add a waypoint.")
    }
    
    func mapView(_ mapview: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer!
    {
        if overlay is MKPolyline
        {
            let polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor.red
            polylineRenderer.lineWidth = 5
            return polylineRenderer
        }
        return nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        uiUpdateTimer.invalidate()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        let location: CLLocationCoordinate2D = manager.location?.coordinate ?? CLLocationCoordinate2D(latitude: 45.307067, longitude: -122.96015)
        currentLat = location.latitude
        currentLong = location.longitude
    }
    
    func centerOnLocation(_ sender: Any)
    {
        zoomUserLocation(locationManager)
        print("ran the damn function")
        let initialLocation = CLLocation(latitude: currentLat, longitude: currentLong)
        centerMapOnLocation(location: initialLocation)
    }
    
    // zoom the map in to the location that we choose. Right now it is hard coded for newberg OR
    func centerMapOnLocation(location: CLLocation) {
        print("spicy2")
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        print("spicy2")
        mapView.setRegion(coordinateRegion, animated: true)
        print("spicy2")

        // make that map satellite view
        mapView.mapType = MKMapType.satellite
    }

    
    func zoomUserLocation(_ manager: CLLocationManager) {
        print("spicy3")
        guard let currentLocation: CLLocationCoordinate2D = manager.location?.coordinate else {
            return
        }
        print("spicy3")
        currentLat = currentLocation.latitude
        currentLong = currentLocation.longitude
        print("spicy3")
        print(currentLat)

        mapView.setCenter(currentLocation, animated: true)
    }

    /* Adds a waypoint when the map gets a long press.
     A maximum of two waypoints can be added by the user. Later, the rest of the waypoints are added to fill in the rectangle. */
    @IBAction func longPressAddWayPoint(_ gestureRecognizer: UILongPressGestureRecognizer) {
        print("Starting longPressAddWayPoint()...")
        
        let MAX_WAYPOINT_NUM = 2
        
        if gestureRecognizer.state == UIGestureRecognizer.State.began
        {
            let touchPoint: CGPoint = gestureRecognizer.location(in: mapView)
            
            // a max of two waypoints are allowed. If they try to add another, print an error message
            if (mission.waypointCount < MAX_WAYPOINT_NUM)
            {
                let newCoordinate: CLLocationCoordinate2D = mapView.convert(touchPoint, toCoordinateFrom: mapView)
                
                // put a annotation on the map for the user
                addAnnotationOnLocation(pointedCoordinate: newCoordinate)
                
                // create the waypoint
                let wayPoint:DJIWaypoint = DJIWaypoint.init(coordinate: newCoordinate)
                // set the altitude, auto speed and max speed
                wayPoint.altitude = 50
                wayPoint.speed = 10
                // add the new waypoint
                if (CLLocationCoordinate2DIsValid(wayPoint.coordinate)) {
                    mission.add(wayPoint)
                } else {
                    print("Waypoint not valid")
                }
            }
            else
            {
            showAlertViewWithTitle(title: "Too many waypoints!", withMessage: "The waypoints you add are the two corners of the box. A max of two are allowed. If you want to adjust the location of the box, push the 'Clear the Waypoints' button and start again. Thanks.")
            }
        }
    }
    
    /* the user longPresses the screen to add two waypoints which are the ends
     of box. This method fills out the rest of the "box" shape automatically. The box has a predetermined
     width and the only thing the user can change is the length. As of now,
     if the user want to move the box, he must clear all the waypoints and start again. Make the runway approx. 60 meters wide.*/
    func addWaypointsInBoxShape(cornersOfBox: [DJIWaypoint]) {
        
        let x1 = cornersOfBox[0].coordinate.longitude
        let x2 = cornersOfBox[1].coordinate.longitude
        let y1 = cornersOfBox[0].coordinate.latitude
        let y2 = cornersOfBox[1].coordinate.latitude

        let numHorizontalPictures: Int = 3
        let numVerticalPictures: Int = 3

        let hSpace = (x2 - x1)/Double(numHorizontalPictures-1)
        let vSpace = (y2 - y1)/Double(numVerticalPictures-1)

        var xcoord: CLLocationDegrees
        var ycoord: CLLocationDegrees
        var newCoord = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        var coords: [CLLocationCoordinate2D] = []

        for i in 0...(numHorizontalPictures-1)
        {
            xcoord = x1 + Double(i) * hSpace
            for j in 0...(numVerticalPictures-1)
            {
                if (i % 2 == 0)
                {
                    ycoord = y1 + Double(j) * vSpace
                }
                else
                {
                    ycoord = y2 - Double(j) * vSpace
                }
                newCoord = CLLocationCoordinate2D(latitude: ycoord, longitude: xcoord)
                coords.append(newCoord)
                
                addAnnotationOnLocation(pointedCoordinate: newCoord, waypointName: String(i*numVerticalPictures + j))
                let waypoint: DJIWaypoint = DJIWaypoint.init(coordinate: newCoord)
                waypoint.altitude = 50
                waypoint.speed = 10
                mission.add(waypoint)
            }
        }
        let polyline: MKPolyline = MKPolyline.init(coordinates: coords, count: numHorizontalPictures*numVerticalPictures)
        mapView.addOverlay(polyline)
    }
    
    
    // clear all the waypoints from the mission
    @IBAction func clearTheWaypoints(_ sender: Any) {

        // get and remove all the annotations in the MKMapView
        let allAnnotation = mapView.annotations
        mapView.removeAnnotations(allAnnotation)
        // remove the waypoints from the mission
        mission.removeAllWaypoints()
    }
    
    // adds the waypoint symbol on the map
    func addAnnotationOnLocation(pointedCoordinate: CLLocationCoordinate2D, waypointName: String = "waypoint") {
        print("Starting addAnnotationOnLocation()...")
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = pointedCoordinate
        annotation.title = waypointName
        
        mapView.addAnnotation(annotation)
        
        
        print("... finished addAnnotationsOnLocation()")
    }
    

    
    // after the waypoints are added to the map, it takes the coordinates and loads the mission, uploads the mission then starts it.
    @IBAction func loadTheMission(_ sender: Any) {
        print("~~~~~\nStarting loadTheMission...")
        let MIN_WAYPOINT_NUM = 2
        print("spicy!")
        
//         once there are four waypoints, call the box method to add the others. if less than four, print message to add more
        if (mission.waypointCount < MIN_WAYPOINT_NUM) {
            showAlertViewWithTitle(title: "Two waypoints are required", withMessage: "You must add markers which are the corners of the box.")
        } else {
            // call the method to create a "box" shape of waypoints
            addWaypointsInBoxShape(cornersOfBox: mission.allWaypoints())
            showAlertViewWithTitle(title: "spicy", withMessage: "super spicy") // I moved the alert to after to only see this after the waypoints should've been calculated
            print("just finished addWaypointsInBoxShape()")
        }
        
        
        
        guard let missionControl = DJISDKManager.missionControl() else {
            showAlertViewWithTitle(title: "Error", withMessage: "Couldn't get mission control!")
            return
        }
        
        // set the heading mode, auto flight speed and max flight speed and the flightPathMode
        // when the mission is over, don't do anything.
        mission.headingMode = .auto
        mission.autoFlightSpeed = 2
        mission.maxFlightSpeed = 4
        mission.flightPathMode = .normal
        mission.finishedAction = DJIWaypointMissionFinishedAction.noAction

        guard let missionOperator:DJIWaypointMissionOperator = Optional(missionControl.waypointMissionOperator()) else {
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

            print("currentState.rawValue", missionOperator.currentState.rawValue)
            
            // load the mission
            if let loadErr = missionOperator.load(mission) {
                print(loadErr.localizedDescription)
                self.showAlertViewWithTitle(title: "Error loading mission", withMessage: loadErr.localizedDescription)
            } else {

                self.debugPrint(String(format: "loaded mission: %@" , missionOperator.loadedMission!))

                self.debugPrint(String(format: "mission load: %@", String(describing: missionOperator.currentState)))

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

                        // once this completes, prompt the user to start the mission
                        self.showAlertViewWithTitle(title: "Start the mission", withMessage: "Mash the 'Start the Mission' button")
                        
                        // reveal the button to the user
                        self.startTheMission.isHidden = false
                    }
                } as DJICompletionBlock)
            }
        }
        print("...Finished loadTheMission()")
    }
    // button to start the mission once it's loaded
    
    @IBAction func startTheMission(_ sender: Any) {
        // start the mission
        self.debugPrint("starting...")
        guard let missionControl = DJISDKManager.missionControl() else {
            showAlertViewWithTitle(title: "Error", withMessage: "Couldn't get mission control!")
            return
        }
        guard let missionOperator:DJIWaypointMissionOperator = Optional(missionControl.waypointMissionOperator()) else {
            showAlertViewWithTitle(title: "Error", withMessage: "Couldn't get waypoint operator!")
            return
        }
    
        
        
        missionOperator.startMission(completion: {(error:Optional<Error>) -> () in
            if let startErr = error {
                // Getting 'Command cannot be executed'
                self.debugPrint("start failed")
                self.debugPrint(startErr.localizedDescription)
                DispatchQueue.main.async {
                    self.showAlertViewWithTitle(title: "Error starting mission", withMessage: startErr.localizedDescription)
                }
            } else {
                self.debugPrint("start succeeded")
                print("mission startMission: %@", missionOperator.currentState)
                print("lastest Execution Progress: %@", missionOperator.latestExecutionProgress)
            
                
                
                // send the drone home after the mission is finished
                self.mission.finishedAction = .goHome
            }
        } as DJICompletionBlock)
    }
    

    
    // show the message as a pop up window in the app
    func showAlertViewWithTitle(title:String, withMessage message:String ) {
        print("Starting showAlertViewWithTitle()...")
        
        let alert:UIAlertController = UIAlertController(title:title, message:message, preferredStyle:UIAlertController.Style.alert)
        let okAction:UIAlertAction = UIAlertAction(title:"Ok", style:UIAlertAction.Style.`default`, handler:nil)
        alert.addAction(okAction)
        self.present(alert, animated:true, completion:nil)
        print("...Finished showAlertWithTitle()")
    }
}
