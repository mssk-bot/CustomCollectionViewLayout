//
//  ELBookshelfPresenter.swift

protocol ELBookshelfPresentation: class, BookshelfPresentation {
    func formatContentForUserDropdown(response: ELBookshelf.UserProfile.Response)
}

class ELBookshelfPresenter: BookshelfPresenter, ELBookshelfPresentation {

    //MARK:- Properties
    var _viewController: ELBookshelfViewControllerInput? {
        return viewController as? ELBookshelfViewControllerInput
    }

    //MARK:- Presenter Methods
    func formatContentForUserDropdown(response: ELBookshelf.UserProfile.Response) {

        let userProfile = ELBookshelf.UserProfile.ViewModel(firstname: response.firstname,
                                                            lastname: response.lastname,
                                                            avatarImageName: response.avatar)

        _viewController?.populateUserDropdown(viewModel: userProfile)
    }
}
