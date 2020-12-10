//
//  ELBookshelfViewController.swift


import UIKit
import Alamofire
import AlamofireImage
import Foundation

protocol ELBookshelfViewControllerInput: BookshelfViewControllerInput {
    func populateUserDropdown(viewModel model: ELBookshelf.UserProfile.ViewModel)
}

@objc class ELBookshelfViewController: BookshelfViewController {
    
    //MARK:- Properties
    var interactor: ELBookshelfInteraction!
    var router: ELBookshelfRoutes!
    var books: [Bookshelf.ViewModel] = []
    var userProfileModel: ELBookshelf.UserProfile.ViewModel?
    var bookshelfSortOrder: SortProtocol!

    var showAdvancedSettings: Bool = false {
        didSet {
            SessionProperties.isAdvancedSettingsOpen = showAdvancedSettings
            if oldValue != showAdvancedSettings {
                UIView.animate(withDuration: 0.25) {
                    self.advancedSettingsBarHeightLayoutConstraint.constant = self.showAdvancedSettings ? 40 : 0
                    self.view.layoutIfNeeded()
                }
            }
        }
    }

    fileprivate var progressIndicator = ProgressIndicator()
    fileprivate var isAboutModalShown = false

    //MARK: --- Advanced Settings Bar
    @IBOutlet weak var advancedSettingsBarHeightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var networkStatusIndicator: NetworkStatusIndicator!

    //MARK: --- Top navigation bar properties
    @IBOutlet weak var topNavigationBarView: UIView!
    @IBOutlet weak var advancedSettingsButton: UIButton!
    @IBOutlet weak var userDropdownView: UIView!

    //MARK: --- Avatar Section
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var userFirstName: UILabel!

    //MARK: --- Container Section
    @IBOutlet weak var noInternetZeroStateView: UIView!

    //MARK: --- Bookshelf container properties
    @IBOutlet weak var bookshelfContainerView: UIView!
    @IBOutlet weak var bookShelfCollectionView: UICollectionView!
    @IBOutlet weak var bookShelfZeroStateView: UIView!
    @IBOutlet weak var bookshelfLoadFailureView: UIView!


    //MARK:- Lifecycle methods
    deinit {
        self.interactor = nil
        self.router = nil
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        ELBookshelfConfigurator.sharedInstance.configure(viewController: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: "Loading bookshelf")

        //Set Advanced Settings menu to closed state
        self.advancedSettingsBarHeightLayoutConstraint.constant = 0
        self.setupTopNavigationBar()

        self.bookshelfSortOrder = AssignedSort()
        setUpCollectionView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.showAdvancedSettings = SessionProperties.isAdvancedSettingsOpen
        if !self.isAboutModalShown {
            self.fetchBooks(refresh: true)
        }
        if SessionProperties.userSession.notification.shouldShowNotification {
            self.router.showUserNotification()
        }
    }


