//
//  Zone.swift
//  Zone-Swift
//
//  Created by 叶云 on 16/7/8.
//  Copyright © 2016年 叶云. All rights reserved.
//

import Foundation
class Zone {
    var userName : String!
    static var _this : Zone!
    var dataCache : Array<Dictionary<String,Array<ZoneModel>>>!
    var lineNum : Int!
    var maxNum = 0
    var lock : NSLock!
    
    private convenience init(){
        self.init(userName: "default")
    }
    
    private init(userName : String){
        self.userName = userName
        lineNum = 1
        lock = NSLock()
    }
    
    static func initZone(){
        if(_this == nil || !(_this.userName == "default")){
            _this = Zone()
        }
        initData()
    }
    
    static func initZone(userName : String){
        if(_this == nil || !(_this.userName == userName)){
            _this = Zone()
        }
        initData()
    }
    
    private static func checkThis() throws{
        if(_this == nil){
            throw "Zone is not init"
        }
    }
    
    static func getInstance() throws -> Zone{
        try checkThis()
        return _this
    }
    
    private static func initData(){
        _this.dataCache = Array<Dictionary<String,Array<ZoneModel>>>()
        let files = FileUtil.getFiles(_this.userName)
        if(files != nil && files.count > 0){
            for file in files{
                _this.lineNum = 1
                let modelStrList = FileUtil.read(file,userName: _this.userName).componentsSeparatedByString("\(FileUtil.END)")
                var zoneModels = Array<ZoneModel>()
                for modelStr in modelStrList {
                    if let model = getModel(file, modelStr: modelStr){
                        zoneModels.append(model)
                    }
                }
                _this.dataCache.append([file: zoneModels])
            }
        }
        
    }
    
    
    private static func getModel(modelName : String,modelStr : String) -> ZoneModel!{
        if NSString(string: modelStr).length > 1{
            let s :Character = ":"
            let zoneModel = (NSClassFromString(modelName) as! ZoneModel.Type).init()
            let mirror = Mirror(reflecting: zoneModel)
            let keyValues = modelStr.componentsSeparatedByString(",")
            let superMirror = mirror.superclassMirror()
            for keyValue in keyValues {
                let key = keyValue.substring(0, keyValue.lastIndexOf(s))
                var value = keyValue.substring(keyValue.lastIndexOf(s) + 1,NSString(string: keyValue).length)
                value = value.stringByReplacingOccurrencesOfString("%^", withString: ":")
                value = value.stringByReplacingOccurrencesOfString("%&", withString: ",")
                for case let (label, _ ) in mirror.children {
                    if(key == label){
                        if value.containsString("!$"){
                            let className = value.substring(value.lastIndexOf("$") + 1, NSString(string: value).length)
                            let modelStr = value.substring(0, value.lastIndexOf("$") - 1)
                            let model = (NSClassFromString(className) as! ZoneModel.Type).init()
                            (model as! ZoneModelHelper).fromString(modelStr)
                            zoneModel.setValue(model, forKey: key)
                        }else{
                            zoneModel.setValue(value, forKey: key)
                        }
                        
                    }
                }
                for case let (label, _ ) in superMirror!.children {
                    if(key == label){
                        zoneModel.setValue(value, forKey: key)
                    }
                }
                zoneModel.setValue(_this.lineNum, forKey: "lineNum")
                
            }
            _this.lineNum = _this.lineNum + 1
            return zoneModel

        }
        
        return nil
    }
    
    
    static func saveorUpdate(className : String,model : ZoneModel) throws{
        _this.lock.lock()
        try checkThis()
        let zoneModel = find(className, model: model)
        if zoneModel == nil{
            add(className, model: model)
        }else{
            update(className, oldModel: zoneModel, model: model)
        }
        _this.lock.unlock()
    }
    
    private static func find(className : String,model : ZoneModel) -> ZoneModel!{
        for dictionary in _this.dataCache {
            if let modelList = dictionary[className]{
                for zoneModel in modelList {
                    if zoneModel.defaultKey == model.defaultKey{
                        return zoneModel
                    }
                }
            }
        }
        
        return nil
    }
    
    private static func add(className : String,model : ZoneModel){
        var temp : Array<ZoneModel>!
        var i = 0
        var num = 0
        for dictionary in _this.dataCache {
            if let modelList = dictionary[className]{
                temp = modelList
                num = i
            }
            i = i + 1
        }
        if temp != nil{
            model.lineNum = temp.count + 1
        }else{
            model.lineNum = 1
        }
        if temp == nil{
            temp = Array<ZoneModel>()
            temp.append(model)
        }else{
            _this.dataCache.removeAtIndex(num)
            temp.append(model)
            
        }
        
        if _this.maxNum > 0 && model.lineNum > _this.maxNum{
            temp.removeAtIndex(0)
            for tempModel in temp {
                tempModel.lineNum = tempModel.lineNum - 1
            }
            FileUtil.deleteLine(0, filePath: NSStringFromClass(model.classForCoder))
        }
        _this.dataCache.append([className : temp])
    
    }
    
