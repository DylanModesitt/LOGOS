//
//  Model.swift
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

// This was my first real use of MVC

import Foundation
import AudioToolbox

// Allow for exponential operations
infix operator ^^ { }
func ^^ (radix: Double, power: Double) -> Double {
    return Double(pow(Double(radix), Double(power)))
}

class Model : Printable {
    
    // check what mode the calculator is in: Scientific or Normal
    var type: String? = NSUserDefaults.standardUserDefaults().objectForKey("type") as! String?
    
    // Error strings
    struct Errors {
        static let UndefinedVar = "This variable represents all real numbers"
        static let MissingOp = "Operands are missing for this operation"
        static let DivideZero = "Impossible to evaluate the current expression"
        static let Imaginary = "Number is not real"
        static let Other = "Impossible to evaluate the current expression"
        static let Infinity = "The approximation of this number is growing too large for calculation."
        }
    
    //Older version of LOGOS allowed users to long press for description of operation
    private var OperandDescription =
    
    [
        "X":"This recalls the stored variable X, if a value has been stored using →X", "→X":"Store what is on the display and recall it by using X in your calculations", "sinh": "returns the hyperbolic sine of the elements of x", "cosh": "returns the hyperbolic cosine of the elements of x", "tanh": "returns the hyperbolic tangent of the element of x", "sinh°": "returns the hyperbolic sine of the elements of x", "cosh°": "returns the hyperbolic cosine of the elements of x", "tanh°": "returns the hyperbolic tangent of the element of x", "ln": "The log of base e (i.e. ln(2) is e^x is 2). It is also known as the natural log.", "logb(a)": "this is the log of that has a base of any value.(i.e. log(4)(2) is 4^? is 2).", "!": "The factorial of a natural number x is the product of all positive integers less than and equal to x", " nCr ": "The number of different, unordered combinations of r objects from a set of n objects. Definition: nCr(n,r) = nPr(n,r) / r!", " nPr ": "The number of possibilities for choosing an ordered set of r objects (a permutation) from a total of nobjects. Definition: nPr(n,r) = n! / (n-r)!", "Σ": "returns the sum of all numbers in the operand RPNStack", "rad": "Switches the trigonometric functions back and forth from radians to degrees.","deg": "Switches the trigonometric functions back and forth from radians to degrees.", "asin": "returns the angle measurement based on the ratio of its sine","acos":"returns the angle measurement based on the ratio of its cosine", "atan": "returns the angle measurement based on the ratio of its tangent","asin°": "returns the angle measurement based on the ratio of its sine","acos°":"returns the angle measurement based on the ratio of its cosine", "atan°": "returns the angle measurement based on the ratio of its tangent",
    ]

    // Result either a Double or Error string
    enum Result : Printable {
        case Value(Double)
        case Error(String)

        var description : String {
            switch self {
            case .Value(let val):
                // Adding support for scientific notation
                var solution: String?
                let numberFormatter = NSNumberFormatter()
                numberFormatter.numberStyle = NSNumberFormatterStyle.ScientificStyle
                // style used by large numbers
                numberFormatter.positiveFormat = "0.###E+0"
                numberFormatter.exponentSymbol = "e"
                if Model().type == "Scientific" {
                    if let stringFromNumber = numberFormatter.stringFromNumber(val){
                        solution = stringFromNumber
                    } else {
                        solution = String(stringInterpolationSegment: val)
                    }
                } else {
                    solution = String(stringInterpolationSegment: val)
                }
                
                return solution!
                
            case .Error(let err):
                if "\(err)" != Errors.UndefinedVar {
                    // vibration on error, unless it is undefined variable because that is just a notice
                    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                }
                return "\(err)"
            }
        }
        var value : Double? {
            switch self {
            case .Value(let val):
                return val
                
            case .Error(let err):
                return nil
            }
        }
        var error : String? {
            switch self {
            case .Value(let val):
                return nil
            case .Error(let err):
                return err
            }
        }
        var doubleValue : Double {
            switch self {
            case .Value(let val):
                return val
            case .Error(let err):
                return Double.NaN
            }
        }
    }
    
