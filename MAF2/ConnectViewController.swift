import Foundation
import UIKit
import DJISDK

class ConnectViewController: UIViewController {
    
    @IBOutlet weak var couldNotConnect: UILabel!
    @IBOutlet weak var retryButton: UIButton!
    
    override func viewDidLoad() {
        // hide the button until needed
        couldNotConnect.isHidden = true
        retryButton.isHidden = true
        
        // if the app is registered correctly, move on the the home page
        retry(self)
    }
    
    @IBAction func retry(_ sender: Any) {
        DroneControl.setup(completion: {(success:Bool) -> Void in
            if success {
                self.performSegue(withIdentifier: "toMainMenu", sender: nil)
            } else {
                // if the app doesn't connect, show a message and a button to try again
                self.couldNotConnect.isHidden = false
                self.retryButton.isHidden = false
            }
        })
    }
    
    
}
