

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFunctions
import SwiftUI
import FirebaseAuth
class ConversationService: ObservableObject {
    private let db = Firestore.firestore()
    private let blockService = BlockService()
    private var blockingCache: [String: (result: Bool, timestamp: Date)] = [:]
    private let cacheTimeout: TimeInterval = 300
    private func incrementPodShares(podId: String) {
        guard !podId.isEmpty else { return }
        Task {
            do {
                let functions = Functions.functions()
                let incrementShares = functions.httpsCallable("incrementPodShares")
                let result = try await incrementShares.call(["podId": podId, "shareType": "direct"])
            } catch {
            }
        }
    }
    func createConversation(participants: [String], completion: @escaping (String?) -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }
        checkForBlockedUsers(participants: participants) { hasBlockedUsers in
            if hasBlockedUsers {
                completion(nil)
                return
            }
            self.createConversationInternal(participants: participants, completion: completion)
        }
    }
    private func createConversationInternal(participants: [String], completion: @escaping (String?) -> Void) {
        createConversationInternal(participants: participants, type: .oneOnOne, name: nil, description: nil, completion: completion)
    }
    private func createConversationInternal(participants: [String], type: ConversationType, name: String?, description: String?, completion: @escaping (String?) -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }
        let conversationId = UUID().uuidString
        let currentTime = Date()
        let isGroup = type == .group
        let maxParticipants = isGroup ? 50 : 2
        var conversationData: [String: Any] = [
            "type": type.rawValue,
            "participants": participants,
            "lastActivity": currentTime,
            "createdAt": currentTime,
            "createdBy": currentUid,
            "version": 1,
            "maxParticipants": maxParticipants,
            "isReported": false,
            "moderationStatus": "approved",
            "contentWarnings": [],
            "isMuted": false,
            "totalMessages": 0,
            "lastMessageAt": currentTime,
            "lastSeenBy": [:]
        ]
        if isGroup {
            conversationData["name"] = name ?? "Group Chat"
        } else {
            conversationData["name"] = name
        }
        db.collection("conversations")
            .document(conversationId)
            .setData(conversationData) { error in
                if let error = error {
                    completion(nil)
                    return
                }
                let batch = self.db.batch()
                let currentTime = Date()
                for participantId in participants {
                    let userConversationRef = self.db.collection("users")
                        .document(participantId)
                        .collection("conversations")
                        .document(conversationId)
                    var userConversationData = conversationData
                    userConversationData["unreadCount"] = 0
                    userConversationData["lastReadTimestamp"] = currentTime
                    userConversationData["conversationRef"] = "conversations/\(conversationId)"
                    userConversationData["joinedAt"] = currentTime
                    userConversationData["isMuted"] = false
                    userConversationData["isPinned"] = false
                    userConversationData["notificationSettings"] = [:]
                    batch.setData(userConversationData, forDocument: userConversationRef)
                }
                batch.commit { error in
                    if let error = error {
                        completion(nil)
                        return
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.verifyUserConversationData(conversationId: conversationId, participants: participants)
                    }
                    completion(conversationId)
                }
            }
    }
    func sendMessage(text: String, conversationId: String, completion: @escaping (Bool) -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        db.collection("conversations")
            .document(conversationId)
            .getDocument { snapshot, error in
                if let error = error {
                    completion(false)
                    return
                }
                guard let conversationData = snapshot?.data(),
                      let participants = conversationData["participants"] as? [String] else {
                    completion(false)
                    return
                }
                self.checkForBlockedUsers(participants: participants) { hasBlockedUsers in
                    if hasBlockedUsers {
                        completion(false)
                        return
                    }
                    self.sendMessageInternal(text: text, conversationId: conversationId, completion: completion)
                }
            }
    }
    private func sendMessageInternal(text: String, conversationId: String, completion: @escaping (Bool) -> Void) {
        let messageId = UUID().uuidString
        let currentTime = Date()
        let currentUid = Auth.auth().currentUser?.uid ?? ""
        let messageData: [String: Any] = [
            "text": text,
            "senderId": currentUid,
            "timestamp": currentTime,
            "isPod": false,
            "podId": NSNull(),
            "isRead": false,
            "version": 1,
            "conversationId": conversationId,
            "isReported": false,
            "readBy": [:],
            "reactions": [:]
        ]
        db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(messageId)
            .setData(messageData) { error in
                if let error = error {
                    completion(false)
                    return
                }
                self.checkAndRestoreDeletedConversation(conversationId: conversationId, userId: Auth.auth().currentUser?.uid ?? "")
                let currentTime = Date()
                self.db.collection("conversations")
                    .document(conversationId)
                    .updateData([
                        "lastMessage": messageData,
                        "lastActivity": currentTime,
                        "lastMessageReadBy": [Auth.auth().currentUser?.uid ?? ""]
                    ]) { error in
                        if let error = error {
                        } else {
                            self.updateUserConversationMetadata(conversationId: conversationId, lastActivity: currentTime)
                        }
                        completion(true)
                    }
            }
    }
    func sendPodMessage(podId: String, conversationId: String, completion: @escaping (Bool) -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        db.collection("conversations")
            .document(conversationId)
            .getDocument { snapshot, error in
                if let error = error {
                    completion(false)
                    return
                }
                guard let conversationData = snapshot?.data(),
                      let participants = conversationData["participants"] as? [String] else {
                    completion(false)
                    return
                }
                self.checkForBlockedUsers(participants: participants) { hasBlockedUsers in
                    if hasBlockedUsers {
                        completion(false)
                        return
                    }
                    self.sendPodMessageInternal(podId: podId, conversationId: conversationId, completion: completion)
                }
            }
    }
    private func sendPodMessageInternal(podId: String, conversationId: String, completion: @escaping (Bool) -> Void) {
        let messageId = UUID().uuidString
        let currentTime = Date()
        let currentUid = Auth.auth().currentUser?.uid ?? ""
        let messageData: [String: Any] = [
            "text": "",
            "senderId": currentUid,
            "timestamp": currentTime,
            "isPod": true,
            "podId": podId,
            "isRead": false,
            "version": 1,
            "conversationId": conversationId,
            "isReported": false,
            "readBy": [:],
            "reactions": [:]
        ]
        db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(messageId)
            .setData(messageData) { error in
                if let error = error {
                    completion(false)
                    return
                }
                self.checkAndRestoreDeletedConversation(conversationId: conversationId, userId: Auth.auth().currentUser?.uid ?? "")
                self.incrementPodShares(podId: podId)
                let currentTime = Date()
                self.db.collection("conversations")
                    .document(conversationId)
                    .updateData([
                        "lastMessage": messageData,
                        "lastActivity": currentTime,
                        "lastMessageReadBy": [Auth.auth().currentUser?.uid ?? ""]
                    ]) { error in
                        if let error = error {
                        } else {
                            self.updateUserConversationMetadata(conversationId: conversationId, lastActivity: currentTime)
                        }
                        completion(true)
                    }
            }
    }
    func fetchMessages(conversationId: String, limit: Int = 20, completion: @escaping ([Message]) -> Void) {
        db.collection("conversations")
            .document(conversationId)
            .getDocument { snapshot, error in
                if let error = error {
                    completion([])
                    return
                }
                guard let conversationData = snapshot?.data(),
                      let participants = conversationData["participants"] as? [String] else {
                    completion([])
                    return
                }
                self.checkForBlockedUsers(participants: participants) { hasBlockedUsers in
                    if hasBlockedUsers {
                        completion([])
                        return
                    }
                    self.fetchMessagesInternal(conversationId: conversationId, limit: limit, completion: completion)
                }
            }
    }
    private func fetchMessagesInternal(conversationId: String, limit: Int = 20, completion: @escaping ([Message]) -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
        db.collection("users")
            .document(currentUid)
            .collection("conversations")
            .document(conversationId)
            .getDocument { [weak self] userDoc, error in
                guard let self = self else { return }
                if let error = error {
                    completion([])
                    return
                }
                let userData = userDoc?.data() ?? [:]
                let isDeleted = userData["isDeleted"] as? Bool ?? false
                let deletedAt = userData["deletedAt"] as? Timestamp
                if deletedAt == nil {
                    self.db.collection("conversations").document(conversationId).getDocument { convDoc, convError in
                        if let convError = convError {
                            self.executeMessageQuery(conversationId: conversationId, isDeleted: isDeleted, deletedAt: deletedAt, limit: limit, completion: completion)
                            return
                        }
                        let convData = convDoc?.data() ?? [:]
                        let deletedFor = convData["deletedFor"] as? [String: [String: Any]] ?? [:]
                        let userDeletedFor = deletedFor[currentUid]
                        let mainDeletedAt = userDeletedFor?["deletedAt"] as? Timestamp
                        let finalDeletedAt = deletedAt ?? mainDeletedAt
                        self.executeMessageQuery(conversationId: conversationId, isDeleted: isDeleted, deletedAt: finalDeletedAt, limit: limit, completion: completion)
                    }
                } else {
                    self.executeMessageQuery(conversationId: conversationId, isDeleted: isDeleted, deletedAt: deletedAt, limit: limit, completion: completion)
                }
            }
    }
    private func verifyUserConversationData(conversationId: String, participants: [String]) {
        for participantId in participants {
            let userConversationRef = db.collection("users")
                .document(participantId)
                .collection("conversations")
                .document(conversationId)
            userConversationRef.getDocument { snapshot, error in
                if let error = error {
                    return
                }
                guard let data = snapshot?.data() else {
                    return
                }
            }
        }
    }
    private func updateUserConversationMetadata(conversationId: String, lastActivity: Date) {
        db.collection("conversations")
            .document(conversationId)
            .getDocument { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    return
                }
                guard let conversationData = snapshot?.data(),
                      let participants = conversationData["participants"] as? [String] else {
                    return
                }
                let batch = self.db.batch()
                for participantId in participants {
                    let userConversationRef = self.db.collection("users")
                        .document(participantId)
                        .collection("conversations")
                        .document(conversationId)
                    batch.updateData([
                        "lastActivity": lastActivity
                    ], forDocument: userConversationRef)
                }
                batch.commit { error in
                    if let error = error {
                    } else {
                    }
                }
            }
    }
    private func executeMessageQuery(conversationId: String, isDeleted: Bool, deletedAt: Timestamp?, limit: Int, completion: @escaping ([Message]) -> Void) {
        var query: Query
        if isDeleted, let deletedAt = deletedAt {
            query = self.db.collection("conversations").document(conversationId).collection("messages").whereField("timestamp", isGreaterThan: deletedAt).order(by: "timestamp", descending: true).limit(to: limit)
        } else if let deletedAt = deletedAt {
            query = self.db.collection("conversations").document(conversationId).collection("messages").whereField("timestamp", isGreaterThan: deletedAt).order(by: "timestamp", descending: true).limit(to: limit)
        } else {
            query = self.db.collection("conversations").document(conversationId).collection("messages").order(by: "timestamp", descending: true).limit(to: limit)
        }
        query.getDocuments { snapshot, error in
            if let error = error {
                completion([])
                return
            }
            guard let snapshot = snapshot else {
                completion([])
                return
            }
            let documents = snapshot.documents
            let messages = documents.compactMap { try? $0.data(as: Message.self) }
            let filteredMessages: [Message]
            if let deletedAt = deletedAt {
                filteredMessages = messages.filter { $0.timestamp > deletedAt.dateValue() }
                if messages.count != filteredMessages.count {
                    let filteredOut = messages.filter { $0.timestamp <= deletedAt.dateValue() }
                    for msg in filteredOut {
                    }
                }
            } else {
                filteredMessages = messages
            }
            if let deletedAt = deletedAt {
                for (index, msg) in messages.enumerated() {
                    let isAfter = msg.timestamp > deletedAt.dateValue()
                }
            }
            let sortedMessages = filteredMessages.sorted { $0.timestamp < $1.timestamp }
            completion(sortedMessages)
        }
    }
    func fetchMessagesPaginated(conversationId: String, lastMessage: Message?, limit: Int = 20, completion: @escaping ([Message]) -> Void) {
        db.collection("conversations")
            .document(conversationId)
            .getDocument { snapshot, error in
                if let error = error {
                    completion([])
                    return
                }
                guard let conversationData = snapshot?.data(),
                      let participants = conversationData["participants"] as? [String] else {
                    completion([])
                    return
                }
                self.checkForBlockedUsers(participants: participants) { hasBlockedUsers in
                    if hasBlockedUsers {
                        completion([])
                        return
                    }
                    self.fetchMessagesPaginatedInternal(conversationId: conversationId, lastMessage: lastMessage, limit: limit, completion: completion)
                }
            }
    }
    private func fetchMessagesPaginatedInternal(conversationId: String, lastMessage: Message?, limit: Int = 20, completion: @escaping ([Message]) -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
        db.collection("users")
            .document(currentUid)
            .collection("conversations")
            .document(conversationId)
            .getDocument { [weak self] userDoc, error in
                guard let self = self else { return }
                if let error = error {
                    completion([])
                    return
                }
                let userData = userDoc?.data() ?? [:]
                let isDeleted = userData["isDeleted"] as? Bool ?? false
                let deletedAt = userData["deletedAt"] as? Timestamp
                if deletedAt == nil {
                    self.db.collection("conversations").document(conversationId).getDocument { convDoc, convError in
                        if let convError = convError {
                            self.executePaginatedMessageQuery(conversationId: conversationId, isDeleted: isDeleted, deletedAt: deletedAt, lastMessage: lastMessage, limit: limit, completion: completion)
                            return
                        }
                        let convData = convDoc?.data() ?? [:]
                        let deletedFor = convData["deletedFor"] as? [String: [String: Any]] ?? [:]
                        let userDeletedFor = deletedFor[currentUid]
                        let mainDeletedAt = userDeletedFor?["deletedAt"] as? Timestamp
                        let finalDeletedAt = deletedAt ?? mainDeletedAt
                        self.executePaginatedMessageQuery(conversationId: conversationId, isDeleted: isDeleted, deletedAt: finalDeletedAt, lastMessage: lastMessage, limit: limit, completion: completion)
                    }
                } else {
                    self.executePaginatedMessageQuery(conversationId: conversationId, isDeleted: isDeleted, deletedAt: deletedAt, lastMessage: lastMessage, limit: limit, completion: completion)
                }
            }
    }
    private func executePaginatedMessageQuery(conversationId: String, isDeleted: Bool, deletedAt: Timestamp?, lastMessage: Message?, limit: Int, completion: @escaping ([Message]) -> Void) {
        var query: Query
        if isDeleted, let deletedAt = deletedAt {
            query = self.db.collection("conversations").document(conversationId).collection("messages").whereField("timestamp", isGreaterThan: deletedAt).order(by: "timestamp", descending: true).limit(to: limit)
        } else if let deletedAt = deletedAt {
            query = self.db.collection("conversations").document(conversationId).collection("messages").whereField("timestamp", isGreaterThan: deletedAt).order(by: "timestamp", descending: true).limit(to: limit)
        } else {
            query = self.db.collection("conversations").document(conversationId).collection("messages").order(by: "timestamp", descending: true).limit(to: limit)
        }
        if let lastMessage = lastMessage, let messageId = lastMessage.id {
            query = query.start(after: [lastMessage.timestamp])
        }
        query.getDocuments { snapshot, error in
            if let error = error {
                completion([])
                return
            }
            guard let snapshot = snapshot else {
                completion([])
                return
            }
            let documents = snapshot.documents
            let messages = documents.compactMap { try? $0.data(as: Message.self) }
            let filteredMessages: [Message]
            if let deletedAt = deletedAt {
                filteredMessages = messages.filter { $0.timestamp > deletedAt.dateValue() }
                if messages.count != filteredMessages.count {
                    let filteredOut = messages.filter { $0.timestamp <= deletedAt.dateValue() }
                    for msg in filteredOut {
                    }
                }
            } else {
                filteredMessages = messages
            }
            if let deletedAt = deletedAt {
                for (index, msg) in messages.enumerated() {
                    let isAfter = msg.timestamp > deletedAt.dateValue()
                }
            }
            let sortedMessages = filteredMessages.sorted { $0.timestamp < $1.timestamp }
            completion(sortedMessages)
        }
    }
    func setupMessageListener(conversationId: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration {
        return setupMessageListenerInternal(conversationId: conversationId, completion: completion)
    }
    private func setupMessageListenerInternal(conversationId: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            return db.collection("conversations")
                .document(conversationId)
                .collection("messages")
                .addSnapshotListener { _, _ in }
        }
        return db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    return
                }
                guard let documents = snapshot?.documents else {
                    return
                }
                let messages = documents.compactMap { try? $0.data(as: Message.self) }
                self.db.collection("users")
                    .document(currentUid)
                    .collection("conversations")
                    .document(conversationId)
                    .getDocument { userDoc, error in
                        let userData = userDoc?.data() ?? [:]
                        let isDeleted = userData["isDeleted"] as? Bool ?? false
                        let deletedAt = userData["deletedAt"] as? Timestamp
                        if deletedAt == nil {
                            self.db.collection("conversations").document(conversationId).getDocument { convDoc, convError in
                                if let convError = convError {
                                    self.filterAndCompleteMessages(messages: messages, isDeleted: isDeleted, deletedAt: deletedAt, completion: completion)
                                    return
                                }
                                let convData = convDoc?.data() ?? [:]
                                let deletedFor = convData["deletedFor"] as? [String: [String: Any]] ?? [:]
                                let userDeletedFor = deletedFor[currentUid]
                                let mainDeletedAt = userDeletedFor?["deletedAt"] as? Timestamp
                                let finalDeletedAt = deletedAt ?? mainDeletedAt
                                self.filterAndCompleteMessages(messages: messages, isDeleted: isDeleted, deletedAt: finalDeletedAt, completion: completion)
                            }
                        } else {
                            self.filterAndCompleteMessages(messages: messages, isDeleted: isDeleted, deletedAt: deletedAt, completion: completion)
                        }
                    }
            }
    }
    private func filterAndCompleteMessages(messages: [Message], isDeleted: Bool, deletedAt: Timestamp?, completion: @escaping ([Message]) -> Void) {
        let filteredMessages: [Message]
        if isDeleted, let deletedAt = deletedAt {
            filteredMessages = messages.filter { $0.timestamp > deletedAt.dateValue() }
            if messages.count != filteredMessages.count {
                let filteredOut = messages.filter { $0.timestamp <= deletedAt.dateValue() }
                for msg in filteredOut {
                }
            }
        } else if let deletedAt = deletedAt {
            filteredMessages = messages.filter { $0.timestamp > deletedAt.dateValue() }
            if messages.count != filteredMessages.count {
                let filteredOut = messages.filter { $0.timestamp <= deletedAt.dateValue() }
                for msg in filteredOut {
                }
            }
        } else {
            filteredMessages = messages
        }
        if let deletedAt = deletedAt {
            for (index, msg) in messages.enumerated() {
                let isAfter = msg.timestamp > deletedAt.dateValue()
            }
        }
        completion(filteredMessages)
    }
    func fetchConversations(for userId: String, completion: @escaping ([Conversation]) -> Void) {
        db.collection("users")
            .document(userId)
            .collection("conversations")
            .order(by: "lastActivity", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion([])
                    return
                }
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                for (index, doc) in documents.enumerated() {
                    let data = doc.data()
                }
                let group = DispatchGroup()
                var conversations: [Conversation] = []
                for document in documents {
                    group.enter()
                    let conversationRef = document.data()["conversationRef"] as? String ?? ""
                    self.db.document(conversationRef).getDocument { conversationDoc, error in
                        if let conversationDoc = conversationDoc,
                           let conversation = try? conversationDoc.data(as: Conversation.self) {
                            let deletedFor = conversationDoc.data()?["deletedFor"] as? [String: [String: Any]] ?? [:]
                            let isDeletedInMain = deletedFor[userId]?["isDeleted"] as? Bool ?? false
                            if !isDeletedInMain {
                                self.checkForBlockedUsers(participants: conversation.participants) { hasBlockedUsers in
                                    if !hasBlockedUsers {
                                        conversations.append(conversation)
                                    } else {
                                    }
                                    group.leave()
                                }
                            } else {
                                group.leave()
                            }
                        } else {
                            group.leave()
                        }
                    }
                }
                group.notify(queue: .main) {
                    let sortedConversations = conversations.sorted { $0.lastActivity > $1.lastActivity }
                    completion(sortedConversations)
                }
            }
    }
    func fetchConversationsWithSearch(
        for userId: String,
        searchQuery: String = "",
        lastConversation: Conversation? = nil,
        limit: Int = 10,
        completion: @escaping ([Conversation]) -> Void
    ) {
        var query = db.collection("users")
            .document(userId)
            .collection("conversations")
            .order(by: "lastActivity", descending: true)
            .limit(to: limit)
        if let lastConversation = lastConversation {
            query = query.start(after: [lastConversation.lastActivity])
        }
        query.getDocuments { snapshot, error in
            if let error = error {
                completion([])
                return
            }
            guard let documents = snapshot?.documents else {
                completion([])
                return
            }
            for (index, doc) in documents.enumerated() {
                let data = doc.data()
            }
            let group = DispatchGroup()
            var conversations: [Conversation] = []
            for document in documents {
                group.enter()
                let conversationRef = document.data()["conversationRef"] as? String ?? ""
                self.db.document(conversationRef).getDocument { conversationDoc, error in
                    if let conversationDoc = conversationDoc,
                       let conversation = try? conversationDoc.data(as: Conversation.self) {
                        let deletedFor = conversationDoc.data()?["deletedFor"] as? [String: [String: Any]] ?? [:]
                        let isDeletedInMain = deletedFor[userId]?["isDeleted"] as? Bool ?? false
                        if !isDeletedInMain {
                            self.checkForBlockedUsers(participants: conversation.participants) { hasBlockedUsers in
                                if !hasBlockedUsers {
                                    if searchQuery.isEmpty || self.conversationMatchesSearch(conversation, searchQuery: searchQuery) {
                                        conversations.append(conversation)
                                    }
                                }
                                group.leave()
                            }
                        } else {
                            group.leave()
                        }
                    } else {
                        group.leave()
                    }
                }
            }
            group.notify(queue: .main) {
                let sortedConversations = conversations.sorted { $0.lastActivity > $1.lastActivity }
                completion(sortedConversations)
            }
        }
    }
    private func conversationMatchesSearch(_ conversation: Conversation, searchQuery: String) -> Bool {
        let query = searchQuery.lowercased()
        for participantId in conversation.participants {
            if participantId.lowercased().contains(query) {
                return true
            }
        }
        return false
    }
    func fetchAllConversationsIncludingDeleted(for userId: String, completion: @escaping ([Conversation], Set<String>) -> Void) {
        db.collection("users")
            .document(userId)
            .collection("conversations")
            .order(by: "lastActivity", descending: true)
            .limit(to: 50)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion([], [])
                    return
                }
                guard let documents = snapshot?.documents else {
                    completion([], [])
                    return
                }
                let group = DispatchGroup()
                var conversations: [Conversation] = []
                var deletedConversationIds: Set<String> = []
                for document in documents {
                    group.enter()
                    let isDeleted = document.data()["isDeleted"] as? Bool ?? false
                    let conversationRef = document.data()["conversationRef"] as? String ?? ""
                    if isDeleted {
                    }
                    self.db.document(conversationRef).getDocument { conversationDoc, error in
                        if let conversationDoc = conversationDoc,
                           let conversation = try? conversationDoc.data(as: Conversation.self) {
                            self.checkForBlockedUsers(participants: conversation.participants) { hasBlockedUsers in
                                if !hasBlockedUsers {
                                    conversations.append(conversation)
                                    if isDeleted {
                                        deletedConversationIds.insert(conversation.id ?? "")
                                    }
                                } else {
                                }
                                group.leave()
                            }
                        } else {
                            group.leave()
                        }
                    }
                }
                group.notify(queue: .main) {
                    completion(conversations, deletedConversationIds)
                }
            }
    }
    func findExistingConversation(with userId: String, completion: @escaping (String?) -> Void) {
        findExistingConversation(with: userId, includeDeleted: false, completion: completion)
    }
    func findExistingConversation(with userId: String, includeDeleted: Bool = false, completion: @escaping (String?) -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }
        db.collection("users")
            .document(currentUid)
            .collection("conversations")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(nil)
                    return
                }
                guard let documents = snapshot?.documents else {
                    completion(nil)
                    return
                }
                let group = DispatchGroup()
                var foundConversationId: String?
                for document in documents {
                    group.enter()
                    let isDeleted = document.data()["isDeleted"] as? Bool ?? false
                    if isDeleted && !includeDeleted {
                        group.leave()
                        continue
                    }
                    let conversationRef = document.data()["conversationRef"] as? String ?? ""
                    self.db.document(conversationRef).getDocument { conversationDoc, error in
                        defer { group.leave() }
                        if let conversationDoc = conversationDoc,
                           let conversation = try? conversationDoc.data(as: Conversation.self) {
                            let deletedFor = conversationDoc.data()?["deletedFor"] as? [String: [String: Any]] ?? [:]
                            let currentUserId = Auth.auth().currentUser?.uid ?? ""
                            let isDeletedInMain = deletedFor[currentUserId]?["isDeleted"] as? Bool ?? false
                            if (includeDeleted || !isDeletedInMain) && conversation.participants.contains(userId) {
                                foundConversationId = conversation.id
                            }
                        }
                    }
                }
                group.notify(queue: .main) {
                    completion(foundConversationId)
                }
            }
    }
    func getOrCreateConversation(with userId: String, completion: @escaping (String?) -> Void) {
        checkForBlockedUsers(participants: [Auth.auth().currentUser?.uid ?? "", userId]) { hasBlockedUsers in
            if hasBlockedUsers {
                completion(nil)
                return
            }
            self.findExistingConversation(with: userId) { existingConversationId in
                if let existingId = existingConversationId {
                    completion(existingId)
                } else {
                    self.createConversation(participants: [Auth.auth().currentUser?.uid ?? "", userId]) { conversationId in
                        completion(conversationId)
                    }
                }
            }
        }
    }
    func fetchPod(withPodId podId: String, completion: @escaping(Pod?) -> Void) {
        guard !podId.isEmpty else {
            completion(nil)
            return
        }
        db.collection("pods")
            .document(podId)
            .getDocument { snapshot, error in
                if let error = error {
                    completion(nil)
                    return
                }
                guard let snapshot = snapshot, snapshot.exists else {
                    completion(nil)
                    return
                }
                do {
                    let pod = try snapshot.data(as: Pod.self)
                    completion(pod)
                } catch {
                    completion(nil)
                }
            }
    }
    func fetchUserDetails(userId: String, completion: @escaping(User?) -> Void) {
        db.collection("users")
            .document(userId)
            .getDocument { snapshot, error in
                if let error = error {
                    completion(nil)
                    return
                }
                guard let snapshot = snapshot, snapshot.exists else {
                    completion(nil)
                    return
                }
                do {
                    let user = try snapshot.data(as: User.self)
                    completion(user)
                } catch {
                    completion(nil)
                }
            }
    }
    private func checkAndRestoreDeletedConversation(conversationId: String, userId: String) {
        let conversationRef = db.collection("conversations").document(conversationId)
        conversationRef.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                return
            }
            guard let snapshot = snapshot, snapshot.exists else {
                return
            }
            let deletedFor = snapshot.data()?["deletedFor"] as? [String: [String: Any]] ?? [:]
            if deletedFor.isEmpty {
                return
            }
            let group = DispatchGroup()
            for (deletedUserId, deletedData) in deletedFor {
                let isDeleted = deletedData["isDeleted"] as? Bool ?? false
                if isDeleted {
                    group.enter()
                    let userConversationRef = self.db.collection("users")
                        .document(deletedUserId)
                        .collection("conversations")
                        .document(conversationId)
                    let userUpdateData: [String: Any] = [
                        "isDeleted": false
                    ]
                    userConversationRef.updateData(userUpdateData) { error in
                        if let error = error {
                        } else {
                        }
                        group.leave()
                    }
                }
            }
            group.notify(queue: .main) {
                let conversationUpdateData: [String: Any] = [
                    "deletedFor": FieldValue.delete()
                ]
                conversationRef.updateData(conversationUpdateData) { error in
                    if let error = error {
                    } else {
                    }
                }
            }
        }
    }
    func markLastMessageAsRead(conversationId: String, completion: @escaping (Bool) -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        db.collection("conversations")
            .document(conversationId)
            .updateData([
                "lastMessageReadBy": FieldValue.arrayUnion([currentUid])
            ]) { error in
                if let error = error {
                    completion(false)
                } else {
                    completion(true)
                }
            }
    }
    func restoreConversationForNewMessage(conversationId: String, completion: @escaping (Bool) -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        let userConversationRef = db.collection("users")
            .document(currentUid)
            .collection("conversations")
            .document(conversationId)
        let userUpdateData: [String: Any] = [
            "isDeleted": false
        ]
        userConversationRef.updateData(userUpdateData) { error in
            if let error = error {
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    func isCurrentUserBlockedBy(userId: String, completion: @escaping (Bool) -> Void) {
        guard !userId.isEmpty else {
            completion(false)
            return
        }
        guard let currentUid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        let userRef = db.collection("users").document(currentUid)
        userRef.getDocument { snapshot, error in
            if let error = error {
                completion(false)
                return
            }
            if let userData = snapshot?.data(),
               let blockedBy = userData["blockedBy"] as? [String] {
                let isBlocked = blockedBy.contains(userId)
                completion(isBlocked)
            } else {
                completion(false)
            }
        }
    }
    func hasCurrentUserBlocked(userId: String, completion: @escaping (Bool) -> Void) {
        guard !userId.isEmpty else {
            completion(false)
            return
        }
        guard let currentUid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        let userRef = db.collection("users").document(currentUid)
        userRef.getDocument { snapshot, error in
            if let error = error {
                completion(false)
                return
            }
            if let userData = snapshot?.data(),
               let blockedUsers = userData["blockedUsers"] as? [String] {
                let hasBlocked = blockedUsers.contains(userId)
                completion(hasBlocked)
            } else {
                completion(false)
            }
        }
    }
    private func checkForBlockedUsers(participants: [String], completion: @escaping (Bool) -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        let cacheKey = participants.sorted().joined(separator: ",")
        if let cached = blockingCache[cacheKey] {
            let timeSinceCache = Date().timeIntervalSince(cached.timestamp)
            if timeSinceCache < cacheTimeout {
                completion(cached.result)
                return
            } else {
                blockingCache.removeValue(forKey: cacheKey)
            }
        }
        let group = DispatchGroup()
        var hasBlockedUsers = false
        for participantId in participants {
            if participantId != currentUid {
                group.enter()
                isCurrentUserBlockedBy(userId: participantId) { isBlockedByThem in
                    if isBlockedByThem {
                        hasBlockedUsers = true
                        group.leave()
                    } else {
                        self.hasCurrentUserBlocked(userId: participantId) { hasBlockedThem in
                            if hasBlockedThem {
                                hasBlockedUsers = true
                            }
                            group.leave()
                        }
                    }
                }
            }
        }
        group.notify(queue: .main) {
            self.blockingCache[cacheKey] = (result: hasBlockedUsers, timestamp: Date())
            if hasBlockedUsers {
            } else {
            }
            completion(hasBlockedUsers)
        }
    }
    func searchConversationsByUsername(
        for userId: String,
        searchQuery: String,
        lastConversation: Conversation? = nil,
        limit: Int = 10,
        completion: @escaping ([Conversation]) -> Void
    ) {
        let usernameQuery = searchQuery.lowercased()
        db.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: usernameQuery)
            .whereField("username", isLessThan: usernameQuery + "\u{f8ff}")
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    completion([])
                    return
                }
                guard let userDocs = snapshot?.documents else {
                    completion([])
                    return
                }
                let matchingUserIds = userDocs.compactMap { doc -> String? in
                    let userData = doc.data()
                    let username = userData["username"] as? String ?? ""
                    let isDeleted = userData["isDeleted"] as? Bool ?? false
                    if isDeleted {
                        return nil
                    }
                    if username.lowercased().hasPrefix("anon_") {
                        return nil
                    }
                    if username.lowercased().contains(usernameQuery) {
                        return doc.documentID
                    }
                    return nil
                }
                if matchingUserIds.isEmpty {
                    completion([])
                    return
                }
                self?.findConversationsWithUsers(
                    userId: userId,
                    targetUserIds: matchingUserIds,
                    lastConversation: lastConversation,
                    limit: limit,
                    completion: completion
                )
            }
    }
    private func findConversationsWithUsers(
        userId: String,
        targetUserIds: [String],
        lastConversation: Conversation? = nil,
        limit: Int = 10,
        completion: @escaping ([Conversation]) -> Void
    ) {
        var query = db.collection("conversations")
            .order(by: "lastActivity", descending: true)
            .limit(to: limit * 3)
        if let lastConversation = lastConversation {
            query = query.start(after: [lastConversation.lastActivity])
        }
        query.getDocuments { [weak self] snapshot, error in
            if let error = error {
                completion([])
                return
            }
            guard let documents = snapshot?.documents else {
                completion([])
                return
            }
            let group = DispatchGroup()
            var conversations: [Conversation] = []
            for document in documents {
                group.enter()
                if let conversation = try? document.data(as: Conversation.self) {
                    let hasTargetUser = conversation.participants.contains { participantId in
                        targetUserIds.contains(participantId)
                    }
                    if hasTargetUser {
                        let hasCurrentUser = conversation.participants.contains { participantId in
                            participantId == userId
                        }
                        if hasCurrentUser {
                            self?.checkForBlockedUsers(participants: conversation.participants) { hasBlockedUsers in
                                if !hasBlockedUsers {
                                    conversations.append(conversation)
                                } else {
                                }
                                group.leave()
                            }
                        } else {
                            group.leave()
                        }
                    } else {
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                let sortedConversations = conversations
                    .sorted { $0.lastActivity > $1.lastActivity }
                    .prefix(limit)
                    .map { $0 }
                completion(Array(sortedConversations))
            }
        }
    }
}
