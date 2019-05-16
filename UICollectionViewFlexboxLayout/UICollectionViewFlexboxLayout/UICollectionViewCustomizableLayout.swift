//
//  UICollectionViewCustomizableLayout.swift
//  UICollectionViewFlexboxLayout
//
//  Created by Jerry Wong on 2019/4/19.
//  Copyright © 2019 com.jerry. All rights reserved.
//

import UIKit

public enum SectionInsetsCollapse {
    
    case separate
    
    case collapse
    
}

public enum CalculateMode : Equatable {
    
    case tolerance(seconds: TimeInterval)
    
    case page(count: Int)
    
    case full
    
}

extension UICollectionView {
    
    public static let elementKindSectionBackground = "UICollectionElementKindSectionBackground"
    
}

public protocol UICollectionViewDelegateExtFlowLayout : UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, showSectionBackgroundAt section: Int) -> Bool
    
}

open class UICollectionViewCustomizableLayout<S> : UICollectionViewLayout where S: LayoutEngine {
    
    @IBInspectable open var minimumLineSpacing = CGFloat(10.0) {
        didSet {
            if oldValue != minimumLineSpacing {
                invalidateLayout()
            }
        }
    }
    
    @IBInspectable open var minimumInteritemSpacing = CGFloat(10.0) {
        didSet {
            if oldValue != minimumInteritemSpacing {
                invalidateLayout()
            }
        }
    }
    
    open var itemSize = CGSize.zero {
        didSet {
            if oldValue != itemSize {
                invalidateLayout()
            }
        }
    }
    
    open var estimatedItemSize = CGSize.zero {
        didSet {
            if oldValue != itemSize {
                invalidateLayout()
            }
        }
    }
    
    @IBInspectable open var headerReferenceSize = CGSize.zero {
        didSet {
            if oldValue != headerReferenceSize {
                invalidateLayout()
            }
        }
    }
    
    @IBInspectable open var footerReferenceSize = CGSize.zero {
        didSet {
            if oldValue != footerReferenceSize {
                invalidateLayout()
            }
        }
    }
    
    @IBInspectable open var sectionInset = UIEdgeInsets.zero {
        didSet {
            if oldValue != sectionInset {
                invalidateLayout()
            }
        }
    }
    
    open var scrollDirection = UICollectionView.ScrollDirection.vertical {
        didSet {
            if oldValue != scrollDirection {
                invalidateLayout()
            }
        }
    }
    
    open var sectionInsetCollapse = SectionInsetsCollapse.collapse {
        didSet {
            if oldValue != sectionInsetCollapse {
                invalidateLayout()
            }
        }
    }
    
    open var calculateMode = CalculateMode.tolerance(seconds: 0.5) {
        didSet {
            if oldValue != calculateMode {
                invalidateLayout()
            }
        }
    }
    
    open override var collectionViewContentSize: CGSize {
        get {
            return mLayoutEngine?.contentSize ?? CGSize.zero
        }
    }
    
    open override func prepare() {
        super.prepare()
        calculateIfNeeded()
    }
    
    open override func shouldInvalidateLayout(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool {
        guard estimatedItemSize != CGSize.zero,
            let delegate = collectionView?.delegate,
            preferredAttributes.frame != originalAttributes.frame else {
            return false
        }
        mAutoSizingMap[preferredAttributes.indexPath] = preferredAttributes
        isAutoSizing = true
        return !(delegate.responds(to: #selector(UICollectionViewDelegateFlowLayout.collectionView(_:layout:sizeForItemAt:))))
    }
    
    open override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        let invalidCount = (context.invalidatedItemIndexPaths != nil ? context.invalidatedItemIndexPaths!.count : 0)
            + (context.invalidatedSupplementaryIndexPaths != nil ? context.invalidatedSupplementaryIndexPaths!.count : 0)
            + (context.invalidatedDecorationIndexPaths != nil ? context.invalidatedDecorationIndexPaths!.count : 0)
        shouldRecalculate = shouldRecalculate || context.invalidateEverything || context.invalidateDataSourceCounts || invalidCount > 0
        super.invalidateLayout(with: context)
    }
    
    open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let mLayoutEngine = mLayoutEngine else {
                return nil
        }
        let pageIndex = mLayoutEngine.pageIndex(for: rect)
        calculateProgressively(to: pageIndex.upperBound)
        let pageList = mLayoutEngine.pageInfo
        if pageList.count == 0 {
            return nil
        }
        let upperBound = min(pageList.count - 1, pageIndex.upperBound)
        let lowerBound = min(pageIndex.lowerBound, upperBound)
        
        let ret = pageList[lowerBound...upperBound]
                    .flatMap{ $0 }
                    .reduce(into: [IndexPath: RectInfo](), { $0[$1.key] = $1 })
                    .map{ $0.value.value.intersects(rect) ? $0.value : nil }
                    .compactMap(layoutAttributesForRectInfo)
        return ret
    }
    
    open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return layoutAttributesForCommon(at: indexPath) {
            UICollectionViewLayoutAttributes(forCellWith: $0)
        }
    }
    
