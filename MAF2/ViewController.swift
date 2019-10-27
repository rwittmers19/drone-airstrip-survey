//
//  ViewController.swift
//  MAF2
//
//  Created by Admin on 9/29/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import UIKit
import DJISDK
import DJIWidget

class ViewController: UIViewController, DJISDKManagerDelegate, DJIVideoFeedListener,DJICameraDelegate {
    
    
    @IBOutlet var recordBtn: UIButton!
    @IBOutlet var changeWorkModeSegmentControl: UISegmentedControl!
    @IBOutlet var fpvPreviewView: UIView!
    
    @IBAction func captureAction(sender: AnyObject) {
    }
    
    
    @IBAction func recordAction(sender: AnyObject) {
    }
    
    
    @IBAction func changeWorkModeAction(sender: AnyObject) {
    }
    
    // the setUpVideoPreviewer
    func setupVideoPreviewer() {
        // variables
        DJIVideoPreviewer.instance().setView(self.fpvPreviewView)
        guard let product:DJIBaseProduct = DJISDKManager.product() else {return}
        
        if product.model == DJIAircraftModelNameA3 ||
            product.model == DJIAircraftModelNameN3 ||
            product.model == DJIAircraftModelNameMatrice600 ||
            product.model == DJIAircraftModelNameMatrice600Pro {
            DJISDKManager.videoFeeder()?.secondaryVideoFeed.add(self, with: nil)
        } else {
            DJISDKManager.videoFeeder()?.primaryVideoFeed.add(self, with: nil)
        }
        
        DJIVideoPreviewer.instance().start()
    }
    
    func resetVideoPreview() {
        DJIVideoPreviewer.instance().unSetView()
        guard let product:DJIBaseProduct = DJISDKManager.product() else {return}
        
        if product.model == DJIAircraftModelNameA3 ||
            product.model == DJIAircraftModelNameN3 ||
            product.model == DJIAircraftModelNameMatrice600 ||
            product.model == DJIAircraftModelNameMatrice600Pro {
            DJISDKManager.videoFeeder()?.secondaryVideoFeed.remove(self)
        } else {
            DJISDKManager.videoFeeder()?.primaryVideoFeed.remove(self)
        }
        
    }
    
    func fetchCamera() -> DJICamera? {
        if DJISDKManager.product() != nil {
            return nil
        }
        

        if let productKind = DJISDKManager.product(), productKind.isKind(of:DJIAircraft.self) {
            return (DJISDKManager.product() as? DJIAircraft)?.camera
        
        } else if let productKind2 = DJISDKManager.product(), productKind2.isKind(of:DJIHandheld.self) {
            return (DJISDKManager.product() as? DJIHandheld)?.camera
            
        }
        return nil
    }
    
    
    func productConnected(_ product:DJIBaseProduct?) {
        if let product = product {
            // as? is how to cast in Swift
            product.delegate = self as? DJIBaseProductDelegate;
            
            guard let camera:DJICamera = self.fetchCamera() else {return}
            // we dont need to check for nil as in the tutorial because of the 'guard let' above
            camera.delegate = self
            
            self.setupVideoPreviewer()
        }
    }
    
    func productDisconnected() {
        guard let camera:DJICamera = self.fetchCamera() else {return}
        if let delegate = camera.delegate, delegate === self {
            camera.delegate = nil;
        }
        self.resetVideoPreview()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard let camera:DJICamera = self.fetchCamera() else {return}
        if let delegate = camera.delegate, delegate === self {
            camera.delegate = nil
        }
        self.resetVideoPreview()
    }
    
    public func videoFeed(_ videoFeed: DJIVideoFeed, didUpdateVideoData videoData: Data) {
        var data2 = videoData
        data2.withUnsafeMutableBytes({ (data: UnsafeMutablePointer<UInt8>) in
            DJIVideoPreviewer.instance().push(data, length: Int32(videoData.count))

        })
    }
    
    func camera(_ camera: DJICamera, didUpdate systemState: DJICameraSystemState) {
    }
    
    
    // from the register app tutorial
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.registerApp()
    }
    

    func registerApp() {
        // let appKey: String =  "8f40318cb61307382126467b"
        DJISDKManager.registerApp(with : self)
    }
    
    public func didUpdateDatabaseDownloadProgress(_ progress: Progress) {
    }
    
    
    public func appRegisteredWithError(_ error: Error?) {
        var message:NSString = "Register App Successed!"
        if (error != nil) {
            message = "Register App Failed! Please enter your App Key and check the network."
        }
        else {
            NSLog("registerAppSuccess")
            DJISDKManager.startConnectionToProduct()
        }
        self.showAlertViewWIthTitle(title: "Register App", withMessage:message)
    }
    
    func showAlertViewWIthTitle(title:NSString, withMessage message:NSString ) {
        let alert:UIAlertController = UIAlertController(title:title as String, message:message as String, preferredStyle:UIAlertController.Style.alert)
        let okAction:UIAlertAction = UIAlertAction(title:"Ok", style:UIAlertAction.Style.`default`, handler:nil)
        alert.addAction(okAction)
        self.present(alert, animated:true, completion:nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}

