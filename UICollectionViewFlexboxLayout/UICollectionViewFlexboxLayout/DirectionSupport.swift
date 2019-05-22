//
//  DirectionSupport.swift
//  UICollectionViewFlexboxLayout
//
//  Created by Jerry Wong on 2019/4/28.
//  Copyright © 2019 com.jerry. All rights reserved.
//

import UIKit

internal protocol VecCondition {
    
    func read<T>(_ input: Vec2<T>) -> T
    
    func write<T>(_ value: T, into: inout Vec2<T>)
    
}

extension UICollectionView.ScrollDirection : VecCondition {
    
    func read<T>(_ input: Vec2<T>) -> T {
        switch self {
        case .horizontal:
            return input.v0
        case .vertical:
            return input.v1
        @unknown default:
            fatalError()
        }
    }
    
    func write<T>(_ value: T, into: inout Vec2<T>) {
        switch self {
        case .horizontal:
            into.v0 = value
        case .vertical:
            into.v1 = value
        @unknown default:
            fatalError()
        }
    }
    
}

internal struct Vec2<Value> {
    
    var v0: Value
    
    var v1: Value
    
    init(_ v: Value) {
        v0 = v
        v1 = v
    }
    
    init(_ v0: Value, _ v1: Value) {
        self.v0 = v0
        self.v1 = v1
    }
    
    subscript(condition: VecCondition) -> Value {
        get {
           return condition.read(self)
        }
        set {
            condition.write(newValue, into: &self)
        }
    }
    
}

internal protocol FloatingVecConvertible {
    
    var vec: Vec2<CGFloat> { get }
    
}

extension CGFloat : FloatingVecConvertible {
    
    var vec: Vec2<CGFloat> {
        return Vec2(self)
    }
    
    var floored: CGFloat {
        return CGFloat(floorf(Float(self)))
    }
    
    var ceiled: CGFloat {
        return CGFloat(ceilf(Float(self)))
    }
    
}

extension Vec2 : FloatingVecConvertible where Value == CGFloat {
    
    var vec: Vec2<CGFloat> {
        return self
    }
    
    var floored: Vec2 {
        return Vec2(v0.floored, v1.floored)
    }
}

extension Vec2 where Value == CGFloat {
    
    static func / (lhs: Vec2, rhs: CGFloat) -> Vec2 {
        return Vec2(lhs.v0 / rhs, lhs.v1 / rhs)
    }
    
    static func * (lhs: Vec2, rhs: CGFloat) -> Vec2 {
        return Vec2(lhs.v0 * rhs, lhs.v1 * rhs)
    }
    
    static func + (lhs: Vec2, rhs: Vec2) -> Vec2 {
        return Vec2(lhs.v0 + rhs.v0, lhs.v1 + rhs.v1)
    }
    
    static func - (lhs: Vec2, rhs: Vec2) -> Vec2 {
        return Vec2(lhs.v0 - rhs.v0, lhs.v1 - rhs.v1)
    }
    
}

extension Vec2 where Value == CGRect {
    
    init(origin: Vec2<CGPoint>, size: Vec2<CGSize>) {
        self.init(CGRect(origin: origin.v0, size: size.v0), CGRect(origin: origin.v1, size: size.v1))
    }
    
}

extension Vec2 where Value == CGPoint {
    
    init(axis: FloatingVecConvertible, cross: FloatingVecConvertible) {
        self.init(CGPoint(x: cross.vec.v0, y: axis.vec.v0), CGPoint(x: axis.vec.v1, y: cross.vec.v1))
    }
    
}

extension Vec2 where Value == CGSize {
    
    init(axis: FloatingVecConvertible, cross: FloatingVecConvertible) {
        self.init(CGSize(width: cross.vec.v0, height: axis.vec.v0), CGSize(width: axis.vec.v1, height: cross.vec.v1))
    }
    
}

extension Vec2 where Value == CGAffineTransform {
    init(axis: FloatingVecConvertible, cross: FloatingVecConvertible) {
        self.init(CGAffineTransform(translationX: cross.vec.v0, y: axis.vec.v0), CGAffineTransform(translationX: axis.vec.v1, y: cross.vec.v1))
    }
}

