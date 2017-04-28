//
//  CircleVCConfigurations.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 5/3/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import UIKit

extension CircleViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("CircleViewController loaded")
        if CircleViewController.testing { return }
        setUpTestSurface()
        setUpGroupAndGuidelinesForTheSurface()
    }
    
    func setUpTestSurface() {
        surface = testType.surface
    }
    
    
    func setUpGroupAndGuidelinesForTheSurface() {
        print("Generating group with time limit \(groupGenerationTimeLimit)")
        surface.setupGroupoidAndGroup(timeLimitInMilliseconds: groupGenerationTimeLimit, maxDistance: Int(cutoffDistance) + 2)
        surface.setUpGuidelines()
        if let i = cuffEditIndex {
            surface.cuffGuidelines[i].object.lineColor = UIColor.red
        }
    }
    
}
