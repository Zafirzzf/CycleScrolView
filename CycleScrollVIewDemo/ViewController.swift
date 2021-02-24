//
//  ViewController.swift
//  CycleScrollVIewDemo
//
//  Created by 周正飞 on 2021/2/24.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scrollView = CycleScrollView<SimpleLabelCell>(frame: .zero,
                                                          options: .init(pageAnimateInterval: 3.0, startAutoScroll: true))
        scrollView.update(with: [SimpleModel(name: "name")])
        view.addSubview(scrollView)
    }
}

struct SimpleModel: Equatable {
    let name: String
}

class SimpleLabelCell: UICollectionViewCell, CycleScrollViewCell {
        
    typealias ItemModel = SimpleModel
    
    func update(with model: ItemModel) {
        // update UI
    }
}