    //MARK:- User interaction handler methods
    @IBAction func advandedSettingButtonTapped(_ sender: UIButton) {
        //Toggle visibility
        UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: "")
        self.showAdvancedSettings = !self.showAdvancedSettings
    }

    @IBAction func displayDropdownMenu(_ sender: UIButton) {
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: "Displaying user drop down menu")
        self.router.showUserDropdown()
    }


    //MARK:- Private methods
    fileprivate func setupTopNavigationBar() {
        //Setup Top Navigation Bar
        self.topNavigationBarView.backgroundColor = UIColor(patternImage: UIImage(named: "el-top-bar-texture")!)

        //Setup Network Status Indicator
        self.networkStatusIndicator.statusTextFont = UIFont.heinemannSchool(style: .bold, size: 14)
        self.networkStatusIndicator.set(status: AppDelegate.isReachable() ? .online : .offline)

        //Setup Advanced Settings button
        self.advancedSettingsButton.attributedButton(withTitle: String.k12UniversalIcon(.settings),
                                                     titleAttributes: [NSAttributedString.Key.font: UIFont.k12UniversalFont(size: 18),
                                                                       NSAttributedString.Key.foregroundColor: UIColor.ELColors.Grayscale.grayDarkest],
                                                     bgColor: .clear,
                                                     for: .normal)

        //Setup Avatar Section
        self.interactor.setupUserDropdown()
    }

    fileprivate func setUpCollectionView() {
        bookShelfCollectionView.delegate = self
        bookShelfCollectionView.dataSource = self
        
        //Custom Layout
        let bookshelfLayout = ELBookshelfLayout()
        bookshelfLayout.delegate = self
        bookShelfCollectionView.collectionViewLayout = bookshelfLayout
        
        let refreshControl =  UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshBookShelf), for: .valueChanged)
        bookShelfCollectionView.addSubview(refreshControl)
        bookShelfCollectionView.alwaysBounceVertical = true
    }

    fileprivate func fetchBooks(refresh: Bool) {
        self.progressIndicator.show(in: self.bookshelfContainerView, style: .lightOpaque)
        DispatchQueue.main.async {
            self.interactor.fetchBooks(refresh: refresh)
        }
    }

    //MARK:- refresh control
    @objc func refreshBookShelf(sender: UIRefreshControl) {
        if AppDelegate.isReachable() {
            UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: "Reloading bookshelf")
            self.bookshelfSortOrder = AssignedSort()
            self.fetchBooks(refresh: true)
        }
        sender.endRefreshing()
    }


    //MARK:- Network reachability status change handlers
    override func handleReachabilityStatusChanged(isOffline: Bool) {
        UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: "Device is \(isOffline ? "offline" : "online") now")
        self.networkStatusIndicator.set(status: isOffline ? .offline : .online)
        self.networkStatusIndicator.accessibilityValue = "Device is \(isOffline ? "offline" : "online")"
        if !isOffline {
            TokenFactory.sharedInstance.renewAllTokensIfRequired()
        }

        if self.navigationController?.topViewController is ELBookshelfViewController {
            self.fetchBooks(refresh: true)
        }
    }


    //MARK:- Session Timeout handler methods
    override func sessionTimedOut() {
        guard AppDelegate.isReachable() else {
            return
        }

        ConsoleLog.debug("Processing Session Timed Out message")

        let resetSessionAndLogout = {
            //Resetting the application session & user configuration before logout
            SessionProperties.resetSession(isLogout: false)
            self.navigationController?.popToRootViewController(animated: true)
        }

        DispatchQueue.main.async {
            self.progressIndicator.hide()
            self.displayAlertMessage(title: NSLocalizedString("Session Timed Out", comment: "Session Timed Out"),
                                     message: NSLocalizedString("Your session has expired. Select OK to renew.", comment: "Your session has expired. Select OK to renew."),
                                     completionHandler: resetSessionAndLogout)
        }
    }


    //MARK:- BookshelfViewControllerInput methods
    override func displayBook(viewModel: Bookshelf.ViewModel) {
        self.router.navigateToBookView(viewModel: viewModel)
        self.progressIndicator.hide()
    }

    override func displayBookshelf(books: [Bookshelf.ViewModel]) {
        DispatchQueue.main.async {
            if !books.isEmpty {
                UIView.transition(with: self.view, duration: 0.25, options: [.curveLinear, .showHideTransitionViews], animations: {
                    self.bookShelfCollectionView.isHidden = false
                    self.bookShelfZeroStateView.isHidden = true
                    self.bookshelfLoadFailureView.isHidden = true
                }, completion: nil)
                self.books = books
                self.sortBookshelf()
                self.progressIndicator.hide()
                UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: "Bookshelf loaded")
            }
            else {
                UIView.transition(with: self.view, duration: 0.25, options: [.curveLinear, .showHideTransitionViews], animations: {
                    self.bookShelfCollectionView.isHidden = true
                    self.bookShelfZeroStateView.isHidden = false
                    self.bookshelfLoadFailureView.isHidden = true
                }, completion: nil)
                self.progressIndicator.hide()
                UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: "No books in bookshelf")
            }
        }
    }

    override func displayBookshelfLoadFailed() {
        self.progressIndicator.hide()
        self.bookshelfContainerView.isHidden = true
        self.bookShelfZeroStateView.isHidden = true
        self.bookshelfLoadFailureView.isHidden = false
        self.view.bringSubviewToFront(self.bookshelfLoadFailureView)
    }

    override func displayBookFetchError(error: String) {
        self.progressIndicator.hide()
        self.displayAlertMessage(title: "Error", message: error, completionHandler: {})
    }

    func sortBookshelf() {
        ConsoleLog.debug("Sorting bookshelf")
        self.books = BookshelfSort(sortType: self.bookshelfSortOrder).sortBooks(books: self.books)
        self.bookShelfCollectionView.reloadData()
    }
}


//MARK:- UICollectionViewDataSource extension
extension ELBookshelfViewController : UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.books.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let collectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "BookshelfCell", for: indexPath) as! ELBookshelfCollectionViewCell
        let viewModel = self.books[indexPath.item]
        collectionViewCell.indexPath = indexPath
        collectionViewCell.setupCell(viewModel)
        if let thumbnail = viewModel.thumbnail {
            collectionViewCell.bookCoverImage.image = viewModel.isBookClickable ? thumbnail : thumbnail.convertToGrayscale()
        }
        return collectionViewCell
    }
}


//MARK:- UICollectionViewDelegate extension
extension ELBookshelfViewController : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let viewModel = self.books[indexPath.item]
        
        if (viewModel.isBookClickable) {
            self.progressIndicator.show(in: self.bookshelfContainerView, style: .lightOpaque)
            self.interactor.selectBook(viewModel: viewModel)
        }
    }
}

//MARK:- ELBookshelfLayoutDelegate extension
extension ELBookshelfViewController: ELBookshelfLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, heightForItemAt indexPath: IndexPath, forWidth width: CGFloat) -> CGFloat {
        var heightPerItem = CGFloat(0.0) //Setting height to zero would use default height while calculating Layout attributes
        if let imageSize = self.books[indexPath.item].imageSize {
            let aspectRatio = imageSize.height / imageSize.width
            heightPerItem = (width * aspectRatio) + 20.0 //Cell top inset + bottom inset
        }

        return heightPerItem + 120.0 //Book Title label height
    }
    
    func isHidden() -> Bool {
        return self.view.isHidden
    }
}

//MARK:- ELBookshelfViewControllerInput extension
extension ELBookshelfViewController: ELBookshelfViewControllerInput {
    func populateUserDropdown(viewModel model: ELBookshelf.UserProfile.ViewModel) {
        if let avatarImage = UIImage(named: model.avatarImageName) {
            self.avatarImageView.image = avatarImage
        }

        self.userFirstName.text = model.firstname
        self.userProfileModel = model
    }
}

//MARK:- ELUserDropdownViewControllerDelegate extension
extension ELBookshelfViewController: ELUserDropdownViewControllerDelegate {
    func showAboutReader() {
        self.isAboutModalShown = true
        self.router.showAbout()
    }

    func signOut() {
        self.presentedViewController?.dismiss(animated: true, completion: nil)
        self.router.logoutUser()
    }
}

//MARK:- AboutDelegate extension
extension ELBookshelfViewController: AboutDelegate {
    func hideAbout() {
        self.isAboutModalShown = false
        self.router.hideAbout()
    }
}
