//
//  WorkoutsViewController.swift
//  Cardiologic
//
//  Created by Ben Zimring on 8/21/18.
//  Copyright © 2018 pulseApp. All rights reserved.
//

import UIKit

class WorkoutsViewController: UIViewController {
    
    let workouts = ["workout1", "workout2", "workout3"]
    let cellSpacingHeight: CGFloat = 10
    
    @IBOutlet weak var workoutsTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func didTouchDoneButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension WorkoutsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return workouts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = workoutsTable.dequeueReusableCell(withIdentifier: "workoutCell")!
        cell.textLabel?.text = workouts[indexPath.section]
        cell.backgroundColor = .white
        cell.layer.borderColor = UIColor.black.cgColor
        cell.layer.borderWidth = 1
        cell.layer.cornerRadius = 8
        cell.clipsToBounds = true
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return cellSpacingHeight
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}
