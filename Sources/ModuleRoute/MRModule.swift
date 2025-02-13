//
//  Module.swift
//  ModuleRoute
//
//  Created by GIKI on 2025/2/13.
//

import UIKit

public protocol MRModule {
    func build(from route: MRRoute?) -> UIViewController
    func resolveDependencies(using container: DependencyContainer)
    func isEnabled(route: MRRoute?) -> Bool
    func fallbackModule(for route: MRRoute?) -> MRModule.Type?
    init()
}

extension MRModule {
    
    public func resolveDependencies(using container: DependencyContainer) {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let resolvable = child.value as? Resolvable {
                resolvable.resolve(using: container)
            }
        }
    }

    public func isEnabled(route: MRRoute?) -> Bool { return true }
    public func fallbackModule(for route: MRRoute?) -> MRModule.Type? { return nil }
}

