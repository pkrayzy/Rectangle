//
//  LeftTwoThirdsCalculation.swift
//  Rectangle
//
//  Created by Ryan Hanson on 7/26/19.
//  Copyright © 2019 Ryan Hanson. All rights reserved.
//

import Foundation

class FirstTwoThirdsCalculation: WindowCalculation, OrientationAware {
    
    
    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        let visibleFrameOfScreen = params.visibleFrameOfScreen

        guard Defaults.subsequentExecutionMode.value != .none,
            let last = params.lastAction, let lastSubAction = last.subAction else {
            return orientationBasedRect(visibleFrameOfScreen)
        }

        if lastSubAction == .leftTwoThirds || lastSubAction == .topTwoThirds {
            return WindowCalculationFactory.lastTwoThirdsCalculation.orientationBasedRect(visibleFrameOfScreen)
        }
        
        return orientationBasedRect(visibleFrameOfScreen)
    }

    func landscapeRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        var rect = visibleFrameOfScreen
        
        rect.size.height = floor(visibleFrameOfScreen.height * 0.985)
        rect.origin.y = round(visibleFrameOfScreen.height * 0.0075)

        rect.size.width = floor(0.99 * visibleFrameOfScreen.width * 2 / 3.0)
        rect.origin.x = round(visibleFrameOfScreen.width * 0.005)
        
        return RectResult(rect, subAction: .leftTwoThirds)
    }

    func portraitRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        var rect = visibleFrameOfScreen
        rect.size.height = (0.985 * floor(visibleFrameOfScreen.height * 2 / 3.0))
        rect.origin.y = visibleFrameOfScreen.origin.y + visibleFrameOfScreen.height - rect.height
        return RectResult(rect, subAction: .topTwoThirds)
    }

}
