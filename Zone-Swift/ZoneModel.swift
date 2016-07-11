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
        if self.defaultKey == nil{
            self.defaultKey = "\(dateFormatter.stringFromDate(NSDate()))\(arc4random())"
            isNew = true
        }
        try Zone.saveorUpdate(NSStringFromClass(classForCoder), model: self)
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
            let mirror = Mirror(reflecting: self)
            let superMirror = mirror.superclassMirror()
            var modelStr = ""
            for case let (label?, value) in mirror.children {
                if var v = (value as? AnyObject){
                    if v is ZoneModelHelper{
                        var temp = (v as! ZoneModelHelper).toString()
                        temp = "\(temp)!$\(NSStringFromClass(v.classForCoder))"
                        if temp.containsString(":"){
                            temp = String(temp).stringByReplacingOccurrencesOfString(":", withString: "%^")
                            temp = String(temp).stringByReplacingOccurrencesOfString(",", withString: "%&")
                        }
                        modelStr = "\(modelStr)\(String(UTF8String: label)!):\(temp),"
                        
                    }else{
                        if String(v).containsString(":"){
                            v = String(v).stringByReplacingOccurrencesOfString(":", withString: "%^")
                            v = String(v).stringByReplacingOccurrencesOfString(",", withString: "%&")
                        }
                        modelStr = "\(modelStr)\(String(UTF8String: label)!):\(String(v)),"
                    }
                    
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
            
            if isNew{
                FileUtil.write(modelStr, filePath: NSStringFromClass(self.classForCoder))
            }else{
                FileUtil.update(modelStr, lineNum: self.lineNum, filePath: NSStringFromClass(self.classForCoder))
            }

        }
        
    }
    
    func del()throws -> Bool {
        if defaultKey == nil || lineNum == 0{
            return false
        }
        if try Zone.delete(NSStringFromClass(classForCoder), model: self){
            dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
                FileUtil.deleteLine(self.lineNum, filePath:  NSStringFromClass(self.classForCoder))
            }
        }
        
        return true
    }
    
}