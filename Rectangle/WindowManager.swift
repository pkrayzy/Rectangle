//
//  WindowManager.swift
//  Rectangle, Ported from Spectacle
//
//  Created by Ryan Hanson on 6/12/19.
//  Copyright © 2019 Ryan Hanson. All rights reserved.
//

import Cocoa

class WindowManager {
    
    private let screenDetection = ScreenDetection()
    private let standardWindowMoverChain: [WindowMover]
    private let fixedSizeWindowMoverChain: [WindowMover]
    
    init() {
        standardWindowMoverChain = [
            StandardWindowMover(),
            BestEffortWindowMover()
        ]
        
        fixedSizeWindowMoverChain = [
            CenteringFixedSizedWindowMover(),
            BestEffortWindowMover()
        ]
    }
    
    private func recordAction(windowId: CGWindowID, resultingRect: CGRect, action: WindowAction, subAction: SubWindowAction?) {
        let newCount: Int
        if let lastRectangleAction = AppDelegate.windowHistory.lastRectangleActions[windowId], lastRectangleAction.action == action {
            newCount = lastRectangleAction.count + 1
        } else {
            newCount = 1
        }
        
        AppDelegate.windowHistory.lastRectangleActions[windowId] = RectangleAction(
            action: action,
            subAction: subAction,
            rect: resultingRect,
            count: newCount
        )
    }
    
    func execute(_ parameters: ExecutionParameters) {
        guard let frontmostWindowElement = parameters.windowElement ?? AccessibilityElement.getFrontWindowElement(),
              let windowId = parameters.windowId ?? frontmostWindowElement.getWindowId()
        else {
            NSSound.beep()
            return
        }
        
        let action = parameters.action
        
        if action == .restore {
            if let restoreRect = AppDelegate.windowHistory.restoreRects[windowId] {
                frontmostWindowElement.setFrame(restoreRect)
            }
            AppDelegate.windowHistory.lastRectangleActions.removeValue(forKey: windowId)
            return
        }
        
        var screens: UsableScreens?
        if let screen = parameters.screen {
            screens = UsableScreens(currentScreen: screen, numScreens: 1)
        } else {
            screens = screenDetection.detectScreens(using: frontmostWindowElement)
        }
        
        guard let usableScreens = screens else {
            NSSound.beep()
            Logger.log("Unable to obtain usable screens")
            return
        }
        
        let currentWindowRect: CGRect = frontmostWindowElement.frame
        
        var lastRectangleAction = AppDelegate.windowHistory.lastRectangleActions[windowId]
        
        let windowMovedExternally = currentWindowRect != lastRectangleAction?.rect
        
        if windowMovedExternally {
            lastRectangleAction = nil
            AppDelegate.windowHistory.lastRectangleActions.removeValue(forKey: windowId)
        }
        
        if parameters.updateRestoreRect {
            if AppDelegate.windowHistory.restoreRects[windowId] == nil
                || windowMovedExternally {
                AppDelegate.windowHistory.restoreRects[windowId] = currentWindowRect
            }
        }
        
        let ignoreTodo = TodoManager.isTodoWindow(windowId)
        
        if frontmostWindowElement.isSheet == true
            || currentWindowRect.isNull
            || usableScreens.frameOfCurrentScreen.isNull
            || usableScreens.currentScreen.adjustedVisibleFrame(ignoreTodo).isNull {
            NSSound.beep()
            Logger.log("Window is not snappable or usable screen is not valid")
            return
        }
        
        let currentNormalizedRect = currentWindowRect.screenFlipped
        let currentWindow = Window(id: windowId, rect: currentNormalizedRect)
        
        let windowCalculation = WindowCalculationFactory.calculationsByAction[action]
        
        let calculationParams = WindowCalculationParameters(window: currentWindow, usableScreens: usableScreens, action: action, lastAction: lastRectangleAction, ignoreTodo: ignoreTodo)
        guard var calcResult = windowCalculation?.calculate(calculationParams) else {
            NSSound.beep()
            Logger.log("Nil calculation result")
            return
        }
        
        let gapsApplicable = calcResult.resultingAction.gapsApplicable
        
        if Defaults.gapSize.value > 0, gapsApplicable != .none {
            let gapSharedEdges = calcResult.resultingSubAction?.gapSharedEdge ?? calcResult.resultingAction.gapSharedEdge
            
            calcResult.rect = GapCalculation.applyGaps(calcResult.rect, dimension: gapsApplicable, sharedEdges: gapSharedEdges, gapSize: Defaults.gapSize.value)
        }

        if currentNormalizedRect.equalTo(calcResult.rect) {
            Logger.log("Current frame is equal to new frame")
            
            recordAction(windowId: windowId, resultingRect: currentWindowRect, action: calcResult.resultingAction, subAction: calcResult.resultingSubAction)
            
            return
        }
        
        let visibleFrameOfDestinationScreen = calcResult.resultingScreenFrame ?? calcResult.screen.adjustedVisibleFrame(ignoreTodo)
        let isFixedSize = (!frontmostWindowElement.isResizable() && action.resizes) || frontmostWindowElement.isSystemDialog == true
        let resultParameters = ResultParameters(windowId: windowId,
                                                action: action,
                                                windowElement: frontmostWindowElement,
                                                calcResult: calcResult,
                                                usableScreens: usableScreens,
                                                visibleFrameOfScreen: visibleFrameOfDestinationScreen,
                                                source: parameters.source,
                                                isFixedSize: isFixedSize)
        
        var resultingRect = apply(result: resultParameters)
        
        let isMovedAcrossDisplays = usableScreens.currentScreen != calcResult.screen
        if isMovedAcrossDisplays {
            if calcResult.rect.height != resultingRect.height {
                Logger.log("Window size wasn't applied perfectly across displays. Trying again.")
                resultingRect = apply(result: resultParameters)
                
                if calcResult.rect.height != resultingRect.height {
                    Logger.log("Final attempt to adjust across displays.")
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(25)) { [weak self] in
                        guard let self else { return }
                        let finalRect = self.apply(result: resultParameters)
                        self.windowMovedAcrossDisplays(windowElement: frontmostWindowElement, resultingRect: finalRect)
                        self.postProcess(result: resultParameters, resultingRect: finalRect)
                    }
                    return
                }
            }
            windowMovedAcrossDisplays(windowElement: frontmostWindowElement, resultingRect: resultingRect)
        }
        
