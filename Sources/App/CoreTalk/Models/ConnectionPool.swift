//
//  ConnectionPool.swift
//  App
//
//  Created by Francisco Lobo on 6/20/19.
//

import Vapor


class ConnectionPool {
    //setup
    static let AuthSandboxTimeOut = 5
    //setup
    private var connections = [Connection]()
    
    var count: Int {
        get {
            return self.connections.count
        }
    }
    
   
    
    func attach(connection: Connection) {        
        self.connections.append(connection)        
        print("[ConnectionPool] Attached connection. Active: \(self.connections.count) Active")
        
        ScheduledTask.perform(in: .seconds(10)) {
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
        let indexOf = self.connections.firstIndex(of: connection)
        if let idx = indexOf {
            self.connections.remove(at: idx)
        }
        
        print("[ConnectionPool] Connection Closed & Detached. Remain: \(self.connections.count) Active")
    }
    
    func detach(socket: WebSocket) {
        let indexOf = self.findConnectionIndex(from: socket)
        
        if let idx = indexOf {
            self.connections.remove(at: idx)
            print("[ConnectionPool] Socket closed. Detached Connection. Remain: \(self.connections.count) Active")
        }
        
    }
    
    func findConnection(from socket: WebSocket) -> Connection? {
        let foundConnections = connections.filter { $0.socket === socket }
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
