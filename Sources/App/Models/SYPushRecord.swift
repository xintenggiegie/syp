//
//  File.swift
//  
//
//  Created by Ens Livan on 2022/4/7.
//

import Foundation

class SYPushRecord: BaseModel {
    static let schema = "pushRecords"
    
    typealias IDValue = UUID
    
    @ID(key: .id)
    var id: UUID?
    
    var title: String
    var subTitle: String
    var body: String
    
    
    var receivedDevice: [String]
    var sendTime: Date
    
    
    
}
