//
//  Zone.swift
//  Zone-Swift
//
//  Created by 叶云 on 16/7/8.
//  Copyright © 2016年 叶云. All rights reserved.
//

import Foundation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}

class Zone {
    var userName : String!
    static var _this : Zone!
    var dataCache : Array<Dictionary<String,Array<ZoneModel>>>!
    var lineNum : Int!
    var maxNum = 0
    var lock : NSLock!
    
    fileprivate convenience init(){
        self.init(userName: "default")
    }
    
    fileprivate init(userName : String){
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
    
    static func initZone(_ userName : String){
        if(_this == nil || !(_this.userName == userName)){
            _this = Zone()
        }
        initData()
    }
    
    fileprivate static func checkThis() throws{
        if(_this == nil){
            throw "Zone is not init"
        }
    }
    
    static func getInstance() throws -> Zone{
        try checkThis()
        return _this
    }
    
    fileprivate static func initData(){
        _this.dataCache = Array<Dictionary<String,Array<ZoneModel>>>()
        let files = FileUtil.getFiles(_this.userName)
        if(files != nil && (files?.count)! > 0){
            for file in files!{
                _this.lineNum = 1
                let modelStrs = FileUtil.read(file,userName: _this.userName)
                let modelStrList = modelStrs?.components(separatedBy: "\(FileUtil.END)")
                if NSString(string:modelStrs!).length  > NSString(string:FileUtil.END).length {
                    if modelStrs?.substring(NSString(string:modelStrs!).length - NSString(string:FileUtil.END).length, NSString(string:modelStrs!).length) == FileUtil.END
                    {
                       
                        var zoneModels = Array<ZoneModel>()
                        for modelStr in modelStrList! {
                            if let model = getModel(file, modelStr: modelStr){
                                zoneModels.append(model)
                            }
                        }
                        _this.dataCache.append([file: zoneModels])
                    }
                
                }else{
                    FileUtil.deleteLine((modelStrList?.count)!, filePath:  file)
                }
            }
        }
        
    }
    
    
    fileprivate static func getModel(_ modelName : String,modelStr : String) -> ZoneModel!{
        if NSString(string: modelStr).length > 1{
            let s :Character = ":"
            let zoneModel = (NSClassFromString(modelName) as! ZoneModel.Type).init()
            let mirror = Mirror(reflecting: zoneModel)
            let keyValues = modelStr.components(separatedBy: ",")
            let superMirror = mirror.superclassMirror
            for keyValue in keyValues {
                let key = keyValue.substring(0, keyValue.lastIndexOf(s))
                var value = keyValue.substring(keyValue.lastIndexOf(s) + 1,NSString(string: keyValue).length)
                value = value.replacingOccurrences(of: "%^", with: ":")
                value = value.replacingOccurrences(of: "%&", with: ",")
                for case let (label, _ ) in mirror.children {
                    if(key == label){
                        if value.contains("!$"){
                            let className = value.substring(value.lastIndexOf("$") + 1, NSString(string: value).length)
                            let modelStr = value.substring(0, value.lastIndexOf("$") - 1)
                            let model = (NSClassFromString(className) as! ZoneModel.Type).init()
                            (model as! ZoneModelHelper).fromString(modelStr)
                            zoneModel.setValue(model, forKey: key)
                        }else if value.contains("date"){
                            let dateStr = value.substring(0, value.lastIndexOf("d") - 1)
                            let date = NSDate(timeIntervalSince1970: (dateStr as NSString).doubleValue)
                            zoneModel.setValue(date, forKey: key)

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
    
    
    static func saveorUpdate(_ className : String,model : ZoneModel) throws{
        _this.lock.lock()
        try checkThis()
        let zoneModel = find(className, model: model)
        if zoneModel == nil{
            add(className, model: model)
        }else{
            update(className, oldModel: zoneModel!, model: model)
        }
        _this.lock.unlock()
    }
    
    fileprivate static func find(_ className : String,model : ZoneModel) -> ZoneModel!{
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
    
    fileprivate static func add(_ className : String,model : ZoneModel){
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
            _this.dataCache.remove(at: num)
            temp.append(model)
            
        }
        
        if _this.maxNum > 0 && model.lineNum > _this.maxNum{
            temp.remove(at: 0)
            for tempModel in temp {
                tempModel.lineNum = tempModel.lineNum - 1
            }
            FileUtil.deleteLine(0, filePath: NSStringFromClass(model.classForCoder))
        }
        _this.dataCache.append([className : temp])
    
    }
    
    fileprivate static func update(_ className : String,oldModel : ZoneModel,model : ZoneModel){
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
                modelList.remove(at: num)
                modelList.append(model)
            }
        }
    
    }
    
    
    static func findAll(_ className : String)throws -> Array<ZoneModel>{
        try checkThis()
        let temp = Array<ZoneModel>()
        for dictionary in _this.dataCache {
            if let modelList = dictionary[className]{
                return modelList
            }
        }
        return temp
    }
    
    
    static func delete(_ className : String,model : ZoneModel)throws -> Bool{
        try checkThis()
        _this.lock.lock()
        if let _ = find(className, model: model){
            var num : Int = 0
            var modelList : Array<ZoneModel>!
            var i = 0
            for dictionary in _this.dataCache {
                if dictionary[className] != nil{
                    modelList = dictionary[className]
                    modelList.remove(at: model.lineNum - 1)
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
    
    
    static func limit(_ start : Int,end : Int,className : String)throws -> Array<ZoneModel>{
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
    
    static func selectWhere(_ whereCondition : WhereCondition,className : String,fieldName : String,value : AnyObject)throws -> Array<ZoneModel>! {
        return  try selectWhere(findAll(className), whereCondition: whereCondition, className: className, fieldName: fieldName, value: value)
        
    }
    
    static func selectWhere(_ zoneModels : Array<ZoneModel>,whereCondition : WhereCondition,className : String,fieldName : String,value : AnyObject) -> Array<ZoneModel>! {
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
                case .equals:
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
                                    if String(describing: fieldValue) == String(describing: value){
                                        temp.append(zoneModel)
                                    }
                                }else if fieldValue is Bool{
                                    if Bool(fieldValue as! NSNumber) == Bool(value as! NSNumber){
                                        temp.append(zoneModel)
                                    }
                                }else if fieldValue is Date{
                                    if (fieldValue as! Date) == (v as! Date){
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
                case .contains:
                    if value is String{
                        for (label, v ) in mirror.children  {
                            if label == fieldName{
                                if value.contains(v as! String){
                                    temp.append(zoneModel)
                                }
                            }
                        }
                    }
                case .after:
                    if value is Date{
                        for (label, v ) in mirror.children  {
                            if label == fieldName{
                                if (value as! Date) == ((value as! Date) as NSDate).laterDate(v as! Date){
                                    temp.append(zoneModel)
                                }
                            }
                        }

                    }
                case .before:
                    if value is Date{
                        for (label, v ) in mirror.children  {
                            if label == fieldName{
                                if (value as! Date) == ((value as! Date) as NSDate).earlierDate(v as! Date){
                                    temp.append(zoneModel)
                                }
                            }
                        }
                        
                    }
                case .less_THAN:
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
                                    if String(describing: fieldValue) < String(describing: value){
                                        temp.append(zoneModel)
                                    }
                                }
                            }
                            break
                        }
                    }
                case .more_THAN:
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
                                    if String(describing: fieldValue) > String(describing: value){
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
    
    static func orderBy(_ className : String,sortField : String,sordMode : SortMode)throws -> Array<ZoneModel>!{
        var modelList = try findAll(className)
        modelList.sort { (model1 :ZoneModel, model2 :ZoneModel) -> Bool in
            let value1,value2 : AnyObject!
            value1 = getValue(model1,fieldName: sortField)
            value2 = getValue(model2,fieldName: sortField)
            if value1 != nil && value2 != nil{
                if value1 is Int{
                    if sordMode == SortMode.asc{
                        return Int(value1 as! NSNumber) < Int(value2 as! NSNumber)
                    }else{
                        return Int(value1 as! NSNumber) >= Int(value2 as! NSNumber)
                    }
                }else if value1 is Float{
                    if sordMode == SortMode.asc{
                        return Float(value1 as! NSNumber) < Float(value2 as! NSNumber)
                    }else{
                        return Float(value1 as! NSNumber) >= Float(value2 as! NSNumber)
                    }
                }else if value1 is Double{
                    if sordMode == SortMode.asc{
                        return Double(value1 as! NSNumber) < Double(value2 as! NSNumber)
                    }else{
                        return Double(value1 as! NSNumber) >= Double(value2 as! NSNumber)
                    }
                }else if value1 is String{
                    if sordMode == SortMode.asc{
                        return String(describing: value1) < String(describing: value2)
                    }else{
                        return String(describing: value1) >= String(describing: value2)
                    }
                }else if value1 is NSDate{
                    if sordMode == SortMode.asc{
                        return  ((value1 as! Date) == ((value1 as! Date) as NSDate).earlierDate(value2 as! Date))
                    }else{
                         return  ((value1 as! Date) == ((value1 as! Date) as NSDate).laterDate(value2 as! Date))
                    }
                }
                
            }
            return false
        }
        return modelList
        
    }

    
    fileprivate static func getValue(_ model : ZoneModel,fieldName : String)-> AnyObject!{
        let mirror = Mirror(reflecting: model)
        for (label, v ) in mirror.children  {
            if label == fieldName{
                return v as AnyObject
            }
        }
        return nil
    }
    
    
    
}
extension String : Error{
    
    func lastIndexOf(_ char : Character) -> Int{
        var position = 0
        for word in  self.characters{
            if(word == char){
                return position
            }
            position = position + 1
        }
        return position
    }
    
    
    func substring(_ s: Int, _ e: Int? = nil) -> String {
        let start = s >= 0 ? self.startIndex : self.endIndex
        let startIndex = self.index(start, offsetBy: s)
        
        var end: String.Index
        var endIndex: String.Index
        if(e == nil){
            end = self.endIndex
            endIndex = self.endIndex
        } else {
            end = e >= 0 ? self.startIndex : self.endIndex
            endIndex = self.index(end, offsetBy: e!)
        }
        
        let range = Range<String.Index>(startIndex..<endIndex)
        return self.substring(with: range)
        
    }
    
}

enum WhereCondition {
    case equals,before,after,contains,more_THAN,less_THAN
}

enum SortMode {
    case asc,desc
}
