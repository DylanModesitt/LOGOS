//
//  ExtenstionViewController.swift
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

// This project was created to learn

// This class uses an open-source library called 'Sprint' 

/* Calculators should not work the same on a touchscreen as they do in real life. 
   They should be dynamic, have extentions, and fit so much more */

import UIKit

// Delegation between the modal and the controller
protocol ExtensionViewControllerDelegate: class {
    func operate(sender:UIButton)
    func evaluateGraph(atX: Double) -> Double?
    func evaluateDerivative(atX: Double) -> Double?
    func evaluateIntegral(atA:Double, atB:Double) -> Double?
    func evaluateLimit(atPoint:Double, side: String) -> Double?
    func dropFromTop()
    func roll()
    func exchange()
    func sum()
}

class ExtensionViewController: UIViewController {
    
    weak var delegate: ExtensionViewControllerDelegate?
    let defaults = NSUserDefaults.standardUserDefaults()

    @IBOutlet weak var modalView: SpringView!
    
    @IBAction func closeButtonPressed(sender: AnyObject) {
        UIApplication.sharedApplication().sendAction("maximizeView:", to: nil, from: self, forEvent: nil)
        modalView.animation = "slideRight"
        modalView.animateFrom = false
        modalView.animateToNext({
            self.dismissViewControllerAnimated(false, completion: nil)
        })
    }
    
    
    // outlets to evaluate trig
    @IBOutlet weak var sin: UIButton!
    @IBOutlet weak var cos: UIButton!
    @IBOutlet weak var tan: UIButton!
    @IBOutlet weak var csc: UIButton!
    @IBOutlet weak var sec: UIButton!
    @IBOutlet weak var cot: UIButton!
    @IBOutlet weak var sinh: UIButton!
    @IBOutlet weak var cosh: UIButton!
    @IBOutlet weak var tanh: UIButton!
    @IBOutlet weak var csch: UIButton!
    @IBOutlet weak var sech: UIButton!
    @IBOutlet weak var coth: UIButton!
    @IBOutlet weak var asin: UIButton!
    @IBOutlet weak var acos: UIButton!
    @IBOutlet weak var atan: UIButton!
    @IBOutlet weak var acsc: UIButton!
    @IBOutlet weak var asec: UIButton!
    @IBOutlet weak var acot: UIButton!
    @IBOutlet weak var asinh: UIButton!
    @IBOutlet weak var acosh: UIButton!
    @IBOutlet weak var atanh: UIButton!
    @IBOutlet weak var acsch: UIButton!
    @IBOutlet weak var asech: UIButton!
    @IBOutlet weak var acoth: UIButton!
    
    @IBOutlet weak var typeButton: UIButton!
    @IBOutlet weak var modeButton: UIButton!
    
    // MARK: ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
          UIModel().makeTutorialAlert("Drawer", alertDescription: "Congratulations! You used your first drawer; explore the others!")
          modalView.transform = CGAffineTransformMakeTranslation(-300, 0)
        
        if let typeButtonOptional = typeButton {
            if let savedType: String = defaults.objectForKey("type") as? String {
                typeButton.setTitle(savedType, forState: UIControlState.Normal)
            }
        }
        if let modeButtonOptional = modeButton {
            if let savedMode: String = defaults.objectForKey("mode") as? String {
                modeButton.setTitle(savedMode, forState: UIControlState.Normal)
            }
        }
        if let sinButton = sin {
            if let savedMode: String = defaults.objectForKey("mode") as? String {
                if savedMode == "Deg" {
                    sin.setTitle("sin°", forState: .Normal)
                    cos.setTitle("cos°", forState: .Normal)
                    tan.setTitle("tan°", forState: .Normal)
                    csc.setTitle("csc°", forState: .Normal)
                    sec.setTitle("sec°", forState: .Normal)
                    cot.setTitle("cot°", forState: .Normal)
                    sinh.setTitle("sinh°", forState: .Normal)
                    cosh.setTitle("cosh°", forState: .Normal)
                    tanh.setTitle("tanh°", forState: .Normal)
                    csch.setTitle("csch°", forState: .Normal)
                    sech.setTitle("sech°", forState: .Normal)
                    coth.setTitle("coth°", forState: .Normal)
                    asin.setTitle("asin°", forState: .Normal)
                    acos.setTitle("acos°", forState: .Normal)
                    atan.setTitle("atan°", forState: .Normal)
                    acsc.setTitle("acsc°", forState: .Normal)
                    asec.setTitle("asec°", forState: .Normal)
                    acot.setTitle("acot°", forState: .Normal)
                    asinh.setTitle("asinh°", forState: .Normal)
                    acosh.setTitle("acosh°", forState: .Normal)
                    atanh.setTitle("atanh°", forState: .Normal)
                    acsch.setTitle("acsch°", forState: .Normal)
                    asech.setTitle("asech°", forState: .Normal)
                    acoth.setTitle("acoth°", forState: .Normal)
                }
                
            }
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        modalView.animate()
        UIApplication.sharedApplication().sendAction("minimizeView:", to: nil, from: self, forEvent: nil)
        
    }
    

