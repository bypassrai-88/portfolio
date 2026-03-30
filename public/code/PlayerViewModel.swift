
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

@MainActor
class PlayerViewModel: ObservableObject {
    static let shared = PlayerViewModel()

    @Published var recommendedPods: [Pod] = []
    @Published var isFetching = false
    @Published var hasLoadedPods = false
    @Published var hasLoadedPreferences = false
    @Published var isUserDataLoading = false

    private var podViewModels: [String: PodViewModel] = [:]
    @Published var lastSnapshot: DocumentSnapshot?
    private var cachedQueryCategories: [String] = []
    private let pageSize = 8

    private var recommendedPodsCache: [String: [Pod]] = [:]
    private var recommendedPodsLastFetch: [String: Date] = [:]
    private let cacheExpirationInterval: TimeInterval = 120

    private let recommendedPodsPageSize = 10

    private var userPreferencesViewModel: UserPreferencesViewModel?

    private init() {
    }

    func setup(userPreferencesViewModel: UserPreferencesViewModel) {
        self.userPreferencesViewModel = userPreferencesViewModel
    }


    private func isCacheValid(for podId: String) -> Bool {
        guard let lastFetch = recommendedPodsLastFetch[podId] else { return false }
        return Date().timeIntervalSince(lastFetch) < cacheExpirationInterval
    }

    func clearCache(for podId: String) {
        recommendedPodsCache.removeValue(forKey: podId)
        recommendedPodsLastFetch.removeValue(forKey: podId)
    }

    func clearAllCaches() {
        recommendedPodsCache.removeAll()
        recommendedPodsLastFetch.removeAll()
    }

    func forceRefreshRecommendedPods(for currentPod: Pod) {
        guard let podId = currentPod.id else { return }

        clearCache(for: podId)

        hasLoadedPods = false
        isFetching = false

        cachedQueryCategories = []

        recommendedPods = []

        fetchFirstPageOfRecommendedPods(for: currentPod)
    }

    func getCacheStats() -> String {
        let cacheCount = recommendedPodsCache.count
        let cacheKeys = Array(recommendedPodsCache.keys)
        let oldestCache = recommendedPodsLastFetch.values.min()
        let newestCache = recommendedPodsLastFetch.values.max()

        return """
        🎯 [PlayerViewModel] Cache Stats:
        - Cached pods: \(cacheCount)
        - Cache keys: \(cacheKeys.joined(separator: ", "))
        - Oldest cache: \(oldestCache?.description ?? "none")
        - Newest cache: \(newestCache?.description ?? "none")
        """
    }

    func hasCachedData(for podId: String) -> Bool {
        return recommendedPodsCache[podId] != nil && isCacheValid(for: podId)
    }


    func loadPreferences(for pod: Pod) async {
        guard !hasLoadedPreferences else { return }

        if let category = pod.category, !category.isEmpty, let keywords = pod.keywords, !keywords.isEmpty {
            if let userId = Auth.auth().currentUser?.uid {
                await userPreferencesViewModel?.handlePodInteraction(pod: pod, userId: userId)
            }
            self.cachedQueryCategories = self.generateQueryCategories(for: pod)
            self.hasLoadedPreferences = true
        } else {
            self.cachedQueryCategories = self.generateQueryCategories(for: pod)
            self.hasLoadedPreferences = true
        }
    }

    func fetchFirstPageOfRecommendedPods(for currentPod: Pod) {
        guard let podId = currentPod.id else { return }


        if let cachedPods = recommendedPodsCache[podId],
           let lastFetch = recommendedPodsLastFetch[podId],
           Date().timeIntervalSince(lastFetch) < cacheExpirationInterval {
            self.recommendedPods = cachedPods
            self.hasLoadedPods = true
            return
        }

        guard !isFetching && !hasLoadedPods else { 
            return 
        }
        isFetching = true

        let queryCategories = cachedQueryCategories.isEmpty ? generateQueryCategories(for: currentPod) : cachedQueryCategories
        let db = Firestore.firestore()
        let podsCollection = db.collection("pods")


        if queryCategories.count <= 10 {
            executeSingleCategoryQuery(podsCollection: podsCollection, categories: queryCategories, currentPod: currentPod)
        } else {
            executeChunkedCategoryQuery(podsCollection: podsCollection, categories: queryCategories, currentPod: currentPod)
        }
    }

