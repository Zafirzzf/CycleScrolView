# CycleScrolView
An infinite cycle scrollView that supports generic views

## How to use

Decide your cell and model type, The compiler will detect whether your cell meets the requirements

Cell - confirm `CycleScrollViewCell` protocol:

```
class SimpleLabelCell: UICollectionViewCell, CycleScrollViewCell {
        
    typealias ItemModel = SimpleModel // This line can delete
    
    func update(with model: SimpleModel) {
        // update UI
    }
}
```


Model - confirm `Equatable`

```
struct SimpleModel: Equatable {
    let name: String
}
```

Then - seutp ScrollView

```
let scrollView = CycleScrollView<SimpleLabelCell>(frame: .zero,
                                                          options: .init(pageAnimateInterval: 3.0, startAutoScroll: true))
scrollView.update(with: [SimpleModel(name: "name")])
view.addSubview(scrollView)
```

### Other methods

```
scrollView.itemDidShow = { view, index, model in
     // cell did display callback
}
        
scrollView.itemDidSelect = { view, index, model in
    // cell did click callback            
}

/// Jump to the specified index
scrollView.scrollTo(index: targetIndex)
```