    // Op: the axiom of LOGOS
    private enum Op : Printable {
        case Operand(Double)
        case Variable(String)
        case Constant(sym:String, val:Double)
        case UnaryOperation(sym:String, f:(Double) -> Result)
        case BinaryOperation(sym:String, precedence:Int, f:(Double, Double) -> Result)
        
        var description : String {
            switch self {
            case .Operand(let val): return "\(val)"
            case .Constant(let symbol, _): return symbol
            case .Variable(let symbol): return symbol
            case .UnaryOperation(let op): return op.sym
            case .BinaryOperation(let op): return op.sym
            }
        }
    }
    
    private var opStack = [Op]()
    private var knownOps = [String : Op]()
    private var variableValues  = [String : Double]()
    private let debug = false
    
    /* This factorial function is used in !, nCr, and nPr
    In order to utilize the error checking in the evaluate function, if n is <0
    0 / 0 is returned. This is indeterminable, and thus an error message gets sent
    to the user. The factorial function cannot calculate beyond 170!, so that returns an
    error to prevent Stack Overflow. Recursive helper. */
    
    func factorial(n: Double) -> Double {
        if n >= 170 {
            return 0 / 0
        } else if n >= 0 {
            return n == 0 ? 1 : n * self.factorial(n - 1)
        } else if n < 0 {
            return 0 / 0
        } else {
            return 0 / 0
        }
    }

