//
//  AxesDrawer.swift
//  LOGOS
//
//  Created by Dylan Modesitt
/*  Copyright (c) 2015 Dylan Modesitt.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE. */

// Inspired by CS193 and the assignemnents from Stanford University.
// based on open-source code on axes drawer from CS193.
// I based this code off of CS193 Axes Drawer.
// This project was created to learn


import UIKit

class AxesDrawer {
    
    private struct Constants {
        static let HashmarkSize: CGFloat = 6
    }
    
    // Initialization of color scheme used to draw the axis
    var text_color = UIColor()
    var hashColor = UIColor()
    var axis_color = UIColor()
    var gridColor = UIColor()
    
    var minimumPointsPerHashmark: CGFloat = 40
    var contentScaleFactor: CGFloat = 1
    
    // set color scheme
    var color : UIColor {
        set {
            text_color = newValue
            hashColor = newValue
            axis_color = newValue
            gridColor = newValue.colorWithAlphaComponent(0.25)
        }
        get {
            return text_color
        }
    }
    
    // initialization of the color scheme and scale
    
    init() {
        color = UIColor.blueColor()
    }
    convenience init(color: UIColor) {
        self.init()
        self.color = color
    }
    convenience init(contentScaleFactor: CGFloat) {
        self.init()
        self.contentScaleFactor = contentScaleFactor
    }
    convenience init(color: UIColor, contentScaleFactor: CGFloat) {
        self.init()
        self.color = color
        self.contentScaleFactor = contentScaleFactor
    }

    /* Draw the axes
     The current context of the graphView
     Origin and bounds must be in the current graphics context's coordinate system
     pointsPerUnit is essentially the scale of the axis along their points  */

    func drawAxesInRect(bounds: CGRect, origin: CGPoint, pointsPerUnit: CGFloat) {
        CGContextSaveGState(UIGraphicsGetCurrentContext())

        axis_color.set()
        
        drawLine(CGPoint(x: align(origin.x), y: bounds.minY), CGPoint(x: align(origin.x), y: bounds.maxY))
        drawLine(CGPoint(x: bounds.minX, y: align(origin.y)), CGPoint(x: bounds.maxX, y: align(origin.y)))

        drawHashmarksInRect(bounds, origin: origin, pointsPerUnit: abs(pointsPerUnit))
        CGContextRestoreGState(UIGraphicsGetCurrentContext())
    }
    
    private func drawHashmarksInRect(bounds: CGRect, origin: CGPoint, pointsPerUnit: CGFloat) {
        if ((origin.x >= bounds.minX) && (origin.x <= bounds.maxX)) || ((origin.y >= bounds.minY) && (origin.y <= bounds.maxY)) {
            // Make hashmarks comply with pointsPerUnit
            var unitsPerHashmark = minimumPointsPerHashmark / pointsPerUnit
            if unitsPerHashmark < 1 {
                unitsPerHashmark = pow(10, ceil(log10(unitsPerHashmark)))
            } else {
                unitsPerHashmark = floor(unitsPerHashmark)
            }

            let pointsPerHashmark = pointsPerUnit * unitsPerHashmark
            
            // figure out which is the closest set of hashmarks (radiating out from the origin) that are in bounds
            var startingHashmarkRadius: CGFloat = 1
            if !CGRectContainsPoint(bounds, origin) {
                if origin.x > bounds.maxX {
                    startingHashmarkRadius = (origin.x - bounds.maxX) / pointsPerHashmark + 1
                } else if origin.x < bounds.minX {
                    startingHashmarkRadius = (bounds.minX - origin.x) / pointsPerHashmark + 1
                } else if origin.y > bounds.maxY {
                    startingHashmarkRadius = (origin.y - bounds.maxY) / pointsPerHashmark + 1
                } else {
                    startingHashmarkRadius = (bounds.minY - origin.y) / pointsPerHashmark + 1
                }
                startingHashmarkRadius = floor(startingHashmarkRadius)
            }
            
            // now create a bounding box inside whose edges those four hashmarks lie
            let hashBoxSize = pointsPerHashmark * startingHashmarkRadius * 2
            var bbox = CGRect(center: origin, size: CGSize(width: hashBoxSize, height: hashBoxSize))

            // formatter for the hashmark labels
            let formatter = NSNumberFormatter()
            formatter.maximumFractionDigits = Int(-log10(Double(unitsPerHashmark)))
            formatter.minimumIntegerDigits = 1

            // set hashmarks further than bounds
            while !CGRectContainsRect(bbox, bounds)
            {
                let label = formatter.stringFromNumber((origin.x-bbox.minX)/pointsPerUnit)!
                if let leftHashmarkPoint = alignedPoint(x: bbox.minX, y: origin.y, insideBounds:bounds) {
                    drawHashAtLocale(bounds, leftHashmarkPoint, .Top("-\(label)"))
                }
                if let rightHashmarkPoint = alignedPoint(x: bbox.maxX, y: origin.y, insideBounds:bounds) {
                    drawHashAtLocale(bounds, rightHashmarkPoint, .Top(label))
                }
                if let topHashmarkPoint = alignedPoint(x: origin.x, y: bbox.minY, insideBounds:bounds) {
                    drawHashAtLocale(bounds, topHashmarkPoint, .Left(label))
                }
                if let bottomHashmarkPoint = alignedPoint(x: origin.x, y: bbox.maxY, insideBounds:bounds) {
                    drawHashAtLocale(bounds, bottomHashmarkPoint, .Left("-\(label)"))
                }
                bbox.inset(dx: -pointsPerHashmark, dy: -pointsPerHashmark)
            }
        }
    }
    
