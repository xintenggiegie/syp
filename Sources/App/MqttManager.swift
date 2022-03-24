//
//  File.swift
//
//
//  Created by Ens Livan on 2022/3/22.
//

import Vapor
import MQTTNIO

class Mqtt {
    static let shared = Mqtt()
    var client: MQTTClient!
    
    func config(_ app: Application) {
        client = MQTTClient(configuration: .init(target: .host("mq.tongxinmao.com", port: 18830), protocolVersion: .version3_1_1, clean: true))
        
        client.connect()
        
        client.whenConnected { response in
            self.client.subscribe(to: "client/status")
        }
        
        client.whenDisconnected { reason in
            print("mqtt disconnected : \(reason)")
        }
        
        client.whenMessage { message in
            if message.topic == "client/status" {
                switch message.payload {
                case var .bytes(data):
                    let status = try? data.readJSONDecodable(Status.self, length:data.capacity)
                    if let st = status {
                        let flag = (st.status == "online")
                        _ = SYDevice.query(on: app.db)
                            .set(\.$online, to: flag)
                            .filter(\.$registrationID, .equal, st.regid).update()
                    }
                    break
                default:
                    break
                }
            }
        }
    }
}

struct Status: Codable {
    var regid: String
    var status: String
}
