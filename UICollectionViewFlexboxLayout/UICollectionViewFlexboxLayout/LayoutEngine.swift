//
//  LayoutEngine.swift
//  UICollectionViewFlexboxLayout
//
//  Created by Jerry Wong on 2019/4/19.
//  Copyright © 2019 com.jerry. All rights reserved.
//

import UIKit

public typealias SizeInfo = Pair<IndexPath, (size: CGSize, grow: CGFloat, shrink: CGFloat)>

public typealias RectInfo = Pair<IndexPath, CGRect>

public typealias PageInfo = [[RectInfo]]

public struct Pair<Key, Value> {
    
    let key: Key
    
    let value: Value
    
    init(_ key: Key, _ value: Value) {
        self.key = key
        self.value = value
    }
    
}

extension Pair where Key == IndexPath {
    
    var section: Int {
        get {
            return key.section
        }
    }
    
    var isHeader: Bool {
        get {
            return key.item == SupplementaryIndex.header.rawValue
        }
    }
    
    var isFooter: Bool {
        get {
            return key.item == SupplementaryIndex.footer.rawValue
        }
    }
    
    var isBackground: Bool {
        get {
            return key.item == SupplementaryIndex.background.rawValue
        }
    }
    
    var isHeaderFooter: Bool {
        get {
            return isHeader || isFooter
        }
    }
}

public protocol LayoutEngine {
    
    associatedtype SizeType
    
    associatedtype Dependency
    
    var dependency: Dependency { get }
    
    var rectMap: [IndexPath: CGRect] { get }
    
    var pageInfo: PageInfo { get }
    
    var contentSize: CGSize { get }
    
    static func begin(with dependency: Dependency) -> Self
    
    func pageIndex(for rect: CGRect) -> ClosedRange<Int>
    
    func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool
    
    func measureHeader(at section: Int) -> SizeType?
    
    func measureFooter(at section: Int) -> SizeType?
    
    func measureBackground(at section: Int) -> SizeType?
    
    func measureItem(at indexPath: IndexPath, with preferredAttr: UICollectionViewLayoutAttributes?) -> SizeType
    
    func append(_ sizeInfo: SizeType)
    
    func finalize()
    
}

public final class FlexboxEngine : LayoutEngine {
    
    unowned public let dependency: FlexboxEngineDependency
    
    let dimensionConstraint: CGSize
    
    public var rectMap = [IndexPath: CGRect]()
    
    public var pageInfo = PageInfo()
    
    public var contentSize = CGSize.zero
    
    private(set) var sectionInfo = [SectionIntermedia]()
    
    private let sd: UICollectionView.ScrollDirection
    
    private var crossPageInfo = [RectInfo]()
    
    private var currentSection = SectionIntermedia(0, CGPoint.zero)
    
    private var currentOrigin = CGPoint.zero
    
    private var currentCrossDimension = CGFloat(0).vec
    
    private var currentLineRectInfo = [RectIntermedia]()
    
    public func finalize() {
        if let lastElement = currentLineRectInfo.last {
            breakLine()
            pushCurrentSection()
            if dependency.flexWrap(in: lastElement.section) == .noWrap {
                 contentSize = contentSize.axisGrow(dependency.insets(in: lastElement.section).axisMax)[sd]
            }
            contentSize = contentSize.crossGrow(dependency.insets(in: lastElement.section).crossMax)[sd]
        }
    }
    
    public func pageIndex(for rect: CGRect) -> ClosedRange<Int> {
        let lowerPageIdx = max(0, (rect.crossMin / PageHeight)[sd])
        let upperPageIdx = max(lowerPageIdx, (rect.crossMax / PageHeight)[sd])
        
        let lowerPageIdxVal = Int(lowerPageIdx.floored)
        let upperPageIdxVal = Int(upperPageIdx.ceiled)
        return lowerPageIdxVal...upperPageIdxVal
    }
    
