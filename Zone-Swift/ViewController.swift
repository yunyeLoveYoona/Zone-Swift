//
//  ViewController.swift
//  Zone-Swift
//
//  Created by 叶云 on 16/7/8.
//  Copyright © 2016年 叶云. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var sort: UIButton!
    @IBOutlet weak var equals: UIButton!
    @IBOutlet weak var msg: UILabel!
    @IBOutlet weak var delete: UIButton!
    @IBOutlet weak var add: UIButton!
    
    @IBOutlet weak var limit: UIButton!
    @IBOutlet weak var update: UIButton!
    
    @IBOutlet weak var findAll: UIButton!
    
    var i = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        add.addTarget(self, action: #selector(ViewController.addModel), for: UIControlEvents.touchUpInside)
        
        findAll.addTarget(self, action: #selector(ViewController.find), for: UIControlEvents.touchUpInside)
        
        update.addTarget(self, action: #selector(ViewController.updateModel), for: UIControlEvents.touchUpInside)
        
        delete.addTarget(self, action: #selector(ViewController.deleteModel), for: UIControlEvents.touchUpInside)
        
        limit.addTarget(self, action: #selector(ViewController.limitModel), for: UIControlEvents.touchUpInside)
        
        equals.addTarget(self, action: #selector(ViewController.equalsSelect), for: UIControlEvents.touchUpInside)
        sort.addTarget(self, action: #selector(ViewController.sortModel), for: UIControlEvents.touchUpInside)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func addModel() {
        let testModel = TestModel()
        i = i + 1
        testModel.age = i * 10
        testModel.birthday = Date()
        testModel.name = "testModel"
        testModel.model = TestModel2()
        testModel.model.money = 11
        do{
            try testModel.saveOrUpdate()
        }catch{
            
        }
    }
    
    func updateModel(){
        do{
            let modelList = try Zone.findAll(NSStringFromClass(TestModel.classForCoder()))
            if modelList.count > 0{
                (modelList[modelList.count - 1] as! TestModel).name = "updateModel"
                try (modelList[modelList.count - 1] as! TestModel).saveOrUpdate()
            }
            msg.text = "更新成功"
        }catch{
            
        }
    }
    
    func find(){
        do{
            let modelList = try Zone.findAll(NSStringFromClass(TestModel.classForCoder()))
            msg.text = "当前数据量：\(modelList.count)"
        }catch{
            
        }
    }
    
    func limitModel(){
        do{
            let modelList = try Zone.limit(0, end: 10, className: NSStringFromClass(TestModel.classForCoder()))
            msg.text = "limit数据量：\(modelList.count)"
        }catch{
            
        }
    }
    
    
    
    func deleteModel(){
        do{
            let modelList = try Zone.findAll(NSStringFromClass(TestModel.classForCoder()))
            if modelList.count > 1{
                let model = modelList[modelList.count - 2]
                if try (model as! TestModel).del(){
                    msg.text = "删除成功"
                }
            }
        }catch{
            
        }
    }
    
    func equalsSelect(){
        do{
            if let modelList = try Zone.selectWhere(WhereCondition.equals, className: NSStringFromClass(TestModel.classForCoder()), fieldName: "name", value: "testModel" as AnyObject){
                    msg.text = "equals查询到：\(modelList.count)"
            }
        }catch{
            
        }
    }
    
    func sortModel() {
        do{
            try Zone.orderBy(NSStringFromClass(TestModel.classForCoder()), sortField: "age", sordMode: SortMode.desc)
        }catch{
            
        }
        msg.text = "排序成功"
    }

}

