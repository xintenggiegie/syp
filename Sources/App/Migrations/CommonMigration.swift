//
//  File.swift
//
//
//  Created by Ens Livan on 2022/3/21.
//

import Foundation
import FluentKit

struct AppMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(SYApp.schema)
            .id()
            .field("app_name", .string, .required)
            .field("app_key", .string, .required)
            .field("user_name", .string, .required)
            .field("phone_number", .string, .required)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(SYApp.schema).delete()
    }
}
 
struct DeviceMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(SYDevice.schema)
            .id()
            .field("registration_id", .string, .required)
            .field("app_key", .string, .required)
            .field("bundle_id", .string, .required)
            .field("device_token", .string, .required)
            .field("online", .bool, .required)
            .field("latest_online_time", .date, .required)
            .field("alias", .string, .required)
            .field("tags", .array(of: .string), .required)
            .field("phone_number", .string, .required)
            .field("platform", .string, .required)
            .field("system_version", .string, .required)
            .field("channel", .string, .required)
            .create()
    }
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(SYDevice.schema).delete()
    }
}

struct BadgeMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(SYDevice.schema)
            .field("badge", .int, .custom("")).update()
    }
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(SYDevice.schema).delete()
    }
}

