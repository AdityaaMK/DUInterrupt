//
//  SettingsTableViewController.swift
//  Cardiologic
//
//  Created by Ben Zimring on 8/16/18.
//  Copyright © 2018 pulseApp. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {
    
    // About section cells
    @IBOutlet weak var settingsNameCell: UITableViewCell!
    
    // Physical section cells
    @IBOutlet weak var settingsHeightCell: UITableViewCell!
    @IBOutlet weak var settingsWeightCell: UITableViewCell!
    @IBOutlet weak var settingsGenderCell: UITableViewCell!
    
    // About section cell elements
    @IBOutlet weak var nameTextField: UITextField!
    
    // Physical section cell elements
    @IBOutlet weak var heightFeetTextField: UITextField!
    @IBOutlet weak var heightInchesTextField: UITextField!
    @IBOutlet weak var weightTextField: UITextField!
    @IBOutlet weak var maleButton: UIButton!
    @IBOutlet weak var femaleButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameCellSetup()
        heightCellSetup()
        addHeightDoneButton()
        weightCellSetup()
        addWeightDoneButton()
        genderCellSetup()
        
        heightFeetTextField.addTarget(self, action: #selector(heightFeetTextFieldDidChange), for: .editingChanged)
        heightInchesTextField.addTarget(self, action: #selector(heightInchesTextFieldDidChange), for: .editingChanged)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 3
        default: return 0
        }
    }
    

    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func nameCellSetup() {
        settingsNameCell.selectionStyle = .none
        nameTextField.placeholder = UserDefaults.standard.string(forKey: "userName")
    }
    
    func heightCellSetup() {
        settingsHeightCell.selectionStyle = .none
        let inches = UserDefaults.standard.integer(forKey: "userHeight")
        let ft = inches/12
        let r = inches%12
        heightFeetTextField.placeholder = "\(ft)"
        heightInchesTextField.placeholder = "\(r)"
    }
    
    func weightCellSetup() {
        let weight = UserDefaults.standard.integer(forKey: "userWeight")
        weightTextField.placeholder = "\(weight)"
    }
    
    func genderCellSetup() {
        settingsGenderCell.selectionStyle = .none
        maleButton.imageView?.tintColor = .black
        femaleButton.imageView?.tintColor = .black
        let gender = UserDefaults.standard.string(forKey: "userGender")!
        switch gender {
        case "Male":
            maleButton.setImage(UIImage(named: "male_filled")!, for: .normal)
            femaleButton.setImage(UIImage(named: "female_unfilled")!, for: .normal)
            maleButton.isMultipleTouchEnabled = false
        case "Female":
            maleButton.setImage(UIImage(named: "male_unfilled")!, for: .normal)
            femaleButton.setImage(UIImage(named: "female_filled")!, for: .normal)
            femaleButton.isMultipleTouchEnabled = false
        default:
            maleButton.setImage(UIImage(named: "male_unfilled")!, for: .normal)
            femaleButton.setImage(UIImage(named: "female_unfilled")!, for: .normal)
        }
    }

}

