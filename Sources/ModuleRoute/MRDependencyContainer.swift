//
//  File.swift
//  ModuleRoute
//
//  Created by GIKI on 2025/2/15.
//

import Foundation

public typealias DependencyFactory = () -> Any

public protocol DependencyContainer {
    func register<T>(dependencyFactory: @escaping DependencyFactory, forType type: T.Type)
    func resolve<T>(_ type: T.Type) -> T?
}

public class DefaultDependencyContainer: DependencyContainer {
    public static let shared = DefaultDependencyContainer()
    
    private var factories = [String: DependencyFactory]()
    private var instances = [String: Any]()
    
    private init() {}
    
    public func register<T>(dependencyFactory: @escaping DependencyFactory, forType type: T.Type) {
        let key = "\(type)"
        factories[key] = dependencyFactory
    }
    
    public func resolve<T>(_ type: T.Type) -> T? {
        let key = "\(type)"
        // 若已存在实例，则直接返回
        if let instance = instances[key] as? T {
            return instance
        }
        // 否则使用注册的工厂方法创建实例
        if let factory = factories[key] {
            let instance = factory()
            instances[key] = instance
            return instance as? T
        }
        return nil
    }
}

// MARK: - MRInject.swift
@propertyWrapper
public class MRInject<T> {
    
    private var dependency: T?
    
    public var wrappedValue: T {
        get {
            if dependency == nil {
                dependency = DefaultDependencyContainer.shared.resolve(T.self)
                if dependency == nil {
                    fatalError("Dependency \(T.self) not resolved")
                }
            }
            return dependency!
        }
    }
    public init() {}
}
