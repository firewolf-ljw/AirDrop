//
//  ADViewController.swift
//  AirDrop
//
//  Created by  lifirewolf on 15/8/17.
//  Copyright (c) 2015年  lifirewolf. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ADViewController: UIViewController {

    let serviceType = "fw-service"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.myPeerId == nil {
            self.myPeerId = MCPeerID(displayName: "not known")
        }
        
        self.displayName.text = self.myPeerId.displayName
        self.targitName.text = nil
        self.connBtn.enabled = false
//        self.sendBtn.enabled = false
        
        self.sendMsg.delegate = self
        self.receivedMsg.delegate = self
        
        self.targitsTB.dataSource = self
        self.targitsTB.delegate = self
        
        self.browser = MCNearbyServiceBrowser(peer: self.myPeerId, serviceType: self.serviceType)
        self.browser.delegate=self
        
        self.session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.Required)
        self.session.delegate = self
        
//        NSLog(@"ViewController :: viewDidLoad (Starting Browse)");
        
//        self.browser.startBrowsingForPeers()
        
//        NSLog(@"ViewController :: launch (Starting Advertise)");
        
        let dic = ["k1": "v1", "k2": "v2"]
        
        self.advertiser = MCNearbyServiceAdvertiser(peer: self.myPeerId, discoveryInfo: dic, serviceType: self.serviceType)
        self.advertiser.delegate = self
        
//        self.advertiser.startAdvertisingPeer()
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        println("view Will Disappear")
        
        if let session = self.session {
            session.disconnect()
        }
        
        if let browser = self.browser {
            browser.stopBrowsingForPeers()
        }
        
        if let advertiser = self.advertiser {
            advertiser.stopAdvertisingPeer()
        }
        
    }
    
    @IBOutlet weak var displayName: UILabel!
    @IBOutlet weak var targitsTB: UITableView!
    @IBOutlet weak var targitName: UILabel!
    @IBOutlet weak var sendMsg: UITextView!
    @IBOutlet weak var receivedMsg: UITextView!
    @IBOutlet weak var connBtn: UIButton!
    @IBOutlet weak var sendBtn: UIButton!
    
    var endEditTap: UITapGestureRecognizer!
    
    var targits = [MCPeerID]()
    
    var myPeerId: MCPeerID!
    var session: MCSession!
    var browser: MCNearbyServiceBrowser!
    var advertiser: MCNearbyServiceAdvertiser!
    
    var targitPeerId: MCPeerID! {
        didSet {
            if self.targitPeerId == nil {
                self.connBtn.enabled = false
            } else {
                self.connBtn.enabled = true
                if let lab = self.targitName {
                    lab.text = self.targitPeerId.displayName
                }
            }
        }
    }
    
    func reset() {
        self.targitPeerId = nil
        self.targitName.text = nil
        self.connBtn.enabled = false
//        self.sendBtn.enabled = false
    }
    
    @IBAction func refresh(sender: AnyObject) {

        self.targits.removeAll(keepCapacity: false)
        self.targitsTB.reloadData()
        
        reset()
        
        self.advertiser.stopAdvertisingPeer()
        self.browser.stopBrowsingForPeers()
        self.browser.startBrowsingForPeers()
        self.advertiser.startAdvertisingPeer()
        
    }
    
    @IBAction func connPeer(sender: AnyObject) {
    
        if let targit = self.targitPeerId {
            
            self.browser.invitePeer(targit, toSession: self.session, withContext: "fw".dataUsingEncoding(NSUTF8StringEncoding), timeout: 10)
            
            self.advertiser.startAdvertisingPeer()
        }
    }
    
    @IBAction func sendData(sender: AnyObject) {
    
        if self.targitPeerId != nil {
            let data = self.sendMsg.text.dataUsingEncoding(NSUTF8StringEncoding)
            
    //        let data = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("1", ofType: "jpg")!)
            
            println("sended data: \(data!.length)")
            
            let rst = self.session.sendData(data!, toPeers: [self.targitPeerId], withMode: MCSessionSendDataMode.Reliable, error: nil)
            
            if rst {
                println("send data succeed")
            } else {
                println("send data failed")
            }
        }
    }
    
}

extension ADViewController: MCSessionDelegate {

    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
        
//        println("reseived data: \(data.length)")
        
