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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy 'at' h:mm:ss a"
        if self.defaultKey == nil{
            self.defaultKey = "\(dateFormatter.string(from: Date()))\(arc4random())"
            isNew = true
        }
        try Zone.saveorUpdate(NSStringFromClass(classForCoder), model: self)
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).sync{
            let mirror = Mirror(reflecting: self)
            let superMirror = mirror.superclassMirror
            var modelStr = ""
            for case let (label?, value) in mirror.children {
                if var v = (value as? AnyObject){
                    if v is ZoneModelHelper{
                        var temp = (v as! ZoneModelHelper).toString()
                        temp = "\(temp)!$\(NSStringFromClass(v.classForCoder))"
                        if temp.contains(":"){
                            temp = String(temp).replacingOccurrences(of: ":", with: "%^")
                            temp = String(temp).replacingOccurrences(of: ",", with: "%&")
                        }
                        modelStr = "\(modelStr)\(String(validatingUTF8: label)!):\(temp),"
                        
                    }else if v is NSDate{
                        let temp = (v as! NSDate).timeIntervalSince1970
                        modelStr = "\(modelStr)\(String(validatingUTF8: label)!):\(temp)date,"
                        
                    }else{
                        if String(describing: v).contains(":"){
                            v = String(describing: v).replacingOccurrences(of: ":", with: "%^") as AnyObject
                            v = String(describing: v).replacingOccurrences(of: ",", with: "%&") as AnyObject
                        }
                        modelStr = "\(modelStr)\(String(validatingUTF8: label)!):\(String(describing: v)),"
                    }
                    
                }
            }
            for case let (label?, value) in superMirror!.children {
                if var v = (value as? AnyObject){
                    if String(describing: v).contains(":"){
                        v = String(describing: v).replacingOccurrences(of: ":", with: "%^") as AnyObject
                        v = String(describing: v).replacingOccurrences(of: ",", with: "%&") as AnyObject
                    }
                    modelStr = "\(modelStr)\(String(validatingUTF8: label)!):\(String(describing: v)),"
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
            DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).sync{
                FileUtil.deleteLine(self.lineNum, filePath:  NSStringFromClass(self.classForCoder))
            }
        }
        
        return true
    }
    
}