    private func drawHashAtLocale(bounds: CGRect, _ location: CGPoint, _ text: AnchoredText) {
        var dx: CGFloat = 0, dy: CGFloat = 0
        switch text {
            case .Left: dx = Constants.HashmarkSize / 2
            case .Right: dx = Constants.HashmarkSize / 2
            case .Top: dy = Constants.HashmarkSize / 2
            case .Bottom: dy = Constants.HashmarkSize / 2
        }
        
        gridColor.set()
        switch text {
        case .Top, .Bottom: drawLine(CGPoint(x: location.x, y: bounds.minY), CGPoint(x: location.x, y: bounds.maxY))
        case .Left, .Right: drawLine(CGPoint(x: bounds.minX, y: location.y), CGPoint(x: bounds.maxX, y: location.y))
        }
        
        hashColor.set()
        drawLine(CGPoint(x: location.x-dx, y: location.y-dy), CGPoint(x: location.x+dx, y: location.y+dy))
        text.drawAnchoredToPoint(location, color: text_color)
    }
    
    private func drawLine(start:CGPoint, _ end:CGPoint)
    {
        let path = UIBezierPath()
        path.moveToPoint(start)
        path.addLineToPoint(end)
        path.stroke()
    }
    
    private enum AnchoredText {
        case Left(String)
        case Right(String)
        case Top(String)
        case Bottom(String)
        
        static let VerticalOffset: CGFloat = 3
        static let HorizontalOffset: CGFloat = 6
        
        func drawAnchoredToPoint(location: CGPoint, color: UIColor) {
            let attributes = [
                NSFontAttributeName : UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote),
                NSForegroundColorAttributeName : color
            ]
            var textRect = CGRect(center: location, size: text.sizeWithAttributes(attributes))
            switch self {
                case Top: textRect.origin.y += textRect.size.height / 2 + AnchoredText.VerticalOffset
                case Bottom: textRect.origin.y -= textRect.size.height / 2 + AnchoredText.VerticalOffset
                case Left: textRect.origin.x += textRect.size.width / 2 + AnchoredText.HorizontalOffset
                case Right: textRect.origin.x -= textRect.size.width / 2 + AnchoredText.HorizontalOffset
            }
            
            text.drawInRect(textRect, withAttributes: attributes)
        }

        var text: String {
            switch self {
                case Left(let text): return text
                case Right(let text): return text
                case Top(let text): return text
                case Bottom(let text): return text
            }
        }
    }


    private func alignedPoint(#x: CGFloat, y: CGFloat, insideBounds: CGRect? = nil) -> CGPoint? {
        let point = CGPoint(x: align(x), y: align(y))
        if let permissibleBounds = insideBounds {
            if (!CGRectContainsPoint(permissibleBounds, point)) {
                return nil
            }
        }
        return point
    }

    private func align(coordinate: CGFloat) -> CGFloat {
        return round(coordinate * contentScaleFactor) / contentScaleFactor
    }
}

extension CGRect
{
    init(center: CGPoint, size: CGSize) {
        self.init(x: center.x-size.width/2, y: center.y-size.height/2, width: size.width, height: size.height)
    }
}
