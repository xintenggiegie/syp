//
//  File.swift
//
//
//  Created by Ens Livan on 2022/3/21.
//

import Foundation
import Vapor
import APNSwift
import MQTTNIO

enum PushStrategy: Int {
    case system = 0
    case inMessage = 1
    case inMessageFirst = 2
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
        return SYDevice.query(on: req.db)
            .filter(\.$appKey, .equal, appKey)
            .all().mapEach { element in
                sendMessage(payload: PushPayload(title: title, subTitle: subTitle, body: body, badge: element.badge ?? 0), regid: element.registrationID, online: element.online, dt: element.deviceToken, req: req)
            }.map { _ in
                ResponseJSON(code: .ok, message: "按app推送成功", data: appKey)
            }
    }
    
    func pushToDevice(req: Request) throws -> EventLoopFuture<ResponseJSON<String>> {
        let regid = try req.content.get(String.self, at: "regid")
        let title = try req.content.get(String.self, at: "title")
        let subTitle = try req.content.get(String.self, at: "subTitle")
        let body = try req.content.get(String.self, at: "body")
        
        return SYDevice.query(on: req.db)
            .filter(\.$registrationID, .equal, regid)
            .all().mapEach { d in
                sendMessage(payload: PushPayload(title: title, subTitle: subTitle, body: body, badge: d.badge ?? 0), regid: regid, online: d.online, dt: d.deviceToken, req: req)
            }.map { _ in
                ResponseJSON(code: .ok, message: "按设备标识推送成功", data: regid)
            }
    }
    
    func pushToAlias(req: Request) throws -> EventLoopFuture<ResponseJSON<[String]>> {
        let alias = try req.content.get(String.self, at: "alias")
        let title = try req.content.get(String.self, at: "title")
        let subTitle = try req.content.get(String.self, at: "subTitle")
        let body = try req.content.get(String.self, at: "body")
        return SYDevice.query(on: req.db)
            .filter(\.$alias, .equal, alias)
            .all().mapEach { d -> SYDevice in
                _ = sendMessage(payload: PushPayload(title: title, subTitle: subTitle, body: body, badge: d.badge ?? 0), regid: d.registrationID, online: d.online, dt: d.deviceToken, req: req)
                return d
            }.map { arr in
                ResponseJSON(code: .ok, message: "按别名推送成功", data: arr.map{$0.registrationID})
            }
    }
//
    func pushToTags(req: Request) throws -> EventLoopFuture<ResponseJSON<[String]>> {
        let tags = try req.content.get([String].self, at: "tags")
        let title = try req.content.get(String.self, at: "title")
        let subTitle = try req.content.get(String.self, at: "subTitle")
        let body = try req.content.get(String.self, at: "body")
        
        return SYDevice.query(on: req.db)
            .all().mapEachCompact{ d -> SYDevice? in
                var hasSameTag = false
                for tag in tags where d.tags!.contains(tag) {
                    hasSameTag = true
                    break
                }
                return hasSameTag ? d : nil
            }.mapEach { d -> SYDevice in
                _ = sendMessage(payload: PushPayload(title: title, subTitle: subTitle, body: body, badge: d.badge ?? 0), regid: d.registrationID, online: d.online, dt: d.deviceToken, req: req)
                return d
            }.map { arr in
                ResponseJSON(code: .ok, message: "按Tag推送成功", data: arr.map{$0.registrationID})
            }
    }
    
    func sendMessage(payload: PushPayload, regid: String, online: Bool, dt: String, req: Request) -> EventLoopFuture<Void> {
        let pushStrategy = try? req.content.get(Int.self, at: "pushStrategy")
        let badgeStr = try? req.content.get(String.self, at: "badge")
        var badge: Int?
        if var bs = badgeStr, bs.hasPrefix("+") {
            bs.removeFirst()
            badge = Int(bs) ?? 0 + payload.badge
        } else {
            badge = payload.badge
        }
        let stra = PushStrategy(rawValue: pushStrategy ?? 2) ?? .inMessageFirst
        switch stra {
        case .system:
            let pl = APNSwiftPayload(alert: APNSwiftAlert(title: payload.title, subtitle: payload.subTitle, body: payload.body), badge: badge, sound: .normal("default"), hasContentAvailable: false, hasMutableContent: false)
            return req.apns.send(pl, to: dt)
        case .inMessage:
            let msg = MqttMsg(_msgid: UUID().uuidString, title: payload.title, subTitle: payload.subTitle, body: payload.body)
            let data = try! JSONEncoder().encode(msg)
            return Mqtt.shared.client.publish(.bytes(ByteBuffer(data: data)), to: regid, qos: .atLeastOnce)
        case .inMessageFirst:
            if online {
                let msg = MqttMsg(_msgid: UUID().uuidString, title: payload.title, subTitle: payload.subTitle, body: payload.body)
                let data = try! JSONEncoder().encode(msg)
                return Mqtt.shared.client.publish(.bytes(ByteBuffer(data: data)), to: regid, qos: .atLeastOnce)
            } else {
                let pl = APNSwiftPayload(alert: APNSwiftAlert(title: payload.title, subtitle: payload.subTitle, body: payload.body), badge: badge, sound: .normal("default"), hasContentAvailable: false, hasMutableContent: false)
                return req.apns.send(pl, to: dt)
            }
        }
    }
}
