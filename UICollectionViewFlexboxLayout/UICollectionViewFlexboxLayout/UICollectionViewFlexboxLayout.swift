//
//  UICollectionViewFlexboxLayout.swift
//  UICollectionViewFlexboxLayout
//
//  Created by Jerry Wong on 2019/4/17.
//  Copyright © 2019 com.jerry. All rights reserved.
//

import UIKit

public protocol UICollectionViewDelegateFlexboxLayout : UICollectionViewDelegateExtFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, justifyContentForSectionAt section: Int) -> UICollectionViewFlexboxLayout.JustifyContent
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, alignItemsForSectionAt section: Int) -> UICollectionViewFlexboxLayout.AlignItems
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, alignSelfForItemAt indexPath: IndexPath) -> UICollectionViewFlexboxLayout.AlignSelf
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, flexGrowForItemAt indexPath: IndexPath) -> CGFloat
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, flexShrinkForItemAt indexPath: IndexPath) -> CGFloat
    
}

public extension UICollectionViewDelegateFlexboxLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, justifyContentForSectionAt section: Int) -> UICollectionViewFlexboxLayout.JustifyContent {
        return .spaceBetween
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, alignItemsForSectionAt section: Int) -> UICollectionViewFlexboxLayout.AlignItems {
        return .center
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

}

extension UICollectionViewFlexboxLayout : FlexboxEngineDependency {
    
    private func withCollectionViewAndDelegate<R>(body: (UICollectionView, UICollectionViewDelegateFlexboxLayout) -> R) -> R? {
        guard let collectionView = collectionView, let delegate = collectionView.delegate as? UICollectionViewDelegateFlexboxLayout else {
            return nil
        }
        return body(collectionView, delegate)
    }
    
    public func justifyContent(in section: Int) -> JustifyContent {
        return withCollectionViewAndDelegate { collectionView, delegate in
            return delegate.collectionView(collectionView, layout: self, justifyContentForSectionAt: section)
        } ?? justifyContent
    }
    
    public func alignItems(in section: Int) -> AlignItems {
        return withCollectionViewAndDelegate { collectionView, delegate in
            return delegate.collectionView(collectionView, layout: self, alignItemsForSectionAt: section)
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
