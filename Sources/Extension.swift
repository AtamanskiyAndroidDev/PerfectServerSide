//
//  Extension.swift
//  new
//
//  Created by sasha ataman on 06.05.17.
//
//

import Foundation


extension Dictionary {
    func merged(with dictionary: Dictionary<Key,Value>) -> Dictionary<Key,Value> {
        var copy = self
        dictionary.forEach {
            copy.updateValue($1, forKey: $0)
        }
        return copy
    }
    
}
