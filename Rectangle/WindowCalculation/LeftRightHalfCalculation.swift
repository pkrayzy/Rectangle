//
//  LeftHalfCalculation.swift
//  Rectangle, Ported from Spectacle
//
//  Created by Ryan Hanson on 6/13/19.
//  Copyright © 2019 Ryan Hanson. All rights reserved.
//
import Cocoa

class LeftRightHalfCalculation: WindowCalculation, RepeatedExecutionsInThirdsCalculation {
    
    let almostMaximizeHeight: CGFloat
    let almostMaximizeWidth: CGFloat

    override init() {
        let defaultHeight = Defaults.almostMaximizeHeight.value
        almostMaximizeHeight = (defaultHeight <= 0 || defaultHeight > 1)
            ? 0.985
            : CGFloat(defaultHeight)

        let defaultWidth = Defaults.almostMaximizeWidth.value
        almostMaximizeWidth = (defaultWidth <= 0 || defaultWidth > 1)
            ? 0.99
            : CGFloat(defaultWidth)
    }
    
    override func calculate(_ params: WindowCalculationParameters) -> WindowCalculationResult? {
        
        let usableScreens = params.usableScreens
        
        switch Defaults.subsequentExecutionMode.value {
            
        case .acrossMonitor, .acrossAndResize:
            if params.action == .leftHalf {
                return calculateLeftAcrossDisplays(params, screen: usableScreens.currentScreen)
            } else if params.action == .rightHalf {
                return calculateRightAcrossDisplays(params, screen: usableScreens.currentScreen)
            }
            return nil
        case .resize:
            let screen = usableScreens.currentScreen
            let rectResult: RectResult = calculateRepeatedRect(params.asRectParams())
            return WindowCalculationResult(rect: rectResult.rect, screen: screen, resultingAction: params.action)
        case .none, .cycleMonitor:
            let screen = usableScreens.currentScreen
            let oneHalfRect = calculateFirstRect(params.asRectParams())
            return WindowCalculationResult(rect: oneHalfRect.rect, screen: screen, resultingAction: params.action)
        }
        
    }
    
    func calculateFractionalRect(_ params: RectCalculationParameters, fraction: Float) -> RectResult {
        let visibleFrameOfScreen = params.visibleFrameOfScreen

        var rect = visibleFrameOfScreen
        
        rect.size.width = floor(visibleFrameOfScreen.width * CGFloat(fraction) * 0.985)
        rect.size.height = round(visibleFrameOfScreen.height * almostMaximizeHeight)
        rect.origin.y = round((visibleFrameOfScreen.height - rect.height) / 2.0) + visibleFrameOfScreen.minY
        rect.origin.x = round(visibleFrameOfScreen.width * 0.005)
        if params.action == .rightHalf {
            // rect.origin.x = visibleFrameOfScreen.maxX - rect.width
            rect.origin.x = round(visibleFrameOfScreen.width * 0.995) - rect.width
        }
        
        return RectResult(rect)
    }

    func calculateLeftAcrossDisplays(_ params: WindowCalculationParameters, screen: NSScreen) -> WindowCalculationResult? {
                
        if isRepeatedCommand(params) {
            if let prevScreen = params.usableScreens.adjacentScreens?.prev {
                return calculateRightAcrossDisplays(params.withDifferentAction(.rightHalf), screen: prevScreen)
            }
        }
        
        let oneHalfRect = calculateFirstRect(params.asRectParams(visibleFrame: screen.adjustedVisibleFrame(params.ignoreTodo), differentAction: .leftHalf))
        return WindowCalculationResult(rect: oneHalfRect.rect, screen: screen, resultingAction: .leftHalf)
    }
    
    
    func calculateRightAcrossDisplays(_ params: WindowCalculationParameters, screen: NSScreen) -> WindowCalculationResult? {
        
        if isRepeatedCommand(params) {
            if let nextScreen = params.usableScreens.adjacentScreens?.next {
                return calculateLeftAcrossDisplays(params.withDifferentAction(.leftHalf), screen: nextScreen)
            }
        }
        
        let oneHalfRect = calculateFirstRect(params.asRectParams(visibleFrame: screen.adjustedVisibleFrame(params.ignoreTodo), differentAction: .rightHalf))
        return WindowCalculationResult(rect: oneHalfRect.rect, screen: screen, resultingAction: .rightHalf)
    }

    // Used to draw box for snapping
    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        if params.action == .leftHalf {
            var oneHalfRect = params.visibleFrameOfScreen
            oneHalfRect.size.width = floor(oneHalfRect.width / 2.0)
            return RectResult(oneHalfRect)
        } else {
            var oneHalfRect = params.visibleFrameOfScreen
            oneHalfRect.size.width = floor(oneHalfRect.width / 2.0)
            oneHalfRect.origin.x += oneHalfRect.size.width
            return RectResult(oneHalfRect)
        }
    }
}
