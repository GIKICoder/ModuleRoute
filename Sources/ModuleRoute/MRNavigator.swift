//
//  Navigator.swift
//  ModuleRoute
//
//  Created by GIKI on 2025/2/13.
//

import UIKit

public class MRNavigator {
    private let container: DependencyContainer
    private var routeToModuleTypeMap: [String: (DependencyContainer) -> MRModule] = [:]
    private var moduleFactoryMap: [String: () -> MRModule] = [:]
    private var middlewares: [MRMiddleware] = []
    private var interceptors: [MRInterceptor] = []
    private var deepLinkParser = DeepLinkParser()
    private var logger: MRLogger = DefaultLogger()
    private var permissionChecker: MRPermissionChecker = DefaultPermissionChecker()
    
    public init(container: DependencyContainer = DefaultDependencyContainer.shared) {
        self.container = container
    }
    
    // MARK: - Registration
    public func register<Interface, Module>(dependencyFactory: @escaping () -> Module,
                                            forType type: Interface.Type) where Module: MRModule {
        container.register(dependencyFactory: dependencyFactory, forType: type)
        
        // 注册路由映射
        Module.supportedRoutes.forEach { routeType in
            routeToModuleTypeMap[routeType.name] = { container in
                // 通过容器获取模块实例
                guard let module = container.resolve(Module.self) else {
                    fatalError("Failed to resolve module: \(Module.self)")
                }
                return module
            }
        }
    }
    
    // MARK: - Middleware & Interceptor
    public func addMiddleware(_ middleware: MRMiddleware) {
        middlewares.append(middleware)
    }
    
    public func addInterceptor(_ interceptor: MRInterceptor) {
        interceptors.append(interceptor)
    }
    
    // MARK: - Navigation
    public func navigate(to route: MRRoute,
                         from viewController: UIViewController,
                         navigationType: NavigationType = .push,
                         animated: Bool = true,
                         completion: (() -> Void)? = nil) {
        
        // 权限检查
        if let permissionResult = checkPermission(for: route) {
            handleResult(permissionResult, from: viewController, navigationType: navigationType, animated: animated, completion: completion)
            return
        }
        
        // 处理路由
        let result = processMiddlewares(route: route)
        handleResult(result, from: viewController, navigationType: navigationType, animated: animated, completion: completion)
    }
    
    // MARK: - DeepLink
    public func registerDeepLinkHandler(scheme: String, handler: @escaping (URL) -> MRRoute?) {
        deepLinkParser.register(scheme: scheme, handler: handler)
    }
    
    public func handleDeepLink(_ url: URL) -> Bool {
        guard let route = deepLinkParser.parse(url: url) else {
            return false
        }
        
        if let rootVC = UIApplication.shared.keyWindow?.rootViewController {
            navigate(to: route, from: rootVC)
            return true
        }
        return false
    }
    
    // MARK: - Private Methods
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
    
    // MARK: - Route Handling
    private func handleRouteDirectly(route: MRRoute) -> RouteResult {
        // 检查拦截器
        for interceptor in interceptors {
            if interceptor.shouldIntercept(route: route) {
                return interceptor.handleInterception(route: route)
            }
        }
        
        // 获取对应的模块工厂
        guard let moduleFactory = routeToModuleTypeMap[type(of: route).name] else {
            logger.log(level: .warning, message: "No module found for route: \(type(of: route).name)", metadata: nil)
            return .none
        }
        
        // 通过容器获取或创建模块实例
        let module = moduleFactory(container)
        let result = module.handle(route: route)
        logRoute(route, result: result)
        return result
    }
    
    private func handleResult(_ result: RouteResult,
                              from viewController: UIViewController,
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
        case .service(_):
            completion?()
        case .value(_):
            completion?()
        case .none:
            completion?()
        }
    }
    
    private func perform(navigation type: NavigationType,
                         from: UIViewController,
                         to: UIViewController,
                         animated: Bool,
                         completion: (() -> Void)?) {
        switch type {
        case .push:
            from.navigationController?.pushViewController(to, animated: animated)
            completion?()
        case .present:
            from.present(to, animated: animated, completion: completion)
        case .modal:
            to.modalPresentationStyle = .fullScreen
            from.present(to, animated: animated, completion: completion)
        case .replace:
            guard let navigationController = from.navigationController else {
                completion?()
                return
            }
            var viewControllers = navigationController.viewControllers
            viewControllers.removeLast()
            viewControllers.append(to)
            navigationController.setViewControllers(viewControllers, animated: animated)
            completion?()
        case .custom(let handler):
            handler(from, to)
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
                   message: "Processing route: \(type(of: route).name)",
                   metadata: ["params": route.params, "result": String(describing: result)])
    }
}
