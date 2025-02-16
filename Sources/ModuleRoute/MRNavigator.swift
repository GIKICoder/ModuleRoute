//
//  Navigator.swift
//  ModuleRoute
//
//  Created by GIKI on 2025/2/13.
//

import UIKit

public class MRNavigator {
    private let container: DependencyContainer
    
    private var middlewares: [MRMiddleware] = []
    private var interceptors: [MRInterceptor] = []
    private var deepLinkParser = DeepLinkParser()
    private var logger: MRLogger = DefaultLogger()
    private var permissionChecker: MRPermissionChecker = DefaultPermissionChecker()
    
    // 在初始化时，将自身注册到容器中，保证 MRNavigator 也能被注入
    public init(container: DependencyContainer = DefaultDependencyContainer.shared) {
        self.container = container
        // 将当前 navigator 注册为依赖项
        self.container.register(dependencyFactory: { self }, forType: MRNavigator.self)
    }
    
    // 修改后的字典，使用 ObjectIdentifier 作为键
    private var routeToModuleTypeMap: [ObjectIdentifier: (DependencyContainer) -> MRModuleInterface] = [:]
    
    // MARK: - Registration
    public func register<T>(dependencyFactory: @escaping DependencyFactory, forType type: T.Type) where T: MRModuleInterface {
        container.register(dependencyFactory: dependencyFactory, forType: type)
        
        // 将模块的所有支持路由逐一映射到通过容器解析模块实例的闭包
        T.supportedRoutes.forEach { routeType in
            let key = ObjectIdentifier(routeType)
            routeToModuleTypeMap[key] = { container in
                // 通过容器获取模块实例
                guard let module = container.resolve(T.self) else {
                    fatalError("Failed to resolve module: \(T.self)")
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
        
        // 通过中间件处理路由，链式调用
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
        
        if let rootVC = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController {
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
        // 检查是否有拦截器需要处理当前路由
        for interceptor in interceptors {
            if interceptor.shouldIntercept(route: route) {
                return interceptor.handleInterception(route: route)
            }
        }
        
        // 通过路由的类型获取模块
        let routeTypeKey = ObjectIdentifier(type(of: route))
        guard let moduleFactory = routeToModuleTypeMap[routeTypeKey] else {
            logger.log(level: .warning, message: "No module found for route: \(type(of: route))", metadata: nil)
            return .none
        }
        
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
        case .service(_),
             .value(_),
             .none:
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
                   message: "Processing route: \(type(of: route))",
                   metadata: ["params": route.params, "result": String(describing: result)])
    }
}
