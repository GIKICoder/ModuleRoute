//
//  Inject.swift
//  ModuleRoute
//
//  Created by GIKI on 2025/2/13.
//

import Foundation

@propertyWrapper
public class MRInject<T>: Resolvable {
    private var dependency: T?
    public var wrappedValue: T {
        guard let dependency = dependency else {
            fatalError("Dependency \(T.self) not resolved")
        }
        return dependency
    }

    public init() {}

    public func resolve(using container: DependencyContainer) {
        dependency = container.resolve(T.self)
    }
}


public protocol Resolvable {
    func resolve(using container: DependencyContainer)
}

