//
//  ConversationService.swift
//  PodWebBlueprint
//
//  Created by Connor Adams on 12/19/23.
//

import Foundation
import Firebase
import FirebaseFirestore
//import FirebaseFirestoreSwift
import FirebaseFunctions
import SwiftUI
import FirebaseAuth

class ConversationService: ObservableObject {
    private let db = Firestore.firestore()
    private let blockService = BlockService() // Add blocking service
    
    private var blockingCache: [String: (result: Bool, timestamp: Date)] = [:]
    private let cacheTimeout: TimeInterval = 300 // 5 minutes
    
    
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
        
        // Check if any participants are blocked
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
        
        // Determine conversation type and set appropriate fields
        let isGroup = type == .group
        let maxParticipants = isGroup ? 50 : 2
        
        var conversationData: [String: Any] = [
            "type": type.rawValue,
            "participants": participants,
            "lastActivity": currentTime,
            "createdAt": currentTime,
            "createdBy": currentUid,
            
            // Essential production fields
            "version": 1,
            
            // Group-specific fields
            "maxParticipants": maxParticipants,
            
            // Content moderation
            "isReported": false,
            "moderationStatus": "approved",
            "contentWarnings": [],
            "isMuted": false,
            
            // Analytics
            "totalMessages": 0,
            "lastMessageAt": currentTime,
            "lastSeenBy": [:]
        ]
        
        // Add group-specific fields if it's a group
        if isGroup {
            conversationData["name"] = name ?? "Group Chat"
        } else {
            // One-on-one conversation
            conversationData["name"] = name
        }
        
