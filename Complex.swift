//
//  complex.swift
//  complex
//
//  Created by Dan Kogai on 6/12/14.
//  Copyright (c) 2014 Dan Kogai. All rights reserved.
//

import Foundation
// protocol RealType : FloatingPointType // sadly crashes as of Swift 1.1 :-(

public protocol RealType {
    // copied from FloatingPointType
    init(_ value: UInt8)
    init(_ value: Int8)
    init(_ value: UInt16)
    init(_ value: Int16)
    init(_ value: UInt32)
    init(_ value: Int32)
    init(_ value: UInt64)
    init(_ value: Int64)
    init(_ value: UInt)
    init(_ value: Int)
    init(_ value: Double)
    init(_ value: Float)
    // class vars are now gone
    // because they will be static vars in Swift 1.2,
    // making them incompatible to one another
    //class var infinity: Self { get }
    //class var NaN: Self { get }
    //class var quietNaN: Self { get }
    var floatingPointClass: FloatingPointClassification { get }
    var isSignMinus: Bool { get }
    var isNormal: Bool { get }
    var isFinite: Bool { get }
    var isZero: Bool { get }
    var isSubnormal: Bool { get }
    var isInfinite: Bool { get }
    var isNaN: Bool { get }
    var isSignaling: Bool { get }
    // copied from Hashable
    var hashValue: Int { get }
    // Built-in operators
    static func ==(_: Self, _: Self)->Bool
    static func !=(_: Self, _: Self)->Bool
    static func < (_: Self, _: Self)->Bool
    static func <= (_: Self, _: Self)->Bool
    static func > (_: Self, _: Self)->Bool
    static func >= (_: Self, _: Self)->Bool
    static prefix func + (_: Self)->Self
    static prefix func - (_: Self)->Self
    static func + (_: Self, _: Self)->Self
    static func - (_: Self, _: Self)->Self
    static func * (_: Self, _: Self)->Self
    static func / (_: Self, _: Self)->Self
    static func += (_: inout Self, _: Self)
    static func -= (_: inout Self, _: Self)
    static func *= (_: inout Self, _: Self)
    static func /= (_: inout Self, _: Self)
    // methodized functions for protocol's sake
    var abs:Self { get }
    func cos()->Self
    func exp()->Self
    func log()->Self
    func sin()->Self
    func sqrt()->Self
    func hypot(_: Self)->Self
    func atan2(_: Self)->Self
    func pow(_: Self)->Self
    //class var LN10:Self { get }
    //class var epsilon:Self { get }
}
// Double is default since floating-point literals are Double by default
extension Double : RealType {
    public var abs:Double { return Swift.abs(self) }
    public func cos()->Double { return Foundation.cos(self) }
    public func exp()->Double { return Foundation.exp(self) }
    public func log()->Double { return Foundation.log(self) }
    public func sin()->Double { return Foundation.sin(self) }
    public func sqrt()->Double { return Foundation.sqrt(self) }
    public func atan2(_ y:Double)->Double { return Foundation.atan2(self, y) }
    public func hypot(_ y:Double)->Double { return Foundation.hypot(self, y) }
    public func pow(_ y:Double)->Double { return Foundation.pow(self, y) }
    public var isSignMinus:Bool { return sign == .minus}
    public var isSignaling:Bool { return isSignalingNaN}
    // these ought to be static let
    // but give users a chance to overwrite it
    static var PI = 3.14159265358979323846264338327950288419716939937510
    static var π = PI
    static var E =  2.718281828459045235360287471352662497757247093699
    static var e = E
    static var LN2 =
    0.6931471805599453094172321214581765680755001343602552
    static var LOG2E = 1 / LN2
    static var LN10 =
    2.3025850929940456840179914546843642076011014886287729
    static var LOG10E = 1/LN10
    static var SQRT2 =
    1.4142135623730950488016887242096980785696718753769480
    static var SQRT1_2 = 1/SQRT2
    static var epsilon = 0x1p-52
    /// self * 1.0i
    var i:Complex<Double>{ return Complex<Double>(0.0, self) }
}
// But when explicitly typed you can use Float
extension Float : RealType {
    public var abs:Float { return Swift.abs(self) }
    public func cos()->Float { return Foundation.cos(self) }
    public func exp()->Float { return Foundation.exp(self) }
    public func log()->Float { return Foundation.log(self) }
    public func sin()->Float { return Foundation.sin(self) }
    public func sqrt()->Float { return Foundation.sqrt(self) }
    public func hypot(_ y:Float)->Float { return Foundation.hypot(self, y) }
    public func atan2(_ y:Float)->Float { return Foundation.atan2(self, y) }
    public func pow(_ y:Float)->Float { return Foundation.pow(self, y) }
    public var isSignMinus:Bool { return sign == .minus}
    public var isSignaling:Bool { return isSignalingNaN}
    // these ought to be static let
    // but give users a chance to overwrite it
    static var PI:Float = 3.14159265358979323846264338327950288419716939937510
    static var π:Float = PI
    static var E:Float =  2.718281828459045235360287471352662497757247093699
    static var e:Float = E
    static var LN2:Float =
    0.6931471805599453094172321214581765680755001343602552
    static var LOG2E:Float = 1 / LN2
    static var LN10:Float =
    2.3025850929940456840179914546843642076011014886287729
    static var LOG10E:Float = 1/LN10
    static var SQRT2:Float =
    1.4142135623730950488016887242096980785696718753769480
    static var SQRT1_2:Float = 1/SQRT2
    static var epsilon:Float = 0x1p-23
    /// self * 1.0i
    var i:Complex<Float>{ return Complex<Float>(0.0 as Float, self) }
}
// el corazon
public struct Complex<T:RealType> : Equatable, CustomStringConvertible {
    public var (re, im): (T, T)
    public init(_ re:T, _ im:T) {
        self.re = re
        self.im = im
    }
    public init(){ self.init(T(0), T(0)) }
    public init(abs:T, arg:T) {
        self.re = abs * arg.cos()
        self.im = abs * arg.sin()
    }
    /// real part thereof
    public var real:T { get{ return re } set(r){ re = r } }
    /// imaginary part thereof
    public var imag:T { get{ return im } set(i){ im = i } }
    /// absolute value thereof
    public var abs:T {
        get { return re.hypot(im) }
        set(r){ let f = r / abs; re *= f; im *= f }
    }
    /// argument thereof
    public var arg:T  {
        get { return im.atan2(re) }
        set(t){ let m = abs; re = m * t.cos(); im = m * t.sin() }
    }
    /// norm thereof
    public var norm:T { return re.hypot(im) }
    /// conjugate thereof
    public var conj:Complex { return Complex(re, -im) }
    /// projection thereof
    public var proj:Complex {
        if re.isFinite && im.isFinite {
            return self
        } else {
            return Complex(
                T(1)/T(0), im.isSignMinus ? -T(0) : T(0)
            )
        }
    }
    /// (real, imag)
    public var tuple:(T, T) {
        get { return (re, im) }
        set(t){ (re, im) = t}
    }
    /// z * i
    public var i:Complex { return Complex(-im, re) }
    /// .description -- conforms to Printable
    public var description:String {
        let plus = im.isSignMinus ? "" : "+"
        return "(\(re)\(plus)\(im).i)"
    }    
    /// .hashvalue -- conforms to Hashable
//    var hashValue:Int { // take most significant halves and join
//        let bits = sizeof(Int) * 4
//        let mask = bits == 16 ? 0xffff : 0xffffFFFF
//        return (re.hashValue & ~mask) | (im.hashValue >> bits)
//    }
}
// operator definitions
precedencegroup ExponentiationPrecedence {
    higherThan: MultiplicationPrecedence
}

