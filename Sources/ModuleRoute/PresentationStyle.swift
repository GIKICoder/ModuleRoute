//
//  PresentationStyle.swift
//  ModuleRoute
//
//  Created by GIKI on 2025/2/13.
//

import UIKit

@MainActor 
public protocol PresentationStyle {
    func present(viewController: UIViewController,
                 from: UIViewController,
                 animated: Bool,
                 completion: (() -> Void)?)
}

@MainActor
public extension PresentationStyle {
    func present(viewController: UIViewController,
                 from: UIViewController,
                 animated: Bool) {
        present(viewController: viewController,
                from: from,
                animated: animated,
                completion: nil)
    }
}

// 推送呈现
@MainActor
public struct PushPresentation: PresentationStyle {
    public init() {}
    public func present(viewController: UIViewController,
                        from: UIViewController,
                        animated: Bool,
                        completion: (() -> Void)?) {
        from.navigationController?.pushViewController(viewController, animated: animated)
        completion?()
    }
}

// 模态呈现
@MainActor
public struct ModalPresentation: PresentationStyle {
    public init() {}
    public func present(viewController: UIViewController,
                        from: UIViewController,
                        animated: Bool,
                        completion: (() -> Void)?) {
        from.present(viewController, animated: animated, completion: completion)
    }
}