    open override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        if indexPath.count < 2 {
            return nil
        }
        
        let mIndexPath: IndexPath
        let zIndex: Int
        switch elementKind {
        case UICollectionView.elementKindSectionHeader:
            mIndexPath = SupplementaryIndex.header.indexPath(for: indexPath.section)
            zIndex = 1
        case UICollectionView.elementKindSectionFooter:
            mIndexPath = SupplementaryIndex.footer.indexPath(for: indexPath.section)
            zIndex = 1
        case UICollectionView.elementKindSectionBackground:
            mIndexPath = SupplementaryIndex.background.indexPath(for: indexPath.section)
            zIndex = -1
        default:
            mIndexPath = indexPath
            zIndex = 0
        } 
        return layoutAttributesForCommon(at: mIndexPath) {
            let attrs = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: $0)
            attrs.zIndex = zIndex
            return attrs
        }
    }
    
    open override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return nil
    }
    
    open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let mLayoutEngine = mLayoutEngine else {
            return false
        }
        return mLayoutEngine.shouldInvalidateLayout(forBoundsChange: newBounds)
    }
    
    @objc private func calculateAheadOfTime() {
        calculateProgressively()
        switch mCalculateState {
        case .done:
            break
        default:
            performSelector(onMainThread: #selector(UICollectionViewCustomizableLayout.calculateAheadOfTime), with: nil, waitUntilDone: false, modes: [RunLoop.Mode.default.rawValue])
        }
    }
    
    private var shouldRecalculate = true
    
    private var isAutoSizing = false
    
    private var mLayoutEngine: S?
    
    private var mSizeInfos: [S.SizeType]?
    
    internal var mOldLayoutAttrMap: LayoutAttrMap?
    
    internal var mLayoutAttrMap = LayoutAttrMap()
    
    private var mAutoSizingMap = LayoutAttrMap()
    
    private var mCalculateState = CalculateState.pending {
        didSet {
            if case .done = mCalculateState {
                mLayoutEngine?.finalize()
                mSizeInfos = nil
            }
        }
    }
    
    private enum CalculateState {
        
        case pending
        
        case inProgress(sizeInbound: CGSize, cursor: Int)
        
        case done
        
        var initialHeight: CGFloat {
            get {
                switch self {
                case .inProgress(let sizeInbound, _):
                    return sizeInbound.height
                default:
                    return 0
                }
            }
        }
        
        var initialCursor: Int {
            get {
                switch self {
                case .inProgress(_, let cursor):
                    return cursor + 1
                default:
                    return 0
                }
            }
        }
        
    }
    
    internal typealias LayoutAttrMap = [IndexPath: UICollectionViewLayoutAttributes]
    
}

private extension UICollectionViewCustomizableLayout {
    
