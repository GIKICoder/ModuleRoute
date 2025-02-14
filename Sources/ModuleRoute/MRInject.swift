//
//  Inject.swift
//  ModuleRoute
//
//  Created by GIKI on 2025/2/13.
//

import Foundation

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


