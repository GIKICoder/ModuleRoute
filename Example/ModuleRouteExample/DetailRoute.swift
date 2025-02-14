//
//  DetailRoute.swift
//  ModuleRouteExample
//
//  Created by GIKI on 2025/2/14.
//

import Foundation
import ModuleRoute

struct DetailRoute: MRRoute {
    static var name: String = "detail"
    
    public var parameters: [String: Any] = [:]
    
    init(parameters: [String: Any]) {
        self.parameters = parameters
    }

}
