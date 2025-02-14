//
//  DetailModule.swift
//  ModuleRouteExample
//
//  Created by GIKI on 2025/2/14.
//

import Foundation
import ModuleRoute
import UIKit

class DetailModule: MRModule {

    var supportedRoutes: [MRRoute.Type] {
        return [
            DetailRoute.self
        ]
    }
    
    
    public init() {}

    public func handle(route: MRRoute) -> RouteResult {
        // 根据具体路由做出响应
        switch route {
        case is DetailRoute:
            let detail = DetailViewController()
            return .viewController(detail)
        default:
            return .none
        }
    }
}