    func layoutAttributesForCommon(at indexPath: IndexPath, attrConstructor: (IndexPath) -> UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes? {
        if let cached = mLayoutAttrMap[indexPath] {
            return cached
        } else if let rect = mLayoutEngine?.rectMap[indexPath] {
            let attr = attrConstructor(indexPath)
            attr.frame = rect
            mLayoutAttrMap[indexPath] = attr
            return attr
        } else {
            return nil
        }
    }
    
    func layoutAttributesForRectInfo(_ info: RectInfo?) -> UICollectionViewLayoutAttributes? {
        guard let info = info else {
            return nil
        }
        let indexPath = info.key
        switch indexPath.item {
        case SupplementaryIndex.header.rawValue:
            return layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, at: indexPath)
        case SupplementaryIndex.footer.rawValue:
            return layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, at: indexPath)
        case SupplementaryIndex.background.rawValue:
            return layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionBackground, at: indexPath)
        default:
            return layoutAttributesForItem(at: indexPath)
        }
    }
    
    func calculateIfNeeded() {
        if let collectionView = collectionView, let engine = mLayoutEngine, collectionView.bounds.axis.take(scrollDirection) != engine.contentSize.axis.take(scrollDirection) {
            shouldRecalculate = true
        }
        if shouldRecalculate || isAutoSizing {
            doCalculate()
            shouldRecalculate = false
            isAutoSizing = false
        }
    }
    
    func doCalculate() {
        guard let dependency = self as? S.Dependency else {
            fatalError("a customizable layout must confirm to the engine's dependency protocol")
        }
        guard let collectionView = collectionView else {
            return
        }
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(UICollectionViewCustomizableLayout.calculateAheadOfTime), object: nil)
        mCalculateState = .pending
        mLayoutEngine = S.begin(with: collectionView, dependency: dependency)
        mSizeInfos = (0..<collectionView.numberOfSections)
            .map { sectionIdx in
                (sectionIdx, (0..<collectionView.numberOfItems(inSection: sectionIdx)).map {
                    IndexPath(item: $0, section: sectionIdx)
                })
            }
            .flatMap(calculateSize(for:))
        mOldLayoutAttrMap = mLayoutAttrMap
        mLayoutAttrMap.removeAll()
        calculateProgressively()
        performSelector(onMainThread: #selector(UICollectionViewCustomizableLayout.calculateAheadOfTime), with: nil, waitUntilDone: false, modes: [RunLoop.Mode.default.rawValue])
    }
    
    func calculateProgressively(to pageIndex: Int? = nil) {
        if case .done = mCalculateState {
            return
        }
        guard let collectionViewHeight = collectionView?.bounds.cross.take(scrollDirection),
              let collectionViewContentOffset = collectionView?.contentOffset,
                let sizeInfos = mSizeInfos,
                let engine = mLayoutEngine,
                collectionViewHeight > 0 else {
            return
        }
        
        func calculateFully(_ maxSeconds: TimeInterval? = nil) {
            let date = Date()
            var abortedIdx: Int?
            for info in sizeInfos.enumerated() {
                if let maxSeconds = maxSeconds,
                   info.offset > 0,
                   info.offset % 128 == 0,
                   Date().timeIntervalSince(date) > maxSeconds {
                    abortedIdx = info.offset - 1
                    break
                }
                engine.append(info.element)
            }
            if let abortedIdx = abortedIdx {
                mCalculateState = .inProgress(sizeInbound: engine.contentSize, cursor: abortedIdx)
            } else {
                mCalculateState = .done
            }
        }
        
        func calculatePaged(_ maxPageCount: Int) {
            if pageIndex != nil && Int((mCalculateState.initialHeight / collectionViewHeight).floored) - pageIndex! >= maxPageCount {
                return
            }
            let maxHeight = max(mCalculateState.initialHeight + CGFloat(maxPageCount) * collectionViewHeight, collectionViewContentOffset.cross.take(scrollDirection) + collectionViewHeight * 2)
            var currentOffset: Int?
            for pair in sizeInfos[mCalculateState.initialCursor...].enumerated() {
                let (offset, sizeInfo) = pair
                engine.append(sizeInfo)
                let isDataEnough = {
                    pageIndex == nil || (
                        Int((engine.contentSize.cross.take(self.scrollDirection) / collectionViewHeight).floored) - pageIndex! >= maxPageCount
                    )
                }
                if engine.contentSize.cross.take(scrollDirection) >= maxHeight && isDataEnough() {
                    currentOffset = offset + mCalculateState.initialCursor
                    break
                }
            }
            if let currentOffset = currentOffset, currentOffset != sizeInfos.count - 1 {
                mCalculateState = .inProgress(sizeInbound: engine.contentSize, cursor: currentOffset)
            } else {
                mCalculateState = .done
            }
        }
        
        switch calculateMode {
        case .tolerance(let seconds):
            if case .pending = mCalculateState {
                calculateFully(seconds)
            } else {
                calculatePaged(2)
            }
        case .full:
            calculateFully()
        case .page(let maxPageCount):
            calculatePaged(maxPageCount)
        }
    }
    
    func calculateSize(for sectionInfo: (Int, [IndexPath])) -> [S.SizeType] {
        guard let engine = mLayoutEngine else {
            fatalError()
        }
        let (sectionIdx, itemIndexPaths) = sectionInfo
        var ret = [S.SizeType]()
        if let headerSizeInfo = engine.measureHeader(at: sectionIdx) {
            ret.append(headerSizeInfo)
        }
        ret.append(contentsOf: itemIndexPaths.map{ engine.measureItem(at: $0, with: self.mAutoSizingMap[$0]) })
        if let footerSizeInfo = engine.measureFooter(at: sectionIdx) {
            ret.append(footerSizeInfo)
        }
        if let backgroundSizeInfo = engine.measureBackground(at: sectionIdx) {
            ret.append(backgroundSizeInfo)
        }
        return ret
    }
    
    typealias RectMap = [IndexPath: CGRect]
    
}

