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
    let regionRadius: CLLocationDistance = 200
    var count = 0;
//    var wayPoint:DJIWaypoint
//    var mission:DJIMutableWaypointMission
//    var missionOperator:DJIWaypointMissionOperator?
    
    
    
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
            
            guard let mission1:DJIMutableWaypointMission = DJIMutableWaypointMission.init() else {
                return
            }
            guard let wayPoint2:DJIWaypoint = DJIWaypoint.init(coordinate: newCoordinate) else {
                return
            }
            
            guard let missionOperator:DJIWaypointMissionOperator = DJIWaypointMissionOperator.init() else {
                return
            }
            
            // add the new waypoint
            mission1.add(wayPoint2)
            count+=1

            if (count > 1) {
                // "make sure the internal state of the mission plan is valid."
                mission1.checkParameters()
                
                // load the mission
                missionOperator.load(mission1)
                
                // upload misssion to the product
                missionOperator.uploadMission(completion: {(error:NSError) -> () in
                    } as? DJICompletionBlock)
                
                //start the mission
                missionOperator.startMission(completion: {(error:NSError) -> () in
                    } as? DJICompletionBlock)
            }
        }
    }
    

    @IBAction func runMission(_ sender: Any) {
        
        
    }
    
    func addAnnotationOnLocation(pointedCoordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = pointedCoordinate
        annotation.title = "waypoint"
        mapView.addAnnotation(annotation)
    }
}
