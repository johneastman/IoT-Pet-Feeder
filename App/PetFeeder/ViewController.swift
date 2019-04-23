//
//  ViewController.swift
//  PetFeeder
//
//  Created by John Eastman on 3/22/19.
//  Copyright © 2019 John. All rights reserved.
//

import UIKit
import CocoaMQTT

// Error handling.
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
        didSet { // Handle events when 'numTimesFed' is updated.
            numTimesFedLabel.text = "\(numTimesFed)"

            // When this number is equal to max number of feedings (specified in the settings), disable
            // the feeder.
            if numTimesFed >= Int(getSetting(key: "times"))! {
                publish(messageText: "Off", topicDescription: "override")
            }
        }
    }

    var topics:[String:String]? // All topics supported by the client.

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure feedPetButton
        feedPetButton.layer.cornerRadius = feedPetButton.bounds.size.height / 2

        // Configure numTimesFedLabel
        numTimesFedLabel.text = "\(numTimesFed)"

        // Setup MQTT client
        mqtt = CocoaMQTT(clientID: "Jackson", host: server, port: port)
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
        // This publishes the status of the proximity sensor when the user exits the settings. If the user
        // chooses to disable the sensor, the feeder will not be activated when the pet comes into range.
        // NOTE: We have to check if the client is connected first because when the app first starts, the
        // client has not been connected yet; without checking first, the app does not work.
        if isConnected {
            let manualOverrideStatus:String = getSetting(key: "manual")
            if manualOverrideStatus != "" {
                publish(messageText: manualOverrideStatus, topicDescription: "override")
            } else {
                // Default to off if the settings cannot be retrieved
                publish(messageText: "Off", topicDescription: "override")
            }
        }
    }


    @IBAction func feedPetButtonAction(_ sender: UIButton) {

        // Disable button while feeder is active
        feedPetButton.alpha = 0.5
        feedPetButton.isEnabled = false
        feedPetButton.isUserInteractionEnabled = false

        // Feed your pet!
        if !feedPet() {
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
    }


    // Logic for feeding pet. Returns true if the pet was successfully fed; returns false otherwise.
    func feedPet() -> Bool {

        let numTimesToFeed:Int = Int(getSetting(key: "times"))!

        // If the number of times the pet can be fed in one day is less than the number of times the pet has
        // been fed, allow the pet to be fed.
        if numTimesFed < numTimesToFeed {
            publish(messageText: "Feeding your pet", topicDescription: "manual")

            // Increase the number of times your pet has been fed.
            numTimesFed += 1
        } else {
            presentAlert(title: "Alert", message: "You cannot feed your pet any more times today. To change this, navigate to the settings tab.")

            return false
        }
        return true
    }


    // Retrieve a topic from 'topics.plist'.
    func getTopic(topicDescription:String) throws -> String {

        if let topics = self.topics, let topic = topics[topicDescription] {
            return topic
        }
        throw MQTTError.invalidTopic(topicDescription: topicDescription)
    }


    // Return a specific value from the settings. Returns an empty string if the settings or specific
    // setting cannot be retrieved.
    func getSetting(key:String) -> String {

        guard let settings = loadSettings() else {
            return ""
        }

        guard let value = settings[key] else {
            return ""
        }

        return value
    }


    // Load settings from UserDefaults
    func loadSettings() -> [String:String]? {
        guard let settings = UserDefaults.standard.dictionary(forKey: "settings") as? [String: String] else {
            return nil
        }
        return settings
    }


    // Publish a message
    func publish(messageText:String, topicDescription:String) {

        do {
            let topic = try getTopic(topicDescription: topicDescription)

            let message:CocoaMQTTMessage = CocoaMQTTMessage(topic: topic, string: messageText)
            mqtt.publish(message)
        } catch {
            presentAlert(title: "Error", message: "Unable to publish to topic \(topicDescription)")
        }
    }


    // Present an alert
    func presentAlert(title:String, message:String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
    }


    // Subscribe to a topic.
    // This function takes a topic description, which is mapped to an actual topic. All topics can be
    // found in 'topics.plist'.
    func subscribe(topicDescription:String) {
        do {
            let topic = try getTopic(topicDescription: topicDescription)
            print(topic)
            mqtt.subscribe(topic)
        } catch {
            // Present an alert if the desired topic cannot be subscribed to.
            presentAlert(title: "Error", message: "Unable to subscribe to \(topicDescription)")
        }
    }
}


// Unused functions required for view controller to conform to MQTT protocol
extension ViewController: CocoaMQTTDelegate {

    func mqtt(_ mqtt: CocoaMQTT, didConnect host: String, port: Int) {
    }

    // Handles published messages that are received.
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {

        do {
            switch message.topic {
            case try getTopic(topicDescription: "proximity_feedling"):
                // When the pet feeds itself, update the number of times the pet was fed.
                let _ = feedPet()
            case try getTopic(topicDescription: "feeding"):
                // Re-enable the button once the pet has been fed
                feedPetButton.alpha = 1
                feedPetButton.isEnabled = true
                feedPetButton.isUserInteractionEnabled = true
            default:
                break
            }
        } catch {
            // Present alert if an error occurs
            presentAlert(title: "Alert", message: error.localizedDescription)
        }
    }

    func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }

    // Client connection acknowledgement
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {

        // Subscribe to topics that publish from the server
        subscribe(topicDescription: "proximity_feedling")
        subscribe(topicDescription: "feeding")

        // Set connection status to true
        isConnected = true
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
