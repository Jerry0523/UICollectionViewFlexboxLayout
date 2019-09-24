//
//  ViewController.swift
//  UICollectionViewFlexboxLayout
//
//  Created by Jerry Wong on 2019/4/17.
//  Copyright © 2019 com.jerry. All rights reserved.
//

import UIKit
import JWRefreshControl
import Intent
import UICollectionViewFlexboxLayout

struct ItemModel {
    
    let widthPercent: CGFloat
    
    let crossAlignment: UICollectionViewFlexboxLayout.AlignItems?
    
    let isCollapsed: Bool
    
    let height: CGFloat
    
    let color: UIColor
    
    init(widthPercent: CGFloat, height: CGFloat, crossAlignment: UICollectionViewFlexboxLayout.AlignItems? = nil) {
        self.widthPercent = widthPercent
        self.height = height
        self.color = UIColor.clear
        self.crossAlignment = crossAlignment
        self.isCollapsed = true
    }
    
    init(widthPercent: CGFloat, height: CGFloat, color: UIColor, crossAlignment: UICollectionViewFlexboxLayout.AlignItems? = nil, isCollapsed: Bool = true) {
        self.widthPercent = widthPercent
        self.height = height
        self.color = color
        self.crossAlignment = crossAlignment
        self.isCollapsed = isCollapsed
    }
    
    func mutated(isCollapsed: Bool) -> ItemModel {
        return ItemModel(widthPercent: widthPercent, height: height, color: color, crossAlignment: crossAlignment, isCollapsed: isCollapsed)
    }
    
}

struct SectionModel {
    
    let header: ItemModel?
    
    var items: [ItemModel]
    
    let footer: ItemModel?
    
    let background: ItemModel?
    
    let insets: CGFloat
    
    init(_ items: [ItemModel], header: ItemModel? = nil, footer: ItemModel? = nil, background: ItemModel? = nil, insets: CGFloat = 10) {
        let color = UIColor(red: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1)
        self.header = header.map { ItemModel(widthPercent: $0.widthPercent, height: $0.height, color: color, crossAlignment: $0.crossAlignment) }
        self.items = items.map { ItemModel(widthPercent: $0.widthPercent, height: $0.height, color: color, crossAlignment: $0.crossAlignment) }
        self.footer = footer.map { ItemModel(widthPercent: $0.widthPercent, height: $0.height, color: color, crossAlignment: $0.crossAlignment) }
        self.background = background
        self.insets = insets
    }
    
    mutating func updateItem(forIndex index: Int, body: (ItemModel) -> ItemModel) {
        guard index < items.count && index >= 0 else {
            return
        }
        items[index] = body(items[index])
    }
}

let MockData = [
    SectionModel(
        [
            ItemModel(widthPercent: 0.8, height: 120),
            ItemModel(widthPercent: 0.2, height: 90),
            ItemModel(widthPercent: 0.3, height: 100),
            ItemModel(widthPercent: 0.5, height: 20),
            ItemModel(widthPercent: 0.9, height: 50)
        ],
        footer: ItemModel(widthPercent: 0.3, height: 30),
        //background: ItemModel(widthPercent: 0, height: 0, color: UIColor.orange),
        insets: 20.0
    ),
    SectionModel(
        [
            ItemModel(widthPercent: 0.2, height: 50, crossAlignment: .end),
            ItemModel(widthPercent: 0.3, height: 100),
            ItemModel(widthPercent: 0.2, height: 80),
            ItemModel(widthPercent: 0.8, height: 190),
            ItemModel(widthPercent: 0.3, height: 60),
            ItemModel(widthPercent: 0.4, height: 120),
            ItemModel(widthPercent: 0.9, height: 90),
            ItemModel(widthPercent: 0.1, height: 140)
        ],
        header: ItemModel(widthPercent: 0.3, height: 30),
        footer: ItemModel(widthPercent: 0.3, height: 30),
        background: ItemModel(widthPercent: 0, height: 0, color: UIColor.red),
        insets: 30.0
    ),
    SectionModel(
        [
            ItemModel(widthPercent: 1.0 / 4.0, height: 90),
            ItemModel(widthPercent: 1.0 / 3.0, height: 60),
            ItemModel(widthPercent: 1.0 / 2.0, height: 110),
            ItemModel(widthPercent: 1.0 / 5.0, height: 120),
            ItemModel(widthPercent: 1.0 / 8.0, height: 80),
            ItemModel(widthPercent: 1.0 / 2.0, height: 110),
            ItemModel(widthPercent: 1.0 / 4.0, height: 80),
            ItemModel(widthPercent: 1.0 / 4.0, height: 70),
            ItemModel(widthPercent: 1.0 / 5.0, height: 120),
            ItemModel(widthPercent: 1.0 / 2.0, height: 100),
            ItemModel(widthPercent: 1.0 / 9.0, height: 60),
            ItemModel(widthPercent: 1.0 / 3.0, height: 120)
        ],
        //background: ItemModel(widthPercent: 0, height: 0, color: UIColor.purple),
        insets: 40.0
    )
]

class ViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var mData = MockData
    
    @objc var isHorizontal = false
    
    var justifyContent = UICollectionViewFlexboxLayout.JustifyContent.start
    
    var alignItems = UICollectionViewFlexboxLayout.AlignItems.start
    
    func mockDelay(_ action: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            action()
        }
    }
    
    @IBAction func didOpenControlPannel(_ sender: UIBarButtonItem) {
        Route() { _ in
            let sb = UIStoryboard(name: "Main", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "controlPannel") as! ControlPannel
            vc.mJustifyContent = self.justifyContent
            vc.mAlignItems = self.alignItems
            vc.exportConfig = self.update
            return vc
        }.config(.popup(.contentTop)).submit()
    }
    
    func update(_ mJustifyContent: UICollectionViewFlexboxLayout.JustifyContent,
                _ mAlignItems: UICollectionViewFlexboxLayout.AlignItems) {
        justifyContent = mJustifyContent
        alignItems = mAlignItems
        collectionView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        justifyContent = isHorizontal ? .center : .start
        alignItems = isHorizontal ? .start : .center
        
//        let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlexboxLayout
//        flowLayout?.itemSize = CGSize.zero
//        flowLayout?.estimatedItemSize = CGSize(width: 20, height: 20)
        
        collectionView.register(ItemCell.self, forCellWithReuseIdentifier: CellReuseIdentifier)
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: HeaderReuseIdentifier)
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: FooterReuseIdentifier)
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionBackground, withReuseIdentifier: BackgroundReuseIdentifier)
        
        if !isHorizontal {
            title = "Vertical"
            collectionView.addRefreshHeader { [weak self] header in
                self?.mockDelay {
                    self?.mData = MockData
                    self?.collectionView.reloadData()
                    header.success()
                }
            }
            collectionView.addRefreshFooter { [weak self] footer in
                self?.mockDelay {
                    if let newSectionIdx = self?.mData.count {
                        self?.mData += MockData
                        self?.collectionView.insertSections(IndexSet(newSectionIdx..<(newSectionIdx + MockData.count)))
                    }
                    footer.success()
                }
            }
        } else {
            title = "Horizontal"
            collectionView.alwaysBounceVertical = false
            (collectionView.collectionViewLayout as? UICollectionViewFlexboxLayout)?.scrollDirection = .horizontal
        }
    }
    
}

extension ViewController : UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return mData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mData[section].items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellReuseIdentifier, for: indexPath) as! ItemCell
        cell.didToggleCollapseState = { [unowned self] mCell in
            if let indexPath = self.collectionView.indexPath(for: mCell) {
                self.mData[indexPath.section].updateItem(forIndex: indexPath.item) {
                    $0.mutated(isCollapsed: !$0.isCollapsed)
                }
                self.collectionView.reloadItems(at: [indexPath])
            }
        }
        cell.didClickDeleteBtn = { [unowned self] mCell in
            if let indexPath = self.collectionView.indexPath(for: mCell) {
                self.mData[indexPath.section].items.remove(at: indexPath.item)
                self.collectionView.deleteItems(at: [indexPath])
            }
        }
        cell.didClickAddBtn = { [unowned self] mCell in
            if let indexPath = self.collectionView.indexPath(for: mCell) {
                let newItem = self.mData[indexPath.section].items[indexPath.row]
                self.mData[indexPath.section].items.insert(newItem, at: indexPath.row)
                self.collectionView.insertItems(at: [IndexPath(item: indexPath.item + 1, section: indexPath.section)])
            }
        }
        let itemModel = mData[indexPath.section].items[indexPath.row]
        cell.backgroundColor = itemModel.color
        cell.updateCollapsedState(itemModel.isCollapsed)
        (cell.contentView.subviews.first as! UILabel).text = indexPath.description
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let createSupplementaryView = { (reuseIdentifier: String, body: (UICollectionReusableView) -> ()) -> UICollectionReusableView in
            let supplementaryView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: reuseIdentifier, for: indexPath)
            body(supplementaryView)
            return supplementaryView
        }
        
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            return createSupplementaryView(HeaderReuseIdentifier) {
                if let header = mData[indexPath.section].header {
                    $0.backgroundColor = header.color
                    $0.layer.borderColor = UIColor.black.cgColor
                    $0.layer.borderWidth = 1.0
                }
            }
        case UICollectionView.elementKindSectionFooter:
            return createSupplementaryView(FooterReuseIdentifier) {
                if let footer = mData[indexPath.section].footer {
                    $0.backgroundColor = footer.color
                    $0.layer.borderColor = UIColor.red.cgColor
                    $0.layer.borderWidth = 1.0
                }
            }
        case UICollectionView.elementKindSectionBackground:
            return createSupplementaryView(BackgroundReuseIdentifier) {
                if let background = mData[indexPath.section].background {
                    $0.backgroundColor = background.color
                }
            }
        default:
            fatalError()
        }
    }
    
}

