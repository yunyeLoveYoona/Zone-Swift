//
//  ZoneModel.swift
//  Zone-Swift
//
//  Created by 叶云 on 16/7/8.
//  Copyright © 2016年 叶云. All rights reserved.
//

import Foundation
class ZoneModel: NSObject {
    var defaultKey : String!
    var lineNum : Int
    
    override required init() {
        print("init")
        lineNum = 0
    }
    
    func saveOrUpdate() throws{
        var isNew = false
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy 'at' h:mm:ss a"
        if defaultKey == nil{
            defaultKey = "\(dateFormatter.stringFromDate(NSDate()))\(arc4random())"
            isNew = true
        }
        let mirror = Mirror(reflecting: self)
        let superMirror = mirror.superclassMirror()
        var modelStr = ""
        for case let (label?, value) in mirror.children {
            if var v = (value as? AnyObject){
                if String(v).containsString(":"){
                   v = String(v).stringByReplacingOccurrencesOfString(":", withString: "%^")
                   v = String(v).stringByReplacingOccurrencesOfString(",", withString: "%&")
                }
                modelStr = "\(modelStr)\(String(UTF8String: label)!):\(String(v)),"
            }
        }
        for case let (label?, value) in superMirror!.children {
            if var v = (value as? AnyObject){
                if String(v).containsString(":"){
                    v = String(v).stringByReplacingOccurrencesOfString(":", withString: "%^")
                    v = String(v).stringByReplacingOccurrencesOfString(",", withString: "%&")
                }
                modelStr = "\(modelStr)\(String(UTF8String: label)!):\(String(v)),"
            }
        }
        modelStr = modelStr.substring(0, NSString(string: modelStr).length - 1)
        try Zone.saveorUpdate(NSStringFromClass(classForCoder), model: self)
        if isNew{
            FileUtil.write(modelStr, filePath: NSStringFromClass(classForCoder))
        }else{
            FileUtil.update(modelStr, lineNum: lineNum, filePath: NSStringFromClass(classForCoder))
        }
        
    }
    
    func del()throws -> Bool {
        if defaultKey == nil || lineNum == 0{
            return false
        }
        if try Zone.delete(NSStringFromClass(classForCoder), model: self){
            FileUtil.deleteLine(lineNum, filePath:  NSStringFromClass(classForCoder))
        }
        
        return true
    }
    
}