    // initialize thek nown operands
    init ()
    {
        func learn(op : Op) {
            knownOps[op.description] = op
        }
        
        // Constants
        learn(.Constant(sym:"π", val:M_PI))
        learn(.Constant(sym:"e", val:M_E))
        learn(.Constant(sym:"√2", val:sqrt(2.0)))
        learn(.Constant(sym:"ɸ", val:1.6180339887))
        learn(.Constant(sym:"M", val: 0.261497212))
        learn(.Constant(sym:"Γ", val:0.5772156649))
        learn(.Constant(sym:"K", val:1.13198824))
        learn(.Constant(sym:"ζ(3)", val:1.202056903))
        
        learn(.Constant(sym:"N", val:6.022 * (10^^23)))
        learn(.Constant(sym:"amu", val:1.66 * (10^^(-27))))
        learn(.Constant(sym:"a0", val: 0.529 * (10 ^^ (-10))))
        learn(.Constant(sym:"C", val: 2.99 * (10 ^^ 8)))
        learn(.Constant(sym:"F", val: 9.649 * (10 ^^ 4)))
        learn(.Constant(sym:"R", val:8.3144621))
        learn(.Constant(sym:"G", val:6.67 * (10^^(-11))))
        learn(.Constant(sym:"h", val:6.626 * (10^^(-34))))
        
        learn(.Constant(sym:"g", val:9.80665))
        learn(.Constant(sym:"k", val:1.13198824))
        learn(.Constant(sym:"σ", val:5.670373 * (10 ^^ (-8))))
        
        learn(.Constant(sym:"rand", val: Double.random(min: 0.0, max: 1.0)))

 
        // Binary Ops
        learn(.BinaryOperation(sym:"+", precedence:1, f:{.Value($0 + $1)}))
        learn(.BinaryOperation(sym:"−", precedence:1, f:{.Value($0 - $1)}))
        learn(.BinaryOperation(sym:"×", precedence:2, f:{.Value($0 * $1)}))
        learn(.BinaryOperation(sym:"÷", precedence:2, f:{$1.isZero ? .Error(Errors.DivideZero) : .Value($0 / $1)}))
        learn(.BinaryOperation(sym:"^", precedence:4, f:{.Value($0 ^^ $1)}))
        learn(.BinaryOperation(sym:"logb(a)", precedence:4, f:{.Value(log10($1) / log10($0))}))
        learn(.BinaryOperation(sym:"EEX", precedence:2, f:{.Value($0 * (10 ^^ $1))}))
        learn(.BinaryOperation(sym:" nCr ", precedence:1, f:{$0 <= $1 ? .Error(Errors.Other) : .Value(self.factorial($0) / ( self.factorial($1) * self.factorial($0 - $1)))}))
        learn(.BinaryOperation(sym:" nPr ", precedence:2, f:{$0 <= $1 ? .Error(Errors.Other) : .Value(self.factorial($0) / (self.factorial($0 - $1)))}))
        
        // Unary Ops
        learn(.UnaryOperation(sym:"±", f:{.Value($0 * -1)}))
        learn(.UnaryOperation(sym:"√", f:{$0 < 0 ? .Error(Errors.Imaginary) : .Value(sqrt($0))}))
        learn(.UnaryOperation(sym:"ln", f:{.Value(log($0))}))
        learn(.UnaryOperation(sym:"log2", f:{.Value(log2($0))}))
        learn(.UnaryOperation(sym:"log10", f:{.Value(log10($0))}))
        learn(.UnaryOperation(sym:"!", f:{$0 > 170 ? .Error(Errors.Infinity) : .Value(self.factorial($0))}))
        learn(.UnaryOperation(sym:"^2", f:{.Value($0 ^^ 2)}))
        learn(.UnaryOperation(sym:"^3", f:{.Value($0 ^^ 3)}))
        learn(.UnaryOperation(sym:"%", f:{.Value($0 * 0.01)}))
        learn(.UnaryOperation(sym:"1/x", f:{.Value(1 / $0)}))
        learn(.UnaryOperation(sym:"abs", f:{.Value(abs($0))}))
        
        // Unary Ops: Trigonometric (Radians)
        learn(.UnaryOperation(sym:"sin", f:{.Value(sin($0))}))
        learn(.UnaryOperation(sym:"cos", f:{.Value(cos($0))}))
        learn(.UnaryOperation(sym:"tan", f:{.Value(tan($0))}))
        
        learn(.UnaryOperation(sym:"csc", f:{.Value(1 / sin($0))}))
        learn(.UnaryOperation(sym:"sec", f:{.Value(1 / cos($0))}))
        learn(.UnaryOperation(sym:"cot", f:{.Value(1 / tan($0))}))
        
        learn(.UnaryOperation(sym:"sinh", f:{.Value(sinh($0))}))
        learn(.UnaryOperation(sym:"cosh", f:{.Value(cosh($0))}))
        learn(.UnaryOperation(sym:"tanh", f:{.Value(tanh($0))}))
        
        learn(.UnaryOperation(sym:"csch", f:{.Value(1 / sinh($0))}))
        learn(.UnaryOperation(sym:"sech", f:{.Value(1 / cosh($0))}))
        learn(.UnaryOperation(sym:"coth", f:{.Value(1 / tanh($0))}))
        
        learn(.UnaryOperation(sym:"asin", f:{.Value(asin($0))}))
        learn(.UnaryOperation(sym:"acos", f:{.Value(acos($0))}))
        learn(.UnaryOperation(sym:"atan", f:{.Value(atan($0))}))
        
        learn(.UnaryOperation(sym:"acsc", f:{.Value(1 / asin($0))}))
        learn(.UnaryOperation(sym:"asec", f:{.Value(1 / acos($0))}))
        learn(.UnaryOperation(sym:"acot", f:{.Value(1 / atan($0))}))
        
        learn(.UnaryOperation(sym:"acsch", f:{.Value(1 / asinh($0))}))
        learn(.UnaryOperation(sym:"asech", f:{.Value(1 / acosh($0))}))
        learn(.UnaryOperation(sym:"acoth", f:{.Value(1 / atanh($0))}))
        
        learn(.UnaryOperation(sym:"asinh", f:{.Value(asinh($0))}))
        learn(.UnaryOperation(sym:"acosh", f:{.Value(acosh($0))}))
        learn(.UnaryOperation(sym:"atanh", f:{.Value(atanh($0))}))
        
        // Unary Ops: Trigonometric (Degrees)
        learn(.UnaryOperation(sym:"sin°", f:{.Value(sin($0 * (M_PI/180)))}))
        learn(.UnaryOperation(sym:"cos°", f:{.Value(cos($0 * (M_PI/180)))}))
        learn(.UnaryOperation(sym:"tan°", f:{.Value(tan($0 * (M_PI/180)))}))
        
        learn(.UnaryOperation(sym:"csc°", f:{.Value(1 / sin($0 * (M_PI/180)))}))
        learn(.UnaryOperation(sym:"sec°", f:{.Value(1 / cos($0 * (M_PI/180)))}))
        learn(.UnaryOperation(sym:"cot°", f:{.Value(1 / tan($0 * (M_PI/180)))}))
        
        learn(.UnaryOperation(sym:"sinh°", f:{.Value(sinh($0 * (M_PI/180)))}))
        learn(.UnaryOperation(sym:"cosh°", f:{.Value(cosh($0 * (M_PI/180)))}))
        learn(.UnaryOperation(sym:"tanh°", f:{.Value(tanh($0 * (M_PI/180)))}))
        
        learn(.UnaryOperation(sym:"csch°", f:{.Value(1 / (sinh($0 * (M_PI/180))))}))
        learn(.UnaryOperation(sym:"sech°", f:{.Value(1 / (cosh($0 * (M_PI/180))))}))
        learn(.UnaryOperation(sym:"coth°", f:{.Value(1 / (tanh($0 * (M_PI/180))))}))
        
        learn(.UnaryOperation(sym:"asin°", f:{.Value((180/M_PI) * asin($0))}))
        learn(.UnaryOperation(sym:"acos°", f:{.Value((180/M_PI) * acos($0))}))
        learn(.UnaryOperation(sym:"atan°", f:{.Value((180/M_PI) * atan($0))}))
        
        learn(.UnaryOperation(sym:"acsc°", f:{.Value((180/M_PI) * ( 1 / asin($0)))}))
        learn(.UnaryOperation(sym:"asec°", f:{.Value((180/M_PI) * (1 / acos($0)))}))
        learn(.UnaryOperation(sym:"acot°", f:{.Value((180/M_PI) * (1 / atan($0)))}))
        
        learn(.UnaryOperation(sym:"asinh°", f:{.Value((180/M_PI) * asinh($0))}))
        learn(.UnaryOperation(sym:"acosh°", f:{.Value((180/M_PI) * acosh($0))}))
        learn(.UnaryOperation(sym:"atanh°", f:{.Value((180/M_PI) * atanh($0))}))
        
        learn(.UnaryOperation(sym:"acsch°", f:{.Value((180/M_PI) * ( 1 / asinh($0)))}))
        learn(.UnaryOperation(sym:"asech°", f:{.Value((180/M_PI) * (1 / acosh($0)))}))
        learn(.UnaryOperation(sym:"acoth°", f:{.Value((180/M_PI) * (1 / atanh($0)))}))
        
        
    }
    
