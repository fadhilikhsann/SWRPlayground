//
//  Configuration.swift
//  SWRPlayground
//
//  Created by Fadhil Ikhsanta's Personal on 05/10/26.
//

enum Configuration {
    case debug
    case release
    
    var current: Self {
#if DEBUG
        .debug
#else
        .release
#endif
    }
    
    var isDebug: Bool {
        self == .debug
    }
}
