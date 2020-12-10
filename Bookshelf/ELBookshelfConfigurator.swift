//
//  ELBookshelfConfigurator.swift

class ELBookshelfConfigurator {

    //MARK:- Properties
    static let sharedInstance = ELBookshelfConfigurator()


    //MARK:- Methods
    func configure(viewController: ELBookshelfViewController) {
        
        let router = ELBookshelfRouter()
        router.viewController = viewController

        let presenter = ELBookshelfPresenter()
        presenter.viewController = viewController
        presenter.offlineManifestStore = OfflineManifestStore()
        presenter.reachability = AppDelegate.reachability

        let interactor = ELBookshelfInteractor()
        interactor.presenter = presenter

        if let aggregationEndpoint = APIEndpoints().getEndpoint(forService: .aggregationService), let _url = URL(string: aggregationEndpoint) {
            interactor.bookshelfQueryWorker = BookshelfQueryWorker(graphQLInterface: GraphQLClientInterface(serviceUrl: _url))
        } else {
            ConsoleLog.error("Bookshelf Query Worker not initiailzed!!")
        }

        interactor.multiBookProfileWorker = MultiBookProfileWorker()
        interactor.bookshelfDataStore = BookshelfDataStore()
        interactor.bookCoverImageCacheType = BookCoverCacheType.disk
        interactor.reachability = AppDelegate.reachability

        let bookSetupWorker = BookSetupWorker()
        bookSetupWorker.assignmentManager = AssignmentManager.sharedInstance
        bookSetupWorker.bookModulesWorker = BookModulesWorker()
        bookSetupWorker.bookMetaDataWorker = BookMetaDataWorker()
        bookSetupWorker.bookProfileWorker = BookProfileWorker(fileSystemManager: FileSystemManager.shared)
        bookSetupWorker.manifestWorker = OfflineManifestWorker()
        bookSetupWorker.tocWorker = TableOfContentsWorker()
        bookSetupWorker.glossaryWorker = GlossaryWorker()
        bookSetupWorker.mlgWorker = MLGlossaryXHTMLWorker()
        bookSetupWorker.manifestStore = OfflineManifestStore()
        bookSetupWorker.pageDataStore = PageDataStore()
        bookSetupWorker.fileSystemManager = FileSystemManager.shared
        bookSetupWorker.tocXhtmlWorker = TocXhtmlWorker(fileSystemManager: FileSystemManager.shared)
        bookSetupWorker.packageOpfWorker = PackageOpfWorker(fileSystemManager: FileSystemManager.shared)
        //bookSetupWorker.customBasketDataStore = CustomBasketDataStore(bookId: _book.contextId(), feature: "custombasket")
        interactor.bookSetupWorker = bookSetupWorker

        viewController.interactor = interactor
        viewController.router = router
    }
}