    private static func update(className : String,oldModel : ZoneModel,model : ZoneModel){
        var num = 0
        for dictionary in _this.dataCache {
            if var modelList = dictionary[className]{
                var i = 0
                for zoneModel in modelList {
                    if zoneModel.defaultKey == oldModel.defaultKey{
                       num = i
                    }
                    i = i + 1
                }
                modelList.removeAtIndex(num)
                modelList.append(model)
            }
        }
    
    }
    
    
    static func findAll(className : String)throws -> Array<ZoneModel>{
        try checkThis()
        let temp = Array<ZoneModel>()
        for dictionary in _this.dataCache {
            if let modelList = dictionary[className]{
                return modelList
            }
        }
        return temp
    }
    
    
    static func delete(className : String,model : ZoneModel)throws -> Bool{
        try checkThis()
        _this.lock.lock()
        if let _ = find(className, model: model){
            var num : Int = 0
            var modelList : Array<ZoneModel>!
            var i = 0
            for dictionary in _this.dataCache {
                if dictionary[className] != nil{
                    modelList = dictionary[className]
                    modelList.removeAtIndex(model.lineNum - 1)
                    for zoneModel in modelList {
                        if(zoneModel.lineNum > model.lineNum){
                            zoneModel.lineNum = zoneModel.lineNum - 1
                        }
                    }
                    num = i
                }
                i = i + 1
            }
            (_this.dataCache[num])[className] = modelList
            _this.lock.unlock()
            return true
        }
        _this.lock.unlock()
        return false
    }
    
    
    static func limit(start : Int,end : Int,className : String)throws -> Array<ZoneModel>{
        try checkThis()
        var temp = Array<ZoneModel>()
        for dictionary in _this.dataCache {
            if let modelList = dictionary[className]{
                var i = 0
                for model in modelList {
                    if i < end && i >= start{
                        temp.append(model)
                    }
                    i = i + 1
                }
            }
        }
        return temp
    }
    
    static func selectWhere(whereCondition : WhereCondition,className : String,fieldName : String,value : AnyObject)throws -> Array<ZoneModel>! {
        return  try selectWhere(findAll(className), whereCondition: whereCondition, className: className, fieldName: fieldName, value: value)
        
    }
    
    static func selectWhere(zoneModels : Array<ZoneModel>,whereCondition : WhereCondition,className : String,fieldName : String,value : AnyObject) -> Array<ZoneModel>! {
        let zoneModel = (NSClassFromString(className) as! ZoneModel.Type).init()
        let mirror = Mirror(reflecting: zoneModel)
        var tempField : String!
        for (label, _ ) in mirror.children  {
            if label == fieldName{
                tempField = label
                break
            }
        }
        if tempField != nil{
            var temp : Array<ZoneModel> =  Array<ZoneModel>()
            for zoneModel in zoneModels {
                let mirror = Mirror(reflecting: zoneModel)
                switch whereCondition {
                case .EQUALS:
                    for (label, v ) in mirror.children  {
                        if label == fieldName{
                            if let fieldValue = (v as? AnyObject){
                                if fieldValue is Int{
                                    if Int(fieldValue as! NSNumber) == Int(value as! NSNumber){
                                        temp.append(zoneModel)
                                    }
                                }else if fieldValue is Float{
                                    if Float(fieldValue as! NSNumber) == Float(value as! NSNumber){
                                        temp.append(zoneModel)
                                    }
                                }else if fieldValue is Double{
                                    if Double(fieldValue as! NSNumber) == Double(value as! NSNumber){
                                        temp.append(zoneModel)
                                    }
                                }else if fieldValue is String{
                                    if String(fieldValue) == String(value){
                                        temp.append(zoneModel)
                                    }
                                }else if fieldValue is Bool{
                                    if Bool(fieldValue as! NSNumber) == Bool(value as! NSNumber){
                                        temp.append(zoneModel)
                                    }
                                }else if fieldValue is NSDate{
                                    if (fieldValue as! NSDate).isEqualToDate(v as! NSDate){
                                        temp.append(zoneModel)
                                    }
                                }else if fieldValue is ZoneModelHelper{
                                    if (fieldValue as! ZoneModelHelper).equals(fieldValue as! ZoneModelHelper, model2: value as! ZoneModelHelper){
                                        temp.append(zoneModel)
                                    }
                                }

                            }
                            break
                        }
                    }
                case .CONTAINS:
                    if value is String{
                        for (label, v ) in mirror.children  {
                            if label == fieldName{
                                if value.containsString(v as! String){
                                    temp.append(zoneModel)
                                }
                            }
                        }
                    }
                case .AFTER:
                    if value is NSDate{
                        for (label, v ) in mirror.children  {
                            if label == fieldName{
                                if (value as! NSDate).isEqualToDate((value as! NSDate).laterDate(v as! NSDate)){
                                    temp.append(zoneModel)
                                }
                            }
                        }

                    }
                case .BEFORE:
                    if value is NSDate{
                        for (label, v ) in mirror.children  {
                            if label == fieldName{
                                if (value as! NSDate).isEqualToDate((value as! NSDate).earlierDate(v as! NSDate)){
                                    temp.append(zoneModel)
                                }
                            }
                        }
                        
                    }
                case .LESS_THAN:
                    for (label, v ) in mirror.children  {
                        if label == fieldName{
                            if let fieldValue = (v as? AnyObject){
                                if fieldValue is Int{
                                    if Int(fieldValue as! NSNumber) < Int(value as! NSNumber){
                                        temp.append(zoneModel)
                                    }
                                }else if fieldValue is Float{
                                    if Float(fieldValue as! NSNumber) < Float(value as! NSNumber){
                                        temp.append(zoneModel)
                                    }
                                }else if fieldValue is Double{
                                    if Double(fieldValue as! NSNumber) < Double(value as! NSNumber){
                                        temp.append(zoneModel)
                                    }
                                }else if fieldValue is String{
                                    if String(fieldValue) < String(value){
                                        temp.append(zoneModel)
                                    }
                                }
                            }
                            break
                        }
                    }
                case .MORE_THAN:
                    for (label, v ) in mirror.children  {
                        if label == fieldName{
                            if let fieldValue = (v as? AnyObject){
                                if fieldValue is Int{
                                    if Int(fieldValue as! NSNumber) > Int(value as! NSNumber){
                                        temp.append(zoneModel)
                                    }
                                }else if fieldValue is Float{
                                    if Float(fieldValue as! NSNumber) > Float(value as! NSNumber){
                                        temp.append(zoneModel)
                                    }
                                }else if fieldValue is Double{
                                    if Double(fieldValue as! NSNumber) > Double(value as! NSNumber){
                                        temp.append(zoneModel)
                                    }
                                }else if fieldValue is String{
                                    if String(fieldValue) > String(value){
                                        temp.append(zoneModel)
                                    }
                                }
                            }
                            break
                        }
                    }
                }
            }
            
            return temp
        }
        
        return nil
    }
    
