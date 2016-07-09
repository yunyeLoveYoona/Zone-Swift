//
//  ViewController.swift
//  Zone-Swift
//
//  Created by 叶云 on 16/7/8.
//  Copyright © 2016年 叶云. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var add: UIButton!
    
    @IBOutlet weak var update: UIButton!
    
    @IBOutlet weak var findAll: UIButton!
    
    var i = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        add.addTarget(self, action: #selector(ViewController.addModel), forControlEvents: UIControlEvents.TouchUpInside)
        
        findAll.addTarget(self, action: #selector(ViewController.find), forControlEvents: UIControlEvents.TouchUpInside)
        
        update.addTarget(self, action: #selector(ViewController.updateModel), forControlEvents: UIControlEvents.TouchUpInside)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func addModel() {
        let testModel = TestModel()
        i = i + 1
        testModel.age = i * 10
        testModel.birthday = NSDate()
        testModel.name = "testModel"
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
            update.setTitle("更新成功", forState: UIControlState.Normal)
        }catch{
            
        }
    }
    
    func find(){
        do{
            let modelList = try Zone.findAll(NSStringFromClass(TestModel.classForCoder()))
            findAll.setTitle("当前数据量：\(modelList.count)", forState: UIControlState.Normal)
        }catch{
            
        }
    }

}

