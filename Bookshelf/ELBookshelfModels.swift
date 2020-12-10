//
//  ELBookshelfModels.swift

struct ELBookshelf {
    struct UserProfile {
        struct Response {
            var firstname: String
            var lastname: String
            var avatar: String
        }

        struct ViewModel {
            var firstname: String
            var lastname: String
            var avatarImageName: String
        }
    }
}
