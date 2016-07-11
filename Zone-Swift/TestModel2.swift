//
//  TestModel2.swift
//  Zone-Swift
//
//  Created by 叶云 on 16/7/11.
//  Copyright © 2016年 叶云. All rights reserved.
//

import Foundation
class TestModel2 :ZoneModel, ZoneModelHelper{
    var money : Float!
    
    func toString() -> String {
        return "\(money)"
    }
    
    func fromString(modelStr : String) {
        money = Float(modelStr)
    }
    
    func equals(model1: ZoneModelHelper, model2: ZoneModelHelper) -> Bool {
        return false
    }
}