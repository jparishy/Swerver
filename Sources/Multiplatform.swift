//
//  Multiplatform.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 03/12/15.
//  Copyright © 2015 Marcin Krzyzanowski. All rights reserved.
//

// Nabbed from CryptoSwift until this lands in mainstream Swift

#if os(Linux)
    import Glibc
    import SwiftShims
#else
    import Darwin
#endif

public func swerver_arc4random_uniform(upperBound: UInt32) -> UInt32 {
    #if os(Linux)
        return _swift_stdlib_arc4random_uniform(upperBound)
    #else
        return arc4random_uniform(upperBound)
    #endif
}
