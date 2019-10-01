//
//  ViewController.swift
//  MAF2
//
//  Created by Admin on 9/29/19.
//  Copyright © 2019 Admin. All rights reserved.
//
// I connected xCode to the DJI SDK. The app displays a message that the app was registered succesfully!! -- Matt Klein

import UIKit
import DJISDK

class ViewController: UIViewController, DJISDKManagerDelegate {
    
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
        let alert:UIAlertController = UIAlertController(title:title as String, message:message as String, preferredStyle:UIAlertControllerStyle.alert)
        let okAction:UIAlertAction = UIAlertAction(title:"Ok", style:UIAlertActionStyle.`default`, handler:nil)
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

