
import SwiftUI
import Firebase
import FirebaseFunctions
import FirebaseAuth

class UserViewModel: ObservableObject {
    static let shared = UserViewModel()

    @Published var user: User?
    @Published var pods = [Pod]()
    @Published var playlists = [Playlist]()
    @Published var isLoadingPlaylists = false
    @Published var savedPods = [Pod]()
    @Published var reposts = [Repost]()
    @Published var repostsWithPods = [RepostWithPod]()
    @Published var isFollowing = false
    @Published var isCurrentUser = false
    @Published var isFriend = false
    @Published var isLoadingFriendshipStatus = false
    @Published var followRequestSent = false
    @Published var isLoadingFollowRequestStatus = false
    @Published var users = [User]()
    @Published var friends = [User]()
    @Published var actualPodCount = 0
    private let authViewModel: AuthViewModel
    let service = UserService()
    let podService = PodService()
    let repostService = RepostService()
    let blockService = BlockService()
    @Published var searchText = ""

    @Published var following = [User]()
    @Published var followers = [User]()

    @Published var filteredFollowing = [User]()
    @Published var filteredFollowers = [User]()

    @Published var isBlocked = false
    @Published var isBlockedByCurrentUser = false
    @Published var isLoadingBlockStatus = false
    @Published var isUserBlocked = false

    @Published var showRateLimitPopup = false
    @Published var rateLimitMessage = ""

    @Published var isCurrentUserBlockedByThisUser = false
    @Published var isBlockingCheckComplete = false

    @Published var isFollowActionInProgress = false

    @Published var hasMorePods = true
    @Published var isFetchingPods = false
    private var lastPodDocument: DocumentSnapshot?
    let podPageSize = 10

    @Published var hasMoreReposts = true
    @Published var isFetchingReposts = false
    private var lastRepostDocument: DocumentSnapshot?
    let repostPageSize = 10

    @Published var hasMoreSavedPods = true
    @Published var isFetchingSavedPods = false
    private var lastSavedPodDocument: DocumentSnapshot?
    let savedPodPageSize = 10

    private var hasInitiallyLoadedPods = false
    private var hasInitiallyLoadedReposts = false
    private var hasInitiallyLoadedSavedPods = false

    private init() {
        self.authViewModel = AuthViewModel.shared
    }

    init(user: User, authViewModel: AuthViewModel) {
        self.user = user
        self.authViewModel = authViewModel
    }

    func setup(user: User) {
        self.user = user

        if !hasInitiallyLoadedPods {
            self.fetchUserPods()
            hasInitiallyLoadedPods = true
        }

        self.checkIfCurrentUser(user: user)

        if !hasInitiallyLoadedSavedPods {
            self.fetchFirstPageOfSavedPods()
            hasInitiallyLoadedSavedPods = true
        }

    }

    func updateUser(user: User) {
        self.user = user
        checkIfCurrentUser(user: user)
    }

    deinit {
        searchTimerFollowing?.invalidate()
        searchTimerFollowers?.invalidate()
    }


    var shouldShowNoPodsMessage: Bool {
        return pods.isEmpty && !isFetchingPods
    }

    var shouldShowNoRepostsMessage: Bool {
        return repostsWithPods.isEmpty && !isFetchingReposts
    }

    var shouldShowNoSavedPodsMessage: Bool {
        return savedPods.isEmpty && !isFetchingSavedPods && !hasMoreSavedPods
    }

    var searchablePods: [Pod] {
        if searchText.isEmpty {
            return pods
        } else {
            let lowercasedQuery = searchText.lowercased()

            return pods.filter({
                $0.title.lowercased().contains(lowercasedQuery)

            })
        }

    }

    func fetchUserPlaylists (user: User) {
        let uid = user.uid
        isLoadingPlaylists = true
        service.fetchUserPlaylists(uid: uid) { playlists in
            DispatchQueue.main.async {
                self.playlists = playlists
                self.isLoadingPlaylists = false
            }
        }
    }


    func fetchUsers() {
        service.fetchUsers { result in
            switch result {
            case .success(let (users, lastDocument)):
                self.users = users
            case .failure(let error):
            }
        }
    }

