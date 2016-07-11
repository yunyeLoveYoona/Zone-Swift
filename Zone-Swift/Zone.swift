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

    
    private convenience init(){
        self.init(userName: "default")
    }
    
    private init(userName : String){
        self.userName = userName
        lineNum = 1
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
                var modelStrList = FileUtil.read(file,userName: _this.userName).componentsSeparatedByString("\(FileUtil.END)")
                var zoneModels = Array<ZoneModel>()
                modelStrList.removeLast()
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
                     zoneModel.setValue(value, forKey: key)
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
    
    
    static func saveorUpdate(className : String,model : ZoneModel) throws{
        try checkThis()
        let zoneModel = find(className, model: model)
        if zoneModel == nil{
            add(className, model: model)
        }else{
            update(className, oldModel: zoneModel, model: model)
        }
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
            return true
        }
        return false
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