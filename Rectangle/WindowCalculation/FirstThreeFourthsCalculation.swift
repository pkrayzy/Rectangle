//
//  FirstThreeFourthsCalculation.swift
//  Rectangle
//
//  Created by Björn Orri Sæmundsson on 26.06.21.
//  Copyright © 2021 Ryan Hanson. All rights reserved.
//

import Foundation

class FirstThreeFourthsCalculation: WindowCalculation, OrientationAware {
    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        let visibleFrameOfScreen = params.visibleFrameOfScreen
        
        guard Defaults.subsequentExecutionMode.value != .none,
              let last = params.lastAction, let lastSubAction = last.subAction else {
            return orientationBasedRect(visibleFrameOfScreen)
        }
        
        if lastSubAction == .leftThreeFourths || lastSubAction == .topThreeFourths {
            return WindowCalculationFactory.lastThreeFourthsCalculation.orientationBasedRect(visibleFrameOfScreen)
        }
        
        return orientationBasedRect(visibleFrameOfScreen)
    }
    
    func landscapeRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        var rect = visibleFrameOfScreen
        
        rect.size.height = floor(visibleFrameOfScreen.height * 0.99)
        rect.origin.y = round(visibleFrameOfScreen.height * 0.005)

        rect.size.width = floor(0.99 * visibleFrameOfScreen.width * 3 / 4.0)
        rect.origin.x = round(visibleFrameOfScreen.width * 0.005)
        
        return RectResult(rect, subAction: .leftThreeFourths)
    }

    func portraitRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        var rect = visibleFrameOfScreen
        rect.size.height = (0.99 * floor(visibleFrameOfScreen.height * 3 / 4.0))
        rect.origin.y = visibleFrameOfScreen.origin.y + visibleFrameOfScreen.height - rect.height
        return RectResult(rect, subAction: .topThreeFourths)
    }

}
