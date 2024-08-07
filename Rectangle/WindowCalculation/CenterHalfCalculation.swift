//
//  AlmostMaximizeCalculation.swift
//  Rectangle
//
//  Created by Ryan Hanson on 7/26/19.
//  Copyright © 2019 Ryan Hanson. All rights reserved.
//

import Foundation

class CenterHalfCalculation: WindowCalculation, OrientationAware, RepeatedExecutionsInThirdsCalculation {
    
    func calculateFractionalRect(_ params: RectCalculationParameters, fraction: Float) -> RectResult {
        
        let visibleFrameOfScreen = params.visibleFrameOfScreen
        return visibleFrameOfScreen.isLandscape
            ? landscapeRect(visibleFrameOfScreen, fraction: fraction)
            : portraitRect(visibleFrameOfScreen, fraction: fraction)
    }
    
    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        
        if (params.lastAction != nil && Defaults.subsequentExecutionMode.resizes) || Defaults.centerHalfCycles.userEnabled {
            return calculateRepeatedRect(params)
        }
        
        return orientationBasedRect(params.visibleFrameOfScreen)
    }
    
    func landscapeRect(_ visibleFrameOfScreen: CGRect, fraction: Float) -> RectResult {
        var rect = visibleFrameOfScreen
        
        // Resize
        rect.size.height = (0.985 * visibleFrameOfScreen.height)
        rect.size.width = round(0.99 * visibleFrameOfScreen.width * CGFloat(fraction))
        
        // Center
        rect.origin.x = round((visibleFrameOfScreen.width - rect.width) / 2.0) + visibleFrameOfScreen.minX
        rect.origin.y = round((visibleFrameOfScreen.height - rect.height) / 2.0) + visibleFrameOfScreen.minY
        
        return RectResult(rect, subAction: .centerVerticalHalf)
    }

    func portraitRect(_ visibleFrameOfScreen: CGRect, fraction: Float) -> RectResult {
        var rect = visibleFrameOfScreen
        
        // Resize
        rect.size.width = round(0.99 * visibleFrameOfScreen.width)
        rect.size.height = round(0.985 * visibleFrameOfScreen.height * CGFloat(fraction))
        
        // Center
        rect.origin.x = round((visibleFrameOfScreen.width * 0.99 - rect.width) / 2.0) + visibleFrameOfScreen.minX
        rect.origin.y = round((visibleFrameOfScreen.height - rect.height) / 2.0) + visibleFrameOfScreen.minY
        
        return RectResult(rect, subAction: .centerHorizontalHalf)
    }

    func landscapeRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        return landscapeRect(visibleFrameOfScreen, fraction: 0.5)
    }
    
    func portraitRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        return portraitRect(visibleFrameOfScreen, fraction: 0.5)
    }

}

