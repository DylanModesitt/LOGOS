//
//  GraphView.swift
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
// This project was created to learn

import UIKit

protocol GraphViewDataSource: class {
    func evaluateGraph(sender: GraphView, atX: Double) -> Double?
}

@IBDesignable class GraphView: UIView {
    
    var axisColor = UIColor.grayColor()
    var lineColor = UIColor.redColor()
    let lineWidth = 1.0
    let pointsPerUnit = 32.0
    
    @IBInspectable
    var scale = 1.0 {
        didSet {setNeedsDisplay()}
    }
    
    @IBInspectable
    var offset = CGPointZero {
        didSet {setNeedsDisplay()}
    }
    
    weak var graphDataSource : GraphViewDataSource? {
        didSet {setNeedsDisplay()}
    }
    
    private var viewCenter : CGPoint {
        return convertPoint(center, fromView: superview)
    }
    
    private var axisCenter : CGPoint {
        return CGPoint(x: viewCenter.x + offset.x, y: viewCenter.y + offset.y)
    }

    override func drawRect(rect: CGRect) {
        let axis = AxesDrawer(color: axisColor, contentScaleFactor: self.contentScaleFactor)
        axis.drawAxesInRect(rect, origin: axisCenter, pointsPerUnit: CGFloat(pointsPerUnit * scale))
        
        if let graphDataSource = graphDataSource {
            drawFunction(graphDataSource, rect:rect, origin:axisCenter, pointsPerUnit: CGFloat(pointsPerUnit * scale))
        }
    }
    
    private func drawFunction(ds:GraphViewDataSource, rect:CGRect, origin:CGPoint, pointsPerUnit:CGFloat) {
        
        // fx,fy is (x,y) in the function
        // px,py is (x,y) in points
        
        var path = UIBezierPath()
        path.lineWidth = CGFloat(lineWidth)
        lineColor.set()
        
        for var px = bounds.minX; px < bounds.maxX; px += (1.0 / self.contentScaleFactor) {
            
            var fx = (px - origin.x) / pointsPerUnit
            
            if let fy = ds.evaluateGraph(self, atX: Double(fx)) where (fy.isNormal || fy.isZero) {
                var py = origin.y - CGFloat(fy) * pointsPerUnit
                if path.empty {
                    path.moveToPoint(CGPoint(x:px, y:py))
                } else {
                    path.addLineToPoint(CGPoint(x:px, y:py))
                }
            } else {
                path.stroke()
                path.removeAllPoints()
            }
        }
        path.stroke()
    }
    
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: "pan:"))
        self.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: "pinch:"))
        let tap = UITapGestureRecognizer(target: self, action: "center:")
        tap.numberOfTapsRequired = 1
        self.addGestureRecognizer(tap)
        let tap2 = UITapGestureRecognizer(target: self, action: "reset:")
        tap2.numberOfTapsRequired = 2
        self.addGestureRecognizer(tap2)
    }
    
    // MARK: Gesture reconizers
    
    func reset(gesture: UITapGestureRecognizer) {
        scale = 1.0
        offset = CGPointZero
    }
    func center(gesture: UITapGestureRecognizer) {
        var tap = gesture.locationInView(self)
        var origin = convertPoint(center, fromView: superview)
        offset.x = tap.x - origin.x
        offset.y = tap.y - origin.y
    }
    
    // Pans coming towards center
    func pinch(gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .Ended:
            fallthrough
        case .Changed:
            
             /* This is to show the degree of the pinching. Not for deployment because it casues a crash due to usage. 
            
            let p0 = gesture.locationOfTouch(0, inView:self)
            let p1 = gesture.locationOfTouch(1, inView:self)
            let angle = Double(atan2(abs(p1.y - p0.y), abs(p1.x - p0.x))) * 180.0 / M_PI;
            
            println("PINCH: scale=\(gesture.scale) angle=\(angle)") */
            
            scale *= Double(gesture.scale)
            gesture.scale = 1.0
            
        default:
            break
        }
    }

    func pan(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .Ended:
            fallthrough
        case .Changed:
            let delta = gesture.translationInView(self)
            offset.x += delta.x
            offset.y += delta.y
            gesture.setTranslation(CGPointZero, inView:self)
        default:
            break
        }
    }
    
    func uicolorFromHex(rgbValue:UInt32)->UIColor{
        let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
        let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
        let blue = CGFloat(rgbValue & 0xFF)/256.0
        
        return UIColor(red:red, green:green, blue:blue, alpha:1.0)
    }
    
}
