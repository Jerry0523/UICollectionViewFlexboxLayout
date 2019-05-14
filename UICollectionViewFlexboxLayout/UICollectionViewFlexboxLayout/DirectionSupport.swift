//
//  DirectionSupport.swift
//  UICollectionViewFlexboxLayout
//
//  Created by Jerry Wong on 2019/4/28.
//  Copyright © 2019 com.jerry. All rights reserved.
//

import UIKit

internal struct Vec<T> {
    
    let hv: T
    
    let vv: T
    
    init(_ v: T) {
        hv = v
        vv = v
    }
    
    init(_ hv: T, _ vv: T) {
        self.hv = hv
        self.vv = vv
    }
    
    @inline(__always) func take(_ direction: UICollectionView.ScrollDirection) -> T {
        switch direction {
        case .horizontal:
            return hv
        case .vertical:
            return vv
        @unknown default:
            fatalError()
        }
    }
    
}

internal protocol FloatingVecConvertible {
    
    var vec: Vec<CGFloat> { get }
    
}

extension CGFloat : FloatingVecConvertible {
    
    var vec: Vec<CGFloat> {
        return Vec(self)
    }
    
    var floored: CGFloat {
        return CGFloat(floorf(Float(self)))
    }
    
    var ceiled: CGFloat {
        return CGFloat(ceilf(Float(self)))
    }
    
}

extension Vec : FloatingVecConvertible where T == CGFloat {
    
    var vec: Vec<CGFloat> {
        return self
    }
    
    var floored: Vec {
        return Vec(hv.floored, vv.floored)
    }
}

extension Vec where T == CGFloat {
    
    static func / (lhs: Vec, rhs: CGFloat) -> Vec {
        return Vec(lhs.hv / rhs, lhs.vv / rhs)
    }
    
    static func * (lhs: Vec, rhs: CGFloat) -> Vec {
        return Vec(lhs.hv * rhs, lhs.vv * rhs)
    }
    
    static func + (lhs: Vec, rhs: Vec) -> Vec {
        return Vec(lhs.hv + rhs.hv, lhs.vv + rhs.vv)
    }
    
    static func - (lhs: Vec, rhs: Vec) -> Vec {
        return Vec(lhs.hv - rhs.hv, lhs.vv - rhs.vv)
    }
    
}

extension Vec where T == CGPoint {
    
    init(axis: FloatingVecConvertible, cross: FloatingVecConvertible) {
        self.init(CGPoint(x: cross.vec.hv, y: axis.vec.hv), CGPoint(x: axis.vec.vv, y: cross.vec.vv))
    }
    
}

extension Vec where T == CGSize {
    
    init(axis: FloatingVecConvertible, cross: FloatingVecConvertible) {
        self.init(CGSize(width: cross.vec.hv, height: axis.vec.hv), CGSize(width: axis.vec.vv, height: cross.vec.vv))
    }
    
}

internal extension CGPoint {
    
    var axis: Vec<CGFloat> {
        return Vec(y, x)
    }
    
    var cross: Vec<CGFloat> {
        return Vec(x, y)
    }
    
    @inline(__always) func crossMove(_ distance: FloatingVecConvertible) -> Vec<CGPoint> {
        return Vec(CGPoint(x: x + distance.vec.hv, y: y), CGPoint(x: x, y: y + distance.vec.vv))
    }
    
    @inline(__always) func axisChange(to dest: FloatingVecConvertible) -> Vec<CGPoint> {
        return Vec(CGPoint(x: x, y: dest.vec.hv), CGPoint(x: dest.vec.vv, y: y))
    }
    
    @inline(__always) func axisMove(_ distance: FloatingVecConvertible) -> Vec<CGPoint> {
        return Vec(CGPoint(x: x, y: y + distance.vec.hv), CGPoint(x: x + distance.vec.vv, y: y))
    }
    
}

internal extension CGRect {
    
    var axis: Vec<CGFloat> {
        return Vec(height, width)
    }
    
    var axisMin: Vec<CGFloat> {
        return Vec(minY, minX)
    }
    
    var axisMax: Vec<CGFloat> {
        return Vec(maxY, maxX)
    }
    
    var cross: Vec<CGFloat> {
        return Vec(width, height)
    }
    
    var crossMin: Vec<CGFloat> {
        return Vec(minX, minY)
    }
    
    var crossMax: Vec<CGFloat> {
        return Vec(maxX, maxY)
    }
    
}

internal extension CGSize {
    
    var axis: Vec<CGFloat> {
        return Vec(height, width)
    }
    
    var cross: Vec<CGFloat> {
        return Vec(width, height)
    }
    
    var floored: CGSize {
        return CGSize(width: width.floored, height: height.floored)
    }
    
    @inline(__always) func axisGrow(_ distance: FloatingVecConvertible) -> Vec<CGSize> {
        return Vec(CGSize(width: width, height: height + distance.vec.hv), CGSize(width: width + distance.vec.vv, height: height))
    }
    
    @inline(__always) func crossGrow(_ distance: FloatingVecConvertible) -> Vec<CGSize> {
        return Vec(CGSize(width: width + distance.vec.hv, height: height), CGSize(width: width, height: height + distance.vec.vv))
    }
    
}

internal extension UIEdgeInsets {
    
    var axisMin: Vec<CGFloat> {
        return Vec(top, left)
    }
    
    var axisMax: Vec<CGFloat> {
        return Vec(bottom, right)
    }
    
    var crossMin: Vec<CGFloat> {
        return Vec(left, top)
    }
    
    var crossMax: Vec<CGFloat> {
        return Vec(bottom, right)
    }
    
    var floored: UIEdgeInsets {
        return UIEdgeInsets(top: top.floored, left: left.floored, bottom: bottom.floored, right: right.floored)
    }
    
}

