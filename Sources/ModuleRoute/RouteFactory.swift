//
//  RouteHandler.swift
//  ModuleRoute
//
//  Created by GIKI on 2025/2/13.
//

import Foundation
import UIKit

public protocol RouteFactory {
    
    var supportedRoutes: [MRRoute.Type] { get }
    func destinationModule(for route: MRRoute, from viewController: UIViewController) -> MRModule.Type?
    
}

// MARK: - RouteInterceptor Protocol

public protocol RouteInterceptor {
    func intercept(route: MRRoute, from viewController: UIViewController) -> MRRoute?
}
