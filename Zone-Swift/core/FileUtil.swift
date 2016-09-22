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
    
    
    static func createDir(_ userName : String) -> String!{
        let userDirPath = "\(NSHomeDirectory())/Documents/\(userName)"
        if(!FileManager.default.fileExists(atPath: userDirPath)){
            do{
             try FileManager.default.createDirectory(atPath: userDirPath, withIntermediateDirectories: false, attributes: nil)
            }catch{
                print("create dir fail")
                return nil
            }
        }
        return userDirPath
    }
    
    static func createFile(_ userName : String,fileName : String) -> String{
        let filePath = "\(NSHomeDirectory())/Documents/\(userName)/\(fileName)"
        if(!FileManager.default.fileExists(atPath: filePath)){
             FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)
        }
        return filePath
    }
    
    /**获取用户文件夹下的所有文件**/
    static func getFiles(_ userName : String) -> [String]!{
        let userDirPath = "\(createDir(userName)!)/"
        return FileManager.default.subpaths(atPath: userDirPath)!
    }
    
    static func read(_ filePath : String,userName : String) -> String!{
        let filePath = "\(NSHomeDirectory())/Documents/\(userName)/\(filePath)"
        if let readData = try? Data(contentsOf: URL(fileURLWithPath: filePath)){
            return NSString(data: readData, encoding: String.Encoding.utf8.rawValue) as! String
        }else{
            return nil
        }
    }
    
    static func write(_ content : String,filePath : String){
        let path = "\(NSHomeDirectory())/Documents/\(Zone._this.userName!)/\(filePath)"
        let _ = createFile(Zone._this.userName, fileName: filePath)
        let newContent = "\(content)\(FileUtil.END)"
        let fileHandler = FileHandle(forWritingAtPath: path)
        fileHandler?.seekToEndOfFile()
        fileHandler?.write(newContent.data(using: String.Encoding.utf8)!)
        fileHandler?.closeFile()
    }
    
    
    static func update(_ content : String,lineNum : Int,filePath : String){
        let path = "\(NSHomeDirectory())/Documents/\(Zone._this.userName)/\(filePath)"
        let oldContent = read(filePath,userName: Zone._this.userName)
        let modelStrList = oldContent?.components(separatedBy: "\(FileUtil.END)")
        var newContent = ""
        var num = 0
        for modelString in modelStrList!{
            num = num + 1
            if( num == lineNum){
                newContent = "\(newContent)\(content)"
                if num != modelStrList?.count{
                    newContent = "\(newContent)\(FileUtil.END)"
                }
            }else{
                newContent = "\(newContent)\(modelString)"
                if num != modelStrList?.count{
                    newContent = "\(newContent)\(FileUtil.END)"
                }
            }
            
        }
        do {
            try FileManager.default.removeItem(atPath: path)
        }catch{
            
        }
        let _ = createFile(Zone._this.userName, fileName: filePath)
        let fileHandler = FileHandle(forWritingAtPath: path)
        fileHandler?.seek(toFileOffset: 0)
        fileHandler?.write(newContent.data(using: String.Encoding.utf8)!)
        fileHandler?.closeFile()
        
    }
    
    
    static func deleteLine(_ lineNum : Int,filePath : String){
        let path = "\(NSHomeDirectory())/Documents/\(Zone._this.userName)/\(filePath)"
        let oldContent = read(filePath,userName: Zone._this.userName)
        var modelStrList = oldContent?.components(separatedBy: "\(FileUtil.END)")
        modelStrList?.remove(at: (modelStrList?.count)! - 1)
        var newContent = ""
        var num = 0
        for modelString in modelStrList!{
            num = num + 1
            if( num != lineNum){
                newContent = "\(newContent)\(modelString)"
                if num != modelStrList?.count{
                    newContent = "\(newContent)\(FileUtil.END)"
                }
            }
        }
        do {
            try FileManager.default.removeItem(atPath: path)
        }catch{
            
        }
        let _ = createFile(Zone._this.userName, fileName: filePath)
        let fileHandler = FileHandle(forWritingAtPath: path)
        fileHandler?.seek(toFileOffset: 0)
        fileHandler?.write(newContent.data(using: String.Encoding.utf8)!)
        fileHandler?.closeFile()
        
    }
    
    
    
}
