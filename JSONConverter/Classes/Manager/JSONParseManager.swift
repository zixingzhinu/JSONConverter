//
//  JSONParseManager.swift
//  Test
//
//  Created by Yao on 2018/2/3.
//  Copyright © 2018年 Yao. All rights reserved.
//

import Foundation

class JSONParseManager {
    
    static let shared: JSONParseManager = {
        let manager = JSONParseManager()
        return manager
    }()
    
    private var file: File!
    
    func parseJSONObject(_ obj: Any, file: File) -> (String, String?) {
        file.contents.removeAll()
        self.file = file
        var content : Content?
        let propertyKey = file.rootName.propertyName()
        
        switch obj {
        case let dic as [String: Any]:
            content = handleDictionary(propertyKey: propertyKey, dic: dic)
        case let arr as [Any]:
            _ = handleArray(itemKey: propertyKey, arr: arr)
        default:
            assertionFailure("parse object type error")
        }
        
        if let content = content {
            file.contents.insert(content, at: 0)
        }
        
        return file.toString()
    }
    
    
    private func handleDictionary(propertyKey: String, dic: [String: Any]) -> Content {
        let content = file.content(withPropertyKey: propertyKey)
        
        dic.forEach { (item) in
            let itemKey = item.key
            var propertyModel: Property?
            
            switch item.value {
            case _ as String:
                propertyModel = file.property(withPropertykey: itemKey, type: .String)
            case let num as NSNumber:
                propertyModel = file.property(withPropertykey: itemKey, type: num.valueType())
            case let dic as [String: Any]:
                propertyModel = file.property(withPropertykey: itemKey, type: .Dictionary)
                let content = handleDictionary(propertyKey: itemKey, dic: dic)
                file.contents.insert(content, at: 0)
            case let arr as [Any]:
                propertyModel = handleArray(itemKey: itemKey, arr: arr)
            case _ as NSNull:
                fallthrough
            case nil:
                propertyModel = file.property(withPropertykey: itemKey, type: .nil)
            default:
                assertionFailure("parse object type error")
            }
            
            if let propertyModel = propertyModel {
                content.properties.append(propertyModel)
            }
        }
        
        return content
    }
    
    private func handleArray(itemKey: String, arr: [Any]) -> Property? {
        if let first = arr.first {
            var propertyModel: Property?
            switch first {
            case _ as String:
                propertyModel = file.property(withPropertykey: itemKey, type: .ArrayString)
            case let num as NSNumber:
                let type = PropertyType(rawValue: num.valueType().rawValue + 6)!
                propertyModel = file.property(withPropertykey: itemKey, type: type)
            case _ as [String: Any]:
                let unionDic = unionDictionaryFromArrayElements(arr)
                propertyModel = file.property(withPropertykey: itemKey, type: .ArrayDictionary)
                let content = handleDictionary(propertyKey: itemKey, dic: unionDic)
                file.contents.insert(content, at: 0)
            default:
                assertionFailure("parse object type error")
                break
            }
            
            return propertyModel
        }
        
        return nil
    }
    
    /**
    Creates and returns a dictionary who is built up by combining all the dictionary elements in the passed array.

    - parameter array: array of dictionaries.
    - returns: dictionary that combines all the dictionary elements in the array.
    */
    private func unionDictionaryFromArrayElements(_ array: [Any]) -> [String: Any]
    {
//        let dictionary = NSMutableDictionary()
        var dictionary = [String: Any]()
        for item in array {
            if let dic = item as? NSDictionary {
                //loop all over its keys
                for key in dic.allKeys as! [String] {
                    guard let value = dic[key] else { continue }
                    if value is NSArray {
                        let t = value as! NSArray
                        if t.count > 0 {
                            dictionary[key] = value
                        }
                    }
                    else if value is NSDictionary {
                        let t = value as! NSDictionary
                        if t.count > 0 {
                            dictionary[key] = value
                        }
                    }
                    else {
                        dictionary[key] = value
                    }
                }
    //            dictionary = dictionary.merging(dic) { (first, second) -> AnyObject in
    //                if first != nil {
    //                    return first
    //                }
    //            }
            }
        }
        return dictionary
    }
}
    
    





