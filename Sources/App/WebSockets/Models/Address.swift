//
//  Address.swift
//  App
//
//  Created by Francisco Lobo on 6/18/19.
//

import Vapor


struct Address: Equatable, Encodable {
    //Setup
    private static let WildCard: Character = "*"
    private static let AddressSeparator:Character = "."
    private static let AllowedSpaces:UInt8 = 3
    //Setup
    
     let address: String
    

    
    init?(_ address: String) {
        if address.split(separator: Address.AddressSeparator).count != Address.AllowedSpaces {
            return nil            
        }
        
        self.address = address
    }
    
    static func == (lhs: Address, rhs: Address) -> Bool {
        if lhs.address == rhs.address { return true }
        return false
    }
    
    func isMember(of query: String) -> Bool {
        let valueElements = address.split(separator: Address.AddressSeparator)
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
