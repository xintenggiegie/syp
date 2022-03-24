//
//  File.swift
//
//
//  Created by Ens Livan on 2022/3/21.
//

import Foundation
import Vapor
import APNSwift

enum PushStrategy {
    case system
    case inMessage
    case bothSystemAndInMessage
    case inMessageFirst
}

struct PushController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let push = routes.grouped("push")
        push.post("toApp", use: pushToApp)
        push.post("toDevice", use: pushToDevice)
        push.post("toAlias", use: pushToAlias)
        push.post("toTags", use: pushToTags)
    }
    
    func pushToApp(req: Request) throws -> EventLoopFuture<ResponseJSON<String>> {
        let appKey = try req.content.get(String.self, at: "appKey")
        let title = try req.content.get(String.self, at: "title")
        let subTitle = try req.content.get(String.self, at: "subTitle")
        let body = try req.content.get(String.self, at: "body")
        let badge = try req.content.get(Int.self, at: "badge")
        return SYDevice.query(on: req.db)
            .filter(\.$appKey, .equal, appKey)
            .all().mapEach { element in
                sendMessage(payload: PushPayload(title: title, subTitle: subTitle, body: body, badge: badge), regid: element.registrationID, online: element.online, dt: element.deviceToken, req: req)
            }.map {_ in
                ResponseJSON(code: .ok, message: "按app推送成功", data: appKey)
            }
    }
    
    func pushToDevice(req: Request) throws -> EventLoopFuture<ResponseJSON<String>> {
        let regid = try req.content.get(String.self, at: "regid")
        let title = try req.content.get(String.self, at: "title")
        let subTitle = try req.content.get(String.self, at: "subTitle")
        let body = try req.content.get(String.self, at: "body")
        let badge = try req.content.get(Int.self, at: "badge")
        
        return SYDevice.query(on: req.db)
            .filter(\.$registrationID, .equal, regid)
            .all().mapEach { d in
                sendMessage(payload: PushPayload(title: title, subTitle: subTitle, body: body, badge: badge), regid: regid, online: d.online, dt: d.deviceToken, req: req)
            }.map { _ in
                ResponseJSON(code: .ok, message: "按设备标识推送成功", data: regid)
            }
    }
    
    func pushToAlias(req: Request) throws -> EventLoopFuture<ResponseJSON<String>> {
        let alias = try req.content.get(String.self, at: "alias")
        let title = try req.content.get(String.self, at: "title")
        let subTitle = try req.content.get(String.self, at: "subTitle")
        let body = try req.content.get(String.self, at: "body")
        let badge = try req.content.get(Int.self, at: "badge")
        return SYDevice.query(on: req.db)
            .filter(\.$alias, .equal, alias)
            .all().mapEach { d in
                sendMessage(payload: PushPayload(title: title, subTitle: subTitle, body: body, badge: badge), regid: d.registrationID, online: d.online, dt: d.deviceToken, req: req)
            }.map { _ in
                ResponseJSON(code: .ok, message: "按别名推送成功", data: alias)
            }
    }
//
    func pushToTags(req: Request) throws -> EventLoopFuture<ResponseJSON<[String]>> {
        let tags = try req.content.get([String].self, at: "tags")
        let title = try req.content.get(String.self, at: "title")
        let subTitle = try req.content.get(String.self, at: "subTitle")
        let body = try req.content.get(String.self, at: "body")
        let badge = try req.content.get(Int.self, at: "badge")
        
        return SYDevice.query(on: req.db)
            .filter(\.$tags, .contains(inverse: false, .anywhere), tags)
            .all().mapEach { d in
                sendMessage(payload: PushPayload(title: title, subTitle: subTitle, body: body, badge: badge), regid: d.registrationID, online: d.online, dt: d.deviceToken, req: req)
            }.map { _ in
                ResponseJSON(code: .ok, message: "按Tag推送成功", data: tags)
            }
    }
    
    func sendMessage(payload: PushPayload, regid: String, online: Bool, dt: String, req:Request) -> EventLoopFuture<Void> {
        if online {
            return Mqtt.shared.client.publish(payload.title, to: regid)
        } else {
            let pl = APNSwiftPayload(alert: APNSwiftAlert.init(title: payload.title, subtitle: payload.subTitle, body: payload.body), badge: payload.badge, sound: .normal("default"), hasContentAvailable: false, hasMutableContent: false)
            return req.apns.send(pl, to: dt)
        }
    }
}
