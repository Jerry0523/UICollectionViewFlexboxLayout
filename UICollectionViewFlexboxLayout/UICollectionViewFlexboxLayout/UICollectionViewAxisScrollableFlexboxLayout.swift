//
//  UICollectionViewAxisScrollableFlexboxLayout.swift
//  UICollectionViewFlexboxLayout
//
//  Created by Jerry Wong on 2019/5/22.
//  Copyright © 2019 com.jerry. All rights reserved.
//

import UIKit

open class UICollectionViewAxisScrollableFlexboxLayout : UICollectionViewFlexboxLayout {
    
    public override init() {
        super.init()
        setupObserver()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupObserver()
    }
    
    open override func prepare() {
        super.prepare()
        collectionView?.isDirectionalLockEnabled = true
    }
    
    open override var collectionViewContentSize: CGSize {
        get {
            if self.mFixedContentSize != nil {
                return self.mFixedContentSize!
            }
            return super.collectionViewContentSize
        }
    }
    
    open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        let ret = super.shouldInvalidateLayout(forBoundsChange: newBounds)
        if ret {
            return ret
        }
        
        if mIsAxisScrolling {
            return true
        }
        
        var shouldInvalidateLayout = false
        if let activeSection = mActiveSection,
            let sectionIndexes = sectionIndexes(in: newBounds),
            sectionIndexes.contains(activeSection) {
            shouldInvalidateLayout = true
        }
        return shouldInvalidateLayout
    }
    
    override func isRectInfo(_ info: (key: IndexPath, value: RectInfo), inside rect: CGRect) -> RectInfo? {
        if  !info.value.isHeaderFooter && !info.value.isBackground,
            let activeSection = mActiveSection, activeSection == info.key.section {
            return super.isRectInfo(info, inside: rect)
        }
        var mInfo = info
        if info.key.item >= 0, let fixedDistance = mSectionAxisScrollDistance[info.key.section] {
            mInfo = (key: info.key, value: RectInfo(info.key, Vec2(origin: Vec2(axis: info.value.value.origin.axis - Vec2(fixedDistance), cross: info.value.value.origin.cross), size: Vec2(info.value.value.size))[scrollDirection]))
        }
        return super.isRectInfo(mInfo, inside: Vec2(origin: Vec2(axis: CGFloat(0), cross: rect.origin.cross), size: Vec2(axis: rect.size.axis + rect.origin.axis, cross: rect.size.cross))[scrollDirection])
    }
    
    override func layoutAttributesForCommon(at indexPath: IndexPath, attrConstructor: (IndexPath) -> UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes? {
        guard let collectionView = collectionView,
            let attr = super.layoutAttributesForCommon(at: indexPath, attrConstructor: attrConstructor)
            else {
                return nil
        }
        if collectionView.contentOffset.axis[scrollDirection] != 0,
            (indexPath.section != (mActiveSection ?? -1) || indexPath.item < 0) {
            if indexPath.item >= 0, let fixedDistance = mSectionAxisScrollDistance[indexPath.section] {
                attr.transform = Vec2(axis: collectionView.contentOffset.axis - Vec2(fixedDistance), cross: CGFloat(0))[scrollDirection]
            } else {
                attr.transform = Vec2(axis: collectionView.contentOffset.axis, cross: CGFloat(0))[scrollDirection]
            }
            return attr
        } else if indexPath.item >= 0, let fixedDistance = mSectionAxisScrollDistance[indexPath.section] {
            attr.transform = Vec2(axis: -fixedDistance, cross: CGFloat(0))[scrollDirection]
            return attr
        }
        return attr
    }
    
    private func fixAxisOffsetIfNeeded(preferredAxisOffset: CGFloat = 0) {
        guard let axisDistance = collectionView?.contentOffset.axis[scrollDirection],
            axisDistance != preferredAxisOffset
            else {
                return
        }
        if let mActiveSection = mActiveSection {
            mSectionAxisScrollDistance[mActiveSection] = axisDistance
        }
        collectionView?.setContentOffset(Vec2(axis: preferredAxisOffset, cross: collectionView!.contentOffset.cross)[scrollDirection], animated: false)
    }
    
    private func sectionIndexes(in rect: CGRect) -> Set<Int>? {
        let begin = sectionIndex(at: Vec2(axis: rect.axisMin, cross: rect.crossMin)[scrollDirection]) ?? 0
        let end = sectionIndex(at: Vec2(axis: rect.axisMin, cross: rect.crossMax)[scrollDirection]) ?? (collectionView!.numberOfSections - 1)
        return Set(begin...end)
    }
    
    private func sectionIndex(at point: CGPoint) -> Int? {
        guard let engine = mLayoutEngine else {
            return nil
        }
        for rangeInfo in engine.sectionInfo.enumerated() {
            let rangeVal = rangeInfo.element
            if (rangeVal.startPoint.cross[scrollDirection]
                ...
                (rangeVal.endPoint ?? rangeVal.startPoint).cross[scrollDirection]
                ).contains(point.cross[scrollDirection]) {
                return rangeInfo.offset
            }
        }
        return nil
    }
    
    private func setupObserver() {
        mObservations = [
            observe(\.collectionView?.panGestureRecognizer.state) { [unowned self] _ , _  in
                guard let collectionView = self.collectionView,
                    (collectionView.panGestureRecognizer.state == .began
                        || collectionView.panGestureRecognizer.state == .ended),
                    let sectionIndex = self.sectionIndex(at: collectionView.panGestureRecognizer.location(in: collectionView))
                    else {
                        return
                }
                let velocity = collectionView.panGestureRecognizer.velocity(in: collectionView)
                let axisVelocity = velocity.axis[self.scrollDirection]
                let absAxisVelocity = abs(axisVelocity)
                let absCrossVelocity = abs(velocity.cross[self.scrollDirection])
                self.mIsAxisScrolling = absAxisVelocity > absCrossVelocity
                let isAxisScrolling = self.mIsAxisScrolling && self.flexWrap(in: sectionIndex) == .noWrap
                func fixContentSizeBySectionChanged() {
                    if let sectionCount = self.mLayoutEngine?.sectionInfo.count,
                        sectionCount > sectionIndex,
                        let secInfo = self.mLayoutEngine?.sectionInfo[sectionIndex],
                        let endPoint = secInfo.endPoint {
                        let maxAxis = endPoint.axis + self.insets(in: sectionIndex).axisMax
                        self.mFixedContentSize = collectionView.contentSize.axisChange(to: maxAxis)[self.scrollDirection]
                    } else {
                        self.mFixedContentSize = nil
                    }
                }
                if isAxisScrolling {
                    if sectionIndex != self.mActiveSection {
                        fixContentSizeBySectionChanged()
                        if let fixedDistance = self.mSectionAxisScrollDistance[sectionIndex] {
                            self.fixAxisOffsetIfNeeded(preferredAxisOffset: fixedDistance)
                            self.mSectionAxisScrollDistance[sectionIndex] = nil
                        } else {
                            self.fixAxisOffsetIfNeeded()
                        }
                        self.mActiveSection = sectionIndex
                    }
                } else {
                    if absCrossVelocity != 0 || absAxisVelocity != 0 {
                        self.mFixedContentSize = nil
                        self.fixAxisOffsetIfNeeded()
                        self.mActiveSection = nil
                    } else {
                        self.mIsAxisScrolling = true
                    }
                }
            }
        ]
    }
    
    public override func flexWrap(in section: Int) -> UICollectionViewFlexboxLayout.FlexWrap {
        return withCollectionViewAndDelegate { collectionView, delegate in
            return delegate.collectionView(collectionView, layout: self, flexWrapForSectionAt: section) ?? flexWrap
            } ?? flexWrap
    }
    
    private var mObservations: [NSKeyValueObservation]?
    
    private var mSectionAxisScrollDistance = [Int: CGFloat]()
    
    private var mActiveSection: Int? {
        didSet {
            if oldValue != mActiveSection {
                self.shouldRecalculate = true
            }
        }
    }
    
    private var mIsAxisScrolling = false
    
    private var mFixedContentSize: CGSize?
}
