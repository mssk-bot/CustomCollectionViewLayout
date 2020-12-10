//
//  ELBookshelfLayout.swift


import UIKit

protocol ELBookshelfLayoutDelegate: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, heightForItemAt indexPath: IndexPath, forWidth width: CGFloat) -> CGFloat
    func isHidden() -> Bool
}

class ELBookshelfLayout: UICollectionViewLayout {

    //MARK:- Properties
    var delegate: ELBookshelfLayoutDelegate!
    private var cachedAttributes = [UICollectionViewLayoutAttributes]()

    private let sectionInset = UIEdgeInsets(top: 15.0, left: 20.0, bottom: 15.0, right: 20.0)
    private let cellInset = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)

    private var isOrientationLandscape: Bool { return  self.collectionView!.frame.size.width > self.collectionView!.frame.size.height }
    private var itemsPerRow: Int { return isOrientationLandscape ? (UIDevice.current.modelName == "iPad Pro" ? 6 : 4) : (UIDevice.current.modelName == "iPad Pro" ? 4 : 3) }
    private let heightToWidth: CGFloat = 240 / 180 //Default colver image aspect ratio

    private var contentHeight: CGFloat = 0.0
    private var contentWidth: CGFloat {
        let contentInset = self.collectionView!.contentInset
        return collectionView!.bounds.width - (contentInset.left + contentInset.right) - (sectionInset.left + sectionInset.right)
    }

    //MARK:- UICollectionViewFlowLayout methods
    override func prepare() {
        if self.cachedAttributes.isEmpty && !delegate.isHidden() {
            ConsoleLog.debug("Layout Attributes calculations: Start")

            let numberOfItems = self.collectionView!.numberOfItems(inSection: 0)
            let itemWidth = self.contentWidth / CGFloat(self.itemsPerRow)
            let cellWidth = itemWidth - (self.cellInset.left + self.cellInset.right)

            let availableWidth = self.collectionView!.frame.width - (CGFloat(self.itemsPerRow) * (self.cellInset.left + self.cellInset.right)) - (sectionInset.left + sectionInset.right)
            let widthPerItem   = availableWidth /  CGFloat(self.itemsPerRow)
            let defaultHeightPerItem  = heightToWidth * widthPerItem

            var xOffset = [CGFloat]()
            for column in 0..<self.itemsPerRow {
                xOffset.append((CGFloat(column) * itemWidth) + sectionInset.left)
            }

            var column = 0
            //For section 0, add sectionInset.top & collectionView.contentInset.top to get the correct value
            //For other sections, use only sectionInset.top
            var indexPaths = [IndexPath](repeating: IndexPath(item: 0, section: 0), count: self.itemsPerRow)
            var currentRowYOffset = [CGFloat](repeating: self.sectionInset.top, count: self.itemsPerRow)
            var itemHeights = [CGFloat](repeating: 0, count: self.itemsPerRow)
            var maxYOffsetForRow: CGFloat = 0

            for item in 0..<numberOfItems {
                indexPaths[column] = IndexPath(item: item, section: 0)
                let itemHeight = self.delegate.collectionView(self.collectionView!, heightForItemAt: indexPaths[column], forWidth: cellWidth)
                itemHeights[column] = itemHeight != 0 ? itemHeight : defaultHeightPerItem

                let maxOffset = currentRowYOffset[column] + itemHeights[column]
                if maxOffset > maxYOffsetForRow {
                    maxYOffsetForRow = maxOffset
                }

                var numberOfItemsInCurrentRow = 0
                if self.isLastItemInRow(index: column) {
                    numberOfItemsInCurrentRow = self.itemsPerRow
                }
                else if ((item == numberOfItems - 1) && (item % self.itemsPerRow > 0)) {
                    numberOfItemsInCurrentRow = numberOfItems % self.itemsPerRow
                }

                for index in 0..<numberOfItemsInCurrentRow {
                    let deltaY = maxYOffsetForRow - (currentRowYOffset[index] + itemHeights[index])
                    currentRowYOffset[index] += deltaY
                }


                if self.isLastItemInRow(index: column) {
                    for index in 0..<self.itemsPerRow {
                        let frame = CGRect(x: xOffset[index], y: currentRowYOffset[index], width: itemWidth, height: itemHeights[index])
                        let insetFrame = frame.insetBy(dx: self.cellInset.left, dy: self.cellInset.top)

                        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPaths[index])
                        attributes.frame = insetFrame
                        self.cachedAttributes.append(attributes)

                        self.contentHeight = max(self.contentHeight, frame.maxY)
                    }

                    currentRowYOffset = [CGFloat](repeating: maxYOffsetForRow, count: self.itemsPerRow)

                    column = 0
                    maxYOffsetForRow = 0
                }
                else {
                    if (item == numberOfItems - 1) && (item % self.itemsPerRow >= 0) {
                        let remainingColumns = numberOfItems % self.itemsPerRow
                        for index in 0..<remainingColumns {
                            let frame = CGRect(x: xOffset[index], y: currentRowYOffset[index], width: itemWidth, height: itemHeights[index])
                            let insetFrame = frame.insetBy(dx: self.cellInset.left, dy: self.cellInset.top)

                            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPaths[index])
                            attributes.frame = insetFrame
                            self.cachedAttributes.append(attributes)

                            self.contentHeight = max(self.contentHeight, frame.maxY)
                        }
                    }

                    column += 1
                }
            }

            self.contentHeight += self.sectionInset.bottom

            ConsoleLog.debug("Layout Attributes calculations: End")
        }
    }

    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributesForVisibileItems = [UICollectionViewLayoutAttributes]()

        for attributes in self.cachedAttributes {
            if attributes.frame.intersects(rect) {
                attributesForVisibileItems.append(attributes)
            }
        }

        return attributesForVisibileItems
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return self.cachedAttributes[indexPath.item]
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return (self.collectionView?.bounds.width != newBounds.width)
    }
    
    override func invalidateLayout() {
        super.invalidateLayout()
        self.cachedAttributes.removeAll()
        self.contentHeight = 0.0
    }

    //MARK:- Private methods
    private func isLastItemInRow(index: Int) -> Bool {
        return (((index + 1) % self.itemsPerRow) == 0)
    }
}