    /// get/set the currect state as a PropertyList. This was to learn about property lists in CS193, and is used in GraphViewController
    var program : AnyObject {
        get {
            return [
                "RPNStack": opStack.map {$0.description},
                "vars": variableValues
            ]
        }
        set {
            if let dict = newValue as? [String:AnyObject] {
                if let strings = dict["RPNStack"] as? [String] {
                    opStack = strings.map {
                        if let op = self.knownOps[$0] {
                            return op
                        } else if let val = NSNumberFormatter().numberFromString($0)?.doubleValue {
                            return .Operand(val)
                        } else {
                            return .Variable($0)
                        }
                    }
                }
                if let vars = dict["vars"] as? [String:Double] {
                    variableValues = vars
                }
            }
        }
    }
    
    
    func setVariable(key:String, _ value:Double) {
        variableValues[key] = value
    }
    func getVariable(key:String) -> Double? {
        return variableValues[key]
    }
    func clearVariables() {
        variableValues.removeAll()
    }
    func clearStack() {
        opStack = []
    }
    func clear() {
        clearStack()
        clearVariables()
    }
    
    func undo() {
        if opStack.count > 0 {
            opStack.removeLast()
        }
    }
    
    func pushOperand(val: Double) -> Double? {
        opStack.append(Op.Operand(val))
        return evaluate()
    }
    func pushOperand(symbol: String) -> Double? {
        opStack.append(Op.Variable(symbol))
        return evaluate()
    }
    
