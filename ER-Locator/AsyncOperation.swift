//
//  AsyncOperation.swift
//  ER-Locator
//
//  Created by Jeffrey Fulton on 2016-06-07.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import Foundation

/**
 Generic Concurrent NSOperation Subclass
 
 Overrides methods and properties required
 to prevent Operation from finishing when
 main() returns.
 
 Meant to be subclassed.
 
 - Important:
 Subclasses must call completeOperation()
 when finished working.
 */
class AsyncOperation: Operation {
    
    // MARK: - Overrides
    
    override var isAsynchronous: Bool { return true }
    
    override func start() {
        guard !isCancelled else {
            _finished = true
            return
        }
        
        _executing = true
        
        main()
    }
    
    // MARK: - State Management
    
    private var _executing: Bool = false {
        willSet { willChangeValue(forKey: "isExecuting") }
        didSet { didChangeValue(forKey: "isExecuting") }
    }
    override var isExecuting: Bool { return _executing }
    
    private var _finished: Bool = false {
        willSet { willChangeValue(forKey: "isFinished") }
        didSet { didChangeValue(forKey: "isFinished") }
    }
    override var isFinished: Bool { return _finished }
    
    // MARK: - Completion
    
    func completeOperation() {
        _executing = false
        _finished = true
    }
}