// MARK: - text field delegation
extension SettingsTableViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("textFieldShouldReturn")
        textField.resignFirstResponder()
        
        if textField.restorationIdentifier == "NameTextField" {
            if textField.text != "" {
                guard let oldName = UserDefaults.standard.string(forKey: "userName") else { return false }
                guard let newName = textField.text else { return false }
                UserDefaults.standard.set(newName, forKey: "userName")
                NSLog("changed userName from \(oldName) to \(newName)")
                
                // clear textfield, add changed info
                textField.text = ""
                textField.placeholder = newName
                return true
            }
            // TODO: post notification for UI
        }
        
        if textField.restorationIdentifier == "HeightInchesTextField" {
            var newInches = 0
            
            // start with ft (if changed)
            if heightFeetTextField.text == "" {
                newInches = Int(heightFeetTextField.placeholder!)!*12
            } else {
                newInches = Int(heightFeetTextField.text!)!*12
            }
            
            // add on the remainder
            if heightInchesTextField.text == "" {
                // use the placeholder
                newInches += Int(heightInchesTextField.placeholder!)!
            } else {
                newInches += Int(heightInchesTextField.text!)!
            }
            
            // check if in normal human bounds
            if !(50...85).contains(newInches) {
                heightFeetTextField.text = ""
                heightInchesTextField.text = ""
                heightCellSetup()
                return false
            }
            
            let oldInches = UserDefaults.standard.integer(forKey: "userHeight")
            if newInches == oldInches { return false}
            UserDefaults.standard.set(newInches, forKey: "userHeight")
            NSLog("changed userHeight from \(oldInches)in to \(newInches)in")
            
            // clear textfields, add changed info
            heightFeetTextField.text = ""
            heightInchesTextField.text = ""
            
            let newFt = newInches/12
            let newR = newInches%12
            heightFeetTextField.placeholder = "\(newFt)"
            heightInchesTextField.placeholder = "\(newR)"
        }
        
        if textField.restorationIdentifier == "WeightTextField" {
            if weightTextField.text == "" { return false }
            let oldWeight = UserDefaults.standard.integer(forKey: "userWeight")
            let newWeight = Int(weightTextField.text!)!
            
            if oldWeight == newWeight { return false }
            UserDefaults.standard.set(newWeight, forKey: "userWeight")
            NSLog("Changed userWeight from \(oldWeight)lbs to \(newWeight)lbs")
            
            // clear textfield, add changed info
            weightTextField.text = ""
            weightTextField.placeholder = "\(newWeight)"
            return true
        }
        return true
    }
    
    func addHeightDoneButton() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 20))
        doneToolbar.barStyle = .default
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target: self, action: #selector(heightDoneButton))
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        // add the bar to these elements
        self.heightFeetTextField.inputAccessoryView = doneToolbar
        self.heightInchesTextField.inputAccessoryView = doneToolbar
    }
    
    func addWeightDoneButton() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 20))
        doneToolbar.barStyle = .default
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target: self, action: #selector(weightDoneButton))
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        // add the bar to these elements
        self.weightTextField.inputAccessoryView = doneToolbar
    }
    
    @objc func heightDoneButton() {
        let _ = textFieldShouldReturn(heightFeetTextField)
        let _ = textFieldShouldReturn(heightInchesTextField)
    }
    
    @objc func weightDoneButton() {
        let _ = textFieldShouldReturn(weightTextField)
    }
    
    @objc func heightFeetTextFieldDidChange() {
        if heightFeetTextField.text != "" {
            if (4...7).contains(Int(heightFeetTextField.text!)!) {
                heightInchesTextField.becomeFirstResponder()
            }
        }
    }
    
    @objc func heightInchesTextFieldDidChange() {
        if heightInchesTextField.text != "" {
            if heightInchesTextField.text?.count == 2 {
                heightDoneButton()
            }
        }
    }
}

// MARK: - gender selection
extension SettingsTableViewController {
    
    @IBAction func didSelectMale(_ sender: Any) {
        UserDefaults.standard.set("Male", forKey: "userGender")
        NSLog("changed userGender from Female to Male")
        
        // unselect female button
        DispatchQueue.main.async {
            UIView.transition(with: self.femaleButton.imageView!, duration: 0.2, options: .transitionCrossDissolve, animations: {
                let newImage = UIImage(named: "female_unfilled")!
                self.femaleButton.imageView?.image = newImage
            })
        }
        
        // select male button
        DispatchQueue.main.async {
            UIView.transition(with: self.maleButton.imageView!, duration: 0.2, options: .transitionCrossDissolve, animations: {
                let newImage = UIImage(named: "male_filled")!
                self.maleButton.imageView?.image = newImage
            })
        }
        maleButton.isMultipleTouchEnabled = false
        femaleButton.isMultipleTouchEnabled = true
        
    }
    
    @IBAction func didSelectFemale(_ sender: Any) {
        UserDefaults.standard.set("Female", forKey: "userGender")
        NSLog("changed userGender from Male to Female")
        
        // unselect male button
        DispatchQueue.main.async {
            UIView.transition(with: self.maleButton.imageView!, duration: 0.2, options: .transitionCrossDissolve, animations: {
                let newImage = UIImage(named: "male_unfilled")!
                self.maleButton.imageView?.image = newImage
            })
        }
        
        // select female button
        DispatchQueue.main.async {
            UIView.transition(with: self.femaleButton.imageView!, duration: 0.2, options: .transitionCrossDissolve, animations: {
                let newImage = UIImage(named: "female_filled")!
                self.femaleButton.imageView?.image = newImage
            })
        }
        femaleButton.isMultipleTouchEnabled = false
        maleButton.isMultipleTouchEnabled = true
    }
}