internal extension CGPoint {
    
    var axis: Vec2<CGFloat> {
        return Vec2(y, x)
    }
    
    var cross: Vec2<CGFloat> {
        return Vec2(x, y)
    }
    
    @inline(__always) func crossMove(_ distance: FloatingVecConvertible) -> Vec2<CGPoint> {
        return Vec2(CGPoint(x: x + distance.vec.v0, y: y), CGPoint(x: x, y: y + distance.vec.v1))
    }
    
    @inline(__always) func axisChange(to dest: FloatingVecConvertible) -> Vec2<CGPoint> {
        return Vec2(CGPoint(x: x, y: dest.vec.v0), CGPoint(x: dest.vec.v1, y: y))
    }
    
    @inline(__always) func axisMove(_ distance: FloatingVecConvertible) -> Vec2<CGPoint> {
        return Vec2(CGPoint(x: x, y: y + distance.vec.v0), CGPoint(x: x + distance.vec.v1, y: y))
    }
    
}

internal extension CGRect {
    
    var axis: Vec2<CGFloat> {
        return Vec2(height, width)
    }
    
    var axisMin: Vec2<CGFloat> {
        return Vec2(minY, minX)
    }
    
    var axisMax: Vec2<CGFloat> {
        return Vec2(maxY, maxX)
    }
    
    var cross: Vec2<CGFloat> {
        return Vec2(width, height)
    }
    
    var crossMin: Vec2<CGFloat> {
        return Vec2(minX, minY)
    }
    
    var crossMax: Vec2<CGFloat> {
        return Vec2(maxX, maxY)
    }
    
}

internal extension CGSize {
    
    var axis: Vec2<CGFloat> {
        return Vec2(height, width)
    }
    
    var cross: Vec2<CGFloat> {
        return Vec2(width, height)
    }
    
    var floored: CGSize {
        return CGSize(width: width.floored, height: height.floored)
    }
    
    @inline(__always) func axisGrow(_ distance: FloatingVecConvertible) -> Vec2<CGSize> {
        return Vec2(CGSize(width: width, height: height + distance.vec.v0), CGSize(width: width + distance.vec.v1, height: height))
    }
    
    @inline(__always) func crossGrow(_ distance: FloatingVecConvertible) -> Vec2<CGSize> {
        return Vec2(CGSize(width: width + distance.vec.v0, height: height), CGSize(width: width, height: height + distance.vec.v1))
    }
    
    @inline(__always) func axisChange(to dest: FloatingVecConvertible) -> Vec2<CGSize> {
        return Vec2(CGSize(width: width, height: dest.vec.v0), CGSize(width: dest.vec.v1, height: height))
    }
    
    @inline(__always) func crossChange(to dest: FloatingVecConvertible) -> Vec2<CGSize> {
        return Vec2(CGSize(width: dest.vec.v0, height: height), CGSize(width: width, height: dest.vec.v1))
    }
    
}

internal extension UIEdgeInsets {
    
    var axisMin: Vec2<CGFloat> {
        return Vec2(top, left)
    }
    
    var axisMax: Vec2<CGFloat> {
        return Vec2(bottom, right)
    }
    
    var crossMin: Vec2<CGFloat> {
        return Vec2(left, top)
    }
    
    var crossMax: Vec2<CGFloat> {
        return Vec2(bottom, right)
    }
    
    var floored: UIEdgeInsets {
        return UIEdgeInsets(top: top.floored, left: left.floored, bottom: bottom.floored, right: right.floored)
    }
    
}

@inline(__always) internal func max<T>(_ x: Vec2<T>, _ y: Vec2<T>) -> Vec2<T> where T : Comparable {
    return Vec2(max(x.v0, y.v0), max(x.v1, y.v1))
}

@inline(__always) internal func min<T>(_ x: Vec2<T>, _ y: Vec2<T>) -> Vec2<T> where T : Comparable {
    return Vec2(min(x.v0, y.v0), min(x.v1, y.v1))
}
