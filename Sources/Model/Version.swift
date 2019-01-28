//
//  Version.swift
//  ScryLogFileService
//
//  Created by Roudique on 1/27/19.
//

import Foundation
import ScryLogHTMLParser

public class Version {
    public let number: Int
    public var entities: Set<Entity>
    
    init(number: Int, entities: [Entity]) {
        self.number = number
        self.entities = Set(entities)
    }
}

extension Version: Hashable {
    public var hashValue: Int {
        return number
    }
    
    public static func == (lhs: Version, rhs: Version) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
