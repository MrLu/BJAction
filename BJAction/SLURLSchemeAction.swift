//
//  SLURLSchemeAction.swift
//  BJAction
//
//  Created by Mrlu on 2018/8/28.
//  Copyright © 2018 Mrlu. All rights reserved.
//

import UIKit

class SLURLSchemeAction: NSObject {
    
    private let action:BJAction = {
        let action = BJAction(scheme: "bjaction", host: "internal.com", path: "redirect", actionKey: "action")
        return action
    }()
    
    static let shared:SLURLSchemeAction = SLURLSchemeAction()
    
    private override init() {
        
    }
    
    func send(to target:Any, url:URL) -> Bool {
        return action.send(to:target, url:url)
    }
    
    func addURLSchemeAction() {
        action.on(type: "web") { (target, payload, callBack) in
            print("payload: \(String(describing: payload))")
        }
    }
    
    private func removeURLSchemeAction() {
        action.off(type: "web")
    }
    
    deinit {
        removeURLSchemeAction()
    }
}
