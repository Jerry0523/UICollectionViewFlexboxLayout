//
//  UICollectionViewFlexboxLayout.swift
//  UICollectionViewFlexboxLayout
//
//  Created by Jerry Wong on 2019/4/17.
//  Copyright © 2019 com.jerry. All rights reserved.
//

import UIKit

public protocol UICollectionViewDelegateFlexboxLayout : UICollectionViewDelegateExtFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, justifyContentForSectionAt section: Int) -> UICollectionViewFlexboxLayout.JustifyContent?
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, alignItemsForSectionAt section: Int) -> UICollectionViewFlexboxLayout.AlignItems?
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, flexWrapForSectionAt section: Int) -> UICollectionViewFlexboxLayout.FlexWrap?
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, alignSelfForItemAt indexPath: IndexPath) -> UICollectionViewFlexboxLayout.AlignSelf
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, flexGrowForItemAt indexPath: IndexPath) -> CGFloat
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, flexShrinkForItemAt indexPath: IndexPath) -> CGFloat
    
}

public extension UICollectionViewDelegateFlexboxLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, justifyContentForSectionAt section: Int) -> UICollectionViewFlexboxLayout.JustifyContent? {
        return nil
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, alignItemsForSectionAt section: Int) -> UICollectionViewFlexboxLayout.AlignItems? {
        return nil
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, flexWrapForSectionAt section: Int) -> UICollectionViewFlexboxLayout.FlexWrap? {
        return nil
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, alignSelfForItemAt indexPath: IndexPath) -> UICollectionViewFlexboxLayout.AlignSelf {
        return .inherited
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, flexGrowForItemAt indexPath: IndexPath) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, flexShrinkForItemAt indexPath: IndexPath) -> CGFloat {
        return 1.0
    }
    
}

open class UICollectionViewFlexboxLayout : UICollectionViewCustomizableLayout<FlexboxEngine> {
    
    public enum FlexWrap: Int {
        
        case wrap = 0
        
        case noWrap
        
    }
    
    public enum JustifyContent : Int {
        
        case start = 0
        
        case end
        
        case center
        
        case spaceBetween
        
        case spaceAround
        
    }
    
    public enum AlignItems : Int {
        
        case start = 0
        
        case end
        
        case center
        
        case stretch
        
    }
    
    public enum AlignSelf {
        
        case inherited
        
        case differed(_ alignItems: AlignItems)
        
        func toAlignItems() -> AlignItems? {
            switch self {
            case .inherited:
                return nil
            case .differed(let val):
                return val
            }
        }
        
    }
    
    open var justifyContent = JustifyContent.start {
        didSet {
            if oldValue != justifyContent {
                invalidateLayout()
            }
        }
    }
    
    open var alignItems = AlignItems.start {
        didSet {
            if oldValue != alignItems {
                invalidateLayout()
            }
        }
    }
    
    open var flexWrap = FlexWrap.wrap {
        didSet {
            if oldValue != flexWrap {
                invalidateLayout()
            }
        }
    }
    
    open override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)
        mUpdateItems = updateItems
    }
    
    open override func finalizeCollectionViewUpdates() {
        super.finalizeCollectionViewUpdates()
        mUpdateItems = nil
        mOldLayoutAttrMap = nil
    }
    
    open override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let mUpdateItems = mUpdateItems else {
            return nil
        }
        if mUpdateItems.contains(action: .reload, forKeyPath: \.indexPathAfterUpdate, and: itemIndexPath) {
            return mOldLayoutAttrMap?[itemIndexPath.shift(with: mUpdateItems, isReversed: true)]
        } else if mUpdateItems.contains(action: .insert, forKeyPath: \.indexPathAfterUpdate, and: itemIndexPath),
            let insertedAttr = mLayoutAttrMap[itemIndexPath]?.copy() as? UICollectionViewLayoutAttributes {
            var frame = insertedAttr.frame
            if let nextBeforeAttr = mOldLayoutAttrMap?[itemIndexPath.next().shift(with: mUpdateItems, isReversed: true)],
                let nextAfterAttr = mLayoutAttrMap[itemIndexPath.next()] {
                if (nextAfterAttr.frame.crossMin - nextBeforeAttr.frame.crossMin)[scrollDirection] != 0 {
                    frame.size = frame.size.crossChange(to: CGFloat(0))[scrollDirection]
                }
                if (nextAfterAttr.frame.axisMin - nextBeforeAttr.frame.axisMin)[scrollDirection] != 0 {
                    frame.size = frame.size.axisChange(to: CGFloat(0))[scrollDirection]
                }
            } else {
                frame.size = CGSize.zero
            }
            insertedAttr.frame = frame
            insertedAttr.alpha = 0
            return insertedAttr
        } else {
            return mLayoutAttrMap[itemIndexPath]
        }
    }
    
    open override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let mUpdateItems = mUpdateItems else {
            return nil
        }
        if mUpdateItems.contains(action: .reload, forKeyPath: \.indexPathBeforeUpdate, and: itemIndexPath),
            let beforeAttr = mOldLayoutAttrMap?[itemIndexPath],
            let afterAttr = mLayoutAttrMap[itemIndexPath] {
            return ((beforeAttr.frame.cross - afterAttr.frame.cross)[scrollDirection] < 0 && (beforeAttr.frame.crossMin - afterAttr.frame.crossMin)[scrollDirection] == 0 ) ? beforeAttr : afterAttr
        } else if let cachedAttr = mOldLayoutAttrMap?[itemIndexPath]?.copy() as? UICollectionViewLayoutAttributes,
                  mUpdateItems.contains(action: .delete, forKeyPath: \.indexPathBeforeUpdate, and: itemIndexPath) {
            var frame = cachedAttr.frame
            if let nextBeforeAttr = mOldLayoutAttrMap?[itemIndexPath.next()],
               let nextAfterAttr = mLayoutAttrMap[itemIndexPath.next().shift(with: mUpdateItems)] {
                if nextAfterAttr.frame.crossMin[scrollDirection] != nextBeforeAttr.frame.crossMin[scrollDirection] {
                    frame.size = frame.size.crossChange(to: CGFloat(0))[scrollDirection]
                }
                if nextAfterAttr.frame.axisMin[scrollDirection] != nextBeforeAttr.frame.axisMin[scrollDirection] {
                    frame.size = frame.size.axisChange(to: CGFloat(0))[scrollDirection]
                }
            } else {
                frame.size = frame.size.crossChange(to: CGFloat(0))[scrollDirection]
            }
            cachedAttr.frame = frame
            cachedAttr.alpha = 0
            return cachedAttr
        } else {
            return mLayoutAttrMap[itemIndexPath.shift(with: mUpdateItems)]
        }
    }
    
    public func flexWrap(in section: Int) -> UICollectionViewFlexboxLayout.FlexWrap {
        return .wrap
    }
    
    private var mUpdateItems: [UICollectionViewUpdateItem]?

}

