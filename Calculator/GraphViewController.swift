//
//  GraphViewController.swift
//  LOGOS
//
//  Created by Dylan Modesitt on 6/2/15.
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

import UIKit

class GraphViewController: UIViewController, GraphViewDataSource
{
    // set when prepared
    var function : ((Double) -> Double?)?
    
    @IBOutlet weak var graphView: GraphView! {
        didSet {
            graphView.graphDataSource = self
        }
    }
    
    // trace coresponding y value for any atX
    @IBAction func trace(sender: UIButton) {
        let alert = SCLAlertView()
        let txt = alert.addTextField(title:"X value")
        txt.keyboardType = UIKeyboardType.NumbersAndPunctuation
        alert.addButton("Trace") {
            var doubleTField = (txt.text as NSString).doubleValue
            var yValue = self.evaluateGraph(GraphView(), atX: Double(doubleTField))
            if let yConfirmed = yValue {
                SCLAlertView().showNotice("Trace", subTitle: "The trace value for X = \(doubleTField) is \(yValue!)")
            } else {
                SCLAlertView().showError("Error", subTitle:"There was an error with that trace. The Y value does not exist. Please try again.", closeButtonTitle:"OK")
            }
        }
        alert.showEdit("Trace Value", subTitle:"Enter an input")
    }
    
    // used to use newton's method
    
    func getZero(precision: Int, var start: Double, var end: Double, f: (Double) -> Double?) -> Double? {
        let isStartNegative = f(start)!.isSignMinus
        if isStartNegative == f(end)!.isSignMinus { return nil }
        
        let doublePrecision = pow(10, -Double(precision))
        
        while end - start > doublePrecision {
            let mid = (start + end) / 2
            if f(mid) > 0 {
                if isStartNegative {
                    end = mid
                } else {
                    start = mid
                }
            } else {
                if isStartNegative {
                    start = mid
                } else {
                    end = mid
                }
            }
        }
        
        return (start + end) / 2
    }
    
    func getZerosInRange(precision: Int, start: Double, end: Double, f: (Double) -> Double?) -> [Double] {
        
        let doublePrecision = pow(10, -Double(precision))
        let stepCount = 100.0
        let by = (end - start) / stepCount
        var zeros = [Double]()
        
        for x in stride(from: start, to: end, by: by) {
            if let xZero = getZero(precision, start: x, end: x + by, f: f) {
                zeros.append(xZero)
            }
        }
        return zeros
    }
    
    @IBAction func getZerosTwo(sender: UIButton) {
        var fofX = {
            (x: Double) in self.function!(x)
        }
        let alert = SCLAlertView()
        let aField = alert.addTextField(title:"a value")
        let bField = alert.addTextField(title:"b value")
        aField.keyboardType = UIKeyboardType.NumbersAndPunctuation
        bField.keyboardType = UIKeyboardType.NumbersAndPunctuation
        alert.addButton("Get Zeros") {
            var aString = aField.text
            var bString = bField.text
            var aPoint = (aString as NSString).doubleValue
            var bPoint = (bString as NSString).doubleValue
            if abs(bPoint - aPoint) != 0.0 {
                if abs(bPoint - aPoint) > 1000 {
                    SCLAlertView().showWarning("Zeros", subTitle: "That interval is too large. Please choose a smaller interval.")
                } else if self.evaluateGraph(GraphView(), atX: aPoint) != nil {
                    var solution = self.getZerosInRange(10, start: aPoint, end: bPoint, f: fofX)
                        if solution.isEmpty {
                            SCLAlertView().showNotice("Zeros", subTitle: "There are no zeros on that interval.")
                        } else if self.evaluateGraph(GraphView(), atX: bPoint) != nil  {
                            SCLAlertView().showNotice("Zeros", subTitle: "The zeros for the graph on the interval [\(aPoint), \(bPoint)] are at x = \(solution).")
                        } else {
                            SCLAlertView().showWarning("Zeros", subTitle: "There are no zeros on that interval.")
                        }
                    } else {
                        SCLAlertView().showError("Zeros", subTitle: "That interval extends out of the domain of the function.")
                    }
                } else {
                    SCLAlertView().showNotice("Zeros", subTitle: "The interval cannot extend over only one point.")
                }
            }
        alert.showEdit("Enter the interval", subTitle:"The zeros in the interval [a,b]:")
    }


    // MARK: GraphViewDataSource
    func evaluateGraph(sender: GraphView, atX: Double) -> Double? {
        return function?(atX)
    }
}




