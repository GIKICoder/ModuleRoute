//
//  Navigator.swift
//  ModuleRoute
//
//  Created by GIKI on 2025/2/13.
//

import Foundation
import UIKit

// MARK: - Navigator
@MainActor
public class MRNavigator {
    
    public let container = DefaultDependencyContainer.shared
    private var routeModules = [String: MRModule]()
    
    public init() {
        register(dependencyFactory: { [unowned self] in
            self
        }, forType: MRNavigator.self)
    }
    
    public func register<T>(dependencyFactory: @escaping DependencyFactory, forType type: T.Type) {
        container.register(dependencyFactory: dependencyFactory, forType: type)
    }

    public func register(module: MRModule) {
        for route in module.supportedRoutes {
            routeModules[route.name] = module
        }
    }
  
}

// MARK: - MRNavigator + navigate
extension MRNavigator {
    
    /// Navigate with success/failure completion handler
    public func navigate(to route: MRRoute,
                         from viewController: UIViewController,
                         using style: PresentationStyle,
                         animated: Bool = true,
                         completion: ((Result<Void, Error>) -> Void)? = nil) {
        
        guard let module = routeModules[type(of: route).name]  else {
            completion?(.failure(NavigationError.noHandler))
            return
        }
    
        guard let target = module.build(from: route) else {
            completion?(.failure(NavigationError.noHandler))
            return
        }
        style.present(viewController: target,
                      from: viewController,
                      animated: animated) {
            completion?(.success(()))
        }
        
    }
}

// MARK: - Convenience Methods
extension MRNavigator {
    
    /// Navigate using top view controller with push style
    public func navigatePush(to route: MRRoute,
                             animated: Bool = true,
                             completion: ((Result<Void, Error>) -> Void)? = nil) {
        guard let topVC = UIApplication.shared.topViewController else {
            completion?(.failure(NavigationError.noTopViewController))
            return
        }
        navigate(to: route,
                 from: topVC,
                 using: PushPresentation(),
                 animated: animated,
                 completion: completion)
    }
    
    /// Navigate using top view controller with modal style
    public func navigateModal(to route: MRRoute,
                              animated: Bool = true,
                              completion: ((Result<Void, Error>) -> Void)? = nil) {
        guard let topVC = UIApplication.shared.topViewController else {
            completion?(.failure(NavigationError.noTopViewController))
            return
        }
        navigate(to: route,
                 from: topVC,
                 using: ModalPresentation(),
                 animated: animated,
                 completion: completion)
    }
}

// MARK: - Navigation Error
enum NavigationError: Error {
    case intercepted
    case noHandler
    case moduleDisabled
    case noTopViewController
}

// MARK: - UIApplication Extension
extension UIApplication {
    var topViewController: UIViewController? {
        let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
        if var topController = keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            return topController
        }
        return nil
    }
}
