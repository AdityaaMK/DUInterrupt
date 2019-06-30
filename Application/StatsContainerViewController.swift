//
//  StatsContainerViewController.swift
//  Cardiologic
//  Contains each instantiation of statistics VC for daily stats
//
//  Created by Ben Zimring on 5/31/18.
//  Copyright © 2018 pulseApp. All rights reserved.
//

import UIKit

class StatsContainerViewController: UIViewController, UIPageViewControllerDataSource {
    
    var pageViewController: UIPageViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        pageViewController = storyboard?.instantiateViewController(withIdentifier: "PageViewController") as? UIPageViewController
        pageViewController?.dataSource = self
        guard let startingViewController = viewControllerAtIndex(0, direction: -1) else { return }
        let viewControllers: [UIViewController] = [startingViewController]
        pageViewController?.setViewControllers(viewControllers, direction: .forward, animated: false, completion: nil)
        pageViewController?.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height-30)
        addChild(pageViewController!)
        view.addSubview(pageViewController!.view)
        pageViewController?.didMove(toParent: self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(nextPage), name: AppDelegate.kNextNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(prevPage), name: AppDelegate.kPrevNotification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let controller = viewController as! StatsContentViewController
        guard let currentDay = controller.numDaysBeforeToday else { return nil }
        return viewControllerAtIndex(currentDay-1, direction: 0)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let controller = viewController as! StatsContentViewController
        guard let currentDay = controller.numDaysBeforeToday else { return nil }
        return viewControllerAtIndex(currentDay+1, direction: 1)
    }
    
    func viewControllerAtIndex(_ idx: Int, direction: Int) -> StatsContentViewController? {
        if idx > 0 { return nil }
        let pageContentViewController = storyboard?.instantiateViewController(withIdentifier: "PageContentViewController") as! StatsContentViewController
        pageContentViewController.numDaysBeforeToday = idx
        pageContentViewController.swipeDirection = direction
        
        return pageContentViewController
    }
    
    @objc func nextPage(notification: Notification) {
        let controller = notification.object as! StatsContentViewController
        guard let currentDay = controller.numDaysBeforeToday else { return }
        guard let nextVC = viewControllerAtIndex(currentDay+1, direction: 1) else { return }
        pageViewController?.setViewControllers([nextVC], direction: .forward, animated: true, completion: nil)
        
    }
    
    @objc func prevPage(notification: Notification) {
        let controller = notification.object as! StatsContentViewController
        guard let currentDay = controller.numDaysBeforeToday else { return }
        guard let prevVC = viewControllerAtIndex(currentDay-1, direction: 0) else { return }
        pageViewController?.setViewControllers([prevVC], direction: .reverse, animated: true, completion: nil)
    }
    
}