infix operator ** : ExponentiationPrecedence
infix operator **= : AssignmentPrecedence
infix operator =~ : ComparisonPrecedence
infix operator !~ : ComparisonPrecedence
// != is auto-generated thanks to Equatable
public func == <T>(lhs:Complex<T>, rhs:Complex<T>) -> Bool {
    return lhs.re == rhs.re && lhs.im == rhs.im
}
public func == <T>(lhs:Complex<T>, rhs:T) -> Bool {
    return lhs.re == rhs && lhs.im == T(0)
}
public func == <T>(lhs:T, rhs:Complex<T>) -> Bool {
    return rhs.re == lhs && rhs.im == T(0)
}
public // +, +=
prefix func + <T>(z:Complex<T>) -> Complex<T> {
    return z
}
public func + <T>(lhs:Complex<T>, rhs:Complex<T>) -> Complex<T> {
    return Complex(lhs.re + rhs.re, lhs.im + rhs.im)
}
public func + <T>(lhs:Complex<T>, rhs:T) -> Complex<T> {
    return lhs + Complex(rhs, T(0))
}
public func + <T>(lhs:T, rhs:Complex<T>) -> Complex<T> {
    return Complex(lhs, T(0)) + rhs
}
public func += <T>(lhs:inout Complex<T>, rhs:Complex<T>) {
    lhs.re += rhs.re ; lhs.im += rhs.im
}
public func += <T>(lhs:inout Complex<T>, rhs:T) {
    lhs.re += rhs
}
// -, -=
public prefix func - <T>(z:Complex<T>) -> Complex<T> {
    return Complex<T>(-z.re, -z.im)
}
public func - <T>(lhs:Complex<T>, rhs:Complex<T>) -> Complex<T> {
    return Complex(lhs.re - rhs.re, lhs.im - rhs.im)
}
public func - <T>(lhs:Complex<T>, rhs:T) -> Complex<T> {
    return lhs - Complex(rhs, T(0))
}
public func - <T>(lhs:T, rhs:Complex<T>) -> Complex<T> {
    return Complex(lhs, T(0)) - rhs
}
public func -= <T>(lhs:inout Complex<T>, rhs:Complex<T>) {
    lhs.re -= rhs.re ; lhs.im -= rhs.im
}
public func -= <T>(lhs:inout Complex<T>, rhs:T) {
    lhs.re -= rhs
}
// *, *=
public func * <T>(lhs:Complex<T>, rhs:Complex<T>) -> Complex<T> {
    return Complex(
        lhs.re * rhs.re - lhs.im * rhs.im,
        lhs.re * rhs.im + lhs.im * rhs.re
    )
}
public func * <T>(lhs:Complex<T>, rhs:T) -> Complex<T> {
    return Complex(lhs.re * rhs, lhs.im * rhs)
}
public func * <T>(lhs:T, rhs:Complex<T>) -> Complex<T> {
    return Complex(lhs * rhs.re, lhs * rhs.im)
}
public func *= <T>(lhs:inout Complex<T>, rhs:Complex<T>) {
    lhs = lhs * rhs
}
public func *= <T>(lhs:inout Complex<T>, rhs:T) {
    lhs = lhs * rhs
}
// /, /=
//
// cf. https://github.com/dankogai/swift-complex/issues/3
//
public func / <T>(lhs:Complex<T>, rhs:Complex<T>) -> Complex<T> {
    if rhs.re.abs >= rhs.im.abs {
        let r = rhs.im / rhs.re
        let d = rhs.re + rhs.im * r
        return Complex (
            (lhs.re + lhs.im * r) / d,
            (lhs.im - lhs.re * r) / d
        )
    } else {
        let r = rhs.re / rhs.im
        let d = rhs.re * r + rhs.im
        return Complex (
            (lhs.re * r + lhs.im) / d,
            (lhs.im * r - lhs.re) / d
        )
        
    }
}
public func / <T>(lhs:Complex<T>, rhs:T) -> Complex<T> {
    return Complex(lhs.re / rhs, lhs.im / rhs)
}
public func / <T>(lhs:T, rhs:Complex<T>) -> Complex<T> {
    return Complex(lhs, T(0)) / rhs
}
public func /= <T>(lhs:inout Complex<T>, rhs:Complex<T>) {
    lhs = lhs / rhs
}
public func /= <T>(lhs:inout Complex<T>, rhs:T) {
    lhs = lhs / rhs
}
// exp(z)
public func exp<T>(_ z:Complex<T>) -> Complex<T> {
    let abs = z.re.exp()
    let arg = z.im
    return Complex(abs * arg.cos(), abs * arg.sin())
}
// log(z)
public func log<T>(_ z:Complex<T>) -> Complex<T> {
    return Complex(z.abs.log(), z.arg)
}
// log10(z) -- just because C++ has it
public func log10<T>(_ z:Complex<T>) -> Complex<T> { return log(z) / T(log(10.0)) }
public func log10<T:RealType>(_ r:T) -> T { return r.log() / T(log(10.0)) }
// pow(b, x)
public func pow<T>(_ lhs:Complex<T>, rhs:Complex<T>) -> Complex<T> {
    if lhs == T(0) { return Complex(T(1), T(0)) } // 0 ** 0 == 1
    let z = log(lhs) * rhs
    return exp(z)
}
public func pow<T>(_ lhs:Complex<T>, rhs:T) -> Complex<T> {
    return pow(lhs, rhs: Complex(rhs, T(0)))
}
public func pow<T>(_ lhs:T, rhs:Complex<T>) -> Complex<T> {
    return pow(Complex(lhs, T(0)), rhs: rhs)
}
// **, **=
public func **<T:RealType>(lhs:T, rhs:T) -> T {
    return lhs.pow(rhs)
}
public func ** <T>(lhs:Complex<T>, rhs:Complex<T>) -> Complex<T> {
    return pow(lhs, rhs: rhs)
}
public func ** <T>(lhs:T, rhs:Complex<T>) -> Complex<T> {
    return pow(lhs, rhs: rhs)
}
public func ** <T>(lhs:Complex<T>, rhs:T) -> Complex<T> {
    return pow(lhs, rhs: rhs)
}
public func **= <T:RealType>(lhs:inout T, rhs:T) {
    lhs = lhs.pow(rhs)
}
public func **= <T>(lhs:inout Complex<T>, rhs:Complex<T>) {
    lhs = pow(lhs, rhs: rhs)
}
public func **= <T>(lhs:inout Complex<T>, rhs:T) {
    lhs = pow(lhs, rhs: rhs)
}
// sqrt(z)
public func sqrt<T>(_ z:Complex<T>) -> Complex<T> {
    // return z ** 0.5
    let d = z.re.hypot(z.im)
    let re = ((z.re + d)/T(2)).sqrt()
    if z.im < T(0) {
        return Complex(re, -((-z.re + d)/T(2)).sqrt())
    } else {
        return Complex(re,  ((-z.re + d)/T(2)).sqrt())
    }
}
// cos(z)
public func cos<T>(_ z:Complex<T>) -> Complex<T> {
    // return (exp(i*z) + exp(-i*z)) / 2
    return (exp(z.i) + exp(-z.i)) / T(2)
}
// sin(z)
public func sin<T>(_ z:Complex<T>) -> Complex<T> {
    // return (exp(i*z) - exp(-i*z)) / (2*i)
    return -(exp(z.i) - exp(-z.i)).i / T(2)
}
// tan(z)
public func tan<T>(_ z:Complex<T>) -> Complex<T> {
    // return sin(z) / cos(z)
    let ezi = exp(z.i), e_zi = exp(-z.i)
    return (ezi - e_zi) / (ezi + e_zi).i
}
// atan(z)
public func atan<T>(_ z:Complex<T>) -> Complex<T> {
    let l0 = log(T(1) - z.i), l1 = log(T(1) + z.i)
    return (l0 - l1).i / T(2)
}
public func atan<T:RealType>(_ r:T) -> T { return atan(Complex(r, T(0))).re }
// atan2(z, zz)
public func atan2<T>(_ z:Complex<T>, zz:Complex<T>) -> Complex<T> {
    return atan(z / zz)
}
// asin(z)
public func asin<T>(_ z:Complex<T>) -> Complex<T> {
    return -log(z.i + sqrt(T(1) - z*z)).i
}
// acos(z)
public func acos<T>(_ z:Complex<T>) -> Complex<T> {
    return log(z - sqrt(T(1) - z*z).i).i
}
// sinh(z)
public func sinh<T>(_ z:Complex<T>) -> Complex<T> {
    return (exp(z) - exp(-z)) / T(2)
}
// cosh(z)
public func cosh<T>(_ z:Complex<T>) -> Complex<T> {
    return (exp(z) + exp(-z)) / T(2)
}
// tanh(z)
public func tanh<T>(_ z:Complex<T>) -> Complex<T> {
    let ez = exp(z), e_z = exp(-z)
    return (ez - e_z) / (ez + e_z)
}
// asinh(z)
public func asinh<T>(_ z:Complex<T>) -> Complex<T> {
    return log(z + sqrt(z*z + T(1)))
}
// acosh(z)
public func acosh<T>(_ z:Complex<T>) -> Complex<T> {
    return log(z + sqrt(z*z - T(1)))
}
// atanh(z)
public func atanh<T>(_ z:Complex<T>) -> Complex<T> {
    let t: Complex<T> = log((T(1) + z)/(T(1) - z))
    return t / T(2)
}
// for the compatibility's sake w/ C++11
public func abs<T>(_ z:Complex<T>) -> T { return z.abs }
public func arg<T>(_ z:Complex<T>) -> T { return z.arg }
public func real<T>(_ z:Complex<T>) -> T { return z.real }
public func imag<T>(_ z:Complex<T>) -> T { return z.imag }
public func norm<T>(_ z:Complex<T>) -> T { return z.norm }
public func conj<T>(_ z:Complex<T>) -> Complex<T> { return z.conj }
public func proj<T>(_ z:Complex<T>) -> Complex<T> { return z.proj }
//
// approximate comparisons
//
public func =~ <T:RealType>(lhs:T, rhs:T) -> Bool {
    if lhs == rhs { return true }
    let t = (rhs - lhs) / rhs
    let epsilon = MemoryLayout<T>.size < 8 ? 0x1p-23 : 0x1p-52
    return t.abs <= T(2) * T(epsilon)
}
public func =~ <T>(lhs:Complex<T>, rhs:Complex<T>) -> Bool {
    if lhs == rhs { return true }
    return lhs.abs =~ rhs.abs
}
public func =~ <T>(lhs:Complex<T>, rhs:T) -> Bool {
    return lhs.abs =~ rhs.abs
}
public func =~ <T>(lhs:T, rhs:Complex<T>) -> Bool {
    return lhs.abs =~ rhs.abs
}
public func !~ <T:RealType>(lhs:T, rhs:T) -> Bool {
    return !(lhs =~ rhs)
}
public func !~ <T>(lhs:Complex<T>, rhs:Complex<T>) -> Bool {
    return !(lhs =~ rhs)
}
public func !~ <T>(lhs:Complex<T>, rhs:T) -> Bool {
    return !(lhs =~ rhs)
}
public func !~ <T>(lhs:T, rhs:Complex<T>) -> Bool {
    return !(lhs =~ rhs)
}
// typealiases
public typealias Complex64 = Complex<Double>
public typealias Complex32 = Complex<Float>
