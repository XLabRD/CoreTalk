//
//  ConnectionPool.swift
//  App
//
//  Created by Francisco Lobo on 6/20/19.
//

import Vapor


class ClientManager {
    private var connections = [Connection]()
    
    var count: Int {
        get {
            return self.connections.count
        }
    }
    
    func all() -> [Connection] {
        return self.connections
    }
    
    func attach(connection: Connection) {        
        self.connections.append(connection)        
        print("[ConnectionPool] Attached connection. Active: \(self.connections.count) Active")
                
        ScheduledTask.perform(in: .seconds(CoreTalkSettings.AuthSandboxTimeOut)) {
            if connection.confirmed == false {
                print("[ConnectionPool] Auth Timeout Detected")
                let err = CoreTalkError(type: .AuthTimeout)
                connection.send(object: err)
                self.detach(connection: connection)
            } else {
                print("[ConnectionPool] Auth Confirmed. Timeout removed")
            }
        }
    }
    
    func detach(connection: Connection) {
        connection.socket.close()
        self.connections.removeAll {$0 == connection}
        
        print("[ConnectionPool] Connection Closed & Detached. Remain: \(self.connections.count) Active")
    }
    
    func detach(socket: WebSocket) {
        self.connections.removeAll { $0.socket === socket }
        print("[ConnectionPool] Socket closed. Detached Connection. Remain: \(self.connections.count) Active")
    }
    
    
    func findConnection(from socket: WebSocket) -> Connection? {
        let foundConnections = connections.filter { $0.socket === socket }
        if foundConnections.count <= 0 {
            return nil
        }
        
        return foundConnections.first
    }
    
    func findConnection(from address: Address) -> Connection? {
        let foundConnections = connections.filter { $0.client?.address == address }
        if foundConnections.count <= 0 {
            return nil
        }
        
        return foundConnections.first
    }
    
    func findConnectionIndex(from socket: WebSocket) -> Int? {
        let foundConnections = connections.filter { $0.socket === socket }
        
        if foundConnections.count <= 0 {
            return nil
        }
        
        if let fc = foundConnections.first {
            return self.connections.firstIndex(of: fc)
        }
        
        return nil
    }
}