    func fetchFriends() {
        guard let user = user else { return }
        service.fetchFriends(withUid: user.uid) { users in
            self.friends = users
        }
    }

    func fetchPods() {
        podService.fetchPods { pods in
            self.pods = pods
        }
    }

    func fetchUserPods() {
        guard let user = user, let uid = user.id else { 
            return 
        }

        podService.fetchPods(withUid: uid) { pods in

            DispatchQueue.main.async {
                self.pods = pods

                for i in 0 ..< pods.count {
                    self.pods[i].user = self.user
                }

            }
        }
    }


    func fetchInitialDataIfNeeded() {
        if !hasInitiallyLoadedPods && !isFetchingPods {
            fetchFirstPageOfUserPods()
        } else {
        }

        if !hasInitiallyLoadedReposts && !isFetchingReposts {
            fetchFirstPageOfUserReposts()
        } else {
        }

        fetchActualPodCount()
    }

    func fetchFirstPageOfUserPods() {
        guard let user = user, let uid = user.id, !isFetchingPods else { return }

        if hasInitiallyLoadedPods && !pods.isEmpty {
            return
        }

        isFetchingPods = true
        hasMorePods = true
        lastPodDocument = nil

        podService.fetchPaginatedUserPods(
            forUid: uid,
            limit: podPageSize,
            lastDocument: nil
        ) { [weak self] pods, lastDocument in
            DispatchQueue.main.async {
                guard let self = self else { return }

                var podsWithUser = pods
                for i in 0..<podsWithUser.count {
                    podsWithUser[i].user = self.user
                }

                self.pods = podsWithUser
                self.lastPodDocument = lastDocument
                self.hasMorePods = lastDocument != nil && pods.count >= self.podPageSize
                self.isFetchingPods = false
                self.hasInitiallyLoadedPods = true

            }
        }
    }

    func fetchNextPageOfUserPods() {
        guard let user = user, let uid = user.id,
              let lastDocument = lastPodDocument,
              !isFetchingPods,
              hasMorePods else { return }

        isFetchingPods = true

        podService.fetchPaginatedUserPods(
            forUid: uid,
            limit: podPageSize,
            lastDocument: lastDocument
        ) { [weak self] newPods, lastDocument in
            DispatchQueue.main.async {
                guard let self = self else { return }

                var newPodsWithUser = newPods
                for i in 0..<newPodsWithUser.count {
                    newPodsWithUser[i].user = self.user
                }

                self.pods.append(contentsOf: newPodsWithUser)
                self.lastPodDocument = lastDocument
                self.hasMorePods = lastDocument != nil && newPods.count >= self.podPageSize
                self.isFetchingPods = false

            }
        }
    }

    func refreshUserPods() {
        pods = []
        hasMorePods = true
        lastPodDocument = nil
        hasInitiallyLoadedPods = false
        fetchFirstPageOfUserPods()
    }


    func fetchFirstPageOfUserReposts() {
        guard let user = user, let uid = user.id, !isFetchingReposts else { return }

        if hasInitiallyLoadedReposts && !repostsWithPods.isEmpty {
            return
        }

        isFetchingReposts = true
        hasMoreReposts = true
        lastRepostDocument = nil

        repostService.fetchPaginatedUserRepostsWithPods(
            userId: uid,
            limit: repostPageSize,
            lastDocument: nil
        ) { [weak self] repostsWithPods, lastDocument in
            DispatchQueue.main.async {
                guard let self = self else { return }

                self.repostsWithPods = repostsWithPods
                self.lastRepostDocument = lastDocument
                self.hasMoreReposts = lastDocument != nil && repostsWithPods.count >= self.repostPageSize
                self.isFetchingReposts = false
                self.hasInitiallyLoadedReposts = true

            }
        }
    }

    func fetchNextPageOfUserReposts() {
        guard let user = user, let uid = user.id,
              let lastDocument = lastRepostDocument,
              !isFetchingReposts,
              hasMoreReposts else { return }

        isFetchingReposts = true

        repostService.fetchPaginatedUserRepostsWithPods(
            userId: uid,
            limit: repostPageSize,
            lastDocument: lastDocument
        ) { [weak self] newRepostsWithPods, lastDocument in
            DispatchQueue.main.async {
                guard let self = self else { return }

                self.repostsWithPods.append(contentsOf: newRepostsWithPods)
                self.lastRepostDocument = lastDocument
                self.hasMoreReposts = lastDocument != nil && newRepostsWithPods.count >= self.repostPageSize
                self.isFetchingReposts = false

            }
        }
    }

