//
//  Address.swift
//  App
//
//  Created by Francisco Lobo on 6/18/19.
//

import Vapor


struct Address: Equatable {
    //Setup
    private static let WildCard: Character = "*"
    private static let AddressSeparator:Character = "."
    private static let AllowedSpaces:UInt8 = 3
    //Setup
    
    private let value: String
    
    var address:String {
        get {
            return self.value
        }
    }
    
    init?(_ address: String) {
        if address.split(separator: Address.AddressSeparator).count != Address.AllowedSpaces {
            return nil            
        }
        
        self.value = address
    }
    
    static func == (lhs: Address, rhs: Address) -> Bool {
        if lhs.value == rhs.value { return true }
        return false
    }
    
    func isMember(of query: String) -> Bool {
        let valueElements = value.split(separator: Address.AddressSeparator)
        let queryElements = query.split(separator: Address.AddressSeparator)
        
        for (index, queryElement) in queryElements.enumerated() {
            if (queryElement == String(Address.WildCard)) || (queryElement == valueElements[index]) {
                continue
            } else {
                return false
            }
        }
        return true
    }
    
    static func find(_ query: String, in pool: [Address?]) -> [Address?] {
        let foundElements = pool.filter {  $0?.isMember(of: query) ?? false }        
        return foundElements

    }
}
