//
//  Permission.swift
//  App
//
//  Created by Francisco Lobo on 6/12/19.
//

struct Permission: Codable, Equatable {
    internal enum Authority: Int, Codable, Equatable {
        case access
        case execute
        case read
        case write
        case update
        case delete
        case admin
    }
    
    let authority: Authority
    let serviceName: String
    
    
    static func can(connection: Connection, _ authority: Authority, in service: CoreTalkService) -> Bool {
        guard let client = connection.client else {
            return false
        }
        let allowedPermissions = client.permissions 
        
        let service = type(of: service)
        let permissionsForService = allowedPermissions.filter { $0.serviceName == service.serviceName }
        
        
        for permissionForService in permissionsForService {
            if permissionForService.authority == authority { return true }
        }
        
        return false
    }
    
    static func newPermission(for service: CoreTalkService.Type, to authority: Authority) -> Permission {        
        return Permission(authority: authority, serviceName: service.serviceName)
    }
}
