//
//  Connection.swift
//  App
//
//  Created by Francisco Lobo on 6/12/19.
//

import Vapor

// CONNECTION MODEL
// ###############################
class Connection: Equatable {
    var confirmed = false
    let socket: WebSocket
    var permissions = [Permission]()
    var address: Address?

    
    
    init(socket: WebSocket) {
        self.socket = socket                
    }
    
    func send(_ message:String) {        
        self.socket.send(message)
    }
    
    func send(_ data: Data) {
        self.socket.send(data)
    }
    
    func send<T: Encodable>(object: T) {
        do {
            let jsonData = try JSONEncoder().encode(object)
            if let messageString = String(data: jsonData, encoding: .utf8) {
                self.socket.send(messageString)
            }
        } catch {
            print("[Connection-send] \(error)")
        }
    }
    
    static func == (lhs: Connection, rhs: Connection) -> Bool {
        if lhs.socket === rhs.socket { return true }        
        
        return false
    }        
    
}


extension WebSocket {
    func send<T: Encodable>(object: T) {
        do {
            let jsonData = try JSONEncoder().encode(object)
            if let messageString = String(data: jsonData, encoding: .utf8) {
                self.send(messageString)
            }
        } catch {
            print("[WebSocket-Extension] \(error)")
        }
        
    }
}
