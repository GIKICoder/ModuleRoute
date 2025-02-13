//
//  DependencyContainer.swift
//  ModuleRoute
//
//  Created by GIKI on 2025/2/13.
//

import Foundation

public typealias DependencyFactory = () -> Any

public protocol DependencyContainer {
    func register<T>(dependencyFactory: @escaping DependencyFactory, forType type: T.Type)
    func resolve<T>(_ type: T.Type) -> T?
}

public class DefaultDependencyContainer: DependencyContainer {

    private var factories = [String: DependencyFactory]()
    private var instances = [String: Any]()

    public init() {}

    public func register<T>(dependencyFactory: @escaping DependencyFactory, forType type: T.Type) {
        let key = "\(type)"
        factories[key] = dependencyFactory
    }

    public func resolve<T>(_ type: T.Type) -> T? {
        let key = "\(type)"
        // 检查是否已有实例
        if let instance = instances[key] as? T {
            return instance
        }

        // 使用工厂创建新实例
        if let factory = factories[key] {
            let instance = factory()
            instances[key] = instance
            return instance as? T
        }

        return nil
    }
}
