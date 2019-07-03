//
//  Address.swift
//  App
//
//  Created by Francisco Lobo on 6/18/19.
//
import Vapor
import FluentSQLite


final class Client: SQLiteUUIDModel {
    var id: UUID?
    var address: Address?
    var permissions = [Permission]()
    var hostname: String?
}

extension Client: Content {}
extension Client: Migration {
    typealias Database = SQLiteDatabase
    
    static func prepare(on connection: SQLiteConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            }.always {
                let client = Client()
                client.address = CoreTalkSettings.ServerAdminAddress
                client.permissions += [Permission(authority: .admin, serviceName: CoreTalkSettings.ServerName)]
                client.save(on: connection).always {
                   print("[Client] Default Data Seeded")
                }
        }
    }
    
    
    static func revert(on connection: SQLiteConnection) -> Future<Void> {
        return .done(on: connection)
    }
}
