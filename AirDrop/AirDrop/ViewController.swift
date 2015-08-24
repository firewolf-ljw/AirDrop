//
//  ViewController.swift
//  AirDrop
//
//  Created by  lifirewolf on 15/8/17.
//  Copyright (c) 2015年  lifirewolf. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.displayName.delegate = self
        
        self.displayName.text = UIDevice.currentDevice().name
        
    }

    @IBOutlet weak var displayName: UITextField!

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "play"  {
            if let vc = segue.destinationViewController as? ADViewController {
                vc.myPeerId = MCPeerID(displayName: self.displayName.text)
                vc.modalTransitionStyle = UIModalTransitionStyle.FlipHorizontal
            }
        }
    }
    
}

extension ViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.displayName.resignFirstResponder()
        return true
    }
    
}