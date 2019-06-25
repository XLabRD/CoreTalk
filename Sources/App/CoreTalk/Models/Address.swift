//
//  Address.swift
//  App
//
//  Created by Francisco Lobo on 6/18/19.
//

import Vapor


struct Address: Equatable, Encodable {
     let address: String
    
    init?(_ address: String) {
        if address.split(separator: CoreTalkSettings.AddressSeparator).count != CoreTalkSettings.AddressAllowedSpaces {
            return nil            
        }
        self.address = address
    }
    
//    init?(addressForDomain domain: String) {
//        if domain.split(separator: CoreTalkSettings.AddressSeparator).count != CoreTalkSettings.AddressAllowedSpaces - 1 {
//            return nil
//        }
//    }
    
    static func == (lhs: Address, rhs: Address) -> Bool {
        if lhs.address == rhs.address { return true }
        return false
    }
    
    func isMember(of query: String) -> Bool {
        let valueElements = address.split(separator: CoreTalkSettings.AddressSeparator)
        let queryElements = query.split(separator: CoreTalkSettings.AddressSeparator)
        
        for (index, queryElement) in queryElements.enumerated() {
            if (queryElement == String(CoreTalkSettings.AddressWildCard)) || (queryElement == valueElements[index]) {
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
