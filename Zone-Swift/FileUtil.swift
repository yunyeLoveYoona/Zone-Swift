//
//  FileUtil.swift
//  Zone-Swift
//
//  Created by 叶云 on 16/7/8.
//  Copyright © 2016年 叶云. All rights reserved.
//

import Foundation
class FileUtil {
    static let END = "-end-"
    
    
    static func createDir(userName : String) -> String!{
        let userDirPath = "\(NSHomeDirectory())/Documents/\(userName)"
        if(!NSFileManager.defaultManager().fileExistsAtPath(userDirPath)){
            do{
             try NSFileManager.defaultManager().createDirectoryAtPath(userDirPath, withIntermediateDirectories: false, attributes: nil)
            }catch{
                print("create dir fail")
                return nil
            }
        }
        return userDirPath
    }
    
    static func createFile(userName : String,fileName : String) -> String{
        let filePath = "\(NSHomeDirectory())/Documents/\(userName)/\(fileName)"
        if(!NSFileManager.defaultManager().fileExistsAtPath(filePath)){
             NSFileManager.defaultManager().createFileAtPath(filePath, contents: nil, attributes: nil)
        }
        return filePath
    }
    
    /**获取用户文件夹下的所有文件**/
    static func getFiles(userName : String) -> [String]!{
        let userDirPath = "\(createDir(userName))/"
        return NSFileManager.defaultManager().subpathsAtPath(userDirPath)!
    }
    
    static func read(filePath : String,userName : String) -> String!{
        let filePath = "\(NSHomeDirectory())/Documents/\(userName)/\(filePath)"
        if let readData = NSData(contentsOfFile: filePath){
            return NSString(data: readData, encoding: NSUTF8StringEncoding) as! String
        }else{
            return nil
        }
    }
    
    static func write(content : String,filePath : String){
        let path = "\(NSHomeDirectory())/Documents/\(Zone._this.userName)/\(filePath)"
        createFile(Zone._this.userName, fileName: filePath)
        let newContent = "\(content)\(FileUtil.END)"
        let fileHandler = NSFileHandle(forWritingAtPath: path)
        fileHandler?.seekToEndOfFile()
        fileHandler?.writeData(newContent.dataUsingEncoding(NSUTF8StringEncoding)!)
        fileHandler?.closeFile()
    }
    
    
    static func update(content : String,lineNum : Int,filePath : String){
        let path = "\(NSHomeDirectory())/Documents/\(Zone._this.userName)/\(filePath)"
        let oldContent = read(filePath,userName: Zone._this.userName)
        let modelStrList = oldContent.componentsSeparatedByString("\(FileUtil.END)")
        var newContent = ""
        var num = 0
        for modelString in modelStrList{
            num = num + 1
            if( num == lineNum){
                newContent = "\(newContent)\(content)\(FileUtil.END)"
            }else{
                newContent = "\(newContent)\(modelString)"
            }
            
        }
        let fileHandler = NSFileHandle(forWritingAtPath: path)
        fileHandler?.seekToFileOffset(0)
        fileHandler?.writeData(newContent.dataUsingEncoding(NSUTF8StringEncoding)!)
        fileHandler?.closeFile()
        
    }
    
    
    static func deleteLine(lineNum : Int,filePath : String){
        let path = "\(NSHomeDirectory())/Documents/\(Zone._this.userName)/\(filePath)"
        let oldContent = read(filePath,userName: Zone._this.userName)
        var modelStrList = oldContent.componentsSeparatedByString("\(FileUtil.END)")
        modelStrList.removeLast()
        var newContent = ""
        var num = 0
        for modelString in modelStrList{
            num = num + 1
            if( num != lineNum){
                newContent = "\(newContent)\(modelString)\(FileUtil.END)"
            }
        }
        do {
            try NSFileManager.defaultManager().removeItemAtPath(path)
        }catch{
            
        }
        createFile(Zone._this.userName, fileName: filePath)
        let fileHandler = NSFileHandle(forWritingAtPath: path)
        fileHandler?.seekToFileOffset(0)
        fileHandler?.writeData(newContent.dataUsingEncoding(NSUTF8StringEncoding)!)
        fileHandler?.closeFile()
        
    }
    
    
    
}