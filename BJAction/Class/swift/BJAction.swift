//
//  BJAction.swift
//  BJAction
//
//  Created by Mrlu on 2018/8/27.
//  Copyright © 2018 Mrlu. All rights reserved.
//

import Foundation

class BJAction: NSObject {
    
    var scheme:String?
    var host:String?
    var path:String?
    var actionKey:String = "action"
    var payload:String?
    
    typealias BJActionHandler = (_ target:Any, _ payload:Dictionary<String, Any>? ,_ callBack:BJActionHandlerCallBack?) -> Void
    typealias BJActionHandlerCallBack = (_ payload:Dictionary<String, Any>? ) -> Void
    
    private lazy var listeners:NSMutableDictionary = {
        return NSMutableDictionary()
    }()
    
    public static let shared = BJAction()
    
    override init() {
        
    }
    
    convenience init(scheme:String, host:String, path:String, actionKey:String = "action") {
        self.init()
        self.scheme = scheme
        self.host = host
        self.path = path
        self.actionKey = actionKey
    }
    
    func on(type:String, handler:BJActionHandler) {
        var listenerList:NSMutableArray? = listeners.object(forKey: type) as? NSMutableArray
        if listenerList == nil {
            listenerList = NSMutableArray()
            self.listeners.setValue(listenerList, forKey: type)
        }
        listenerList?.add(handler)
    }
    
    func off(type:String) {
        listeners.removeObject(forKey: type)
    }
    
    func send(to target:Any, url:URL) -> Bool {
        if url.scheme == scheme {
            if host == nil {
                let eventType:String = url.host ?? ""
                let query:String? = url.query
                var param:Dictionary<String, Any>?
                if let aquery = query {
                    var jsonString:String?
                    if #available(iOS 9.0, *) {
                        jsonString = (aquery as NSString).removingPercentEncoding
                    } else {
                        jsonString = (aquery as NSString).replacingPercentEscapes(using: String.Encoding.utf8.rawValue)
                    }
                    param = jsonString?.__queryDictionary
                }
                return triggerEvent(to: target, event: eventType, data: param)
            } else if let host = url.host, host == self.host {
                var path:String?
                let pathStr = url.path
                if pathStr.count > 1 {
                    path = String(pathStr[pathStr.index(pathStr.startIndex, offsetBy: 1)...])
                }
                if self.path == nil || self.path == path {
                    let query:String? = url.query
                    var param:Dictionary<String, Any>?
                    if let aquery = query {
                        var jsonString:String?
                        if #available(iOS 9.0, *) {
                            jsonString = (aquery as NSString).removingPercentEncoding
                        } else {
                            jsonString = (aquery as NSString).replacingPercentEscapes(using: String.Encoding.utf8.rawValue)
                        }
                        param = jsonString?.__queryDictionary
                    }
                    return triggerEvent(to: target, data: param)
                } else {
                    print("匹配失败: path error \(String(describing: url.path))")
                    return false
                }
            } else {
                print("匹配失败: host error \(String(describing: url.host))")
                return false
            }
        } else {
            print("匹配失败: schema error \(String(describing: url.scheme))")
            return false
        }
    }
    
    func send(to target:Any, actionName:String, payload:Dictionary<String, Any>,callback:BJActionHandlerCallBack? = nil) -> Bool
    {
        let listenerList:NSArray? = listeners.value(forKey: actionName) as? NSArray
        if let aListenerList = listenerList {
            for handle in aListenerList {
                if let ahandle = handle as? BJActionHandler {
                    ahandle(target, payload, callback)
                }
            }
        }
        return true
    }
    
    private func triggerEvent(to target:Any, event:String, data:Dictionary<String, Any>?) -> Bool {
        let listenerList:NSArray? = listeners.value(forKey: event) as? NSArray
        var payload = data
        if let aData = data {
            if let apayload = self.payload {
                payload = aData[apayload] as? Dictionary<String, Any>
            }
        }
        if let aListenerList = listenerList {
            for handle in aListenerList {
                if let ahandle = handle as? BJActionHandler {
                    ahandle(target, payload, nil)
                }
            }
            return true
        }
        return false
    }
    
    private func triggerEvent(to target:Any, data:Dictionary<String, Any>?) -> Bool {
        var key:String?
        var payload:Dictionary<String, Any>? = data
        var listenerList:NSArray?
        if let aData = data {
            key = aData[self.actionKey] as? String
            if let apayload = self.payload {
                payload = aData[apayload] as? Dictionary<String, Any>
            }
            if let akey = key {
                listenerList = listeners.value(forKey: akey) as? NSArray
            }
            if let aListenerList = listenerList {
                for handle in aListenerList {
                    if let ahandle = handle as? BJActionHandler {
                        ahandle(target, payload, nil)
                    }
                }
                return true
            }
        }
        return false
    }
    
    deinit {
        listeners.removeAllObjects()
    }
}

extension String {
    var __queryDictionary: [String: String]? {
        let query = self
        var queryStrings = [String: String]()
        for pair in query.components(separatedBy: "&") {
            let key = pair.components(separatedBy: "=")[0]
            let value = pair
                .components(separatedBy:"=")[1]
                .replacingOccurrences(of: "+", with: " ")
                .removingPercentEncoding ?? ""
            
            queryStrings[key] = value
        }
        return queryStrings
    }
}
