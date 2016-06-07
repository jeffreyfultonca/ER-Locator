//
//  DependencyEnforcing.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-06-06.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

/**
 DependencyEnforcing protocol ensures conforming types implement `func enforceDependencies()` to guard against nil dependencies.
 
 Especially useful in UIViewController subclasses where initializer based dependency injection is not possible because classes can be instantiated from Storyboards and Xibs.
 
 The purpose of this protocol is to remind developers of the dependency requirements and aid in debugging. Hopefully Apple will add something in future versions of Swift/Xcode to enable the compiler to check this for us.
 
 Example implemenation:
 ```
 func enforceDependencies() {
    guard networkService != nil else {
        fatalError("networkService dependency not met.")
    }
 }
 
 ```
 
 */
protocol DependencyEnforcing {
    /**
     Use guard statements to ensure all dependencies are met for this instance. 
     
     i.e.
     ```
     guard networkService != nil else { 
        fatalError("networkService dependency not met.") 
     }
     ```
     */
    func enforceDependencies()
}
