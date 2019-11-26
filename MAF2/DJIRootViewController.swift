import UIKit
import DJISDK
import DJIWidget
import MapKit

class DJIRootViewController: UIViewController {
    // lat and log variables
    let currentLat = 45.307067  // newberg ore
    let currentLong = -122.96015
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let initialLocation = CLLocation(latitude: currentLat, longitude: currentLong)
        centerMapOnLocation(location: initialLocation)
    }
    
    let regionRadius: CLLocationDistance = 200
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
                                                  latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
        // make that map satellite view
        mapView.mapType = MKMapType.satellite
    }
}