    @IBAction func operateExtention(sender: UIButton) {
        delegate?.operate(sender)
    }
    
    
    @IBAction func limit(sender: UIButton) {
        let alert = SCLAlertView()
        let xValue = alert.addTextField(title:"?")
        xValue.keyboardType = UIKeyboardType.NumbersAndPunctuation
        alert.addButton("Approximate Limit") {
            if let given = (xValue.text as NSString).doubleValue as Double? {
                if let answer = self.delegate?.evaluateLimit(given, side: "general") {
                SCLAlertView().showNotice("Limit", subTitle: "The limit as x approaches \(given) is \(answer) ")
                } else {
                    SCLAlertView().showNotice("Limit", subTitle: "The limit as x approaches \(given) does not exist as the values from approaching from the left and right do not match.")
                }
            } else {
                SCLAlertView().showNotice("Limit", subTitle: "The given x value is outside of the domain.")
            }
        }
        alert.addButton("Limit from left") {
            if let given = (xValue.text as NSString).doubleValue as Double? {
                if let answer = self.delegate?.evaluateLimit(given, side: "left") {
                    SCLAlertView().showNotice("Limit", subTitle: "The limit as x approaches \(given) from the left is \(answer) ")
                } else {
                    SCLAlertView().showNotice("Limit", subTitle: "The limit as x approaches \(given) does not exist as the approaching values from the left and right do not match.")
                }
            } else {
                SCLAlertView().showNotice("Limit", subTitle: "The given x value is outside of the domain.")
            }
            
        }
        alert.addButton("Limit from right") {
            if let given = (xValue.text as NSString).doubleValue as Double? {
                if let answer = self.delegate?.evaluateLimit(given, side: "right") {
                    SCLAlertView().showNotice("Limit", subTitle: "The limit as x approaches \(given) from the right is \(answer) ")
                } else {
                    SCLAlertView().showNotice("Limit", subTitle: "The limit as x approaches \(given) does not exist as the values from approaching from the left and right do not match.")
                }
            } else {
                SCLAlertView().showNotice("Limit", subTitle: "The given x value is outside of the domain.")
            }
        }
        alert.showEdit("Limit", subTitle:"as x approaches -> ")
    }
    
    
    @IBAction func nDeriv(sender: UIButton) {
        let alert = SCLAlertView()
        let xValue = alert.addTextField(title:"x value")
        xValue.keyboardType = UIKeyboardType.NumbersAndPunctuation
        alert.addButton("Numerical Derivative") {
            if let given = (xValue.text as NSString).doubleValue as Double? {
                if let answer = self.delegate?.evaluateDerivative(given) {
                    SCLAlertView().showNotice("Derivative", subTitle: "The derivative at x = \(given) is \(answer) ")
                } else {
                    SCLAlertView().showWarning("Derivative", subTitle: "The derivative does not exist at \(given)")
                }
            } else {
                SCLAlertView().showWarning("Derivative", subTitle: "The given x value is outside of the domain.")
            }
        }
        alert.showEdit("Derivative", subTitle:"The derivative of the function at a value.")
    }
    
    @IBAction func NINT(sender: UIButton) {
        let alert = SCLAlertView()
        let aValue = alert.addTextField(title:"x value")
        let bValue = alert.addTextField(title:"x value")
        aValue.keyboardType = UIKeyboardType.NumbersAndPunctuation
        bValue.keyboardType = UIKeyboardType.NumbersAndPunctuation
        alert.addButton("Numerical Integral") {
            if let aGiven = (aValue.text as NSString).doubleValue as Double? {
                if let bGiven = (bValue.text as NSString).doubleValue as Double? {
                    if let answer = self.delegate?.evaluateIntegral(aGiven, atB: bGiven) {
                        SCLAlertView().showNotice("Integral", subTitle: "The ∫ on the interval [ \(aGiven), \(bGiven) ] is \(answer).")
                    } else {
                        SCLAlertView().showError("Integral", subTitle: "The ∫ does not exist on the interval [ \(aGiven), \(bGiven) ]")
                    }
                } else {
                    SCLAlertView().showWarning("Integral", subTitle: "The given interval extends outside of the domain of the function.")
                }
            } else {
                SCLAlertView().showWarning("Integral", subTitle: "The given interval extends outside of the domain of the function.")
            }
        }
        alert.showEdit("Integral", subTitle:"The ∫ on the interval [a,b]")
    }
    
    
    @IBAction func modeSwitch(sender: UIButton) {
        if sender.currentTitle == "Deg" {
            sender.setTitle("Rad", forState: UIControlState.Normal)
            defaults.setObject("Rad", forKey: "mode")
            defaults.synchronize()
        } else if sender.currentTitle == "Rad" {
            sender.setTitle("Deg", forState: UIControlState.Normal)
            defaults.setObject("Deg", forKey: "mode")
            defaults.synchronize()
        }
    }
    
    @IBAction func typeSwitch(sender: UIButton) {
        if sender.currentTitle == "Normal" {
            sender.setTitle("Scientific", forState: UIControlState.Normal)
            defaults.setObject("Scientific", forKey: "type")
            defaults.synchronize()
        } else if sender.currentTitle == "Scientific" {
            sender.setTitle("Normal", forState: UIControlState.Normal)
            defaults.setObject("Normal", forKey: "type")
            defaults.synchronize()
        }
    }
    
    //RPN Functions
    
    @IBAction func operandPushInformation(sender: UIButton) {
        SCLAlertView().showInfo("RPN Operand Push", subTitle: "This", closeButtonTitle: "Okay", duration: 0.0)
    }
    
    @IBAction func dropFromTop(sender: UIButton) {
        delegate?.dropFromTop()
    }
    @IBAction func roll(sender: UIButton) {
        delegate?.roll()
    }
    @IBAction func exchange(sender: UIButton) {
        delegate?.exchange()
    }
    @IBAction func sum(sender: AnyObject) {
        delegate?.sum()
    }
    
    
}