    // Recursive helper for rolling and exchanging
    func beginningIndexForOperationEndingAt(index: Int) -> Int? {
        if index < 0 || index >= opStack.count {
            return nil
        }
        switch opStack[index] {
        case .UnaryOperation:
            return beginningIndexForOperationEndingAt(index-1)
        case .BinaryOperation:
            if let firstOp = beginningIndexForOperationEndingAt(index-1) {
                return beginningIndexForOperationEndingAt(firstOp-1)
            }
            return nil
        default:
            return index
        }
    }
    
    // Roll the opStack like you are Carly Fiorina
    func rollOpStack() {
        if let index = beginningIndexForOperationEndingAt(opStack.count-1) {
            var newArray: ArraySlice<Op> = opStack[index..<opStack.count]
            newArray += opStack[0..<index]
            var newArrayArrayed: [Op] = Array(newArray)
            opStack = newArrayArrayed
        } else {
            //No complete operation...
        }
    }
    
    // Exchange the opStack, again, like you are Carly Fiorina...
    func exchangeOpStack() {
        println("allowed")
        if let index = beginningIndexForOperationEndingAt(opStack.count-1) {
            println(index)
            println("allowed1")
                if let indexTwo = beginningIndexForOperationEndingAt(index-1) {
                    println(indexTwo)
                    println("allowed2")
                    var newArray: ArraySlice<Op> = opStack[0..<indexTwo]
                    var newTwoArray: ArraySlice<Op> = opStack[indexTwo..<index]
                    var newOneArray: ArraySlice<Op> = opStack[index..<opStack.count]
                    println(newArray)
                    println(newTwoArray)
                    println(newOneArray)
                    newArray +=  newOneArray
                    newArray += newTwoArray
                    println(opStack)
                    var newArrayArrayed: [Op] = Array(newArray)
                    println(newArrayArrayed)
                    opStack = newArrayArrayed
                }
            } else {
            //No complete operation...
        }
    }
    
    
    // It is like undo, but from the top
    func dropFromTop() {
        if opStack.count > 0 {
            opStack.removeAtIndex(0)
        }
    }
    
    func pushOperation(symbol: String) -> Double?
    {
        if let op = knownOps[symbol] {
            opStack.append(op)
        }
        return evaluate()
    }
    
    func getOperandDescription(Operand: String) -> String {
        return OperandDescription[Operand]!
    }
    
