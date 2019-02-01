//
//  Entity.swift
//  ScryLogFileService
//
//  Created by Roudique on 1/27/19.
//

import Foundation
import ScryLogHTMLParser

public class Entity {
    public let title: String
    internal(set) public var tables: Set<Table>
    
    public init(title: String, tables: [Table]) {
        self.title = title
        self.tables = Set(tables)
    }
}

extension Entity: Hashable {
    public var hashValue: Int {
        return title.hashValue
    }
    
    public static func == (lhs: Entity, rhs: Entity) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
