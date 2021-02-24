//
//  CycScrollView.swift
//  CycleScrollVIewDemo
//
//  Created by 周正飞 on 2021/2/24.
//

import UIKit

class CycleScrollView<CellType: CycleScrollViewCell>: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    typealias Model = CellType.ItemModel
    typealias CycleItemCallback = (CycleScrollView, Int, Model) -> Void
    typealias CycleCallback = (CycleScrollView) -> Void
    
    struct Options {
        var pageAnimateInterval = 3.0
        /// 是否开启自动滚动
        var startAutoScroll = true
    }
    
    var itemDidSelect: CycleItemCallback?
    var itemDidShow: CycleItemCallback?
    
    private lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        let collectionLayout = UICollectionViewFlowLayout()
        collectionLayout.itemSize = self.bounds.size
        collectionLayout.scrollDirection = .horizontal
        collectionLayout.minimumLineSpacing = 0
        return collectionLayout
    }()
    private lazy var collectionView: UICollectionView = {

        let collectionView = UICollectionView(frame: self.bounds, collectionViewLayout: self.collectionViewLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        CellType.register(of: collectionView)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true
        collectionView.isScrollEnabled = false
        collectionView.backgroundColor = UIColor.clear
        return collectionView
    }()
    lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.5)
        pageControl.currentPageIndicatorTintColor = UIColor.white
        pageControl.isEnabled = false
        pageControl.hidesForSinglePage = true
        return pageControl
    }()
    
    private let options: Options
    private var timer: Timer?
    private var models: [Model] = []
    
    var currentPage: Int = 0 {
        didSet {
            pageControl.currentPage = currentPage
            itemDidShow?(self, currentPage, models[currentPage])
        }
    }
    
    var elementCount: Int {
        models.count == 1 ? models.count : models.count - 2
    }
    
    deinit {
        stopTimer()
    }
    
    init(frame: CGRect, options: Options = Options()) {
        self.options = options
        super.init(frame: frame)
        setupUI()
        NotificationCenter.default.addObserver(self, selector: #selector(self.enterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.enterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) { return nil }
    
    private func setupUI() {
        addSubview(collectionView)
        addSubview(pageControl)
        setPageControlFrame()
    }
    
    private func setPageControlFrame() {
        pageControl.frame = CGRect(x: 0, y: bounds.height - 20, width: bounds.width, height: 15)
    }
    
    func addScrollTimerIfNeed() {
        guard options.startAutoScroll, timer == nil, models.count > 1 else {
            return
        }
        let timer = Timer.scheduledTimer(withTimeInterval: options.pageAnimateInterval, repeats: true, block: { [weak self] (_) in
            if let self = self {
                let currentOffset = self.collectionView.contentOffset
                // 先用Int取整, 确保每次动画不会偏移
                let targetOffsetX = CGFloat(Int(currentOffset.x / self.bounds.width) + 1) * self.bounds.width
                self.collectionView.setContentOffset(CGPoint(x: targetOffsetX, y: currentOffset.y), animated: true)
            }
        })
        RunLoop.current.add(timer, forMode: .common)
        self.timer = timer
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    /// 更新数据源
    /// - Parameter models: 数据源数组
    /// - Returns: 是否进行了更新(false为相同数据源没有更新)
    @discardableResult
    func update(with models: [Model]) -> Bool {
        guard needUpdate(of: models) else {
            return false
        }
        self.models = models
        guard models.count > 0 else {
            collectionView.reloadData()
            pageControl.numberOfPages = models.count
            stopTimer()
            return true
        }
        makeModelsCanCycleScroll(of: models)
        let isMulti = models.count > 1
        isMulti ? addScrollTimerIfNeed() : stopTimer()
        collectionView.reloadData()
        let indexPath = IndexPath(item: isMulti ? 1 : 0, section: 0)
        DispatchQueue.main.async {
            self.collectionView.scrollToItem(at: indexPath, at: .left, animated: false)
        }
        collectionView.isScrollEnabled = isMulti
        pageControl.numberOfPages = models.count
        pageControl.currentPage = 0
        return true
    }
    
    private func needUpdate(of newModels: [Model]) -> Bool {
        if models.count <= 1 {
            return models != newModels
        } else {
            return Array(models[1 ..< models.count - 1]) != newModels
        }
    }
    
    private func makeModelsCanCycleScroll(of originalModels: [Model]) {
        if originalModels.count > 1 {
            models.insert(originalModels[models.count - 1], at: 0)
            models.append(originalModels[0])
        }
    }

    func changeFrame(_ frame: CGRect) {
        if self.frame != frame {
            self.frame = frame
            collectionView.frame = CGRect(origin: .zero, size: frame.size)
            setPageControlFrame()
        }
    }
    
    /// 选中指定的索引
    func scrollTo(index: Int) {
        guard models.count > 1, index < models.count else {
            assertionFailure()
            return
        }
        let indexPath: IndexPath
        indexPath = IndexPath(item: index + 1, section: 0)
        DispatchQueue.main.async {
            self.collectionView.scrollToItem(at: indexPath, at: .left, animated: false)
        }
        pageControl.currentPage = index
    }
    
    // MARK: Collectionview 代理数据源
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        models.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = CellType.cell(from: collectionView, indexPath: indexPath)
        cell.update(with: models[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        itemDidSelect?(self, indexPath.row - 1, models[indexPath.item])
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        bounds.size
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        stopTimer()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        addScrollTimerIfNeed()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard models.count > 1 else {
            currentPage = 0
            return
        }
        let offsetX = scrollView.contentOffset.x
        if offsetX <= 0 {
            scrollView.contentOffset = CGPoint(x: CGFloat(elementCount) * bounds.width, y: 0)
            currentPage = 0
        } else if offsetX >= CGFloat(elementCount + 1) * bounds.width {
            scrollView.contentOffset = CGPoint(x: bounds.width, y: 0)
            currentPage = 0
        } else {
            var index = Int(offsetX / bounds.width) - 1
            if index >= models.count {
                index = models.count - 1
            } else if index < 0 {
                index = 0
            }
            if index != currentPage {
                currentPage = index
            }
        }
    }
    
    @objc
    func enterBackground() {
        stopTimer()
    }
    
    @objc
    func enterForeground() {
        addScrollTimerIfNeed()
    }
}

class CollectionViewCellLoader {
    static func cell<T>(collectionView: UICollectionView, indexPath: IndexPath) -> T where T: UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: T.self), for: indexPath) as? T {
            return cell
        } else {
            fatalError()
        }
    }
}

extension UICollectionViewCell {
    static func register(of collectionView: UICollectionView) {
        collectionView.register(self, forCellWithReuseIdentifier: String(describing: self))
    }
    
    static func cell(from collectionView: UICollectionView, indexPath: IndexPath) -> Self {
        return CollectionViewCellLoader.cell(collectionView: collectionView, indexPath: indexPath)
    }
}

