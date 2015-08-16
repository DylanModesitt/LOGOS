//
//  CalculatorViewController.swift
//  LOGOS
//
//  Created by Dylan Modesitt on 4/23/15.
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
import AudioToolbox

// Delegation handled by Drawers 
class CalculatorViewController: UIViewController, ExtensionViewControllerDelegate {
    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var status: UILabel!
    
    private var enteringNumber = false
    private var brain = Model()
    private let memoryName = "X"  // variable name used for Memory
    private let errorColor = UIColor.redColor()
    private var normalColor = UIColor.blackColor()
    
    @IBOutlet weak var plus: UIButton!

    @IBOutlet var CalculatorView: UIView!
    
    let defaults = NSUserDefaults.standardUserDefaults()
    
    // Gestures for quick use
    @IBAction func swipeRight(sender: UISwipeGestureRecognizer) {
        enter()
    }
    
    @IBAction func swipeLeft(sender: UISwipeGestureRecognizer) {
        undo()
    }
    
    // Model chaining for the extention
    lazy var function: ((Double) -> Double?)? = {
        self.brain.setVariable(self.memoryName, $0)
        return self.brain.evaluate()
    }
    
    func evaluateGraph(atX: Double) -> Double? {
        return function?(atX)
    }
    
    func evaluateDerivative(atPoint:Double) -> Double? {
        let h = 0.0000001
    
        var solution: Double?
        
        if let xValue = evaluateGraph(atPoint) as Double? {
            if let answer = ((evaluateGraph(atPoint + h)! - evaluateGraph(atPoint)! ) / h) as Double? {
                solution = answer
            } else {
                solution = nil
            }
        } else {
            solution = nil
        }
        
        return solution
    }
    
    func evaluateLimit(atPoint:Double, side: String) -> Double? {
        let h = 0.0000001
        
        var solution: Double?
        
        var leftSide = evaluateGraph(atPoint - h)
        var rightSide = evaluateGraph(atPoint + h)
        
        if abs(rightSide! - leftSide!) > 1 {
            solution = nil
        } else {
            if side == "left" {
                solution = leftSide
            } else if side == "right" {
                solution = rightSide
            } else {
                solution = ((rightSide! + leftSide!) / 2 )
            }
        }
        return solution
    }
    
    func evaluateIntegral(atA:Double, atB:Double) -> Double? {
        var solution: Double?
        if let aValue = evaluateGraph(atA) {
            if let bValue = evaluateGraph(atB) {
                let totalInterval = atB - atA
                var answer = 0.0
                var changInX = 1.0 / 100.0
                var howMany = totalInterval * 100
                var currentPoint = atA
                var index: Double
                for index = 0.0; index < howMany; ++index {
                    answer = answer + evaluateGraph(currentPoint)! + evaluateGraph(currentPoint + changInX)!
                    currentPoint = currentPoint + changInX
                }
                solution = answer * changInX / 2
            } else {
                solution = nil
            }
        } else {
            solution = nil
        }
        return solution
    }
    
    
    @IBAction func appendDecimal(sender: UIButton) {
        if (!enteringNumber || display.text!.rangeOfString(".") == nil) {
            appendDigit(sender)
        }
    }
    
    @IBAction func appendDigit(sender: UIButton) {
        if let digit = sender.currentTitle {
            
            if enteringNumber {
                display.text = display.text! + digit
            }
            else {
                display.text = digit
                enteringNumber = true
            }
            update()
        }
    }
    
    @IBAction func clear()
    {
        brain.clear()
        enteringNumber = false
        update()
    }
    
    @IBAction func undo() {
        UIModel().makeTutorialAlert("Undo", alertDescription: "Swipe across the calculator from right to left to quickly undo.")
        if enteringNumber {
            var num = display.text!
            removeLast(&num)
            display.text = count(num) > 0 ? num : "0"
        } else {
            brain.undo()
        }
        update()
    }
    
    @IBAction func useMemory() {
        UIModel().makeTutorialAlert("Memory", alertDescription: "You can set 'X' to be the value of any number, or use it to represent all real numbers.")
        if enteringNumber {
            enter()
        }
        brain.pushOperand(memoryName)
        update()
    }

    @IBAction func setMemory() {
        if let x = displayValue {
            brain.setVariable(memoryName, x)
            enteringNumber = false
            update()
        }
    }

    @IBAction func changeSign(sender: UIButton) {
        if enteringNumber {
            display.text = "\(-(displayValue ?? 0))"
        } else {
            operate(sender)
        }

    }
    
    // send title to model to be evaluated based on string value
    @IBAction func operate(sender: UIButton) {
        if let operation = sender.currentTitle {
            if enteringNumber {
                enter()
            }
            brain.pushOperation(operation)
            update()
        }
     }
    
    @IBAction func enter()
    {
        UIModel().makeTutorialAlert("Enter", alertDescription: "Swipe across the calculator from left to right to quickly enter.")
        enteringNumber = false
        if let value = displayValue {
            brain.pushOperand(value)
            update()
        }
    }
    
    
    // RPN Stack manipulation
    func dropFromTop() {
        brain.dropFromTop()
        update()
    }
    
    func roll() {
        brain.rollOpStack()
        update()
    }
    
    func exchange() {
        brain.exchangeOpStack()
        update()
    }

    // summ all numbers left on current RPNStack
    func sum () {
        var stackTitle = status.text
        var numberOfSummableItems = Array(stackTitle!).filter{$0 == ","}.count
        var i:Int
        for i = 0; i < numberOfSummableItems; ++i{
            operate(plus)
        }
    }
    
