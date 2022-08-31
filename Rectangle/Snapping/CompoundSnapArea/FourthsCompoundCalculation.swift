//
//  FourthsCompoundCalculation.swift
//  Rectangle
//
//  Created by Ryan Hanson on 8/24/22.
//  Copyright © 2022 Ryan Hanson. All rights reserved.
//

import Foundation

struct FourthsColumnCompoundCalculation: CompoundSnapAreaCalculation {
    
    func snapArea(cursorLocation loc: NSPoint, screen: NSScreen, priorSnapArea: SnapArea?) -> SnapArea? {
        let frame = screen.frame
        let quarterWidth = floor(frame.width / 4)
        
        // check first quarter column
        if loc.x <= frame.minX + quarterWidth {
            return SnapArea(screen: screen, action: .firstFourth)
        }
        
        // check second quarter column
        if loc.x >= frame.minX + quarterWidth && loc.x <= frame.maxX - quarterWidth*2 {
            if let priorAction = priorSnapArea?.action {
                if priorAction == .firstFourth || priorAction == .firstThreeFourths {
                    return SnapArea(screen: screen, action: .firstThreeFourths)
                }
                if priorAction == .thirdFourth || priorAction == .lastThreeFourths || priorAction == .centerHalf {
                    return SnapArea(screen: screen, action: .centerHalf)
                }
            }
            return SnapArea(screen: screen, action: .secondFourth)
        }
        
        // check third quarter column
        if loc.x >= frame.minX + quarterWidth * 2 && loc.x <= frame.maxX - quarterWidth {
            if let priorAction = priorSnapArea?.action {
                if priorAction == .lastFourth || priorAction == .lastThreeFourths {
                    return SnapArea(screen: screen, action: .lastThreeFourths)
                }
                if priorAction == .secondFourth || priorAction == .firstThreeFourths || priorAction == .centerHalf {
                    return SnapArea(screen: screen, action: .centerHalf)
                }
            }
            return SnapArea(screen: screen, action: .thirdFourth)
        }
        
        // check fourth quarter column
        if loc.x >= frame.minX + quarterWidth * 2 {
            return SnapArea(screen: screen, action: .lastFourth)
        }
        
        return nil
    }
}