extension ViewController : UICollectionViewDelegateFlexboxLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, alignItemsForSectionAt section: Int) -> UICollectionViewFlexboxLayout.AlignItems? {
        return alignItems
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, justifyContentForSectionAt section: Int) -> UICollectionViewFlexboxLayout.JustifyContent? {
        return justifyContent
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, flexWrapForSectionAt section: Int) -> UICollectionViewFlexboxLayout.FlexWrap? {
        return section <= 1  ? .noWrap : nil
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, alignSelfForItemAt indexPath: IndexPath) -> UICollectionViewFlexboxLayout.AlignSelf {
        let itemModel = mData[indexPath.section].items[indexPath.item]
        return itemModel.crossAlignment != nil ? .differed(itemModel.crossAlignment!) : .inherited
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let sectionInfo = mData[section]
        return UIEdgeInsets(top: sectionInfo.insets,
                            left: sectionInfo.insets,
                            bottom: sectionInfo.insets,
                            right: sectionInfo.insets)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let model = mData[indexPath.section].items[indexPath.row]
        return CGSize(width: collectionView.bounds.width * model.widthPercent + (model.isCollapsed ? 0 : 30), height: model.height + (model.isCollapsed ? 0 : 30) )
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let sectionInfo = mData[section]
        if let header = sectionInfo.header {
            return CGSize(width: collectionView.bounds.width * header.widthPercent, height: header.height)
        } else {
            return CGSize.zero
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        let sectionInfo = mData[section]
        if let footer = sectionInfo.footer {
            return CGSize(width: collectionView.bounds.width * footer.widthPercent, height: footer.height)
        } else {
            return CGSize.zero
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, showSectionBackgroundAt section: Int) -> Bool {
        let sectionInfo = mData[section]
        return sectionInfo.background != nil
    }
    
}

class ItemCell : UICollectionViewCell {
    
    let label = UILabel()
    
    let collapseBtn = UIButton()
    
    let addBtn = UIButton()
    
    let deleteBtn = UIButton()
    
    var didToggleCollapseState: ((UICollectionViewCell) -> ())?
    
    var didClickAddBtn: ((UICollectionViewCell) -> ())?
    
    var didClickDeleteBtn: ((UICollectionViewCell) -> ())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    @objc private func didClickAddBtn(with sender: UIButton) {
        didClickAddBtn?(self)
    }
    
    @objc private func didClickClickBtn(with sender: UIButton) {
        didClickDeleteBtn?(self)
    }
    
    @objc private func didClickCollapseBtn(with sender: UIButton) {
        didToggleCollapseState?(self)
    }
    
    func updateCollapsedState(_ isCollapsed: Bool) {
        addBtn.isHidden = isCollapsed
        deleteBtn.isHidden = isCollapsed
    }
    
    private func setupView() {
        contentView.clipsToBounds = true
        contentView.addSubview(label)
        contentView.addSubview(addBtn)
        contentView.addSubview(deleteBtn)
        contentView.addSubview(collapseBtn)
        
        collapseBtn.setTitle("*", for: .normal)
        addBtn.setTitle("+", for: .normal)
        deleteBtn.setTitle("-", for: .normal)
        collapseBtn.addTarget(self, action: #selector(ItemCell.didClickCollapseBtn(with:)), for: .touchUpInside)
        addBtn.addTarget(self, action: #selector(ItemCell.didClickAddBtn(with:)), for: .touchUpInside)
        deleteBtn.addTarget(self, action: #selector(ItemCell.didClickClickBtn(with:)), for: .touchUpInside)
        label.textAlignment = .center
        label.textColor = UIColor.white
        
        [collapseBtn, addBtn, deleteBtn, label].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        NSLayoutConstraint.activate([
            collapseBtn.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            collapseBtn.topAnchor.constraint(equalTo: contentView.topAnchor),
            label.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            label.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -10),
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            deleteBtn.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            deleteBtn.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            addBtn.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            addBtn.rightAnchor.constraint(equalTo: deleteBtn.leftAnchor),
        ])
    }
    
}

private let CellReuseIdentifier = "cell"

private let HeaderReuseIdentifier = "header"

private let FooterReuseIdentifier = "footer"

private let BackgroundReuseIdentifier = "background"

