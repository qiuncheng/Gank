//
//  WelfareViewController.swift
//  Gank
//
//  Created by 程庆春 on 16/5/23.
//  Copyright © 2016年 qiuncheng.com. All rights reserved.
//

import UIKit
import Kingfisher
import PKHUD
import SnapKit


class WelfareViewController: UIViewController, UIViewControllerTransitioningDelegate {

    var noticeView: QCNoticeView!
    var customRefresh: CustomRefreshControl!
    var page: Int = 1
    var indexPath: NSIndexPath?  /// 用了记录点击了哪一个 indexPath

    weak var rightButton: UIButton?

    // MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        /// 添加刷新控件
        let rightView = UIButton(frame: CGRect.zero)

        rightView.setImage(UIImage(named: "refresh"), forState: .Normal)
        rightView.setImage(UIImage(named: "refresh_highlighted"), forState: .Highlighted)

        rightView.tintColor = UIColor.blackColor()

        rightView.sizeToFit()
        rightView.addTarget(self, action: #selector(loadData), forControlEvents: .TouchUpInside)
        rightButton = rightView
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightView)

        view.addSubview(collectionView)

        customRefresh = CustomRefreshControl()

        collectionView.addSubview(customRefresh)

        self.automaticallyAdjustsScrollViewInsets = false

        // show notice View
        let noticeView = QCNoticeView.loadNoticeView()
        noticeView.delegate = self
        self.view.addSubview(noticeView)
        self.noticeView = noticeView
        // 加载数据
        loadData()


    }

    override func viewWillAppear(animated: Bool) {
         super.viewWillAppear(animated)

        /**
         * 隐藏navigationBar
         */
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)

        // set noticeView

        noticeView.snp.makeConstraints(closure: { (make) in
            make.leading.equalTo(self.view.snp.leading)
            make.top.equalTo(self.view.snp.top).offset(128)
            make.width.equalTo(self.view.snp.width)
            make.height.equalTo(200)
        })

    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        self.collectionView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0)

    }

    // private functions
    @objc private func refreshBarButtonDidClick() {
        collectionView.setContentOffset(CGPoint(x: 0, y: -64-60), animated: true)
        self.scrollViewDidEndDecelerating(collectionView)
    }

    @objc private func loadData() {

        if abs(collectionView.contentOffset.y) > 0 {

            collectionView.setContentOffset(CGPoint(x: 0, y: -64), animated: true)
        }
        // 添加旋转动画
        let rotationAnimation = CABasicAnimation()
        rotationAnimation.keyPath = "transform.rotation"
        rotationAnimation.fromValue = 0
        rotationAnimation.toValue = M_PI
        rotationAnimation.duration = 0.5

        rotationAnimation.repeatCount = MAXFLOAT

        self.rightButton?.layer.addAnimation(rotationAnimation, forKey: "rotationAnimation")

        // 每次加载数据之前都要将数据置空
        results.removeAll()
        page = 1
        AlamofireManager.sharedInstance.page = page

        AlamofireManager.sharedInstance.type = URLType.welfare

        HUD.flash(.LabeledProgress(title: "数据加载ing", subtitle: ""),delay: 3.0)
        AlamofireManager.sharedInstance.fetchDataForWelfare { (rootClass) in
            guard let root = rootClass else {
                HUD.flash(.LabeledError(title: "数据加载失败", subtitle: "请稍后再试~"),delay: 1.0)
                HUD.hide()
                self.rightButton!.layer.removeAllAnimations()
                self.noticeView.setNoticeViewShow({ (finished) in
                })
                return
            }
            self.noticeView.setNoticeViewHidden({ (finished) in
            })
            for result in root.results {
                self.results.append(result)
            }

            self.customRefresh.endAnimation()
            self.collectionView.reloadData()
            self.rightButton?.layer.removeAllAnimations()

            HUD.hide()
        }

    }
    func loadMoreData() {

        AlamofireManager.sharedInstance.type = URLType.welfare

        AlamofireManager.sharedInstance.page = page
        
        HUD.flash(.LabeledProgress(title: "数据加载ing", subtitle: ""),delay: 3.0)

        AlamofireManager.sharedInstance.fetchDataForWelfare { (rootClass) in
            guard let root = rootClass else {
                HUD.flash(.LabeledError(title: "数据加载失败", subtitle: "请稍后再试~"),delay: 1.0)
                HUD.hide()
                self.rightButton?.layer.removeAllAnimations()
                return
            }
            for result in root.results {
                self.results.append(result)
            }

            self.results.sortInPlace({ (r1, r2) -> Bool in
                r1.publishedAt > r2.publishedAt
            })
            
            self.collectionView.reloadData()
            HUD.hide()

        }
    }

    // MARK: - lazy

    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let width = Common.Screen_width*0.5 - 1.0
        layout.itemSize = CGSizeMake(width, width)
        layout.minimumLineSpacing = 1.0
        layout.minimumInteritemSpacing = 1.0

        let collectionView: UICollectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)

        collectionView.backgroundColor = Common.navigationBarBackgroundColor

        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: -36, right: 0)

        collectionView.dataSource = self

        collectionView.delegate = self

        // 从nib中加载cell
        collectionView.registerNib(UINib.init(nibName: "WelfareCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: Common.welfareCellID)

        return collectionView
    }()

    lazy var results = [Result]()

}
// MARK: - UICollectionViewDataSource
extension WelfareViewController: UICollectionViewDataSource {

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return results.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Common.welfareCellID, forIndexPath: indexPath) as! WelfareCollectionViewCell

        if indexPath.item == (results.count-1) {
            if page < 5 {
                page += 1
                self.loadMoreData()
            } else {
                HUD.flash(.LabeledError(title: "", subtitle: "没有更多福利了！"), delay: 1.3)
            }
        }
        
        /**
         *  避免数组越界
         */
        if results.count > 0 {
            cell.result = results[indexPath.row]
        }

        return cell
    }
}

extension WelfareViewController: UICollectionViewDelegate {

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.indexPath = indexPath
        let showWealfareVC = ShowWelfareViewController()
        showWealfareVC.result = self.results[indexPath.item]

        self.presentViewController(showWealfareVC, animated: true) {}
    }

    func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! WelfareCollectionViewCell

        UIView.animateWithDuration(0.09) {
            cell.alphaView.alpha = 0.0
        }
    }

    func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! WelfareCollectionViewCell

        UIView.animateWithDuration(0.09) {
            cell.alphaView.alpha = 0.5
        }
    }

}

extension WelfareViewController {
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if customRefresh.refreshing {
            customRefresh.startAnimation()
            self.loadData()

        }
    }
}
extension WelfareViewController: QCNoticeViewDelegate {
    func noticeViewDidClickTryToRefreshButton(noticeView: QCNoticeView, sender: UIButton) {
        loadData()
    }
}