        if let msg = NSString(data: data, encoding: NSUTF8StringEncoding) {
        
            dispatch_async(dispatch_get_main_queue()) {
                self.receivedMsg.text = "\(msg)"
            }
            
        }
    }
    
    func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState) {
        
        println("MCSessionDelegate -- didChangeState -- PeerId: \(peerID) changed to state: \(state)")
        
        dispatch_async(dispatch_get_main_queue()) {
            var title = "连接设备"
            var alert: UIAlertController? = nil
            if state == MCSessionState.Connected {
                
                let msg = "成功连接上: \(peerID.displayName)"
                alert = UIAlertController(title: title, message: msg, preferredStyle: UIAlertControllerStyle.Alert)
//                if self.connBtn.enabled {
//                    self.sendBtn.enabled = true
//                }
            } else if state == MCSessionState.NotConnected {
                
                let msg = "未能连接上: \(peerID.displayName)"
                alert = UIAlertController(title: title, message: msg, preferredStyle: UIAlertControllerStyle.Alert)
                self.sendBtn.enabled = false
            } else {
                println(state)
            }
            
            if alert != nil {
                alert!.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert!, animated: true, completion: nil)
            }
        }
    }
    
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) {
        println("Received a byte stream from remote peer")
    }
    
    func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) {
        println("Start receiving a resource from remote peer")
    }
    
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {
        println("Finished receiving a resource from remote peer and saved the content in a temporary location - the app is responsible for moving the file to a permanent location within its sandbox")
    }

}


extension ADViewController: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!) {
        
        println("MCNearbyServiceAdvertiserDelegate -- didReceiveInvitationFromPeer -- peerId: \(peerID)")
        
        let alert = UIAlertController(title: "通知", message: "\(peerID.displayName) 请求连接", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {action in invitationHandler(true, self.session); }))
        alert.addAction(UIAlertAction(title: "NO", style: UIAlertActionStyle.Default, handler: {action in invitationHandler(false, self.session); }))
        
        self.presentViewController(alert, animated: true, completion: nil)
        
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didNotStartAdvertisingPeer error: NSError!) {
        println("Advertising did not start due to an error: \(error)")
    }
    
}

extension ADViewController: MCNearbyServiceBrowserDelegate {
    
    // Found a nearby advertising peer
    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
        println("MCNearbyServiceABrowserDelegate -- foundPeer -- PeerID: \(peerID) , DiscoveryInfo: \(info.description)")
        
        println("\(browser.serviceType)")
        
        var flag = false
        
        for (i, p) in enumerate(targits) {
            if p == peerID {
                flag = true
            }
        }
        
        if !flag {
            println("add peer: \(peerID)")
            self.targits.append(peerID)
        }
        
        self.targitsTB.reloadData()
    }
    
    // A nearby peer has stopped advertising
    func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!) {
        println("MCNearbyServiceABrowserDelegate -- lostPeer -- PeerID: \(peerID)")
        
        for (i, p) in enumerate(targits) {
            if p == peerID {
                targits.removeAtIndex(i)
                break
            }
        }
        
        self.targitsTB.reloadData()
        
        if let targit = self.targitPeerId {
            if targit == peerID {
                reset()
            }
        }
    }
    
    func browser(browser: MCNearbyServiceBrowser!, didNotStartBrowsingForPeers error: NSError!) {
        println("Browsing did not start due to an error: \(error)")
    }
    
}


// MARK: -- table view

extension ADViewController: UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.targits.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let item = targits[indexPath.row]
        
        let cell = tableView.dequeueReusableCellWithIdentifier("targit") as! UITableViewCell
        
        cell.textLabel?.text = item.displayName
        
        return cell
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "可连接设备"
    }
    
}

extension ADViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.targitPeerId = targits[indexPath.row]
    }
    
}


// MARK: -- text view

extension ADViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(textView: UITextView) {
        println("begin editing")
        self.beginEdit()
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        println("end editing")
    }
    
    func textViewDidChange(textView: UITextView) {
        println("did change")
    }
    
    func beginEdit() {
        
        self.endEditTap = UITapGestureRecognizer(target: self, action: "endEdit")
        self.view.addGestureRecognizer(self.endEditTap)
    }
    
    func endEdit() {
        self.sendMsg.resignFirstResponder()
        
        if let tap = self.endEditTap {
            self.view.removeGestureRecognizer(tap)
        }
    }
}

