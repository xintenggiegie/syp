//
//  File.swift
//
//
//  Created by Ens Livan on 2022/3/21.
//

import Vapor

struct DeviceController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let deviceR = routes.grouped("device")
        deviceR.get("list", use: index)
        deviceR.get("info", ":regid", use: deviceInfo)
    
        //
        deviceR.post("register", use: register)
        deviceR.post("delete", use: deleteDevice)
        
        deviceR.post("setDeviceToken", use: setDeviceToken)
        //
        deviceR.post("setAlias", use: setAlias)
        deviceR.post("deleteAlias", use: deleteAlias)
        deviceR.post("getAlias", use: getAlias)
        deviceR.get("getAliasDevices", use: getAliasDevices)
        
        //
        deviceR.post("setTags", use: setTags)
    
        deviceR.get("getTags", use: getTags)
        
        //
        deviceR.post("setBadge", use: setBadge)
        
        //
        deviceR.post("setMobile", use: setMobile)
    }
    
    func index(req: Request) throws -> EventLoopFuture<ResponseJSON<[SYDevice]>> {
        if let appKey = try? req.content.get(String.self, at: "appKey") {
            return SYDevice.query(on: req.db)
                .filter(\.$appKey, .equal, appKey).all().map { list in
                    ResponseJSON(data: list)
                }
        } else {
            return SYDevice.query(on: req.db).all().map { abc in
                ResponseJSON(data: abc)
            }
        }
    }
    
    func register(req: Request) throws -> EventLoopFuture<ResponseJSON<SYDevice>> {
        let dr = try req.content.decode(SYDeviceReq.self)
        return SYApp.query(on: req.db)
            .filter(\.$appKey, .equal, dr.appKey).first().map { app -> ResponseJSON<SYDevice> in
                if let app = app {
                    let device = SYDevice()
                    device.appKey = app.appKey
                    device.registrationID = UUID().uuidString
                    device.deviceToken = dr.deviceToken ?? ""
                    device.bundleId = dr.bundleId
                    device.channel = dr.channel
                    device.online = false
                    device.platform = dr.platform
                    device.systemVersion = dr.systemVersion
                    device.latestOnlineTime = Date()
                    device.alias = ""
                    device.tags = []
                    device.phoneNumber = ""
                    device.badge = 0
                    _ = device.create(on: req.db)
                    return ResponseJSON(code: .ok, message: "??????????????????", data: device)
                } else {
                    return ResponseJSON(code: .invalid, message: "appkey??????", data: nil)
                }
            }
    }
    
    func deleteDevice(req: Request) throws -> EventLoopFuture<ResponseJSON<String>> {
        let regid = try req.content.get(String.self, at: "regid")
        return SYDevice.query(on: req.db)
            .filter(\.$registrationID, .equal, regid).delete(force: true).map {
                ResponseJSON(code: .ok, message: "??????????????????")
            }
    }
    
    func deviceInfo(req: Request) throws -> EventLoopFuture<ResponseJSON<SYDevice>> {
        guard let regid = req.parameters.get("regid", as: String.self) else { throw Abort(.badRequest) }
        return SYDevice.query(on: req.db)
            .filter(\.$registrationID, .equal, regid).first().map { device -> ResponseJSON<SYDevice> in
                if let device = device {
                    return ResponseJSON(code: .ok, message: "????????????????????????", data: device)
                } else {
                    return ResponseJSON(code: .dataNotExist, message: "???????????????", data: nil)
                }
            }
    }
    
    func setDeviceToken(req: Request) throws -> EventLoopFuture<ResponseJSON<String>> {
        let regid = try req.content.get(String.self, at: "regid")
        let deviceToken = try req.content.get(String.self, at: "deviceToken")
        return SYDevice.query(on: req.db)
            .filter(\.$registrationID, .equal, regid)
            .set(\.$deviceToken, to: deviceToken).update().map {
                ResponseJSON(data: "??????token??????")
            }
    }
    
    func setAlias(req: Request) throws -> EventLoopFuture<ResponseJSON<String>> {
        let regid = try req.content.get(String.self, at: "regid")
        let alias = try req.content.get(String.self, at: "alias")
        return SYDevice.query(on: req.db)
            .filter(\.$registrationID, .equal, regid)
            .set(\.$alias, to: alias).update().map {
                ResponseJSON(code: .ok, message: "??????Alias??????", data: alias)
            }
    }
    
    func deleteAlias(req: Request) throws -> EventLoopFuture<ResponseJSON<String>> {
        let regid = try req.content.get(String.self, at: "regid")
        return SYDevice.query(on: req.db)
            .filter(\.$registrationID, .equal, regid)
            .set(\.$alias, to: "").update().map {
                ResponseJSON(code: .ok, message: "??????Alias??????", data: "")
        }
    }
    
    func getAlias(req: Request) throws -> EventLoopFuture<ResponseJSON<String>> {
        let regid = try req.content.get(String.self, at: "regid")
        return SYDevice.query(on: req.db)
            .filter(\.$registrationID, .equal, regid).first().map { device -> ResponseJSON<String> in
                if let device = device {
                    return ResponseJSON(code: .ok, message: "??????Alias??????", data: device.alias)
                } else {
                    return ResponseJSON(code: .dataNotExist, message:"???????????????", data: regid)
                }
            }
    }
    
    func getAliasDevices(req: Request) throws -> EventLoopFuture<ResponseJSON<[String]>> {
        let alias = try req.content.get(String.self, at: "alias")
        return SYDevice.query(on: req.db)
            .filter(\.$alias, .equal, alias).all().map { devices in
            ResponseJSON(data: devices.map{$0.registrationID})
        }
    }
    
    func setTags(req: Request) throws -> EventLoopFuture<ResponseJSON<[String]>> {
        let regid = try req.content.get(String.self, at: "regid")
        let tags = try req.content.get([String].self, at: "tags")
        return SYDevice.query(on: req.db)
            .filter(\.$registrationID, .equal, regid)
            .set(\.$tags, to: tags).update().map {
                ResponseJSON(code: .ok, message: "??????tags??????", data: tags)
            }
    }
    
    func getTags(req: Request) throws -> EventLoopFuture<ResponseJSON<[String]>> {
        let regid = try req.content.get(String.self, at: "regid")
        return SYDevice.query(on: req.db)
            .filter(\.$registrationID, .equal, regid).first().map { d in
                ResponseJSON(code: .ok, message: "??????tags??????", data: d?.tags)
            }
    }
    
    func setBadge(req: Request) throws -> EventLoopFuture<ResponseJSON<Int>> {
        let badge = try req.content.get(Int.self, at: "badge")
        let regid = try req.content.get(String.self, at: "regid")
        return SYDevice.query(on: req.db)
            .filter(\.$registrationID, .equal, regid)
            .set(\.$badge, to: badge).update().map {
            ResponseJSON(code: .ok, message: "??????badge??????", data: badge)
        }
    }
    
    func setMobile(req: Request) throws -> EventLoopFuture<ResponseJSON<String>> {
        let mobile = try req.content.get(String.self, at: "mobile")
        let regid = try req.content.get(String.self, at: "regid")
        return SYDevice.query(on: req.db)
            .filter(\.$registrationID, .equal, regid)
            .set(\.$phoneNumber, to: mobile).update().map {
                ResponseJSON(code: .ok, message: "?????????????????????", data: mobile)
            }
    }
    
}
