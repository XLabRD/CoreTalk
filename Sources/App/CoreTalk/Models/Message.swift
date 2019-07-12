//
//  Message.swift
//  App
//
//  Created by Francisco Lobo on 7/12/19.
//
import Foundation

let raw = """
{"service":{"payload":"zzz"}}
"""


protocol Message: Codable {
    var noun: String? {get}
    var raw: String? {get set}
}


extension Message {
    var noun: String? {
        get {
            guard let noun = raw?.split(separator: "\"")[1] ?? nil else { return nil }
            return String(noun)
        }
    }
}

struct CoreMessage: Message {
    var raw: String?
}
