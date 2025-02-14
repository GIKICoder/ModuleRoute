//
//  Module.swift
//  ModuleRoute
//
//  Created by GIKI on 2025/2/13.
//

import UIKit

// 路由处理结果枚举
public enum RouteResult {
    case navigator(UIViewController)  // 返回控制器
    case handler(() -> Void)              // 执行闭包
    case service(Any)                     // 返回服务实例
    case value(Any)                       // 返回值
    case none                             // 无返回
}

public protocol MRModule {
    
    var supportedRoutes: [MRRoute.Type] { get }
    // 处理路由请求
    func handle(route: MRRoute) -> RouteResult
}

extension MRModule {
    // 如果路由处理结果为 .viewController，则返回构造的目标控制器，否则返回 nil
    func build(from route: MRRoute) -> UIViewController? {
        switch handle(route: route) {
        case .navigator(let vc):
            return vc
        default:
            return nil
        }
    }
}