        postProcess(result: resultParameters, resultingRect: resultingRect)
    }
    
    /// Move/resize a window based on the calculation results.
    /// - Returns: The rect of the window after applying the window action
    func apply(result: ResultParameters) -> CGRect {
        let windowMoverChain = result.isFixedSize
        ? fixedSizeWindowMoverChain
        : standardWindowMoverChain
        
        let newRect = result.calcResult.rect.screenFlipped
        
        for windowMover in windowMoverChain {
            windowMover.moveWindowRect(newRect,
                                       frameOfScreen: result.usableScreens.frameOfCurrentScreen,
                                       visibleFrameOfScreen: result.visibleFrameOfScreen,
                                       frontmostWindowElement: result.windowElement,
                                       action: result.action)
        }
        
        return result.windowElement.frame
    }
    
    func windowMovedAcrossDisplays(windowElement: AccessibilityElement, resultingRect: CGRect) {
        windowElement.bringToFront(force: true)
        
        if Defaults.moveCursorAcrossDisplays.userEnabled {
            CGWarpMouseCursorPosition(resultingRect.centerPoint)
        }
    }
    
    func postProcess(result: ResultParameters, resultingRect: CGRect) {
        let calcResult = result.calcResult
        
        if Defaults.moveCursor.userEnabled, result.source == .keyboardShortcut {
            CGWarpMouseCursorPosition(resultingRect.centerPoint)
        }
        
        recordAction(windowId: result.windowId, resultingRect: resultingRect, action: calcResult.resultingAction, subAction: calcResult.resultingSubAction)
        
        if Logger.logging {
            var logItems = ["\(result.action.name)",
                            "display: \(result.visibleFrameOfScreen.debugDescription)",
                            "calculatedRect: \(result.calcResult.rect.screenFlipped.debugDescription)",
                            "resultRect: \(resultingRect.debugDescription)",
                            "srcScreen: \(result.usableScreens.currentScreen.localizedName)",
                            "destScreen: \(calcResult.screen.localizedName)"]
            if let resultScreens = screenDetection.detectScreens(using: result.windowElement) {
                logItems.append("resultScreen: \(resultScreens.currentScreen.localizedName)")
            }
            Logger.log(logItems.joined(separator: ", "))
        }
    }
    
    struct ResultParameters {
        let windowId: CGWindowID
        let action: WindowAction
        let windowElement: AccessibilityElement
        let calcResult: WindowCalculationResult
        let usableScreens: UsableScreens
        let visibleFrameOfScreen: CGRect
        let source: ExecutionSource
        let isFixedSize: Bool
    }
}

struct RectangleAction {
    let action: WindowAction
    let subAction: SubWindowAction?
    let rect: CGRect
    let count: Int
}

struct ExecutionParameters {
    let action: WindowAction
    let updateRestoreRect: Bool
    let screen: NSScreen?
    let windowElement: AccessibilityElement?
    let windowId: CGWindowID?
    let source: ExecutionSource

    init(_ action: WindowAction, updateRestoreRect: Bool = true, screen: NSScreen? = nil, windowElement: AccessibilityElement? = nil, windowId: CGWindowID? = nil, source: ExecutionSource = .keyboardShortcut) {
        self.action = action
        self.updateRestoreRect = updateRestoreRect
        self.screen = screen
        self.windowElement = windowElement
        self.windowId = windowId
        self.source = source
    }
}

enum ExecutionSource {
    case keyboardShortcut, dragToSnap, menuItem, url, titleBar
}
