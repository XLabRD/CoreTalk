//
//  DataTypeExtensions.swift
//  App
//
//  Created by Francisco Lobo on 6/25/19.

import Vapor

extension Date {
    func coreTalkDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = CoreTalkSettings.ServerDateFormat
        let myString = formatter.string(from: self)
        return myString
    }
}
