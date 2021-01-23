//
//  CountingDispatchGroup.swift
//  Breaking reCAPTCHA
//
//  Created by James Burriss on 15/04/2020.
//  Copyright © 2020 James Burriss. All rights reserved.
//

import Foundation

/// A counting `DispatchGroup` which prevents over-leaving.
public final class CountingDispatchGroup {
    
    /// The dispatch group.
    public private(set) var manager: DispatchGroup!
    
    /// The number of groups entered.
    fileprivate var count: Int = 0
    
    /// The error which was encountered in the group.
    public var error: Error?
    
    public init(enter count: Int = 0) {
        manager = DispatchGroup()
        for _ in 0..<count {
            enter()
        }
    }
    
    /// Boolean value whether the counting dispatch group is finished.
    public var isFinished: Bool {
        count == 0
    }
    
    /// Enters the dispatch group.
    public func enter() {
        manager.enter()
        count += 1
    }
    
    /// Leaves the dispatch group.
    public func leave() {
        if count > 0 {
            count -= 1
            manager.leave()
        }
    }
}