internal extension Array where Element == UICollectionViewUpdateItem {
    
    func contains(action: UICollectionViewUpdateItem.Action, forKeyPath keyPath: KeyPath<UICollectionViewUpdateItem, IndexPath?>, and indexPath: IndexPath) -> Bool {
        return filter {
            $0.updateAction == action && $0[keyPath: keyPath] == indexPath
        }.count > 0
    }
    
}

internal extension IndexPath {
    
    func next() -> IndexPath {
        return IndexPath(item: item + 1, section: section)
    }
    
    func shift(with updateItems: [UICollectionViewUpdateItem]?, isReversed: Bool = false) -> IndexPath {
        guard let updateItems = updateItems else {
            return self
        }
        let delta = updateItems.reduce(into: 0) { (result, item) in
            switch item.updateAction {
            case .delete:
                if let indexPath = item.indexPathBeforeUpdate,
                    indexPath.section == section,
                    indexPath.item < self.item {
                    result -= 1
                }
            case .insert:
                if let indexPath = item.indexPathAfterUpdate,
                    indexPath.section == section,
                    indexPath.item <= self.item {
                    result += 1
                }
            case .move:
                if let indexPath = item.indexPathBeforeUpdate,
                    indexPath.section == section,
                    indexPath.item < self.item {
                    result -= 1
                }
                if let indexPath = item.indexPathAfterUpdate,
                    indexPath.section == section,
                    indexPath.item <= self.item {
                    result += 1
                }
            default:
                break
            }
        }
        let ret = IndexPath(item: item + delta * (isReversed ? -1 : 1), section: section)
        return ret
    }
    
}

extension UICollectionViewFlexboxLayout : FlexboxEngineDependency {
    
    internal func withCollectionViewAndDelegate<R>(body: (UICollectionView, UICollectionViewDelegateFlexboxLayout) -> R) -> R? {
        guard let collectionView = collectionView, let delegate = collectionView.delegate as? UICollectionViewDelegateFlexboxLayout else {
            return nil
        }
        return body(collectionView, delegate)
    }
    
    public var collectionViewBounds: CGRect {
        return collectionView?.bounds ?? CGRect.zero
    }
    
    public var collectionViewAdjustedContentInset: UIEdgeInsets {
        return collectionView?.adjustedContentInset ?? UIEdgeInsets.zero
    }
    
    public func justifyContent(in section: Int) -> JustifyContent {
        return withCollectionViewAndDelegate { collectionView, delegate in
            return delegate.collectionView(collectionView, layout: self, justifyContentForSectionAt: section) ?? justifyContent
        } ?? justifyContent
    }
    
    public func alignItems(in section: Int) -> AlignItems {
        return withCollectionViewAndDelegate { collectionView, delegate in
            return delegate.collectionView(collectionView, layout: self, alignItemsForSectionAt: section) ?? alignItems
            } ?? alignItems
    }
    
    public func alignSelf(at indexPath: IndexPath) -> UICollectionViewFlexboxLayout.AlignSelf {
        return withCollectionViewAndDelegate { collectionView, delegate in
            return delegate.collectionView(collectionView, layout: self, alignSelfForItemAt: indexPath)
            } ?? .inherited
    }
    
    public func flexShrink(at indexPath: IndexPath) -> CGFloat {
        return withCollectionViewAndDelegate { collectionView, delegate in
            return delegate.collectionView(collectionView, layout: self, flexShrinkForItemAt: indexPath)
        } ?? 1.0
    }
    
    public func flexGrow(at indexPath: IndexPath) -> CGFloat {
        return withCollectionViewAndDelegate { collectionView, delegate in
            return delegate.collectionView(collectionView, layout: self, flexGrowForItemAt: indexPath)
            } ?? 0.0
    }
    
}
