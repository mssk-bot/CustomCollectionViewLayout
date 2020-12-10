//
//  ELBookshelfRouter.swift

protocol ELBookshelfRoutes: class {
    func logoutUser()
    func showAbout()
    func hideAbout()
    func showUserDropdown()
    func showUserNotification()
    func navigateToBookView(viewModel: Bookshelf.ViewModel)
}

class ELBookshelfRouter: ELBookshelfRoutes {

    //MARK:- Properties
    weak var viewController: ELBookshelfViewController!


    //MARK:- Protocol methods
    func popToLogin() {
        _ = self.viewController.navigationController?.popToRootViewController(animated: true)
        self.viewController = nil
    }

    func logoutUser() {
        //Resetting User properties on logout
        SessionProperties.resetSession(isLogout: true)

        _ = self.viewController?.navigationController?.popToRootViewController(animated: true)
        self.viewController = nil
    }

    func navigateToBookView(viewModel: Bookshelf.ViewModel) {
        let storyboard = UIStoryboard(name: "ELBook", bundle: Bundle.main)
        let bookViewController = storyboard.instantiateViewController(withIdentifier: "el_book_view_controller") as! ELBookViewController
        self.viewController?.navigationController?.pushViewController(bookViewController, animated: true)
    }

    //MARK:--- User dropdown methods
    func showUserDropdown() {
        let userDropdownViewController = ELUserDropdownViewController()
        userDropdownViewController.modalPresentationStyle = .popover
        userDropdownViewController.preferredContentSize = CGSize(width: 140, height: 116)
        userDropdownViewController.delegate = self.viewController
        userDropdownViewController.view.tag = Constants.ViewTag.USER_DROPDOWN_VIEW_TAG

        let popoverPresentationViewController = userDropdownViewController.popoverPresentationController
        popoverPresentationViewController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
        popoverPresentationViewController?.sourceView = viewController.view

        let frame = viewController.userDropdownView.convert(viewController.userDropdownView.center, to: viewController.view)

        popoverPresentationViewController?.sourceRect = CGRect(x: (frame.x -  viewController.userDropdownView.frame.size.width / 2) - 3, y: frame.y - 23, width: 147, height: viewController.userDropdownView.frame.size.height)
        self.viewController.present(userDropdownViewController, animated: true, completion: nil)
        userDropdownViewController.firstName = viewController.userProfileModel?.firstname
        userDropdownViewController.lastName  = viewController.userProfileModel?.lastname

        userDropdownViewController.firstNameLabel.accessibilityIdentifier = "el.bookshelf.header.user-dropdown.user-first-name"
        userDropdownViewController.firstNameLabel.accessibilityLabel = "First name"
        userDropdownViewController.firstNameLabel.accessibilityValue = userDropdownViewController.firstName ?? ""
        userDropdownViewController.lastNameLabel.accessibilityIdentifier = "el.bookshelf.header.user-dropdown.user-last-name"
        userDropdownViewController.lastNameLabel.accessibilityLabel = "Last name"
        userDropdownViewController.lastNameLabel.accessibilityValue = userDropdownViewController.lastName ?? ""
        userDropdownViewController.about.accessibilityIdentifier = "el.bookshelf.header.user-dropdown.about"
        userDropdownViewController.about.accessibilityLabel = "About"
        userDropdownViewController.about.accessibilityHint = "Opens about application options"
        userDropdownViewController.signOut.accessibilityIdentifier = "el.bookshelf.header.user-dropdown.signout"
        userDropdownViewController.signOut.accessibilityLabel = "Sign Out"
        userDropdownViewController.signOut.accessibilityHint = "Signs out of the application"
    }

    func showUserNotification() {
        let storyBoard = UIStoryboard(name: "UserNotification", bundle: Bundle.main)
        let usernotificationViewController = storyBoard.instantiateViewController(withIdentifier: "user_notification_view") as! UserNotificationViewController

        usernotificationViewController.modalPresentationStyle = .overFullScreen
        usernotificationViewController.modalTransitionStyle = .crossDissolve

        self.viewController.present(usernotificationViewController, animated: true)
        usernotificationViewController.popoverPresentationController?.sourceView = self.viewController.view
        usernotificationViewController.popoverPresentationController?.sourceRect = self.viewController.view.frame
    }

    //MARK:--- About Methods
    func showAbout() {
        let storyboard = UIStoryboard(name: "About", bundle: Bundle.main)
        let aboutViewController = storyboard.instantiateViewController(withIdentifier: "about_view_controller") as! AboutViewController

        aboutViewController.delegate = self.viewController
        aboutViewController.view.tag = Constants.ViewTag.ABOUT_VIEW_TAG

        viewController.addChild(aboutViewController)
        viewController.view.addSubview(aboutViewController.view)
        aboutViewController.didMove(toParent: self.viewController)
    }

    func hideAbout() {
        UIApplication.shared.delegate?.window??.viewWithTag(Constants.ViewTag.ABOUT_VIEW_TAG)?.removeFromSuperview()
    }    
}
