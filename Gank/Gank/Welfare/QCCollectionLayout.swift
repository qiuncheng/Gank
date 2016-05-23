//
//  QCCollectionLayout.swift
//  Gank
//
//  Created by 程庆春 on 16/5/23.
//  Copyright © 2016年 qiuncheng.com. All rights reserved.
//

import UIKit

class QCCollectionLayout: UICollectionViewLayout {

    // global variable

    /**
     准备布局
     */
    override func prepareLayout() {
        super.prepareLayout()

        /**
         *  init columnHeights
         */
        for _ in 0 ..< Constants.CollectionViewLayoutColumnCount {
            columnHeights.append(Constants.CollectionViewLayoutEdgeInsets.top)
        }


        /// attrs
        attrs.removeAll() // remove all the data from attrs
        guard let count: Int = self.collectionView?.numberOfItemsInSection(0) else {
            return
        }

        for i in 0 ..< count {
            let indexPath = NSIndexPath(forItem: i, inSection: 0)
            guard let attr = layoutAttributesForItemAtIndexPath(indexPath) else {
                return
            }

            attrs.append(attr)
        }


    }

    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {

        return attrs

    }
    /**
     * 决定cell的布局的方法
     */
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let attr = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)

        let collectionViewWidth = self.collectionView?.width

        let width = collectionViewWidth! / CGFloat(Constants.CollectionViewLayoutColumnCount)

//        let height =


        return attr
    }

    override func collectionViewContentSize() -> CGSize {
        return CGSizeMake(0, 1000)
    }

    // MARK: - Lazy
    lazy var attrs: [UICollectionViewLayoutAttributes] = {
        let attrs = [UICollectionViewLayoutAttributes]()

        return attrs

    }()

    lazy var columnHeights = [CGFloat]()
}