//
//  File.swift
//  ModuleRoute
//
//  Created by GIKI on 2025/2/13.
//

import Foundation

public protocol MRRoute {
    static var identifier: String { get }
    init?(parameters: [String: Any])
    func encode() -> String
}

extension MRRoute {
    public func encode() -> String {
        let parameters = Mirror(reflecting: self).children.reduce(into: [String: Any]()) {
            if let label = $1.label {
                $0[label] = $1.value
            }
        }
        guard let data = try? JSONSerialization.data(withJSONObject: parameters, options: []),
              let paramString = String(data: data, encoding: .utf8) else {
            return Self.identifier
        }
        return "\(Self.identifier)|\(paramString)"
    }
}