    func refreshUserReposts() {
        repostsWithPods = []
        hasMoreReposts = true
        lastRepostDocument = nil
        hasInitiallyLoadedReposts = false
        fetchFirstPageOfUserReposts()
    }

    func fetchUserSavedPods() {
        guard let user = user else { return }
        let uid = user.uid

        podService.fetchSavedPods(withUid: uid) { pods in
            self.savedPods = pods

            for i in 0 ..< pods.count {
                let pod = self.savedPods[i]
                if pod.user == nil && !pod.userId.isEmpty {
                    self.service.fetchUser(withUid: pod.userId) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let user):
                                if i < self.savedPods.count {
                                    self.savedPods[i].user = user
                                }
                            case .failure(let error):
                            }
                        }
                    }
                }
            }

        }
    }


    func fetchFirstPageOfSavedPods() {
        guard !isFetchingSavedPods else { return }
        guard let user = user else { return }

        let uid = user.uid

        isFetchingSavedPods = true
        hasMoreSavedPods = true
        lastSavedPodDocument = nil

        podService.fetchPaginatedSavedPods(
            forUid: uid,
            limit: savedPodPageSize,
            lastDocument: nil
        ) { [weak self] pods, lastDocument in
            DispatchQueue.main.async {
                guard let self = self else { return }

                var podsWithUsers = pods
                for i in 0..<podsWithUsers.count {
                    let pod = podsWithUsers[i]
                    if pod.user == nil && !pod.userId.isEmpty {
                        self.service.fetchUser(withUid: pod.userId) { result in
                            DispatchQueue.main.async {
                                switch result {
                                case .success(let user):
                                    if i < podsWithUsers.count {
                                        podsWithUsers[i].user = user
                                    }
                                case .failure(let error):
                                }
                            }
                        }
                    }
                }

                self.savedPods = podsWithUsers
                self.lastSavedPodDocument = lastDocument
                self.hasMoreSavedPods = lastDocument != nil && pods.count >= self.savedPodPageSize
                self.isFetchingSavedPods = false

            }
        }
    }

    func fetchNextPageOfSavedPods() {
        guard let lastDocument = lastSavedPodDocument,
              !isFetchingSavedPods,
              hasMoreSavedPods else { return }
        guard let user = user else { return }

        let uid = user.uid

        isFetchingSavedPods = true

        podService.fetchPaginatedSavedPods(
            forUid: uid,
            limit: savedPodPageSize,
            lastDocument: lastDocument
        ) { [weak self] newPods, lastDocument in
            DispatchQueue.main.async {
                guard let self = self else { return }

                var newPodsWithUsers = newPods
                for i in 0..<newPodsWithUsers.count {
                    let pod = newPodsWithUsers[i]
                    if pod.user == nil && !pod.userId.isEmpty {
                        self.service.fetchUser(withUid: pod.userId) { result in
                            DispatchQueue.main.async {
                                switch result {
                                case .success(let user):
                                    if i < newPodsWithUsers.count {
                                        newPodsWithUsers[i].user = user
                                    }
                                case .failure(let error):
                                }
                            }
                        }
                    }
                }

                self.savedPods.append(contentsOf: newPodsWithUsers)
                self.lastSavedPodDocument = lastDocument
                self.hasMoreSavedPods = lastDocument != nil && newPods.count >= self.savedPodPageSize
                self.isFetchingSavedPods = false

            }
        }
    }

    func refreshSavedPods() {
        fetchFirstPageOfSavedPods()
    }

    func fetchUserReposts() {
        guard let user = user, let uid = user.id else { return }
        repostService.fetchUserRepostsWithPods(userId: uid) { repostsWithPods in
            self.repostsWithPods = repostsWithPods
        }
    }

    func removeOrphanedSavedPod(podId: String) {
        podService.removeOrphanedSavedPod(podId: podId) {
            DispatchQueue.main.async {
                self.savedPods.removeAll { $0.id == podId }
            }
        }
    }

    func removeOrphanedRepost(podId: String) {
        repostService.removeOrphanedRepost(podId: podId) {
            DispatchQueue.main.async {
                self.repostsWithPods.removeAll { $0.repost.podId == podId }
            }
        }
    }


    func bulkDeletePods(podIds: [String], progressCallback: ((Int, Int) -> Void)? = nil, completion: @escaping (Bool) -> Void) {
        guard !podIds.isEmpty else {
            completion(false)
            return
        }


        Task {
            var successfulDeletes = 0
            var failedDeletes = 0
            let totalPods = podIds.count

            for (index, podId) in podIds.enumerated() {
                guard let pod = pods.first(where: { $0.id == podId }) else {
                    failedDeletes += 1
                    continue
                }


                let podViewModel = PodViewModel(pod: pod)
                let deletionSuccess = await withCheckedContinuation { continuation in
                    podViewModel.deletePod {
                        continuation.resume(returning: true)
                    }
                }

                if deletionSuccess {
                    successfulDeletes += 1

                    await MainActor.run {
                        self.pods.removeAll { $0.id == podId }
                    }
                } else {
                    failedDeletes += 1
                }

                await MainActor.run {
                    progressCallback?(successfulDeletes + failedDeletes, totalPods)
                }
            }

            let overallSuccess = successfulDeletes > 0 && failedDeletes == 0

            await MainActor.run {
                completion(overallSuccess)
            }
        }
    }

    func followUser() {
        guard let user = user else { return }

        isFollowActionInProgress = true

        withAnimation {
            if user.isPrivate == true {
                followRequestSent = true
            } else {
                isFollowing = true
                self.user?.didFollow = true
                self.user?.followers = (self.user?.followers ?? 0) + 1
            }
        }

        if user.isPrivate == true {
            service.sendFollowRequest(to: user) { [weak self] success in
                DispatchQueue.main.async {
                    if success {
                        self?.isFollowActionInProgress = false
                    } else {
                        withAnimation {
                            self?.followRequestSent = false
                        }
                        self?.isFollowActionInProgress = false
                    }
                }
            }
        } else {
            service.followUser(user: user) { [weak self] success, errorMessage in
                DispatchQueue.main.async {
                    if success {
                        self?.isFollowActionInProgress = false
                        if let user = self?.user {
                            self?.checkIfUsersAreFriends(user: user)
                        }
                    } else {
                        withAnimation {
                            self?.isFollowing = false
                            self?.user?.didFollow = false
                            self?.user?.followers = max(0, (self?.user?.followers ?? 1) - 1)
                        }
                        self?.isFollowActionInProgress = false

                        if errorMessage == "RATE_LIMITED" {
                            self?.showRateLimitMessage()
                        }
                    }
                }
            }
        }
    }

    func unfollowUser() {
        guard let currentUser = user else { return }

        isFollowActionInProgress = true

        let wasFollowing = isFollowing
        let wasRequestSent = followRequestSent
        let previousFollowers = currentUser.followers

        withAnimation {
            if currentUser.isPrivate == true && followRequestSent {
                followRequestSent = false
            } else {
                isFollowing = false
                self.user?.didFollow = false
                self.user?.followers = max(0, (self.user?.followers ?? 1) - 1)
            }
        }

        if currentUser.isPrivate == true && wasRequestSent {
            service.cancelFollowRequest(to: currentUser) { [weak self] success in
                DispatchQueue.main.async {
                    if success {
                        self?.isFollowActionInProgress = false
                    } else {
                        withAnimation {
                            self?.followRequestSent = wasRequestSent
                        }
                        self?.isFollowActionInProgress = false
                    }
                }
            }
        } else {
            service.unfollowUser(user: currentUser) { [weak self] success, errorMessage in
                DispatchQueue.main.async {
                    if success {
                        self?.isFollowActionInProgress = false
                        if let user = self?.user {
                            self?.checkIfUsersAreFriends(user: user)
                        }
                    } else {
                        withAnimation {
                            self?.isFollowing = wasFollowing
                            self?.user?.didFollow = wasFollowing
                            self?.user?.followers = previousFollowers
                        }
                        self?.isFollowActionInProgress = false

                        if errorMessage == "RATE_LIMITED" {
                            self?.showRateLimitMessage()
                        }
                    }
                }
            }
        }
    }


    func showRateLimitMessage() {
        rateLimitMessage = "You've followed/unfollowed this user too many times. Please wait 10 minutes before trying again."
        showRateLimitPopup = true
    }


    func removeFollower(user: User, completion: @escaping(Bool) -> Void) {
        guard let currentUser = self.user else { return }

        isFollowActionInProgress = true

        let previousFollowers = currentUser.followers

        withAnimation {
            self.user?.followers = max(0, (self.user?.followers ?? 1) - 1)
        }

        service.removeFollower(user: user) { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.isFollowActionInProgress = false
                    completion(true)
                } else {
                    withAnimation {
                        self?.user?.followers = previousFollowers
                    }
                    self?.isFollowActionInProgress = false
                    completion(false)
                }
            }
        }
    }


    func unfollowSpecificUser(user: User, completion: @escaping(Bool) -> Void) {
        guard let currentUser = self.user else { return }

        isFollowActionInProgress = true

        let previousFollowing = currentUser.following

        withAnimation {
            self.user?.following = max(0, (self.user?.following ?? 1) - 1)
        }

        service.unfollowUser(user: user) { [weak self] success, errorMessage in
            DispatchQueue.main.async {
                if success {
                    self?.isFollowActionInProgress = false
                    completion(true)
                } else {
                    withAnimation {
                        self?.user?.following = previousFollowing
                    }
                    self?.isFollowActionInProgress = false

                    if errorMessage == "RATE_LIMITED" {
                        self?.showRateLimitMessage()
                    }

                    completion(false)
                }
            }
        }
    }


    @Published var isLoadingMoreFollowing = false
    @Published var isLoadingFollowing = false
    @Published var hasMoreFollowing = true
    @Published var isSearchPendingFollowing = false
    private var lastFollowingUser: User?
    private let followingPageSize = 10
    private var searchTimerFollowing: Timer?
    private let searchDelay: TimeInterval = 1.0

    func fetchUserFollowing() {
        guard let user = user, let uid = user.id else { return }

        isLoadingFollowing = true

        lastFollowingUser = nil
        hasMoreFollowing = true
        following.removeAll()
        filteredFollowing.removeAll()

        service.fetchUserFollowing(forUid: uid, lastUser: nil, limit: followingPageSize) { users in
            DispatchQueue.main.async {
                self.following = users
                self.filteredFollowing = users.filter { user in
                    let isDeleted = user.isDeleted ?? false
                    let isAnonymous = user.username.lowercased().hasPrefix("anon_")
                    return !isDeleted && !isAnonymous
                }

                if let lastUser = users.last {
                    self.lastFollowingUser = lastUser
                }

                self.hasMoreFollowing = users.count == self.followingPageSize
                self.isLoadingFollowing = false
            }
        }
    }

    func loadMoreFollowing() {
        guard !isLoadingMoreFollowing && hasMoreFollowing else { return }

        let lastUser = lastFollowingUser

        isLoadingMoreFollowing = true

        guard let user = user else { return }
        service.fetchUserFollowing(forUid: user.id ?? "", lastUser: lastUser, limit: followingPageSize) { newUsers in
            let uniqueNewUsers = newUsers.filter { newUser in
                !self.following.contains { existingUser in
                    existingUser.id == newUser.id
                }
            }

            self.following.append(contentsOf: uniqueNewUsers)
            let filteredNewUsers = uniqueNewUsers.filter { user in
                let isDeleted = user.isDeleted ?? false
                let isAnonymous = user.username.lowercased().hasPrefix("anon_")
                return !isDeleted && !isAnonymous
            }
            self.filteredFollowing.append(contentsOf: filteredNewUsers)

            if let lastNewUser = uniqueNewUsers.last {
                self.lastFollowingUser = lastNewUser
            }

            self.hasMoreFollowing = uniqueNewUsers.count == self.followingPageSize
            self.isLoadingMoreFollowing = false
        }
    }

    func performDebouncedSearchFollowing(searchText: String) {
        searchTimerFollowing?.invalidate()

        if searchText.isEmpty {
            filteredFollowing = following.filter { user in
                let isDeleted = user.isDeleted ?? false
                let isAnonymous = user.username.lowercased().hasPrefix("anon_")
                return !isDeleted && !isAnonymous
            }
            isSearchPendingFollowing = false
            return
        }

        isSearchPendingFollowing = true

        searchTimerFollowing = Timer.scheduledTimer(withTimeInterval: searchDelay, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.isSearchPendingFollowing = false
                self?.performSearchFollowing(searchText: searchText)
            }
        }
    }

    private func performSearchFollowing(searchText: String) {
        let lowercasedQuery = searchText.lowercased()

        let loadedMatches = following.filter { user in
            let isDeleted = user.isDeleted ?? false
            let isAnonymous = user.username.lowercased().hasPrefix("anon_")
            let matchesSearch = (user.fullname?.lowercased().contains(lowercasedQuery) ?? false) ||
                               user.username.lowercased().contains(lowercasedQuery)
            return !isDeleted && !isAnonymous && matchesSearch
        }

        if loadedMatches.count >= 10 {
            filteredFollowing = loadedMatches
        } else {
            filteredFollowing = loadedMatches

            if hasMoreFollowing && !isLoadingMoreFollowing {
                loadMoreFollowing()
            }
        }
    }

    func filterFollowing(searchText: String) {
        if searchText.isEmpty {
            filteredFollowing = following.filter { user in
                let isDeleted = user.isDeleted ?? false
                let isAnonymous = user.username.lowercased().hasPrefix("anon_")
                return !isDeleted && !isAnonymous
            }
        } else {
            let lowercasedQuery = searchText.lowercased()

            let loadedMatches = following.filter { user in
                let isDeleted = user.isDeleted ?? false
                let isAnonymous = user.username.lowercased().hasPrefix("anon_")
                let matchesSearch = (user.fullname?.lowercased().contains(lowercasedQuery) ?? false) ||
                                   user.username.lowercased().contains(lowercasedQuery)
                return !isDeleted && !isAnonymous && matchesSearch
            }

            if loadedMatches.count >= 10 {
                filteredFollowing = loadedMatches
            } else {
                filteredFollowing = loadedMatches

                if hasMoreFollowing && !isLoadingMoreFollowing {
                    loadMoreFollowing()
                }
            }
        }
    }


    @Published var isLoadingMoreFollowers = false
    @Published var isLoadingFollowers = false
    @Published var hasMoreFollowers = true
    @Published var isSearchPendingFollowers = false
    private var lastFollowersUser: User?
    private let followersPageSize = 10
    private var searchTimerFollowers: Timer?

    func fetchUserFollowers() {
        guard let user = user, let uid = user.id else { return }

        isLoadingFollowers = true

        lastFollowersUser = nil
        hasMoreFollowers = true
        followers.removeAll()
        filteredFollowers.removeAll()

        service.fetchUserFollowers(forUid: uid, lastUser: nil, limit: followersPageSize) { users in
            DispatchQueue.main.async {
                self.followers = users
                self.filteredFollowers = users.filter { user in
                    let isDeleted = user.isDeleted ?? false
                    let isAnonymous = user.username.lowercased().hasPrefix("anon_")
                    return !isDeleted && !isAnonymous
                }

                if let lastUser = users.last {
                    self.lastFollowersUser = lastUser
                }

                self.hasMoreFollowers = users.count == self.followersPageSize
                self.isLoadingFollowers = false
            }
        }
    }

    func loadMoreFollowers() {
        guard !isLoadingMoreFollowers && hasMoreFollowers else { return }

        let lastUser = lastFollowersUser

        isLoadingMoreFollowers = true

        guard let user = user else { return }
        service.fetchUserFollowers(forUid: user.id ?? "", lastUser: lastUser, limit: followersPageSize) { newUsers in
            let uniqueNewUsers = newUsers.filter { newUser in
                !self.followers.contains { existingUser in
                    existingUser.id == newUser.id
                }
            }

            self.followers.append(contentsOf: uniqueNewUsers)
            let filteredNewUsers = uniqueNewUsers.filter { user in
                let isDeleted = user.isDeleted ?? false
                let isAnonymous = user.username.lowercased().hasPrefix("anon_")
                return !isDeleted && !isAnonymous
            }
            self.filteredFollowers.append(contentsOf: filteredNewUsers)

            if let lastNewUser = uniqueNewUsers.last {
                self.lastFollowersUser = lastNewUser
            }

            self.hasMoreFollowers = uniqueNewUsers.count == self.followersPageSize
            self.isLoadingMoreFollowers = false
        }
    }

    func performDebouncedSearchFollowers(searchText: String) {
        searchTimerFollowers?.invalidate()

        if searchText.isEmpty {
            filteredFollowers = followers.filter { user in
                let isDeleted = user.isDeleted ?? false
                let isAnonymous = user.username.lowercased().hasPrefix("anon_")
                return !isDeleted && !isAnonymous
            }
            isSearchPendingFollowers = false
            return
        }

        isSearchPendingFollowers = true

        searchTimerFollowers = Timer.scheduledTimer(withTimeInterval: searchDelay, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.isSearchPendingFollowers = false
                self?.performSearchFollowers(searchText: searchText)
            }
        }
    }

    private func performSearchFollowers(searchText: String) {
        let lowercasedQuery = searchText.lowercased()

        let loadedMatches = followers.filter { user in
            let isDeleted = user.isDeleted ?? false
            let isAnonymous = user.username.lowercased().hasPrefix("anon_")
            let matchesSearch = (user.fullname?.lowercased().contains(lowercasedQuery) ?? false) ||
                               user.username.lowercased().contains(lowercasedQuery)
            return !isDeleted && !isAnonymous && matchesSearch
        }

        if loadedMatches.count >= 10 {
            filteredFollowers = loadedMatches
        } else {
            filteredFollowers = loadedMatches

            if hasMoreFollowers && !isLoadingMoreFollowers {
                loadMoreFollowers()
            }
        }
    }

    func filterFollowers(searchText: String) {
        if searchText.isEmpty {
            filteredFollowers = followers.filter { user in
                let isDeleted = user.isDeleted ?? false
                let isAnonymous = user.username.lowercased().hasPrefix("anon_")
                return !isDeleted && !isAnonymous
            }
        } else {
            let lowercasedQuery = searchText.lowercased()

            let loadedMatches = followers.filter { user in
                let isDeleted = user.isDeleted ?? false
                let isAnonymous = user.username.lowercased().hasPrefix("anon_")
                let matchesSearch = (user.fullname?.lowercased().contains(lowercasedQuery) ?? false) ||
                                   user.username.lowercased().contains(lowercasedQuery)
                return !isDeleted && !isAnonymous && matchesSearch
            }

            if loadedMatches.count >= 10 {
                filteredFollowers = loadedMatches
            } else {
                filteredFollowers = loadedMatches

                if hasMoreFollowers && !isLoadingMoreFollowers {
                    loadMoreFollowers()
                }
            }
        }
    }

    func checkIfUserIsFollowed(user: User) {
        service.checkIfUserIsFollowed(user: user) { didFollow in
            DispatchQueue.main.async {
                self.isFollowing = didFollow
                if didFollow {
                    self.user?.didFollow = true
                }
            }
        }
    }

    func editProfile(fullname: String, username: String, bio: String, link: String) {
        guard let user = user else { return }
        service.editProfile(withUid: user.uid, fullname: fullname, username: username, bio: bio, link: link) { _ in

        }
    }

    func checkUsername(username: String, completion: @escaping(Bool) -> Void) {
        service.isUsernameInUse(username: username) { bool in
            completion(bool)
        }
    }

    func changeUsernameAndProfile(newUsername: String, fullname: String, bio: String, link: String, completion: @escaping (Bool, Error?) -> Void) {
        let functions = Functions.functions()
        let changeUsername = functions.httpsCallable("changeUsername")

        guard let user = user else { return }
        let data: [String: Any] = [
            "newUsername": newUsername,
            "currentUsername": user.username
        ]

        changeUsername.call(data) { [weak self] result, error in
            if let error = error {
                completion(false, error)
                return
            }

            self?.service.editProfile(withUid: self?.user?.uid ?? "", fullname: fullname, username: newUsername, bio: bio, link: link) { result in
                switch result {
                case .success(let updatedUser):
                    DispatchQueue.main.async {
                        self?.user = updatedUser

                        self?.objectWillChange.send()

                    }
                    completion(true, nil)
                case .failure(let error):
                    completion(false, error)
                }
            }
        }
    }

    func deleteUsername(username: String) {
        service.deleteUsername(username: username)
    }

    func addUsername(username: String) {
        service.addUsername(username: username)
    }

    var isFollowed: Bool {
        return user?.didFollow ?? false
        }

    func toggleFollow() {
        guard let user = user else { return }
        if user.isPrivate == true {
            if followRequestSent {
                unfollowUser()
            } else if isFollowing {
                unfollowUser()
            } else {
                followUser()
            }
        } else {
            if isFollowing {
                unfollowUser()
            } else {
                followUser()
            }
        }
    }

    func createPlaylist(title: String, podIds: [String], thumbnailUrl: String, description: String? = nil) {
        service.createPlaylist(title: title, podIds: podIds, thumbnailUrl: thumbnailUrl, description: description) { success, error in

        }

    }

    func checkIfCurrentUser(user: User) {
        guard let currentUserId = authViewModel.currentUser?.id else {
            isCurrentUser = false
            return
        }

        isCurrentUser = (user.id == currentUserId)
    }

    func checkIfUsersAreFriends(user: User) {
        service.checkIfUsersAreFriends(withUid: user.uid) { isFriend in
            DispatchQueue.main.async {
                self.isFriend = isFriend
                self.isLoadingFriendshipStatus = false
            }
        }
    }

    func checkIfFollowRequestSent(user: User) {
        service.checkIfFollowRequestSent(to: user) { sent in
            DispatchQueue.main.async {
                self.followRequestSent = sent
                self.isLoadingFollowRequestStatus = false
            }
        }
    }

    func fetchActualPodCount() {
        guard let user = user else { return }
        service.countUserPods(withUid: user.uid) { count in
            DispatchQueue.main.async {
                self.actualPodCount = count
            }
        }
    }


    func checkBlockStatus(user: User) {

        guard let currentUid = Auth.auth().currentUser?.uid else { 
            return 
        }


        let group = DispatchGroup()

        group.enter()
        blockService.checkIfUserIsBlocked(userId: user.uid) { isBlocked in
            DispatchQueue.main.async {
                self.isBlockedByCurrentUser = isBlocked
                self.isUserBlocked = isBlocked
            }
            group.leave()
        }

        group.enter()
        blockService.accurateCheckIfCurrentUserIsBlocked(by: user.uid) { isBlocked in
            DispatchQueue.main.async {
                self.isBlocked = isBlocked
                self.isCurrentUserBlockedByThisUser = isBlocked
            }
            group.leave()
        }

        group.notify(queue: .main) {
            self.isLoadingBlockStatus = false
            self.isBlockingCheckComplete = true

            if !self.isCurrentUserBlockedByThisUser && !self.isUserBlocked {
                self.fetchActualPodCount()
                self.fetchFirstPageOfUserPods()
                self.fetchFirstPageOfUserReposts()

                self.checkIfUserIsFollowed(user: user)
                self.checkIfFollowRequestSent(user: user)
            } else {
            }
        }
    }

    func blockUser(completion: @escaping (Bool) -> Void) {
        guard let user = user else { return }

        blockService.blockUser(userId: user.uid) { success in
            DispatchQueue.main.async {
                if success {
                    self.isBlockedByCurrentUser = true
                    self.isUserBlocked = true
                } else {
                }
                completion(success)
            }
        }
    }

    func unblockUser(completion: @escaping (Bool) -> Void) {
        guard let user = user else { return }

        blockService.unblockUser(userId: user.uid) { success in
            DispatchQueue.main.async {
                if success {
                    self.isBlockedByCurrentUser = false
                    self.isUserBlocked = false
                } else {
                }
                completion(success)
            }
        }
    }

}
