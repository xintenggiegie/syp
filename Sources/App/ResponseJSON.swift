//
//  File.swift
//
//
//  Created by Ens Livan on 2022/3/17.
//

import Vapor

struct Empty: Content {}

struct ResponseJSON<T: Content>: Content {
    private var code: ResponseCode
    private var message: String
    private var data: T?
    
    init(data: T) {
        self.code = .ok
        self.data = data
        self.message = code.desc
    }
    
    init(code: ResponseCode = .ok) {
        self.code = code
        self.message = code.desc
        self.data = nil
    }
    
    init(code: ResponseCode = .ok, message: String = ResponseCode.ok.desc) {
        self.code = code
        self.message = message
        self.data = nil
    }
    
    init(code: ResponseCode = .ok, message: String? = ResponseCode.ok.desc, data: T?) {
        self.code = code
        self.message = message ?? code.desc
        self.data = data
    }
}


enum ResponseCode: Int, Content {
    case ok = 0
    case missingField = 1
    case dataNotExist = 2
    case invalid = 3
    case unknown = 4
    var desc: String {
        switch self {
        case .ok:
            return "请求成功"
        case .missingField:
            return "缺少参数"
        case .dataNotExist:
            return "数据不存在"
        case .invalid:
            return "参数无效"
        case .unknown:
            return "其他错误"
        }
    }
}
