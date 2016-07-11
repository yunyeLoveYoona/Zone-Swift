//
//  ZoneModelHelper.swift
//  Zone-Swift
//
//  Created by 叶云 on 16/7/11.
//  Copyright © 2016年 叶云. All rights reserved.
//

import Foundation

protocol ZoneModelHelper{
    func equals(model1 : ZoneModelHelper,model2 :ZoneModelHelper) -> Bool
    
    func toString() -> String
    
    func fromString(modelStr : String)
    
}
