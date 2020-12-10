//
//  ELBookshelfCollectionViewCell.swift

import UIKit

class ELBookshelfCollectionViewCell: UICollectionViewCell {

    //MARK:- Properties
    @IBOutlet weak var expiredIconImageView: UIView!
    @IBOutlet weak var bookCoverImage: UIImageView!
    @IBOutlet weak var bookIdLabel: UILabel!
    @IBOutlet weak var downloadStatusView: UIView!
    @IBOutlet private weak var downloadStatusIcon: UILabel!
    @IBOutlet private weak var downloadStatusText: UILabel!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var bookTitleLabel: UILabel!
    @IBOutlet weak var bookAssignedView: UIView!
    @IBOutlet weak var shareIcon: UILabel!
    var indexPath : IndexPath!

    //MARK:- Lifecycle methods
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func setupCell(_ viewModel: Bookshelf.ViewModel) {
        self.contentView.roundedCorners(radius: 6.0)
        self.addShadow(offset: CGSize(width: 0, height: 3.0), opacity: 0.2, radius: 6.0, color: .black)
        self.downloadStatusView.addGradient(top: .clear, bottom: .black)
        self.downloadStatusIcon.font = UIFont.fontAwesomeFont(size: 12.0)
        self.downloadStatusIcon.text = String.fontAwesomeIcon(.check)
        self.shareIcon.font = UIFont.k12UniversalFont(size: 14)
        self.shareIcon.text = String.k12UniversalIcon(.assign)
        self.bookTitleLabel.text = viewModel.book.title
        self.downloadStatusView.isHidden = !viewModel.isDownloaded
        self.expiredIconImageView.isHidden = !viewModel.book.isExpired
        self.bookAssignedView.isHidden = !viewModel.isAssigned

        //Setup Accessibility
        self.isAccessibilityElement = true
        self.bookCoverImage.isAccessibilityElement = true
        var accessibilityHint = NSLocalizedString("Tap to open title", comment: "Tap to open title")
        if !viewModel.isBookClickable {
            accessibilityHint = NSLocalizedString("Title not available when offline", comment: "Title not available when offline")
        }
        if viewModel.book.isExpired {
            accessibilityHint = NSLocalizedString("Title expired and not available for use", comment: "Title expired and not available for use")
        }
        self.accessibilityIdentifier = "el.bookshelf.book.\(self.indexPath.section)-\(self.indexPath.row)"
        self.accessibilityLabel = viewModel.book.title
        self.accessibilityHint = accessibilityHint

        //Setup Loading View
        let loader = ThreeCircleAnimation(frame: CGRect(x: 0, y: 0, width: 40, height: 20))
        loader.tintColor = UIColor.ELColors.Blue.blue
        loader.center = self.loadingView.center
        loader.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin, .flexibleWidth]
        self.loadingView.backgroundColor = UIColor.ELColors.Blue.blueLightest
        self.loadingView.addSubview(loader)
        self.showLoadingView()

        #if DEBUG
        //Display Book ID in the cell
        self.bookIdLabel.text = viewModel.book.contextId()
        self.bookIdLabel.isHidden = false
        #endif
    }

    //MARK:- Public methods
    func showLoadingView() {
        self.bringSubviewToFront(self.loadingView)
        self.loadingView.isHidden = false
    }

    func hideLoadingView() {
        self.sendSubviewToBack(self.loadingView)
        self.loadingView.isHidden = true
    }
}
