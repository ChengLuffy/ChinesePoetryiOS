//
//  PoetryManager.swift
//  ChinesePoetry
//
//  Created by 成殿 on 2018/2/9.
//  Copyright © 2018年 成殿. All rights reserved.
//

import Foundation
import FMDB

class PoetryManager: NSObject {
    
    static let shareManager = PoetryManager()
    
    var dbQueue: FMDatabaseQueue?
    
    override init() {
        let dbPath = Bundle.main.path(forResource: "tangshi", ofType: ".db")
        dbQueue = FMDatabaseQueue(path: dbPath)
        super.init()
    }
    
}
