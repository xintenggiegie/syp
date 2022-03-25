//
//  File.swift
//
//
//  Created by Ens Livan on 2022/3/17.
//

import Vapor
import Fluent
import Foundation

final class SYDevice: BaseModel {
    
    static let schema = "sydevices"
    
    typealias IDValue = UUID
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "registration_id")
    var registrationID: String
    @Field(key: "app_key")
    var appKey: String
    @Field(key: "bundle_id")
    var bundleId: String
    @Field(key: "device_token")
    var deviceToken: String
    @Field(key: "online")
    var online: Bool
    @Field(key: "latest_online_time")
    var latestOnlineTime: Date?
    @OptionalField(key: "alias")
    var alias: String?
    @OptionalField(key: "tags")
    var tags: [String]?
    @OptionalField(key: "phone_number")
    var phoneNumber: String?
    @Field(key: "platform")
    var platform: String
    @Field(key: "system_version")
    var systemVersion: String
    @OptionalField(key: "channel")
    var channel: String?
    @OptionalField(key: "badge")
    var badge: Int?
    
    init () {}
}

struct SYDeviceReq: Content {
    var appKey: String
    var bundleId: String
    var platform: String
    var systemVersion: String
    var channel: String
    var deviceToken: String?
}

//
struct PushPayload: Content {
    var title: String
    var subTitle: String
    var body: String?
    var badge: Int?
}
