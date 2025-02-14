//
//  AppRouteFacotry.swift
//  ModuleRouteExample
//
//  Created by GIKI on 2025/2/14.
//

import Foundation
import ModuleRoute
import UIKit
class AppRouteFacotry:RouteFactory {
    var supportedRoutes: [MRRoute.Type] {
        return []
    }
    
    func destinationModule(for route: MRRoute, from viewController: UIViewController) -> MRModule.Type? {
        return nil
    }
}
