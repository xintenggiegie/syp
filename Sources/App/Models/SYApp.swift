//
//  File.swift
//
//
//  Created by Ens Livan on 2022/3/18.
//

import Vapor
import FluentKit

typealias BaseModel = Content & Model

struct SYAppContent: Content {
    var userName: String
    var appName: String
    var phoneNumber: String
}

extension SYAppContent: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("phoneNumber", as: String.self, is: .alphanumeric)
    }
}

final class SYApp: BaseModel {
    
    static let schema = "syapps"
    
    typealias IDValue = UUID
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "app_key")
    var appKey: String
    @Field(key: "user_name")
    var userName: String
    @Field(key: "app_name")
    var appName: String
    @OptionalField(key: "phone_number")
    var phoneNumber: String?
    
    init () {}
    
}
