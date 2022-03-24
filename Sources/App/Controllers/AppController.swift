//
//  File.swift
//
//
//  Created by Ens Livan on 2022/3/21.
//

import Vapor

struct AppController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let app = routes.grouped("app")
        
        app.get("list", use: index)
        app.post("create", use: create)
    }
    
    func index(req: Request) throws -> EventLoopFuture<ResponseJSON<[SYApp]>> {
        return SYApp.query(on: req.db).all().map { abc in
            ResponseJSON(data: abc)
        }
    }
    
    func create(req: Request) throws -> EventLoopFuture<ResponseJSON<SYApp>> {
        let appContent = try req.content.decode(SYAppContent.self)
        let app = SYApp()
        app.appName = appContent.appName
        app.userName = appContent.userName
        app.phoneNumber = appContent.phoneNumber
        app.appKey = UUID().uuidString
        return app.create(on: req.db).map {
            ResponseJSON(code: .ok, message: "新建app成功", data: app)
        }
    }
}