    public func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        let insets = dependency.collectionViewAdjustedContentInset
        return (dependency.collectionViewBounds.size.axis - insets.axisMin - insets.axisMax - dimensionConstraint.axis)[sd] != 0
    }
    
    private init(dependency: FlexboxEngineDependency,
                 dimensionConstraint: CGSize,
                 scrollDirection: UICollectionView.ScrollDirection) {
        self.dependency = dependency
        self.dimensionConstraint = dimensionConstraint
        self.sd = scrollDirection
    }
    
    private func loadRectIntermediaIntoPage(_ rectIntermedia: RectIntermedia) {
        let rect = rectIntermedia.value
        let indexPath = rectIntermedia.key
        rectMap[indexPath] = rect
        let pageRange = pageIndex(for: rect)
        while pageInfo.count <= pageRange.upperBound {
            pageInfo.append([RectInfo]())
        }
        let rectInfo = rectIntermedia.map{ RectInfo($0.key, $0.value) }
        pageIndex(for: rect).forEach{ pageInfo[$0].append(rectInfo) }
    }
    
    private func applyCrossAlignment() {
        guard currentLineRectInfo.count > 1 else {
            return
        }
        let alignItems = dependency.alignItems(in: currentSection.index)
        let lineHeight = currentCrossDimension
        currentLineRectInfo = currentLineRectInfo.map {
            var rect = $0.value
            switch (dependency.alignSelf(at: $0.key).toAlignItems() ?? alignItems) {
            case .start:
                break
            case .end:
                rect.origin = rect.origin.crossMove(lineHeight.vec - rect.size.cross)[sd]
            case .center:
                rect.origin = rect.origin.crossMove(((lineHeight.vec - rect.size.cross) * 0.5).floored)[sd]
            case .stretch:
                rect.size = rect.size.crossGrow(lineHeight.vec - rect.size.cross)[sd]
            }
            return $0.shift{ $0 = rect }
        }
    }
    
    private func applyAxisDistribution() {
        guard let first = currentLineRectInfo.first, let last = currentLineRectInfo.last, !last.isHeaderFooter else {
            return
        }
        let justifyContent = dependency.justifyContent(in: currentSection.index)
        let insets = dependency.insets(in: currentSection.index)
        
        let totalValidSpace = dimensionConstraint.axis - insets.axisMin - insets.axisMax
        let totalItemSize = currentLineRectInfo.lazy.reduce(into: Vec2(0)) { $0 = $0 + $1.value.size.axis }
        
        switch justifyContent {
        case .start:
            break
        case .end:
            let fixedOffset = dimensionConstraint.axis - last.value.axisMax - insets.axisMax
            currentLineRectInfo = currentLineRectInfo.map {
                $0.shift {
                    $0.origin = $0.origin.axisMove(fixedOffset)[sd]
                }
            }
        case .center:
            let fixedOffset = ((totalValidSpace - (last.value.axisMax - first.value.axisMin)) * 0.5).floored
            currentLineRectInfo = currentLineRectInfo.map {
                $0.shift{
                    $0.origin = $0.origin.axisMove(fixedOffset)[sd]
                }
            }
        case .spaceAround:
            if currentLineRectInfo.count > 1 {
                let itemSpacing = ((totalValidSpace - totalItemSize) / CGFloat(currentLineRectInfo.count)).floored
                let halfSpacing = (itemSpacing * 0.5).floored
                currentLineRectInfo = currentLineRectInfo.reduce(into: (insets.axisMin - halfSpacing, [RectIntermedia]())) {
                    var rect = $1.value
                    rect.origin = rect.origin.axisChange(to: $0.0 + itemSpacing)[sd]
                    $0.0 = rect.axisMax
                    $0.1.append($1.shift{ $0 = rect })
                    }.1
            }
        case .spaceBetween:
            if currentLineRectInfo.count > 1 {
                let itemSpacing = ((totalValidSpace - totalItemSize) / CGFloat(currentLineRectInfo.count - 1)).floored
                currentLineRectInfo = currentLineRectInfo.reduce(into: (insets.axisMin - itemSpacing, [RectIntermedia]())) {
                    var rect = $1.value
                    rect.origin = rect.origin.axisChange(to: $0.0 + itemSpacing)[sd]
                    var ret = $0.1
                    ret.append($1.shift{ $0 = rect })
                    $0 = (rect.axisMax, ret)
                    }.1
            }
        }
    }
    
    private func fixGrowAndShrink() {
        guard let firstItem = currentLineRectInfo.first,
              !firstItem.isHeaderFooter,
              let maxX = currentLineRectInfo.last?.value.axisMax else {
            return
        }
        guard dependency.flexWrap(in: firstItem.section) == .wrap else {
            return
        }
        let minX = firstItem.value.axisMin
        let insets = dependency.insets(in: currentSection.index)
        let deltaX = dimensionConstraint.axis - insets.axisMin - insets.axisMax - (maxX - minX)
        if deltaX[sd] > 0 {
            let growRatio = currentLineRectInfo.reduce(into: 0) {
                $0 += abs($1.grow)
            }
            if growRatio > 0 {
                currentLineRectInfo = currentLineRectInfo.reduce(into: (CGFloat(0).vec, [RectIntermedia]())) { result, info in
                    let fixedX = (deltaX * abs(info.grow) / growRatio).floored
                    result.1.append(info.shift { rect in
                        rect.origin = rect.origin.axisMove(result.0)[sd]
                        rect.size = rect.size.axisGrow(fixedX)[sd]
                    })
                    result.0 = result.0 + fixedX
                }.1
            }
        } else if deltaX[sd] < 0 {
            let shrinkRatio = currentLineRectInfo.reduce(into: 0) {
                $0 += abs($1.shrink)
            }
            if shrinkRatio > 0 {
                currentLineRectInfo = currentLineRectInfo.reduce(into: (CGFloat(0).vec, [RectIntermedia]())) { result, info in
                    let fixedX = (deltaX * abs(info.shrink) / shrinkRatio).floored
                    result.1.append(info.shift { rect in
                        rect.origin = rect.origin.axisMove(result.0)[sd]
                        rect.size = rect.size.axisGrow(fixedX)[sd]
                    })
                    result.0 = result.0 + fixedX
                }.1
            }
        }
    }
    
    private func pushCurrentSection() {
        currentSection.finallize(Vec2(axis: currentOrigin.axis, cross: currentOrigin.cross + currentCrossDimension)[sd])
        if sectionInfo.count <= currentSection.index {
            sectionInfo.append(currentSection)
        } else {
            sectionInfo[currentSection.index] = currentSection
        }
    }
    
    private func breakLine(for reason: LineBreakReason = .items) {
        guard let lastRectInfo = currentLineRectInfo.last else {
            return
        }
        applyCrossAlignment()
        applyAxisDistribution()
        fixGrowAndShrink()
        currentLineRectInfo.forEach{ loadRectIntermediaIntoPage($0) }
        contentSize = Vec2(axis: max(dimensionConstraint.axis, contentSize.axis), cross: lastRectInfo.value.crossMax)[sd]
        switch reason {
        case .header:
            break
        case .items:
            currentSection.breakLine()
        case .section:
            if dependency.flexWrap(in: currentSection.index) == .noWrap {
                contentSize = contentSize.axisGrow(dependency.insets(in: currentSection.index).axisMax)[sd]
            }
            pushCurrentSection()
            currentSection = currentSection.next(startPoint: Vec2(axis: CGFloat(0).vec, cross: currentOrigin.cross + currentCrossDimension)[sd])
        case .footer:
            currentSection.finallize(Vec2(axis: currentOrigin.axis, cross: currentOrigin.cross + currentCrossDimension)[sd])
            currentSection.exit()
        }
        currentOrigin = Vec2(axis: CGFloat(0).vec, cross: currentOrigin.cross + currentCrossDimension)[sd]
        currentCrossDimension = CGFloat(0).vec
        currentLineRectInfo.removeAll()
    }
    
    public func measureHeader(at section: Int) -> SizeInfo? {
        let refHeaderSize = dependency.referenceSizeForHeader(in: section)
        if refHeaderSize != CGSize.zero {
            return SizeInfo(SupplementaryIndex.header.indexPath(for: section), (refHeaderSize, 0, 0))
        } else {
            return nil
        }
    }
    
    public func measureFooter(at section: Int) -> SizeInfo? {
        let refFooterSize = dependency.referenceSizeForFooter(in: section)
        if refFooterSize != CGSize.zero {
            return SizeInfo(SupplementaryIndex.footer.indexPath(for: section), (refFooterSize, 0, 0))
        } else {
            return nil
        }
    }
    
    public func measureBackground(at section: Int) -> SizeInfo? {
        if dependency.showSectionBackground(in: section) {
            return SizeInfo(SupplementaryIndex.background.indexPath(for: section), (CGSize.zero, 0, 0))
        } else {
            return nil
        }
    }
    
    public func measureItem(at indexPath: IndexPath, with preferredAttr: UICollectionViewLayoutAttributes?) -> SizeInfo {
        return SizeInfo(indexPath, (
                dependency.sizeForItem(at: indexPath, with: preferredAttr),
                dependency.flexGrow(at: indexPath),
                dependency.flexShrink(at: indexPath)
            )
        )
    }
    
    public func appendBackground(_ sizeInfo: SizeInfo) {
        var newRect = Vec2(origin: Vec2(currentSection.startPoint), size: Vec2(axis: dimensionConstraint.axis, cross: currentOrigin.cross + currentCrossDimension - currentSection.startPoint.cross))[sd]
        if let lastElement = currentLineRectInfo.last, !lastElement.isHeaderFooter {
            newRect.size = newRect.size.crossGrow(dependency.insets(in: currentSection.index).crossMax)[sd]
        }
        let backgroundInfo = RectIntermedia(key: sizeInfo.key, value: newRect, grow: 0, shrink: 0)
        loadRectIntermediaIntoPage(backgroundInfo)
    }
    
    public func append(_ sizeInfo: SizeInfo) {
        guard dimensionConstraint.cross[sd] > 0 else {
            return
        }
        if sizeInfo.isBackground {
            appendBackground(sizeInfo)
            return
        }
        if sizeInfo.section != currentSection.index {
            breakLine(for: .section)
        } else if sizeInfo.isFooter {
            breakLine(for: .footer)
        } else if currentLineRectInfo.count > 0 && dependency.flexWrap(in: sizeInfo.section) == .wrap {
            let maxV = currentOrigin.axis
                + dependency.minimumInteritemSpacing(in: currentSection.index).vec
                + sizeInfo.value.size.axis
                + dependency.insets(in: currentSection.index).axisMax
            if maxV[sd] > dimensionConstraint.axis[sd] {
                breakLine()
            }
        }

        if currentLineRectInfo.count == 0 {
            if currentSection.lineCount <= 0 || currentSection.isExiting {
                let preInsets = sizeInfo.section > 0 ? dependency.insets(in: sizeInfo.section - 1) : UIEdgeInsets.zero
                let currentInsets = dependency.insets(in: sizeInfo.section)
                currentOrigin = currentOrigin.axisMove(sizeInfo.isHeaderFooter ? CGFloat(0).vec : currentInsets.axisMin)[sd]
                if sizeInfo.isHeaderFooter {
                    let lastSectionInsetBottom: CGFloat
                    let currentSectionInsetBottom: CGFloat
                    if let lastElement = pageInfo.last?.last {
                        if lastElement.section != sizeInfo.section && !lastElement.isHeaderFooter {
                            lastSectionInsetBottom = preInsets.crossMax[sd]
                        } else {
                            lastSectionInsetBottom = 0
                        }
                        currentSectionInsetBottom = (sizeInfo.isFooter && lastElement.section == sizeInfo.section && !lastElement.isHeaderFooter) ? currentInsets.crossMax[sd] : 0
                    } else {
                        lastSectionInsetBottom = 0
                        currentSectionInsetBottom = 0
                    }
                    currentOrigin = currentOrigin.crossMove(lastSectionInsetBottom + currentSectionInsetBottom)[sd]
                } else {
                    switch dependency.sectionInsetCollapse {
                    case .separate:
                        currentOrigin = currentOrigin.crossMove(currentInsets.crossMin + preInsets.crossMax)[sd]
                    case .collapse:
                        currentOrigin = currentOrigin.crossMove(max(currentInsets.crossMax[sd], preInsets.crossMax[sd]))[sd]
                    }
                }
            } else {
                currentOrigin = currentOrigin.axisMove(dependency.insets(in: currentSection.index).axisMin)[sd]
                currentOrigin = currentOrigin.crossMove(dependency.minimumLineSpacing(in: currentSection.index))[sd]
            }
        } else {
            currentOrigin = currentOrigin.axisMove(dependency.minimumInteritemSpacing(in: currentSection.index))[sd]
        }
        
        let newRect: CGRect
        if sizeInfo.isHeaderFooter {
            newRect = CGRect(origin: currentOrigin, size: Vec2(axis: dimensionConstraint.axis, cross: sizeInfo.value.size.cross)[sd])
        } else {
            newRect = CGRect(origin: currentOrigin, size: sizeInfo.value.size)
        }
        currentLineRectInfo.append(RectIntermedia(key: sizeInfo.key, value: newRect, grow: sizeInfo.value.grow, shrink: sizeInfo.value.shrink))
        currentCrossDimension = max(currentCrossDimension, newRect.cross)
        contentSize = contentSize.axisChange(to: max(contentSize.axis, newRect.axisMax))[sd]
        if sizeInfo.isHeader {
            breakLine(for: .header)
        } else {
            currentOrigin = currentOrigin.axisChange(to: newRect.axisMax)[sd]
        }
    }
    
    public static func begin(with dependency: FlexboxEngineDependency) -> FlexboxEngine {
        let insets = dependency.collectionViewAdjustedContentInset
        let bounds = dependency.collectionViewBounds
        let size = CGSize(width: bounds.size.width - insets.left - insets.right, height: bounds.size.height - insets.top - insets.bottom)
        return FlexboxEngine(
            dependency: dependency,
            dimensionConstraint: size,
            scrollDirection: dependency.scrollDirection
        )
    }
    
    internal struct SectionIntermedia {
        
        let index: Int
        
        let startPoint: CGPoint
        
        var lineCount = 0
        
        var endPoint: CGPoint?
        
        var isExiting = false
        
        init(_ index: Int, _ startPoint: CGPoint) {
            self.index = index
            self.startPoint = startPoint
        }
        
        func next(startPoint: CGPoint) -> SectionIntermedia {
            return SectionIntermedia(index + 1, startPoint)
        }
        
        mutating func breakLine() {
            lineCount += 1
        }
        
        mutating func exit() {
            isExiting = true
        }
        
        mutating func finallize(_ mEndPoint: CGPoint) {
            if let endPoint = endPoint {
                self.endPoint = CGPoint(x: max(endPoint.x, mEndPoint.x), y: max(endPoint.y, mEndPoint.y))
            } else {
               endPoint = mEndPoint
            }
        }
        
    }
    
    private struct RectIntermedia {
        
        let key: IndexPath
        
        let value: CGRect
        
        let grow: CGFloat
        
        let shrink: CGFloat
        
        func map<R>(_ body: (RectIntermedia) -> R) -> R {
            return body(self)
        }
        
        func shift(_ body: (inout CGRect) -> Void) -> RectIntermedia {
            var rect = value
            body(&rect)
            return RectIntermedia(key: key, value: rect, grow: grow, shrink: shrink)
        }
        
        var section: Int {
            get {
                return key.section
            }
        }
        
        var isHeader: Bool {
            get {
                return key.item == SupplementaryIndex.header.rawValue
            }
        }
        
        var isFooter: Bool {
            get {
                return key.item == SupplementaryIndex.footer.rawValue
            }
        }
        
        var isHeaderFooter: Bool {
            get {
                return isHeader || isFooter
            }
        }
        
    }
    
    private enum LineBreakReason {
        
        case header
        
        case items
        
        case footer
        
        case section
    }
    
}