    // recursive assistant for evaluateResult function
    private func evaluate(RPNStack:[Op]) -> (result:Result, RPNStack:[Op])
    {
        if RPNStack.count > 0 {
            var RPNStack = RPNStack
            var op = RPNStack.removeLast()
            switch op {
            case .Operand(let val):
                return (.Value(val), RPNStack)
            case .Variable(let symbol):
                if let value = variableValues[symbol] {
                    return (.Value(value), RPNStack)
                } else {
                    return (.Error(Errors.UndefinedVar), RPNStack)
                }
            case .Constant(_, let val):
                return (.Value(val), RPNStack)
            case .UnaryOperation(let op):
                var rhs = evaluate(RPNStack)
                if let val = rhs.result.value {
                    rhs.result = op.f(val)
                }
                return (rhs.result, rhs.RPNStack)
            case .BinaryOperation(let op):
                let rhs = evaluate(RPNStack)
                var lhs = evaluate(rhs.RPNStack)
                if let rhv = rhs.result.value {
                    if let lhv = lhs.result.value {
                        lhs.result = op.f(lhv, rhv)
                    }
                }
                else {
                    lhs.result = rhs.result
                }
                return (lhs.result, lhs.RPNStack)
            }
        }
        return (.Error(Errors.MissingOp), RPNStack)
    }
    

    /// evaluate the current RPNStack as a Result
    func evaluateResult() -> Result
    {
        if debug {
            let eval = evaluate(opStack)
        }
        
        return evaluate(opStack).result
    }
    
    /// evaluate the result of the current RPNStack as a Double
    func evaluate() -> Double?
    {
        return evaluateResult().value
    }
    
    // recursive helper for the description
    // returns description of RPNStack as a string, plus the remaining un-evalulated RPNStack
    private func getDescription(RPNStack:[Op]) -> (result:String, RPNStack:[Op], precedence:Int)
    {
        if RPNStack.count > 0 {
            var RPNStack = RPNStack
            var op = RPNStack.removeLast()
            switch op {
            case .Operand(let val):
                let str = String(format:"%g", val)
                return (str , RPNStack, Int.max)
            case .Variable(let symbol):
                return (symbol, RPNStack, Int.max)
            case .Constant(let op):
                return (op.sym, RPNStack, Int.max)
            case .UnaryOperation(let op):
                var rhs = getDescription(RPNStack)
                if count(op.sym) > 1 || rhs.precedence < Int.max {
                    rhs.result = "(" + rhs.result + ")"
                }
                return (op.sym+rhs.result, rhs.RPNStack, Int.max)
            case .BinaryOperation(var symbol, let precedence, _):
                var rhs = getDescription(RPNStack)
                var lhs = getDescription(rhs.RPNStack)
                if lhs.precedence < precedence {
                    lhs.result = "(" + lhs.result + ")"
                }
                if rhs.precedence < precedence {
                    rhs.result = "(" + rhs.result + ")"
                }
                return (lhs.result+symbol+rhs.result, lhs.RPNStack, precedence)
            }
        }
        return ("?", RPNStack, Int.max)
    }
    
    /// render the current stack as a string using infix
    /// if multiple expressions are on the stack all expressions are rendered separated by commas
    var fullDescription : String {
        if (opStack.isEmpty) {return ""}
        var description = getDescription(opStack)
        while description.RPNStack.count > 0 {
            let str = description.result
            description = getDescription(description.RPNStack)
            description.result += ", " + str
        }
        return description.result
    }
    /// render the current `stack` as a string using notation
    var description : String {
        if (opStack.isEmpty) {return ""}
        return getDescription(opStack).result
    }
}
// get last member in an array
extension Array {
    var last: T {
        return self[self.endIndex - 1]
    }
}
// Generate random number for different types
public extension Int {
    public static func random(n: Int) -> Int {
        return Int(arc4random_uniform(UInt32(n)))
    }
    public static func random(#min: Int, max: Int) -> Int {
        return Int(arc4random_uniform(UInt32(max - min + 1))) + min
    }
}
public extension Double {
    public static func random() -> Double {
        return Double(arc4random()) / 0xFFFFFFFF
    }
    
    public static func random(#min: Double, max: Double) -> Double {
        return Double.random() * (max - min) + min
    }
}
public extension Float {
    public static func random() -> Float {
        return Float(arc4random()) / 0xFFFFFFFF
    }
    public static func random(#min: Float, max: Float) -> Float {
        return Float.random() * (max - min) + min
    }
}



