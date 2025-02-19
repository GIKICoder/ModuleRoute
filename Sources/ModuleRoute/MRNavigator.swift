//
//  Navigator.swift
//  ModuleRoute
//
//  Created by GIKI on 2025/2/13.
//

import UIKit

public class MRNavigator {
    
    public let serviceLocator: ServiceLocator
    
    private var middlewares: [MRMiddleware] = []
    private var interceptors: [MRInterceptor] = []
    private var deepLinkParser = DeepLinkParser()
    private var logger: MRLogger = DefaultLogger()
    private var permissionChecker: MRPermissionChecker = DefaultPermissionChecker()
    
    public init(serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
        MRNavigatorLocator.shared.serviceLocator = serviceLocator
        serviceLocator.register {
            self
        }
        buildServiceLocator()
    }
    
    private var routeToModuleTypeMap: [ObjectIdentifier: (ServiceLocator) -> MRModule] = [:]
    
    public func register<T>(_ type: T.Type = T.self, routes: [MRRoute.Type], _ factory: @escaping () -> T) -> Void {
        serviceLocator.single(type, factory)
        routes.forEach { routeType in
            let key = ObjectIdentifier(routeType)
            routeToModuleTypeMap[key] = { locator in
                guard let instance = try? locator.resolve() as T else {
                    fatalError("Failed to resolve type \(T.self)")
                }
                return instance as! MRModule
            }
        }
        buildServiceLocator()
    }
    
    private func buildServiceLocator() {
        if #available(iOS 13.0, *) {
            Task{
                await serviceLocator.build()
            }
        }
    }
    
    public func addMiddleware(_ middleware: MRMiddleware) {
        middlewares.append(middleware)
    }
    
    public func addInterceptor(_ interceptor: MRInterceptor) {
        interceptors.append(interceptor)
    }
    
    public func navigate(to route: MRRoute,
                         from viewController: UIViewController? = nil,
                         navigationType: NavigationType = .push,
                         animated: Bool = true,
                         completion: (() -> Void)? = nil) {
        
        if let permissionResult = checkPermission(for: route) {
            handleResult(permissionResult, from: viewController, navigationType: navigationType, animated: animated, completion: completion)
            return
        }
        
        let result = processMiddlewares(route: route)
        handleResult(result, from: viewController, navigationType: navigationType, animated: animated, completion: completion)
    }
    
    public func registerDeepLinkHandler(scheme: String, handler: @escaping (URL) -> MRRoute?) {
        deepLinkParser.register(scheme: scheme, handler: handler)
    }
    
    public func handleDeepLink(_ url: URL) -> Bool {
        guard let route = deepLinkParser.parse(url: url) else {
            return false
        }
        
        if let topvc = topViewController() {
            navigate(to: route, from: topvc)
            return true
        }
        return false
    }
    
    private func processMiddlewares(route: MRRoute, index: Int = 0) -> RouteResult {
        if index >= middlewares.count {
            return handleRouteDirectly(route: route)
        }
        
        let middleware = middlewares[index]
        return middleware.process(route: route, navigator: self) { [weak self] route in
            guard let self = self else { return .none }
            return self.processMiddlewares(route: route, index: index + 1)
        }
    }
    
    private func handleRouteDirectly(route: MRRoute) -> RouteResult {
        for interceptor in interceptors {
            if interceptor.shouldIntercept(route: route) {
                return interceptor.handleInterception(route: route)
            }
        }
        
        let routeTypeKey = ObjectIdentifier(type(of: route))
        guard let moduleFactory = routeToModuleTypeMap[routeTypeKey] else {
            logger.log(level: .warning, message: "No module found for route: \(type(of: route))", metadata: nil)
            return .none
        }
        
        let module = moduleFactory(serviceLocator)
        let result = module.handle(route: route)
        logRoute(route, result: result)
        return result
    }
    
    private func handleResult(_ result: RouteResult,
                              from viewController: UIViewController?,
                              navigationType: NavigationType,
                              animated: Bool,
                              completion: (() -> Void)?) {
        switch result {
        case .navigator(let targetVC):
            perform(navigation: navigationType,
                    from: viewController,
                    to: targetVC,
                    animated: animated,
                    completion: completion)
        case .handler(let handler):
            handler()
            completion?()
        case .service(_),
                .value(_),
                .none:
            completion?()
        }
    }
    
    private func perform(navigation type: NavigationType,
                         from: UIViewController?,
                         to: UIViewController,
                         animated: Bool,
                         completion: (() -> Void)?) {
        var temp = (from != nil) ? from : topViewController()
        guard let base = temp else {
            completion?()
            return
        }
        switch type {
        case .push:
            if let navigationController = base.navigationController {
                navigationController.pushViewController(to, animated: animated)
                completion?()
            } else {
                let nav = UINavigationController(rootViewController: to)
                base.present(nav, animated: animated, completion: completion)
            }
        case .present:
            base.present(to, animated: animated, completion: completion)
        case .modal:
            to.modalPresentationStyle = .fullScreen
            base.present(to, animated: animated, completion: completion)
        case .replace:
            guard let navigationController = base.navigationController else {
                completion?()
                return
            }
            var viewControllers = navigationController.viewControllers
            viewControllers.removeLast()
            viewControllers.append(to)
            navigationController.setViewControllers(viewControllers, animated: animated)
            completion?()
        case .custom(let handler):
            handler(base, to)
            completion?()
        }
    }
    
    private func checkPermission(for route: MRRoute) -> RouteResult? {
        guard permissionChecker.hasPermission(for: route) else {
            return permissionChecker.handleUnauthorized(route: route)
        }
        return nil
    }
    
    private func logRoute(_ route: MRRoute, result: RouteResult) {
        logger.log(level: .info,
                   message: "Processing route: \(type(of: route))",
                   metadata: ["params": route.params, "result": String(describing: result)])
    }
}


public extension MRNavigator {
    
    ///  Get the top most view controller from the base view controller; default param is UIWindow's rootViewController
    func topViewController(_ from: UIViewController? = nil) -> UIViewController? {
        var base = (from != nil) ? from : compatibleKeyWindow?.rootViewController
        if let nav = base as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(presented)
        }
        return base
    }

    var compatibleKeyWindow: UIWindow? {
        if #available(iOS 13, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.keyWindow
        }
    }
    /// 重置应用到根视图控制器
    func resetToRootViewController(_ animated: Bool = false) {
        guard let window = compatibleKeyWindow,
              let rootViewController = window.rootViewController else {
            return
        }
        
        // 1. 先处理当前显示的模态视图
        if let presentedVC = rootViewController.presentedViewController {
            presentedVC.dismiss(animated: false) {
                self.resetToRootHelper(rootViewController, animated: animated)
            }
        } else {
            resetToRootHelper(rootViewController, animated: animated)
        }
    }
    
    private func resetToRootHelper(_ rootViewController: UIViewController, animated: Bool) {
        // 2. 处理 UINavigationController
        if let navigationController = rootViewController as? UINavigationController {
            navigationController.popToRootViewController(animated: animated)
        }
        
        // 3. 处理 UITabBarController
        if let tabBarController = rootViewController as? UITabBarController {
            // 重置所有 tab 的导航栈
            tabBarController.viewControllers?.forEach { viewController in
                if let navigationController = viewController as? UINavigationController {
                    navigationController.popToRootViewController(animated: animated)
                }
            }
            // 切换到第一个 tab
            tabBarController.selectedIndex = 0
        }
    }
}
