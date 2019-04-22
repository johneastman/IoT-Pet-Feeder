//
//  ViewController.swift
//  PetFeeder
//
//  Created by John Eastman on 3/22/19.
//  Copyright © 2019 John. All rights reserved.
//

import UIKit
import CocoaMQTT

public enum MQTTError: Error, LocalizedError {
    
    case invalidTopic(topicDescription: String)
    case invalidFilename(filename:String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidTopic(let topicDescription):
            return "No topics associated with: \(topicDescription)."
        case .invalidFilename(let filename):
            return "Unable to open file: \(filename)"
        }
    }
}


class ViewController: UIViewController {
    
    @IBOutlet weak var numTimesFedLabel: UILabel!
    
    @IBOutlet weak var feedPetButton: UIButton!
    
    var mqtt:CocoaMQTT!
    
    var isConnected:Bool = false
    
    let feeder:Feeder = Feeder()
    
    let username:String = "bnnawkvq"
    let password:String = "es5Z7ceUhB65"
    let server:String = "m16.cloudmqtt.com"
    let port:UInt16 = 15055
    
    var numTimesFed:Int = 0 {
        didSet {
            numTimesFedLabel.text = "\(numTimesFed)"
        }
    }
    
    var topics:[String:String]?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure feedPetButton
        feedPetButton.layer.cornerRadius = feedPetButton.bounds.size.height / 2
        
        // Configure numTimesFedLabel
        numTimesFedLabel.text = "\(numTimesFed)"
        
        // Setup mqtt client
        let clientID = "CocoaMQTT-" + String(ProcessInfo().processIdentifier)
        
        mqtt = CocoaMQTT(clientID: clientID, host: server, port: port)
        mqtt.username = username
        mqtt.password = password
        mqtt.willMessage = CocoaMQTTWill(topic: "/will", message: "dieout")
        mqtt.keepAlive = 60
        mqtt.delegate = self
        mqtt.connect()
        
        // Load topics from topics.plist
        if let path = Bundle.main.path(forResource: "topics", ofType: "plist") {
            topics = NSDictionary(contentsOfFile: path) as? [String:String]
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if isConnected {
            if let settings = loadSettings() {
                guard let manualOverride = settings["manual"] else {
                    return
                }
                publish(messageText: manualOverride, topic: "feeder/override")
            } else {
                publish(messageText: "On", topic: "feeder/override")
            }
        }
    }
    
    @IBAction func feedPetButtonAction(_ sender: UIButton) {
        
        // Disable button while feeder is active
        feedPetButton.alpha = 0.5
        feedPetButton.isEnabled = false
        feedPetButton.isUserInteractionEnabled = false
        
        // Get information from settings to check whether the user can feed their pet today.
        guard let settings = loadSettings() else {
            
            // Re-enable button while feeder is active
            feedPetButton.alpha = 1
            feedPetButton.isEnabled = true
            feedPetButton.isUserInteractionEnabled = true
            
            self.tabBarController?.selectedIndex = 1
            presentAlert(title: "Settings Alert", message: "Please set your prefered setting before proceeding")
            return
        }
        
        guard let numTimesToFeed = settings["times"] else {
            return
        }
        
        print(numTimesToFeed)
        
        if numTimesFed < Int(numTimesToFeed)! {
            do {
                // Feed pet manually
                let topic = try getTopic(topicDescription: "manual")
                publish(messageText: "Feeding your pet", topic: topic)
            } catch {
                presentAlert(title: "Alert", message: error.localizedDescription)
            }
            
            // Increase the number of times your pet has been fed.
            numTimesFed += 1
        } else {
            presentAlert(title: "Alert", message: "You cannot feed your pet any more times today. To change this, navigate to the settings tab.")
            
            // Re-enable button while feeder is active
            feedPetButton.alpha = 1
            feedPetButton.isEnabled = true
            feedPetButton.isUserInteractionEnabled = true
        }
    }
    
    
    func getTopic(topicDescription:String) throws -> String {
        
        if let topics = self.topics, let topic = topics[topicDescription] {
            return topic
        }
        throw MQTTError.invalidTopic(topicDescription: topicDescription)
    }
    
    
    func publish(messageText:String, topic:String) {
        let message:CocoaMQTTMessage = CocoaMQTTMessage(topic: topic, string: messageText)
        mqtt.publish(message)
    }
    
    func presentAlert(title:String, message:String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    // Load settings from UserDefaults
    func loadSettings() -> [String:String]? {
        guard let settings = UserDefaults.standard.dictionary(forKey: "settings") as? [String: String] else {
            return nil
        }
        return settings
    }
}


extension ViewController: CocoaMQTTDelegate {
    func mqtt(_ mqtt: CocoaMQTT, didConnect host: String, port: Int) {
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        
        do {
            switch message.topic {
            case try getTopic(topicDescription: "proximity_feedling"):
                numTimesFed += 1
            case try getTopic(topicDescription: "feeding"):
                feedPetButton.alpha = 1
                feedPetButton.isEnabled = true
                feedPetButton.isUserInteractionEnabled = true
            default:
                break
            }
        } catch {
            presentAlert(title: "Alert", message: error.localizedDescription)
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        
        do {
            // Subscribe to topics that publish from the server
            var topic = try getTopic(topicDescription: "proximity_feedling")
            mqtt.subscribe(topic)
            
            topic = try getTopic(topicDescription: "feeding")
            mqtt.subscribe(topic)
            
            // Set connection status
            isConnected = true
        } catch {
            // ERROR
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
    }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
    }
    
    func _console(_ info: String) {
    }
}

