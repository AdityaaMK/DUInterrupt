//
//  TabBarViewController.swift
//  Cardiologic
//  Encapsulating VC with tabs to each part of application (dashboard, metrics, etc..)
//
//  Created by Ben Zimring on 7/18/18.
//  Copyright © 2018 pulseApp. All rights reserved.
//

import UIKit
import FlexTabBar

class TabBarViewController: WKTabBarController {
    var dashboardViewController: UIViewController?
    var trendsViewController: UIViewController?
    var statsViewController: UIViewController?
    var settingsViewController: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        register(cell: WKTabBarImageLabelCell.self, withName: WKTabBarCellNameImageLabel)
        // Do any additional setup after loading the view.
        tabBarItems = [
            WKTabBarItem(title: "Dashboard", image: UIImage(named: "dashboard_icon")!, selected: UIImage(named: "dashboard_icon_selected")!),
            WKTabBarItem(title: "Trends", image: UIImage(named: "metrics_icon")!, selected: UIImage(named: "metrics_icon_selected")!),
            WKTabBarItem(title: "Statistics", image: UIImage(named: "stats_icon")!, selected: UIImage(named: "stats_icon_selected")!),
            WKTabBarItem(title: "Settings", image: UIImage(named: "settings-icon")!, selected: UIImage(named: "settings-icon-selected")!)
        ]
        
        trendsViewController = storyboard?.instantiateViewController(withIdentifier: "TrendsViewController")
        let _ = trendsViewController?.view // preload trends (lots of querying)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func commonInit() {
        super.commonInit()
    }
    
    override func tabBarController(_ controller: WKTabBarController, customize cell: WKBaseTabBarCell, with item: WKTabBarItem, at index: Int) {
        
    }
    
    override func tabBarController(_ controller: WKTabBarController, viewControllerAtIndex index: Int) -> UIViewController? {
        switch index {
        case 0:
            if dashboardViewController == nil {
                dashboardViewController = storyboard?.instantiateViewController(withIdentifier: "MainViewController")
            }
            return dashboardViewController
        case 1:
            if trendsViewController == nil {
                trendsViewController = storyboard?.instantiateViewController(withIdentifier: "TrendsViewController")
            }
            return trendsViewController
        case 2:
            if statsViewController == nil {
                statsViewController = storyboard?.instantiateViewController(withIdentifier: "StatsContainerViewController")
            }
            return statsViewController
        case 3:
            if settingsViewController == nil {
                settingsViewController = storyboard?.instantiateViewController(withIdentifier: "SettingsViewController")
            }
            return settingsViewController
        default:
            return nil
        }
    }
    
    override func tabBarController(_ controller: WKTabBarController, cellNameAtIndex index: Int) -> WKTabBarCellName {
        return WKTabBarCellNameImageLabel
    }
    

}