    static func orderBy(className : String,sortField : String,sordMode : SortMode)throws -> Array<ZoneModel>!{
        var modelList = try findAll(className)
        modelList.sortInPlace { (model1 :ZoneModel, model2 :ZoneModel) -> Bool in
            let value1,value2 : AnyObject!
            value1 = getValue(model1,fieldName: sortField)
            value2 = getValue(model2,fieldName: sortField)
            if value1 != nil && value2 != nil{
                if value1 is Int{
                    if sordMode == SortMode.ASC{
                        return Int(value1 as! NSNumber) < Int(value2 as! NSNumber)
                    }else{
                        return Int(value1 as! NSNumber) >= Int(value2 as! NSNumber)
                    }
                }else if value1 is Float{
                    if sordMode == SortMode.ASC{
                        return Float(value1 as! NSNumber) < Float(value2 as! NSNumber)
                    }else{
                        return Float(value1 as! NSNumber) >= Float(value2 as! NSNumber)
                    }
                }else if value1 is Double{
                    if sordMode == SortMode.ASC{
                        return Double(value1 as! NSNumber) < Double(value2 as! NSNumber)
                    }else{
                        return Double(value1 as! NSNumber) >= Double(value2 as! NSNumber)
                    }
                }else if value1 is String{
                    if sordMode == SortMode.ASC{
                        return String(value1) < String(value2)
                    }else{
                        return String(value1) >= String(value2)
                    }
                }else if value1 is NSDate{
                    if sordMode == SortMode.ASC{
                        return  (value1 as! NSDate).isEqualToDate((value1 as! NSDate).earlierDate(value2 as! NSDate))
                    }else{
                         return  (value1 as! NSDate).isEqualToDate((value1 as! NSDate).laterDate(value2 as! NSDate))
                    }
                }
                
            }
            return false
        }
        return modelList
        
    }

    
    private static func getValue(model : ZoneModel,fieldName : String)-> AnyObject!{
        let mirror = Mirror(reflecting: model)
        for (label, v ) in mirror.children  {
            if label == fieldName{
                return v as! AnyObject
            }
        }
        return nil
    }
    
    
    
}
extension String : ErrorType{
    
    func lastIndexOf(char : Character) -> Int{
        var position = 0
        for word in  self.characters{
            if(word == char){
                return position
            }
            position = position + 1
        }
        return position
    }
    
    
    func substring(s: Int, _ e: Int? = nil) -> String {
        let start = s >= 0 ? self.startIndex : self.endIndex
        let startIndex = start.advancedBy(s)
        
        var end: String.Index
        var endIndex: String.Index
        if(e == nil){
            end = self.endIndex
            endIndex = self.endIndex
        } else {
            end = e >= 0 ? self.startIndex : self.endIndex
            endIndex = end.advancedBy(e!)
        }
        
        let range = Range<String.Index>(startIndex..<endIndex)
        return self.substringWithRange(range)
        
    }
    
}

enum WhereCondition {
    case EQUALS,BEFORE,AFTER,CONTAINS,MORE_THAN,LESS_THAN
}

enum SortMode {
    case ASC,DESC
}