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
    static let ServerDateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
    static let ErrorDefaultDomain = "ct.err"
}