    private func executeSingleCategoryQuery(podsCollection: CollectionReference, categories: [String], currentPod: Pod) {
        let query = podsCollection
            .whereField("category", in: categories as [Any])
            .limit(to: recommendedPodsPageSize)

        executeQuery(query: query, currentPod: currentPod)
    }

    private func executeChunkedCategoryQuery(podsCollection: CollectionReference, categories: [String], currentPod: Pod) {
        let chunks = chunkArray(categories, into: 10)

        let group = DispatchGroup()
        var allPods: [Pod] = []
        var allDocuments: [QueryDocumentSnapshot] = []

        for (index, chunk) in chunks.enumerated() {
            group.enter()

            let query = podsCollection
                .whereField("category", in: chunk as [Any])
                .limit(to: recommendedPodsPageSize)

            query.getDocuments { [weak self] snapshot, error in
                defer { group.leave() }

                if let error = error {
                    return
                }

                if let documents = snapshot?.documents {

                    for document in documents {
                        if var pod = try? document.data(as: Pod.self) {
                            pod.id = document.documentID
                            allPods.append(pod)
                            allDocuments.append(document)
                        }
                    }
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }

            let uniquePods = Array(Set(allPods.map { $0.id ?? "" })).compactMap { podId in
                allPods.first { $0.id == podId }
            }.filter { $0.id != currentPod.id }

            let sortedPods = uniquePods.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
            let finalPods = Array(sortedPods.prefix(self.recommendedPodsPageSize))


            Task { @MainActor in
                for pod in finalPods {
                    _ = self.getOrCreateViewModel(for: pod)
                }
                self.recommendedPods = finalPods
                self.lastSnapshot = allDocuments.last

                self.recommendedPodsCache[currentPod.id ?? ""] = finalPods
                self.recommendedPodsLastFetch[currentPod.id ?? ""] = Date()
            }

            self.isFetching = false
            self.hasLoadedPods = true
        }
    }

    private func executeQuery(query: Query, currentPod: Pod) {
        guard let podId = currentPod.id else { return }

        query.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                self.isFetching = false
                return
            }

            if let documents = snapshot?.documents {
                var newPods: [Pod] = []

                for document in documents {
                    if var pod = try? document.data(as: Pod.self) {
                        pod.id = document.documentID
                        newPods.append(pod)
                    }
                }

                newPods = newPods.filter { $0.id != currentPod.id }

                if RecommendationConfig.enableRecommendationDebugging {
                }

                newPods = self.sortPodsByPopularity(newPods)

                newPods = self.diversifyPlayerRecommendations(newPods)

                let finalPods = Array(newPods.prefix(self.recommendedPodsPageSize))

                if RecommendationConfig.enableRecommendationDebugging {
                }

                Task { @MainActor in
                    for pod in finalPods {
                        _ = self.getOrCreateViewModel(for: pod)
                    }
                    self.recommendedPods = finalPods
                    self.lastSnapshot = documents.last

                    self.recommendedPodsCache[podId] = finalPods
                    self.recommendedPodsLastFetch[podId] = Date()

                    if RecommendationConfig.enableRecommendationDebugging {
                    }
                }
            } else {
                self.fetchFallbackPods(for: currentPod)
            }

            self.isFetching = false
            self.hasLoadedPods = true
        }
    }


    func fetchUserForPod(_ pod: Pod) async -> User? {
        let db = Firestore.firestore()
        let userId = pod.userId

        do {
            let document = try await db.collection("users").document(userId).getDocument()
            if document.exists {
                let user = try document.data(as: User.self)
                return user
            }
        } catch {
        }

        return nil
    }

    func getTimeAgo(for pod: Pod) -> String {
        let currentTime = Date()
        let postedTime = pod.timestamp.dateValue()

        let calendar = Calendar.current
        if calendar.isDate(postedTime, inSameDayAs: currentTime) {
            return "today"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: postedTime)
    }


    private func getOrCreateViewModel(for pod: Pod) -> PodViewModel {
        if let existingViewModel = podViewModels[pod.id ?? ""] {
            return existingViewModel
        }
        let viewModel = PodViewModel(pod: pod)
        podViewModels[pod.id ?? ""] = viewModel
        return viewModel
    }

    private func generateQueryCategories(for pod: Pod) -> [String] {
        cachedQueryCategories = []

        let userCategories = userPreferencesViewModel?.getTopCategories(limit: 10) ?? []

        let podCategory = pod.category ?? "Miscellaneous"
        let podKeywords = pod.keywords ?? []
        let podContext = [podCategory] + podKeywords

        let totalQuerySize = 15
        let similarityCount = Int(Double(totalQuerySize) * RecommendationConfig.PlayerRecommendations.currentPodSimilarityWeight)
        let userPrefCount = Int(Double(totalQuerySize) * RecommendationConfig.PlayerRecommendations.userPreferenceWeight)
        let randomCount = totalQuerySize - similarityCount - userPrefCount

        if RecommendationConfig.enableRecommendationDebugging {
        }

        let selectedSimilarityCategories = Array(podContext.prefix(similarityCount))

        let shuffledUserCategories = userCategories.shuffled()
        let selectedUserCategories = Array(shuffledUserCategories.prefix(userPrefCount))

        let allAvailableCategories = AIConfig.validCategories
        let usedCategories = Set(selectedSimilarityCategories + selectedUserCategories)
        let availableRandomCategories = allAvailableCategories.filter { category in
            !usedCategories.contains(category)
        }
        let randomCategories = Array(availableRandomCategories.shuffled().prefix(randomCount))

        let combinedCategories = selectedSimilarityCategories + selectedUserCategories + randomCategories

        if RecommendationConfig.enableRecommendationDebugging {
        }

        return combinedCategories
    }

    private func chunkArray<T>(_ array: [T], into size: Int) -> [[T]] {
        return stride(from: 0, to: array.count, by: size).map {
            Array(array[$0..<min($0 + size, array.count)])
        }
    }

    private func fetchFallbackPods(for currentPod: Pod) {
        guard let podId = currentPod.id else { return }

        let db = Firestore.firestore()
        let podsCollection = db.collection("pods")

        let fallbackQuery = podsCollection
            .limit(to: pageSize)

        fallbackQuery.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                return
            }

            if let documents = snapshot?.documents {
                var newPods: [Pod] = []

                for document in documents {
                    if var pod = try? document.data(as: Pod.self) {
                        pod.id = document.documentID
                        newPods.append(pod)
                    }
                }

                newPods = newPods.filter { $0.id != currentPod.id }

                Task { @MainActor in
                    self.recommendedPods.append(contentsOf: newPods)
                    self.lastSnapshot = snapshot?.documents.last

                    self.recommendedPodsCache[podId] = newPods
                    self.recommendedPodsLastFetch[podId] = Date()
                }
            }
        }
    }


    func startAllLoadingInParallel(for pod: Pod, currentUrl: URL, manager: PlayerManager, viewModel: PodViewModel) {

        DispatchQueue.global(qos: .userInitiated).async {
            manager.play(url: currentUrl, pod: pod)
            Task { @MainActor in
                manager.setupBasicNowPlayingInfo()
            }
        }

        if pod.user == nil {
            Task {
                let user = await self.fetchUserForPod(pod)
                await MainActor.run {
                    var updatedPod = pod
                    updatedPod.user = user
                    viewModel.pod = updatedPod
                    viewModel.refreshSaveState()

                    manager.currentPod = updatedPod

                    if let user = user {
                        manager.setNowPlayingInfoWithPod(updatedPod, user: user)
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.isUserDataLoading = false
                    }
                }
            }
        } else {
            viewModel.refreshSaveState()
            self.isUserDataLoading = false
        }

        if !hasLoadedPreferences {
            Task {
                await self.loadPreferences(for: pod)
            }
        }

        if !hasLoadedPods && !isFetching {
            self.fetchFirstPageOfRecommendedPods(for: pod)
        }

    }


    private func sortPodsByPopularity(_ pods: [Pod]) -> [Pod] {
        if RecommendationConfig.Diversification.enablePopularityTierShuffling {
            return sortPodsByPopularityTiers(pods)
        } else {
            return sortPodsByPopularityWithRandomness(pods)
        }
    }

    private func sortPodsByPopularityWithRandomness(_ pods: [Pod]) -> [Pod] {
        let randomnessFactor = RecommendationConfig.Diversification.popularityRandomnessFactor

        return pods.sorted { pod1, pod2 in
            let score1 = RecommendationConfig.calculatePopularityScore(
                likes: pod1.likes,
                views: pod1.views,
                shares: pod1.shares,
                saves: pod1.saves,
                comments: pod1.comments,
                createdAt: pod1.createdAt?.dateValue()
            )

            let score2 = RecommendationConfig.calculatePopularityScore(
                likes: pod2.likes,
                views: pod2.views,
                shares: pod2.shares,
                saves: pod2.saves,
                comments: pod2.comments,
                createdAt: pod2.createdAt?.dateValue()
            )

            let randomBonus1 = Double.random(in: 0...score1) * randomnessFactor
            let randomBonus2 = Double.random(in: 0...score2) * randomnessFactor

            let finalScore1 = score1 + randomBonus1
            let finalScore2 = score2 + randomBonus2

            if finalScore1 != finalScore2 {
                return finalScore1 > finalScore2
            }

            return pod1.timestamp.dateValue() > pod2.timestamp.dateValue()
        }
    }

    private func sortPodsByPopularityTiers(_ pods: [Pod]) -> [Pod] {
        let podsWithScores = pods.map { pod in
            let score = RecommendationConfig.calculatePopularityScore(
                likes: pod.likes,
                views: pod.views,
                shares: pod.shares,
                saves: pod.saves,
                comments: pod.comments,
                createdAt: pod.createdAt?.dateValue()
            )
            return (pod: pod, score: score)
        }

        let allScores = podsWithScores.map { $0.score }.sorted(by: >)
        guard !allScores.isEmpty else { return pods }

        let maxScore = allScores.first ?? 0
        let minScore = allScores.last ?? 0
        let scoreRange = maxScore - minScore

        let highTierThreshold = maxScore - (scoreRange * 0.33)
        let mediumTierThreshold = maxScore - (scoreRange * 0.67)

        var highTierPods: [Pod] = []
        var mediumTierPods: [Pod] = []
        var lowTierPods: [Pod] = []

        for (pod, score) in podsWithScores {
            if score >= highTierThreshold {
                highTierPods.append(pod)
            } else if score >= mediumTierThreshold {
                mediumTierPods.append(pod)
            } else {
                lowTierPods.append(pod)
            }
        }

        if RecommendationConfig.enableRecommendationDebugging {
        }

        let shuffledHighTier = highTierPods.shuffled()
        let shuffledMediumTier = mediumTierPods.shuffled()
        let shuffledLowTier = lowTierPods.shuffled()

        return shuffledHighTier + shuffledMediumTier + shuffledLowTier
    }

    private func diversifyPlayerRecommendations(_ pods: [Pod]) -> [Pod] {
        guard RecommendationConfig.Diversification.enableSmartShuffling else {
            return pods
        }

        var optimizedPods = pods
        let maxSameCategory = RecommendationConfig.Diversification.maxConsecutiveSameCategory
        let maxSameUser = RecommendationConfig.Diversification.maxConsecutiveSameUser

        var lastCategory: String? = nil
        var lastUserId: String? = nil
        var consecutiveCategoryCount = 0
        var consecutiveUserCount = 0

        var i = 0
        while i < optimizedPods.count - 1 {
            let currentPod = optimizedPods[i]
            let currentCategory = currentPod.category
            let currentUserId = currentPod.userId

            if currentCategory == lastCategory {
                consecutiveCategoryCount += 1
            } else {
                consecutiveCategoryCount = 1
                lastCategory = currentCategory
            }

            if currentUserId == lastUserId {
                consecutiveUserCount += 1
            } else {
                consecutiveUserCount = 1
                lastUserId = currentUserId
            }

            if consecutiveCategoryCount > maxSameCategory || consecutiveUserCount > maxSameUser {
                if let swapIndex = findDiversePodInRecommendations(
                    in: optimizedPods,
                    startingFrom: i + 1,
                    avoidingCategory: currentCategory,
                    avoidingUser: currentUserId
                ) {
                    optimizedPods.swapAt(i + 1, swapIndex)

                    if RecommendationConfig.enableRecommendationDebugging {
                    }

                    consecutiveCategoryCount = 1
                    consecutiveUserCount = 1
                }
            }

            i += 1
        }

        return optimizedPods
    }

    private func findDiversePodInRecommendations(
        in pods: [Pod],
        startingFrom index: Int,
        avoidingCategory: String?,
        avoidingUser: String
    ) -> Int? {
        for i in index..<pods.count {
            let pod = pods[i]
            if pod.category != avoidingCategory && pod.userId != avoidingUser {
                return i
            }
        }
        return nil
    }
}
