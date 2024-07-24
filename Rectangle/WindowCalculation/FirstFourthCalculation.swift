//
//  LeftThirdCalculation.swift
//  Rectangle
//
//  Created by Ryan Hanson on 7/26/19.
//  Copyright © 2019 Ryan Hanson. All rights reserved.
//

import Foundation

class FirstFourthCalculation: WindowCalculation, OrientationAware {

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        let visibleFrameOfScreen = params.visibleFrameOfScreen
        
        guard Defaults.subsequentExecutionMode.value != .none,
              params.action == .firstFourth,
              let last = params.lastAction,
              let lastSubAction = last.subAction
        else {
            return orientationBasedRect(visibleFrameOfScreen)
        }

        var calculation: WindowCalculation?
        if last.action == .firstFourth {
            switch lastSubAction {
            case .topFourth, .leftFourth:
                calculation = WindowCalculationFactory.secondFourthCalculation
            case .centerTopFourth, .centerLeftFourth:
                calculation = WindowCalculationFactory.thirdFourthCalculation
            case .centerBottomFourth, .centerRightFourth:
                calculation = WindowCalculationFactory.lastFourthCalculation
            default:
                break
            }
        } else if last.action == .lastFourth {
            switch lastSubAction {
            case .leftFourth, .topFourth:
                calculation = WindowCalculationFactory.secondFourthCalculation
            default:
                break
            }
        }

        if let calculation = calculation {
            return calculation.calculateRect(params)
        }
        
        return orientationBasedRect(visibleFrameOfScreen)
    }
    
    func landscapeRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        var rect = visibleFrameOfScreen
        
        rect.size.height = floor(visibleFrameOfScreen.height * 0.985)
        rect.origin.y = round(visibleFrameOfScreen.height * 0.0075)

        rect.size.width = floor(0.99 * visibleFrameOfScreen.width / 4.0)
        rect.origin.x = round(visibleFrameOfScreen.width * 0.005)
        
        return RectResult(rect, subAction: .leftFourth)
    }
    
    func portraitRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        var rect = visibleFrameOfScreen
        rect.size.height = (0.99 * floor(visibleFrameOfScreen.height / 4.0))
        rect.origin.y = visibleFrameOfScreen.origin.y + visibleFrameOfScreen.height - rect.height
        return RectResult(rect, subAction: .topFourth)
    }
    
}
