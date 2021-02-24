//
//  CycleScrollViewCell.swift
//  CycleScrollVIewDemo
//
//  Created by 周正飞 on 2021/2/24.
//

import UIKit

protocol CycleScrollViewCell where Self: UICollectionViewCell {
    associatedtype ItemModel: Equatable
    func update(with model: ItemModel)
}
