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
    
    public let container: DependencyContainer
    private var routeHandlers = [String: RouteFactory]()
    private var interceptors = [RouteInterceptor]()

    public init(container: DependencyContainer = DefaultDependencyContainer()) {
        self.container = container
        register(dependencyFactory: {
            [unowned self] in self
        }, forType: MRNavigator.self)
    }
    
    public func register<T>(dependencyFactory: @escaping DependencyFactory, forType type: T.Type) {
        container.register(dependencyFactory: dependencyFactory, forType: type)
    }
    
    public func register(routeHandler: RouteFactory) {
        for route in routeHandler.supportedRoutes {
            routeHandlers[route.identifier] = routeHandler
        }
    }
    
    public func addInterceptor(_ interceptor: RouteInterceptor) {
        interceptors.append(interceptor)
    }
}

// MARK: - MRNavigator + navigate
extension MRNavigator {
    
    public func handleDeepLink(url: URL,
                               from viewController: UIViewController,
                               using style: PresentationStyle,
                               animated: Bool = true,
                               completion: ((Result<Void, Error>) -> Void)? = nil) {
        guard let scheme = url.scheme,
              let absoluteStr = url.absoluteString.removingPrefix("\(scheme)://") else {
            return
        }
        
        let components = absoluteStr.components(separatedBy: "|")
        guard let routeIdentifier = components.first else {
            return
        }
        
        var parameters = [String: Any]()
        if components.count > 1, let jsonString = components.last,
           let jsonData = jsonString.data(using: .utf8),
           let jsonDict = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
            parameters = jsonDict
        }
        
        guard let handler = routeHandlers[routeIdentifier] else {
            return
        }
        
        if let routeType = handler.supportedRoutes.first(where: { $0.identifier == routeIdentifier }),
           let route = routeType.init(parameters: parameters) {
            navigate(to: route, from: viewController, using: style, animated: animated, completion: completion)
        } else {
            
        }
    }
}

// MARK: - MRNavigator + navigate 
extension MRNavigator {
    
    /// Navigate with success/failure completion handler
    public func navigate(to originalRoute: MRRoute,
                        from viewController: UIViewController,
                        using style: PresentationStyle,
                        animated: Bool = true,
                        completion: ((Result<Void, Error>) -> Void)? = nil) {
        
        var route = originalRoute
        for interceptor in interceptors {
            if let interceptedRoute = interceptor.intercept(route: route, from: viewController) {
                route = interceptedRoute
            } else {
                completion?(.failure(NavigationError.intercepted))
                return
            }
        }
        
        guard let handler = routeHandlers[type(of: route).identifier],
              let destinationModuleType = handler.destinationModule(for: route, from: viewController) else {
            completion?(.failure(NavigationError.noHandler))
            return
        }
        
        let module = destinationModuleType.init()
        module.resolveDependencies(using: container)
        
        let destinationVC: UIViewController
        if module.isEnabled(route: route) {
            destinationVC = module.build(from: route)
        } else if let fallbackModuleType = module.fallbackModule(for: route) {
            let fallbackModule = fallbackModuleType.init()
            fallbackModule.resolveDependencies(using: container)
            destinationVC = fallbackModule.build(from: route)
        } else {
            completion?(.failure(NavigationError.moduleDisabled))
            return
        }
        
        style.present(viewController: destinationVC,
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

// MARK: - String Extension

extension String {
    func removingPrefix(_ prefix: String) -> String? {
        guard self.hasPrefix(prefix) else { return nil }
        return String(self.dropFirst(prefix.count))
    }
}
