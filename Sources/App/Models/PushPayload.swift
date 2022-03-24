//
//  File.swift
//  
//
//  Created by Ens Livan on 2022/3/24.
//

import Foundation
import Vapor

struct MqttMsg: Content {
    var _msgid: String
    var title: String
    var subTitle: String
    var body: String?
}
