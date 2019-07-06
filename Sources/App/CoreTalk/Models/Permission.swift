//
//  Permission.swift
//  App
//
//  Created by Francisco Lobo on 6/12/19.
//
import FluentSQLite

final class Permission: SQLiteUUIDModel, Equatable {
    internal enum Authority: Int, Codable, Equatable {
        case access
        case execute
        case read
        case write
        case update
        case delete
        case admin
    }
    
    var id: UUID?
//    var clientId: UUID?
    let authority: Authority
    let serviceName: String
    
    
    init(authority: Authority, serviceName: String) {
        self.authority = authority
        self.serviceName = serviceName
    }
    
    
    static func can(connection: Connection, _ authority: Authority, in service: CoreTalkService) -> Bool {
        guard let client = connection.client, client.permissions.count > 0 else {
            return false
        }
        
        
        //IS ADMIN
        if client.permissions.contains(where: {$0.authority == Authority.admin && $0.serviceName == CoreTalkSettings.ServerName}) {
            return true
        }
        
        let service = type(of: service)
        let permissionsForService = client.permissions.filter { $0.serviceName == service.serviceName }
        
        
        for permissionForService in permissionsForService {
            if permissionForService.authority == authority { return true }
        }
        
        return false
    }
    
    static func newPermission(for service: CoreTalkService.Type, to authority: Authority) -> Permission {        
        return Permission(authority: authority, serviceName: service.serviceName)
    }
    
    static func == (lhs: Permission, rhs: Permission) -> Bool {
        if lhs.authority == rhs.authority && lhs.serviceName == rhs.serviceName { return true }
        return false
    }
}
