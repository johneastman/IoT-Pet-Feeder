//
//  SettingsViewController.swift
//  PetFeeder
//
//  Created by John Eastman on 4/4/19.
//  Copyright © 2019 John. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var perDayInput: UITextField!
    @IBOutlet weak var feederManualOverrideOutlet: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        saveSettings()
    }
    
    @IBAction func feedingaction(_ sender: UITextField) {
        print(perDayInput)
    }
    
    @IBAction func doneButton(_ sender: UIButton) {
        
        // Dismiss numberpad
        perDayInput.resignFirstResponder()
        
        saveSettings()
    }
    
    // Save the user's preferred settings
    func saveSettings() {
        let settings:[String:String] =
            ["times":  perDayInput.text!,
             "manual": feederManualOverrideOutlet.titleForSegment(at: feederManualOverrideOutlet.selectedSegmentIndex)!]
        
        // Save settings
        UserDefaults.standard.set(settings, forKey: "settings")
    }
}
