//  CATransaction+Instant.swift
//  Created by Vladimir Roganov on 01.05.17.

import QuartzCore

extension CATransaction {
    
    class func instant(_ closure: () -> Void) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        closure()
        CATransaction.commit()
    }
}
