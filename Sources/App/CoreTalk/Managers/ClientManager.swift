//
//  ConnectionPool.swift
//  App
//
//  Created by Francisco Lobo on 6/20/19.
//

import Vapor


class ClientManager {
    private var connections = [Connection]()
        
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
        socket.close()
        self.connections.removeAll { $0.socket === socket }
        print("[ConnectionPool] Socket closed. Detached Connection. Remain: \(self.connections.count) Active")
    }
    
    subscript(address: String) -> Connection? {
        let conn =  connections.filter { $0.client?.address == address }
        if conn.count <= 0 {
            return nil
        }
        
        return conn.first
    }
    
    subscript(socket: WebSocket) -> Connection? {
        let conn =  connections.filter { $0.socket === socket }
        if conn.count <= 0 {
            return nil
        }
        
        return conn.first
    }
    
    
    var count: Int {
        get {
            return self.connections.count
        }
    }
    
    
    func list() -> [Address] {
        let flat = self.connections.compactMap({$0.client?.address})
        return flat
    }
    
}
