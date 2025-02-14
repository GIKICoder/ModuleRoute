//
//  File.swift
//  ModuleRoute
//
//  Created by GIKI on 2025/2/15.
//

import Foundation
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
