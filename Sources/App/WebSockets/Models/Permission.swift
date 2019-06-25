//
//  Permission.swift
//  App
//
//  Created by Francisco Lobo on 6/12/19.
//

struct Permission {
    enum Authority {
        case access
        case read
        case write
        case update
        case delete
        case admin
    }
    let authority: Authority
    let serviceName: String
    
    
    static func can(connection: Connection, _ authority: Authority, in service: CoreTalkService ) -> Bool {
        let allowedPermissions = connection.permissions
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
