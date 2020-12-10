//
//  ELBookshelfInteractor.swift
protocol ELBookshelfInteraction: BookshelfInteraction {
    func setupUserDropdown()
}

class ELBookshelfInteractor: BookshelfInteractor, ELBookshelfInteraction {

    //AMRK:- Properties
    var _presenter: ELBookshelfPresentation? {
        return presenter as? ELBookshelfPresentation
    }

    //MARK:- Interactor Methods
    func setupUserDropdown() {
        guard let _userSession = StoredProperties.User.userSession, let _firstname = _userSession.user.firstname, let _lastname = _userSession.user.lastname else {
            return
        }

        let userProfileResponse = ELBookshelf.UserProfile.Response(firstname: _firstname, lastname: _lastname, avatar: _userSession.user.avatar)
        _presenter?.formatContentForUserDropdown(response: userProfileResponse)
    }
}