public extension UICollectionViewCustomizableLayout {
    
    private func withCollectionViewAndDelegate<R>(body: (UICollectionView, UICollectionViewDelegateExtFlowLayout) -> R) -> R? {
        guard let collectionView = collectionView, let delegate = collectionView.delegate as? UICollectionViewDelegateExtFlowLayout else {
            return nil
        }
        return body(collectionView, delegate)
    }
    
    func sizeForItem(at indexPath: IndexPath, with preferredAttr: UICollectionViewLayoutAttributes?) -> CGSize {
        if let preferredAttr = preferredAttr {
            return preferredAttr.frame.size
        }
        var ret = withCollectionViewAndDelegate { collectionView, delegate in
            return delegate.collectionView?(collectionView, layout: self, sizeForItemAt: indexPath) ?? CGSize.zero
        }
        if ret == nil || ret == CGSize.zero {
            if estimatedItemSize != CGSize.zero {
                ret = estimatedItemSize
            } else {
                ret = itemSize
            }
        }
        return ret!.floored
    }
    
    func insets(in section: Int) -> UIEdgeInsets {
        return (withCollectionViewAndDelegate { collectionView, delegate in
            return (delegate.collectionView?(collectionView, layout: self, insetForSectionAt: section) ?? sectionInset)
            } ?? sectionInset).floored
    }
    
    func minimumLineSpacing(in section: Int) -> CGFloat {
        return (withCollectionViewAndDelegate { collectionView, delegate in
            return (delegate.collectionView?(collectionView, layout: self, minimumLineSpacingForSectionAt: section) ?? minimumLineSpacing)
            } ?? minimumLineSpacing).floored
    }
    
    func minimumInteritemSpacing(in section: Int) -> CGFloat {
        return (withCollectionViewAndDelegate { collectionView, delegate in
            return (delegate.collectionView?(collectionView, layout: self, minimumInteritemSpacingForSectionAt: section) ?? minimumInteritemSpacing)
            } ?? minimumInteritemSpacing).floored
    }
    
    func referenceSizeForHeader(in section: Int) -> CGSize {
        return (withCollectionViewAndDelegate { collectionView, delegate in
            return (delegate.collectionView?(collectionView, layout: self, referenceSizeForHeaderInSection: section) ?? headerReferenceSize)
            } ?? headerReferenceSize).floored
    }
    
    func referenceSizeForFooter(in section: Int) -> CGSize {
        return (withCollectionViewAndDelegate { collectionView, delegate in
            return (delegate.collectionView?(collectionView, layout: self, referenceSizeForFooterInSection: section) ?? footerReferenceSize)
            } ?? footerReferenceSize).floored
    }
    
    func showSectionBackground(in section: Int) -> Bool {
        return withCollectionViewAndDelegate { collectionView, delegate in
            return delegate.collectionView(collectionView, layout: self, showSectionBackgroundAt: section)
        } ?? false
    }
    
}

extension UICollectionViewDelegateExtFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, showSectionBackgroundAt section: Int) -> Bool {
        return false
    }
    
}

internal enum SupplementaryIndex : Int {
    
    case header = -1
    
    case footer = -2
    
    case background = -3
    
    func indexPath(for section: Int) -> IndexPath {
        return IndexPath(item: rawValue, section: section)
    }
    
}
