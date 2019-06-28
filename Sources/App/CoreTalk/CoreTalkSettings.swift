//
//  CoreTalkSettings.swift
//  App
//
//  Created by Francisco Lobo on 6/25/19.
//

import Vapor


struct CoreTalkSettings {
    static let ServerVersion = "0.1"
    static let ServerName = "CoreTalk"
    static let EndPoint = "coretalk"
    static let AuthSandboxTimeOut = 5
    static let ServerAdminAddress = "server.admin.root"
    static let ServerDateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
    static let ErrorDefaultDomain = "ct.err"
    static let AddressWildCard: Character = "*"
    static let AddressSeparator:Character = "."
    static let AddressAllowedSpaces:UInt8 = 3
}
