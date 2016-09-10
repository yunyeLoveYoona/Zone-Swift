Pod::Spec.new do |s| 
    # 名称 使用的时候pod search [name] 
    s.name = "Zone" 
    # 代码库的版本 
    s.version = "1.0.2" 
    # 简介 
    s.summary = "一个Swift文件型数据库" 
    # 主页  
    s.homepage = "https://github.com/yunyeLoveYoona/Zone-Swift" 
    # 许可证书类型，要和仓库的LICENSE 的类型一致 
    s.license = "MIT" 
    # 作者名称 和 邮箱 
    s.author = { "yeyun" => "550752356@qq.com" }  
    # 代码库最低支持的版本 
    s.platform = :ios, "8.0" 
    # 代码的Clone 地址 和 tag 版本 
    s.source = { :git => "https://github.com/yunyeLoveYoona/Zone-Swift.git", :tag => "1.0.2" } 
    # 如果使用pod 需要导入哪些资源 
    s.source_files = "Zone-Swift/core/*.{swift}" 
    # 框架是否使用的ARC 
    s.requires_arc = true  
end