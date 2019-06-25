//
//  DataTypeExtensions.swift
//  App
//
//  Created by Francisco Lobo on 6/25/19.

import Vapor

extension Date {
    func ctStringValue() -> String {
        let formatter = DateFormatter()
        //SETUP
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        let myString = formatter.string(from: self)
        return myString
    }
}
