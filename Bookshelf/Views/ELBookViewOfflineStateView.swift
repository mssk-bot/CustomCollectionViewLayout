//
//  ELBookshelfOfflineView.swift


import UIKit

class ELBookViewOfflineStateView: UIView {
    
    @IBOutlet weak var bookShelfOfflineStateimage: UIImageView!
    class  func bookshelfOfflineState() -> ELBookViewOfflineStateView {
        return UINib(nibName: "ELBookShelfOfflineStateView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! ELBookViewOfflineStateView
    }
    
}