        // Create conversation
        db.collection("conversations")
            .document(conversationId)
            .setData(conversationData) { error in
                if let error = error {
                    completion(nil)
                    return
                }
                
                // Add conversation reference to each participant
                let batch = self.db.batch()
                let currentTime = Date()
                
                for participantId in participants {
                    let userConversationRef = self.db.collection("users")
                        .document(participantId)
                        .collection("conversations")
                        .document(conversationId)
                    
                    // Use the same data as the main conversation document for consistency
                    var userConversationData = conversationData
                    userConversationData["unreadCount"] = 0
                    userConversationData["lastReadTimestamp"] = currentTime
                    userConversationData["conversationRef"] = "conversations/\(conversationId)"
                    userConversationData["joinedAt"] = currentTime
                    
                    // Add user-specific metadata fields
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
                    
                    
                    // Verify the data was written correctly by reading it back
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
        
        // Check if conversation exists and get participants
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
                
                // Check if any participants are blocked
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
            
            // Essential production fields
            "version": 1,
            
            // Message content
            "conversationId": conversationId,
            
            // Content moderation
            "isReported": false,
            
            // Read status (isRead for one-on-one, readBy for group chats)
            "readBy": [:],
            
            // Analytics
            "reactions": [:]
        ]
        
        // Add message to conversation
        db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(messageId)
            .setData(messageData) { error in
                if let error = error {
                    completion(false)
                    return
                }
                
                // Check if sender has deleted this conversation and restore it if needed
                self.checkAndRestoreDeletedConversation(conversationId: conversationId, userId: Auth.auth().currentUser?.uid ?? "")
                
                // Update conversation's last message and activity
                let currentTime = Date()
                self.db.collection("conversations")
                    .document(conversationId)
                    .updateData([
                        "lastMessage": messageData,
                        "lastActivity": currentTime,
                        "lastMessageReadBy": [Auth.auth().currentUser?.uid ?? ""] // Only sender has read the new message
                    ]) { error in
                        if let error = error {
                        } else {
                            // Also update user conversation metadata with lastActivity for proper sorting
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
        
        // Check if conversation exists and get participants
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
                
                // Check if any participants are blocked
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
            
            // Essential production fields
            "version": 1,
            
            // Message content
            "conversationId": conversationId,
            
            // Content moderation
            "isReported": false,
            
            // Read status (isRead for one-on-one, readBy for group chats)
            "readBy": [:],
            
            // Analytics
            "reactions": [:]
        ]
        
        // Add message to conversation
        db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(messageId)
            .setData(messageData) { error in
                if let error = error {
                    completion(false)
                    return
                }
                
                // Check if sender has deleted this conversation and restore it if needed
                self.checkAndRestoreDeletedConversation(conversationId: conversationId, userId: Auth.auth().currentUser?.uid ?? "")
                
                // Increment shares count for the pod
                self.incrementPodShares(podId: podId)
                
                // Update conversation's last message and activity
                let currentTime = Date()
                self.db.collection("conversations")
                    .document(conversationId)
                    .updateData([
                        "lastMessage": messageData,
                        "lastActivity": currentTime,
                        "lastMessageReadBy": [Auth.auth().currentUser?.uid ?? ""] // Only sender has read the new message
                    ]) { error in
                        if let error = error {
                        } else {
                            // Also update user conversation metadata with lastActivity for proper sorting
                            self.updateUserConversationMetadata(conversationId: conversationId, lastActivity: currentTime)
                        }
                        completion(true)
                    }
            }
    }
    
    
    func fetchMessages(conversationId: String, limit: Int = 20, completion: @escaping ([Message]) -> Void) {
        // Check if conversation has blocked users before fetching messages
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
                
                // Check if any participants are blocked
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
        // First check if current user has deleted this conversation
        guard let currentUid = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
        
        
        // Check user's deletion status
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
                
                
                // If we don't have deletedAt from user metadata, check the main conversation document
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
                        
                        
                        // Use the main conversation's deletedAt if user metadata doesn't have it
                        let finalDeletedAt = deletedAt ?? mainDeletedAt
                        self.executeMessageQuery(conversationId: conversationId, isDeleted: isDeleted, deletedAt: finalDeletedAt, limit: limit, completion: completion)
                    }
                } else {
                    self.executeMessageQuery(conversationId: conversationId, isDeleted: isDeleted, deletedAt: deletedAt, limit: limit, completion: completion)
                }
            }
    }
    
    
    /// Verify that user conversation data was written correctly
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
    
    /// Update user conversation metadata with lastActivity for proper sorting
    private func updateUserConversationMetadata(conversationId: String, lastActivity: Date) {
        // Get conversation participants first
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
                
                // Update lastActivity for all participants
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

            // Apply in-memory filtering as a safety net
            let filteredMessages: [Message]
            if let deletedAt = deletedAt {
                filteredMessages = messages.filter { $0.timestamp > deletedAt.dateValue() }
                
                // DEBUG: Show which messages were filtered out
                if messages.count != filteredMessages.count {
                    let filteredOut = messages.filter { $0.timestamp <= deletedAt.dateValue() }
                    for msg in filteredOut {
                    }
                }
            } else {
                filteredMessages = messages
            }
            
            // DEBUG: Show all message timestamps vs deletedAt
            if let deletedAt = deletedAt {
                for (index, msg) in messages.enumerated() {
                    let isAfter = msg.timestamp > deletedAt.dateValue()
                }
            }

            // Sort ascending for display
            let sortedMessages = filteredMessages.sorted { $0.timestamp < $1.timestamp }
            completion(sortedMessages)
        }
    }
    
    
    func fetchMessagesPaginated(conversationId: String, lastMessage: Message?, limit: Int = 20, completion: @escaping ([Message]) -> Void) {
        // Check if conversation has blocked users before fetching messages
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
                
                // Check if any participants are blocked
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
        // First check if current user has deleted this conversation
        guard let currentUid = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
        
        
        // Check user's deletion status
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
                
                
                // If we don't have deletedAt from user metadata, check the main conversation document
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
                        
                        
                        // Use the main conversation's deletedAt if user metadata doesn't have it
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
            // For pagination, we need to create a DocumentSnapshot or use start(after:)
            // Since we have the message data, we can use start(after:) with the timestamp
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

            // Apply in-memory filtering as a safety net
            let filteredMessages: [Message]
            if let deletedAt = deletedAt {
                filteredMessages = messages.filter { $0.timestamp > deletedAt.dateValue() }
                
                // DEBUG: Show which messages were filtered out
                if messages.count != filteredMessages.count {
                    let filteredOut = messages.filter { $0.timestamp <= deletedAt.dateValue() }
                    for msg in filteredOut {
                    }
                }
            } else {
                filteredMessages = messages
            }
            
            // DEBUG: Show all message timestamps vs deletedAt
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
        // Set up the message listener directly without blocking checks
        return setupMessageListenerInternal(conversationId: conversationId, completion: completion)
    }
    
    private func setupMessageListenerInternal(conversationId: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration {
        // First check if current user has deleted this conversation
        guard let currentUid = Auth.auth().currentUser?.uid else {
            // Return empty listener if no current user
            return db.collection("conversations")
                .document(conversationId)
                .collection("messages")
                .addSnapshotListener { _, _ in }
        }
        
        // Set up message listener with deletion filter
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
                
                // Check user's deletion status and filter messages
                self.db.collection("users")
                    .document(currentUid)
                    .collection("conversations")
                    .document(conversationId)
                    .getDocument { userDoc, error in
                        let userData = userDoc?.data() ?? [:]
                        let isDeleted = userData["isDeleted"] as? Bool ?? false
                        let deletedAt = userData["deletedAt"] as? Timestamp
                        
                        
                        // If we don't have deletedAt from user metadata, check the main conversation document
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
                                
                                
                                // Use the main conversation's deletedAt if user metadata doesn't have it
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
            
            // DEBUG: Show which messages were filtered out
            if messages.count != filteredMessages.count {
                let filteredOut = messages.filter { $0.timestamp <= deletedAt.dateValue() }
                for msg in filteredOut {
                }
            }
        } else if let deletedAt = deletedAt {
            filteredMessages = messages.filter { $0.timestamp > deletedAt.dateValue() }
            
            // DEBUG: Show which messages were filtered out
            if messages.count != filteredMessages.count {
                let filteredOut = messages.filter { $0.timestamp <= deletedAt.dateValue() }
                for msg in filteredOut {
                }
            }
        } else {
            filteredMessages = messages
        }
        
        // DEBUG: Show all message timestamps vs deletedAt
        if let deletedAt = deletedAt {
            for (index, msg) in messages.enumerated() {
                let isAfter = msg.timestamp > deletedAt.dateValue()
            }
        }
        
        completion(filteredMessages)
    }
    
    
    func fetchConversations(for userId: String, completion: @escaping ([Conversation]) -> Void) {
        
        // Query user's conversation metadata
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
                
                
                // Debug: Print the user conversation data
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
                            // Double-check that the conversation isn't marked as deleted in the main document
                            let deletedFor = conversationDoc.data()?["deletedFor"] as? [String: [String: Any]] ?? [:]
                            let isDeletedInMain = deletedFor[userId]?["isDeleted"] as? Bool ?? false
                            
                            if !isDeletedInMain {
                                // Check if conversation has blocked users
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
                    // Sort by lastActivity from the main conversation document to ensure correct order
                    let sortedConversations = conversations.sorted { $0.lastActivity > $1.lastActivity }
                    completion(sortedConversations)
                }
            }
    }
    
    /// Fetch conversations with server-side search and pagination
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
        
        // Add pagination cursor using lastActivity
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
            
            
            // Debug: Print the user conversation data
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
                        // Check if conversation isn't deleted
                        let deletedFor = conversationDoc.data()?["deletedFor"] as? [String: [String: Any]] ?? [:]
                        let isDeletedInMain = deletedFor[userId]?["isDeleted"] as? Bool ?? false
                        
                        if !isDeletedInMain {
                            // Check for blocked users
                            self.checkForBlockedUsers(participants: conversation.participants) { hasBlockedUsers in
                                if !hasBlockedUsers {
                                    // Apply search filter if query exists
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
                // Sort by lastActivity from the main conversation document to ensure correct order
                let sortedConversations = conversations.sorted { $0.lastActivity > $1.lastActivity }
                completion(sortedConversations)
            }
        }
    }
    
    /// Check if conversation matches search query
    private func conversationMatchesSearch(_ conversation: Conversation, searchQuery: String) -> Bool {
        let query = searchQuery.lowercased()
        
        // For now, we'll do basic search on conversation data
        // In a production app, you'd want to store searchable fields in the conversation document
        // or create a separate search index
        
        // Check if any participant ID contains the query (basic fallback)
        for participantId in conversation.participants {
            if participantId.lowercased().contains(query) {
                return true
            }
        }
        
        return false
    }
    
    /// Fetch ALL conversations for a user (including deleted ones) for the New Message view
    /// This method shows full conversation history but still applies blocking filters for security
    /// Returns both conversations and a set of deleted conversation IDs
    func fetchAllConversationsIncludingDeleted(for userId: String, completion: @escaping ([Conversation], Set<String>) -> Void) {
        
        // Query user's conversation metadata (including deleted ones) with limit
        db.collection("users")
            .document(userId)
            .collection("conversations")
            .order(by: "lastActivity", descending: true)
            .limit(to: 50) // Limit to prevent fetching too many conversations
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
                    
                    // Include ALL conversations, even deleted ones
                    let isDeleted = document.data()["isDeleted"] as? Bool ?? false
                    let conversationRef = document.data()["conversationRef"] as? String ?? ""
                    
                    if isDeleted {
                    }
                    
                    // Fetch full conversation data
                    self.db.document(conversationRef).getDocument { conversationDoc, error in
                        if let conversationDoc = conversationDoc,
                           let conversation = try? conversationDoc.data(as: Conversation.self) {
                            
                            // Check if conversation has blocked users (still apply blocking filter for security)
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
        
        // Check if conversation already exists
        db.collection("users")
            .document(currentUid)
            .collection("conversations")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(nil)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    // No conversations exist
                    completion(nil)
                    return
                }
                
                // Check if conversation with this user already exists
                let group = DispatchGroup()
                var foundConversationId: String?
                
                for document in documents {
                    group.enter()
                    
                    // Check if this conversation is marked as deleted for the user
                    let isDeleted = document.data()["isDeleted"] as? Bool ?? false
                    
                    // Skip deleted conversations unless explicitly requested
                    if isDeleted && !includeDeleted {
                        group.leave()
                        continue
                    }
                    
                    let conversationRef = document.data()["conversationRef"] as? String ?? ""
                    
                    self.db.document(conversationRef).getDocument { conversationDoc, error in
                        defer { group.leave() }
                        
                        if let conversationDoc = conversationDoc,
                           let conversation = try? conversationDoc.data(as: Conversation.self) {
                            // Double-check that the conversation isn't marked as deleted in the main document
                            let deletedFor = conversationDoc.data()?["deletedFor"] as? [String: [String: Any]] ?? [:]
                            let currentUserId = Auth.auth().currentUser?.uid ?? ""
                            let isDeletedInMain = deletedFor[currentUserId]?["isDeleted"] as? Bool ?? false
                            
                            // If including deleted conversations, don't check main document deletion status
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
        // Check if users are blocked before proceeding
        checkForBlockedUsers(participants: [Auth.auth().currentUser?.uid ?? "", userId]) { hasBlockedUsers in
            if hasBlockedUsers {
                completion(nil)
                return
            }
            
            // First try to find existing conversation
            self.findExistingConversation(with: userId) { existingConversationId in
                if let existingId = existingConversationId {
                    // Found existing conversation
                    completion(existingId)
                } else {
                    // No existing conversation found, create new one
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
        // First check the main conversation document to see who has it marked as deleted
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
            
            // If no one has it marked as deleted, nothing to restore
            if deletedFor.isEmpty {
                return
            }
            
            
            // Restore conversation for all users who have it marked as deleted
            let group = DispatchGroup()
            
            for (deletedUserId, deletedData) in deletedFor {
                let isDeleted = deletedData["isDeleted"] as? Bool ?? false
                
                if isDeleted {
                    group.enter()
                    
                    // Update the user's conversation reference to mark as not deleted
                    let userConversationRef = self.db.collection("users")
                        .document(deletedUserId)
                        .collection("conversations")
                        .document(conversationId)
                    
                    let userUpdateData: [String: Any] = [
                        "isDeleted": false
                        // Keep deletedAt timestamp for message filtering
                    ]
                    
                    userConversationRef.updateData(userUpdateData) { error in
                        if let error = error {
                        } else {
                        }
                        group.leave()
                    }
                }
            }
            
            // After restoring all user references, remove the deletedFor entries from main document
            group.notify(queue: .main) {
                let conversationUpdateData: [String: Any] = [
                    "deletedFor": FieldValue.delete() // Remove the entire deletedFor field
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
        
        // Add current user to the lastMessageReadBy array
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
        
        // Update user's conversation reference to mark as not deleted
        let userConversationRef = db.collection("users")
            .document(currentUid)
            .collection("conversations")
            .document(conversationId)
        
        let userUpdateData: [String: Any] = [
            "isDeleted": false
            // Keep deletedAt timestamp for message filtering
        ]
        
        userConversationRef.updateData(userUpdateData) { error in
            if let error = error {
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    
    /// Simple check: is current user blocked by a specific user?
    /// Uses the same approach as ProfileView - reads from current user's blockedBy array
    func isCurrentUserBlockedBy(userId: String, completion: @escaping (Bool) -> Void) {
        // Guard against empty user IDs that would cause Firestore crashes
        guard !userId.isEmpty else {
            completion(false)
            return
        }
        
        guard let currentUid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        // Use the EXACT same approach as ProfileView - read current user's blockedBy array
        // This reads from users/{currentUid} and checks the blockedBy array field
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
    
    /// Simple check: has current user blocked a specific user?
    /// Reads from current user's blockedUsers array
    func hasCurrentUserBlocked(userId: String, completion: @escaping (Bool) -> Void) {
        // Guard against empty user IDs that would cause Firestore crashes
        guard !userId.isEmpty else {
            completion(false)
            return
        }
        
        guard let currentUid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        // Read from current user's blockedUsers array
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
        
        // Create cache key from sorted participants
        let cacheKey = participants.sorted().joined(separator: ",")
        
        // Check cache first
        if let cached = blockingCache[cacheKey] {
            let timeSinceCache = Date().timeIntervalSince(cached.timestamp)
            if timeSinceCache < cacheTimeout {
                completion(cached.result)
                return
            } else {
                blockingCache.removeValue(forKey: cacheKey)
            }
        }
        
        
        // Check both directions: if current user is blocked by someone OR if current user has blocked someone
        let group = DispatchGroup()
        var hasBlockedUsers = false
        
        for participantId in participants {
            if participantId != currentUid { // Skip checking self
                group.enter()
                
                // Check if current user is blocked by this participant
                isCurrentUserBlockedBy(userId: participantId) { isBlockedByThem in
                    if isBlockedByThem {
                        hasBlockedUsers = true
                        group.leave()
                    } else {
                        // Check if current user has blocked this participant
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
            // Cache the result
            self.blockingCache[cacheKey] = (result: hasBlockedUsers, timestamp: Date())
            
            if hasBlockedUsers {
            } else {
            }
            completion(hasBlockedUsers)
        }
    }
    
    /// Server-side search for conversations by participant usernames
    /// This method searches through all conversations, not just loaded ones
    func searchConversationsByUsername(
        for userId: String,
        searchQuery: String,
        lastConversation: Conversation? = nil,
        limit: Int = 10,
        completion: @escaping ([Conversation]) -> Void
    ) {
        
        // First, find users whose usernames match the search query
        let usernameQuery = searchQuery.lowercased()
        
        // Search in users collection for matching usernames
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
                    
                    
                    // Filter out deleted accounts
                    if isDeleted {
                        return nil
                    }
                    
                    // Filter out anonymous accounts (usernames starting with "anon_")
                    if username.lowercased().hasPrefix("anon_") {
                        return nil
                    }
                    
                    // Double-check the username actually contains our query
                    if username.lowercased().contains(usernameQuery) {
                        return doc.documentID
                    }
                    return nil
                }
                
                
                if matchingUserIds.isEmpty {
                    completion([])
                    return
                }
                
                // Now find conversations that include any of these users
                self?.findConversationsWithUsers(
                    userId: userId,
                    targetUserIds: matchingUserIds,
                    lastConversation: lastConversation,
                    limit: limit,
                    completion: completion
                )
            }
    }
    
    /// Find conversations that include specific users
    private func findConversationsWithUsers(
        userId: String,
        targetUserIds: [String],
        lastConversation: Conversation? = nil,
        limit: Int = 10,
        completion: @escaping ([Conversation]) -> Void
    ) {
        
        // Search through ALL conversations globally to find ones with target users
        // This is more efficient than checking every user's conversation collection
        var query = db.collection("conversations")
            .order(by: "lastActivity", descending: true)
            .limit(to: limit * 3) // Fetch more to account for filtering
        
        // Add pagination cursor
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
                
                // Parse conversation directly from document
                if let conversation = try? document.data(as: Conversation.self) {
                    
                    // Check if this conversation includes any of our target users
                    let hasTargetUser = conversation.participants.contains { participantId in
                        targetUserIds.contains(participantId)
                    }
                    
                    if hasTargetUser {
                        // Check if current user is also a participant (they need to be in the conversation)
                        let hasCurrentUser = conversation.participants.contains { participantId in
                            participantId == userId
                        }
                        
                        if hasCurrentUser {
                            // Check for blocked users
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
                // Sort by last activity and limit results
                let sortedConversations = conversations
                    .sorted { $0.lastActivity > $1.lastActivity }
                    .prefix(limit)
                    .map { $0 }
                
                completion(Array(sortedConversations))
            }
        }
    }
} 