public protocol FlexboxEngineDependency : AnyObject {
    
    var collectionViewBounds: CGRect { get }
    
    var collectionViewAdjustedContentInset: UIEdgeInsets { get }
    
    var scrollDirection: UICollectionView.ScrollDirection { get }
    
    var sectionInsetCollapse: SectionInsetsCollapse { get }
    
    func sizeForItem(at indexPath: IndexPath, with preferredAttr: UICollectionViewLayoutAttributes?) -> CGSize
    
    func insets(in section: Int) -> UIEdgeInsets
    
    func minimumLineSpacing(in section: Int) -> CGFloat
    
    func minimumInteritemSpacing(in section: Int) -> CGFloat
    
    func justifyContent(in section: Int) -> UICollectionViewFlexboxLayout.JustifyContent
    
    func alignItems(in section: Int) -> UICollectionViewFlexboxLayout.AlignItems
    
    func alignSelf(at indexPath: IndexPath) -> UICollectionViewFlexboxLayout.AlignSelf
    
    func flexWrap(in section: Int) -> UICollectionViewFlexboxLayout.FlexWrap
    
    func flexShrink(at indexPath: IndexPath) -> CGFloat
    
    func flexGrow(at indexPath: IndexPath) -> CGFloat
    
    func referenceSizeForHeader(in section: Int) -> CGSize
    
    func referenceSizeForFooter(in section: Int) -> CGSize
    
    func showSectionBackground(in section: Int) -> Bool
    
}

fileprivate let PageHeight = UIScreen.main.bounds.height