    // update UI to match modal
    private func update()
    {
        var description = brain.fullDescription
        UIModel().makeTutorialAlert("Stack", alertDescription: "The calculator automatically keeps track of your stack, which is the list of all your current operations, and displays it in Infix notation. Seperate operations are seperated by commas until joined by an operation.")
        if enteringNumber {
            status.text = " " + description
            display.textColor = normalColor
        } else {
            if count(description) == 0 {
                status.text = " "
                display.text = "0.0"
                display.textColor = normalColor
            } else {
                status.text = description + "="
                var result = brain.evaluateResult()
                display.text = result.description
                display.textColor = result.value == nil ? errorColor : normalColor
            }
        }
    }
    
    private var displayValue: Double? {
        get {
            return NSNumberFormatter().numberFromString(display.text!)?.doubleValue
        }
    }
    @IBAction func infoRequest(sender: AnyObject) {
         let alertView = SCLAlertView()
         alertView.addButton("Tutorial") {
            let warning = SCLAlertView()
            warning.addButton("Continue") {
                self.clearTutorial()
            }
            warning.showTitle("Tutorial", subTitle: "Do you really wish to re-enable the tutorial notifications for LOGOS?", duration: 0, completeText: "Cancel", style: SCLAlertViewStyle.Warning)
         }
         alertView.addButton("More About Me") {
            let more = SCLAlertView()
        
            more.addButton("My Website", action: { () -> Void in
                var url : NSURL
                url = NSURL(string: "http://www.dylanmodesitt.com")!
                UIApplication.sharedApplication().openURL(url)

            })
            
            more.addButton("Twitter", action: { () -> Void in
                let screenName =  "DylanModesitt"
                let appURL = NSURL(string: "twitter://user?screen_name=\(screenName)")!
                let webURL = NSURL(string: "https://twitter.com/\(screenName)")!
                
                let application = UIApplication.sharedApplication()
                
                if application.canOpenURL(appURL) {
                    application.openURL(appURL)
                } else {
                    application.openURL(webURL)
                }
            })

            more.showTitle("More About Me", subTitle: "You can find more about me here.", duration: 0, completeText: "Done", style: SCLAlertViewStyle.Info)

         }
         alertView.showInfo("Information", subTitle: "This application was designed by Dylan Modesitt in Atherton, CA.")
    }
    
    @IBAction func playClick(sender: UIButton) {
        AudioServicesPlaySystemSound(1104)
        let backgroundColor = sender.backgroundColor
    }
    
    // animate on extention draw 
    
    func minimizeView(sender: AnyObject) {
        SpringAnimation.spring(0.7, animations: {
            self.view.transform = CGAffineTransformMakeScale(0.935, 0.935)
        })
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
    }
    
    func maximizeView(sender: AnyObject) {
        SpringAnimation.spring(0.7, animations: {
            self.view.transform = CGAffineTransformMakeScale(1, 1)
        })
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)
    }
    
    func clearTutorial() {
        defaults.removeObjectForKey("Enter")
        defaults.removeObjectForKey("Undo")
        defaults.removeObjectForKey("Memory")
        defaults.removeObjectForKey("Stack")
        defaults.removeObjectForKey("RPN")
        defaults.removeObjectForKey("Drawers")
        defaults.removeObjectForKey("Drawer")
        defaults.removeObjectForKey("Graph")
    }
    // MARK: ViewController Lifecycle
    
    @IBAction func graphTutorial(sender: AnyObject) {
        UIModel().makeTutorialAlert("Graph", alertDescription: "Graph the function currently displayed on the stack.")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIModel().makeTutorialAlert("RPN", alertDescription: "LOGOS is an RPN Calculator. You enter your operands, and then your operations. To add 2 and 3, press '2' then 'Enter' then '3' and finally '+' to recieve '5'. RPN Calculators are very quick, you will love it in no time.")
        
        UIModel().makeTutorialAlert("Drawers", alertDescription: "Drawers are the dark buttons on your left. They hold various mathematical functions from calculus to trigonometry that you can utilize. Play around!")
    }
    // set the graphViewFunction
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let ExtensionViewController = segue.destinationViewController as? ExtensionViewController {
            ExtensionViewController.delegate = self
        }
        if let gvc = segue.destination as? GraphViewController {
            if segue.identifier == "displayGraph" {
                var newBrain = Model()
                newBrain.program = brain.program
                gvc.title = newBrain.description
                gvc.function = {
                    newBrain.setVariable(self.memoryName, $0)
                    return newBrain.evaluate()
                }
            }
        }
    }

}

extension UIStoryboardSegue
{
    var destination : UIViewController? {
        var dvc = self.destinationViewController as? UIViewController
        if let nav = dvc as? UINavigationController {
            dvc = nav.visibleViewController
        }
        return dvc
    }
}
extension UIButton {
    func setBackgroundColor(color: UIColor, forState: UIControlState) {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(), color.CGColor)
        CGContextFillRect(UIGraphicsGetCurrentContext(), CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.setBackgroundImage(colorImage, forState: forState)
    }}
extension UIColor{
    func adjust(red: CGFloat, green: CGFloat, blue: CGFloat, alpha:CGFloat) -> UIColor{
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        var w: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: r+red, green: g+green, blue: b+blue, alpha: a+alpha)
    }
}

