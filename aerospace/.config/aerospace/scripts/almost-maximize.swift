#!/usr/bin/swift
import AppKit

func getFrontmostWindow() -> AXUIElement? {
    guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
    let appRef = AXUIElementCreateApplication(app.processIdentifier)
    var value: AnyObject?
    guard AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &value) == .success else { return nil }
    return (value as! AXUIElement)
}

func getMonitorForWindow(window: AXUIElement) -> NSScreen? {
    var value: AnyObject?
    var windowFrame = CGRect.zero
    if AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &value) == .success,
       AXValueGetValue(value as! AXValue, .cgPoint, &windowFrame.origin) {
        if AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &value) == .success,
           AXValueGetValue(value as! AXValue, .cgSize, &windowFrame.size) {
            return NSScreen.screens.first(where: { $0.frame.intersects(windowFrame) })
        }
    }
    return nil
}

func setWindowPositionAndSize(window: AXUIElement, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
    var position = CGPoint(x: x, y: y)
    var size = CGSize(width: width, height: height)
    if let positionValue = AXValueCreate(.cgPoint, &position),
       let sizeValue = AXValueCreate(.cgSize, &size) {
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
    }
}

// Main
guard let window = getFrontmostWindow() else { exit(1) }
guard let screen = getMonitorForWindow(window: window) ?? NSScreen.main else { exit(1) }

let margin: CGFloat = 30
let visibleFrame = screen.visibleFrame
let screenFrame = screen.frame

// Convert from Cocoa coords (origin bottom-left) to screen coords (origin top-left)
let menuBarHeight = screenFrame.height - visibleFrame.height - visibleFrame.origin.y + screenFrame.origin.y
let x = visibleFrame.origin.x + margin
let y = menuBarHeight + margin
let w = visibleFrame.width - (margin * 2)
let h = visibleFrame.height - (margin * 2)

setWindowPositionAndSize(window: window, x: x, y: y, width: w, height: h)
