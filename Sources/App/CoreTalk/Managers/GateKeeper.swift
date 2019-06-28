//
//  GateKeeper.swift
//  App
//
//  Created by Francisco Lobo on 6/28/19.
//

import Vapor
import FluentSQLite


class GateKeeper {
    typealias CompletionCallback = (Client?)->(Void)
    
    func getClient(from address: Address, req: Request, on completion:@escaping CompletionCallback) {
        _ = Client.query(on: req).filter(\.address == address).first().map { client in
            completion(client)
        }        
    }
}


