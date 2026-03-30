"use client";

import { motion } from "framer-motion";
import { useInView } from "framer-motion";
import { useRef, useState } from "react";
import { Copy, Check } from "lucide-react";

const files = [
  {
    name: "UserService.swift",
    lang: "Swift",
    project: "In-Tuned",
    color: "cyan",
    code: `import Firebase
import FirebaseFunctions
import FirebaseFirestore
import UIKit
import FirebaseAuth

struct UserService {
    var collectionRef = Firestore.firestore().collection("users")
    private let blockService = BlockService()

    func fetchUser(withUid uid: String, completion: @escaping(Result<User, Error>) -> Void) {
        Firestore.firestore().collection("users")
            .document(uid)
            .getDocument { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let snapshot = snapshot, snapshot.exists else {
                    let error = NSError(domain: "UserService", code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "User not found"])
                    completion(.failure(error))
                    return
                }
                do {
                    let user = try snapshot.data(as: User.self)
                    completion(.success(user))
                } catch {
                    completion(.failure(error))
                }
            }
    }

    func searchUsers(query: String, lastDocument: DocumentSnapshot? = nil,
                     completion: @escaping ([User], DocumentSnapshot?) -> Void) {
        var queryRef = collectionRef
            .whereField("username", isGreaterThanOrEqualTo: query.lowercased())
            .whereField("username", isLessThan: query.lowercased() + "~")
            .order(by: "username")
            .limit(to: 25)

        if let lastDocument = lastDocument {
            queryRef = queryRef.start(afterDocument: lastDocument)
        }

        queryRef.getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else {
                completion([], nil)
                return
            }
            let resultUsers = documents.compactMap { try? $0.data(as: User.self) }
                .filter { user in
                    let isDeleted = user.isDeleted ?? false
                    let isAnonymous = user.username.lowercased().hasPrefix("anon_")
                    return !isDeleted && !isAnonymous
                }
            completion(resultUsers, documents.last)
        }
    }
}`,
  },
  {
    name: "ConversationService.swift",
    lang: "Swift",
    project: "In-Tuned",
    color: "cyan",
    code: `import Foundation
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
                try await incrementShares.call(["podId": podId, "shareType": "direct"])
            } catch {
                print("Error incrementing pod shares: \\(error.localizedDescription)")
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

    private func createConversationInternal(participants: [String], type: ConversationType,
                                            name: String?, description: String?,
                                            completion: @escaping (String?) -> Void) {
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
            "createdAt": Timestamp(date: currentTime),
            "lastMessageAt": Timestamp(date: currentTime),
            "maxParticipants": maxParticipants,
            "createdBy": currentUid,
        ]
        if let name = name { conversationData["name"] = name }
        if let description = description { conversationData["description"] = description }

        db.collection("conversations").document(conversationId).setData(conversationData) { error in
            if let error = error {
                print("Error creating conversation: \\(error)")
                completion(nil)
            } else {
                completion(conversationId)
            }
        }
    }
}`,
  },
  {
    name: "UserViewModel.swift",
    lang: "Swift",
    project: "In-Tuned",
    color: "cyan",
    code: `import SwiftUI
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
}`,
  },
  {
    name: "PlayerViewModel.swift",
    lang: "Swift",
    project: "In-Tuned",
    color: "cyan",
    code: `import Foundation
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

    private init() {}

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
        Task {
            await fetchRecommendedPods(for: currentPod)
        }
    }
}`,
  },
  {
    name: "summarize-url/route.ts",
    lang: "TypeScript",
    project: "Bypassr AI",
    color: "indigo",
    code: `import { NextRequest, NextResponse } from "next/server";
import Anthropic from "@anthropic-ai/sdk";
import { createClient } from "@/lib/supabase/server";
import { checkAnonymousQuota, countWords,
         incrementAnonymousUsage, setAnonCookie } from "@/lib/quota-anonymous";
import { checkUserQuota, incrementUserUsage } from "@/lib/quota-user";
import { buildSummarizePayloadFromPage, isUrlAllowedForFetch } from "@/lib/extract-page-from-html";
import { SUMMARIZE_SYSTEM } from "@/lib/prompts";

const MAX_HTML_BYTES = 600_000;
const MAX_TEXT_CHARS = 10_000;
const FETCH_TIMEOUT_MS = 20_000;
const MAX_REDIRECTS = 6;

const FETCH_HEADERS: Record<string, string> = {
  Accept: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
  "Accept-Language": "en-US,en;q=0.9",
  "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/131.0.0.0 Safari/537.36",
  "Sec-Fetch-Dest": "document",
  "Sec-Fetch-Mode": "navigate",
  "Cache-Control": "no-cache",
};

async function fetchHtmlWithRedirects(startUrl: URL) {
  let current = startUrl.href;
  let refererForNext = "";

  for (let i = 0; i < MAX_REDIRECTS; i++) {
    const allowed = isUrlAllowedForFetch(current);
    if (!allowed.ok) return { ok: false as const, error: allowed.reason };

    const u = allowed.url;
    const ac = new AbortController();
    const t = setTimeout(() => ac.abort(), FETCH_TIMEOUT_MS);
    let res: Response;

    try {
      res = await fetch(u.href, {
        method: "GET",
        redirect: "manual",
        signal: ac.signal,
        headers: { ...FETCH_HEADERS, Referer: refererForNext || \`\${u.origin}/\` },
      });
    } catch (e) {
      clearTimeout(t);
      return { ok: false as const, error: fetchFailureMessage(e) };
    }
    clearTimeout(t);

    if (res.status >= 300 && res.status < 400) {
      const loc = res.headers.get("location");
      if (!loc) return { ok: false as const, error: "Redirect without location." };
      refererForNext = u.href;
      current = new URL(loc, u.href).href;
      continue;
    }

    if (!res.ok) {
      if (res.status === 403 || res.status === 401)
        return { ok: false as const, error: "Site blocked the request — paste text instead." };
      return { ok: false as const, error: \`Page returned status \${res.status}.\` };
    }

    const buf = await res.arrayBuffer();
    if (buf.byteLength > MAX_HTML_BYTES)
      return { ok: false as const, error: "Page is too large to process." };

    const html = new TextDecoder("utf-8", { fatal: false }).decode(buf);
    return { ok: true as const, html, finalUrl: u.href };
  }
  return { ok: false as const, error: "Too many redirects." };
}`,
  },
  {
    name: "EssayWriterClient.tsx",
    lang: "TypeScript",
    project: "Bypassr AI",
    color: "indigo",
    code: `"use client";

import { useRouter } from "next/navigation";
import { useState, useEffect } from "react";
import { useQuotaModal } from "@/components/QuotaModalContext";
import { isQuotaReachedError } from "@/lib/quota-messages";

type FormState = {
  typeOfPaper: string;
  topic: string;
  purpose: string;
  gradeLevel: string;
  format: string;
  wordCount: string;
  tone: string;
  vocabulary: string;
  pointOfView: string;
  includeQuotes: boolean;
  additionalRequirements: string;
};

const defaultForm: FormState = {
  typeOfPaper: "Essay",
  topic: "",
  purpose: "Inform",
  gradeLevel: "High school",
  format: "No specific format",
  wordCount: "500",
  tone: "Formal",
  vocabulary: "Intermediate",
  pointOfView: "Third person (he/she/they)",
  includeQuotes: false,
  additionalRequirements: "",
};

export function EssayWriterClient() {
  const { openQuotaModal } = useQuotaModal();
  const [form, setForm] = useState<FormState>(defaultForm);
  const [essay, setEssay] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const clampWordCount = (raw: string): number | null => {
    const n = parseInt(raw.trim(), 10);
    if (!Number.isFinite(n)) return null;
    return Math.min(2000, Math.max(200, n));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const topic = form.topic.trim();
    if (!topic) { setError("Topic is required."); return; }
    const wordCount = clampWordCount(form.wordCount);
    if (wordCount == null) { setError("Enter a word count between 200 and 2000."); return; }

    setError("");
    setLoading(true);
    setEssay("");

    try {
      const res = await fetch("/api/essay-writer", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ ...form, topic, wordCount,
          additionalRequirements: [
            form.includeQuotes ? "Include relevant quotes where appropriate." : "",
            form.additionalRequirements.trim(),
          ].filter(Boolean).join(" "),
        }),
      });

      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        if (res.status === 403 && isQuotaReachedError(data.error)) {
          openQuotaModal();
        } else {
          setError(data.error || \`Error (\${res.status}). Please try again.\`);
        }
        return;
      }
      if (data.essay) setEssay(data.essay);
    } catch {
      setError("Something went wrong. Please try again.");
    } finally {
      setLoading(false);
    }
  };
}`,
  },
];

function highlight(code: string, lang: string): string {
  const swiftKeywords = /\b(import|struct|class|func|let|var|guard|return|if|else|do|catch|try|throws|async|await|private|public|internal|static|override|init|self|nil|true|false|for|in|switch|case|default|break|continue|where|extension|protocol|enum|@Published|@MainActor|@escaping|@objc|Task)\b/g;
  const tsKeywords = /\b(import|export|from|const|let|var|function|async|await|return|if|else|try|catch|throw|new|typeof|type|interface|class|extends|implements|default|null|undefined|true|false|for|of|in|switch|case|break|continue|void)\b/g;
  const strings = /(["'`])((?:\\.|(?!\1)[^\\])*)\1/g;
  const numbers = /\b(\d+(_\d+)?)\b/g;
  const comments = /(\/\/[^\n]*)/g;

  let out = code
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");

  out = out.replace(strings, '<span style="color:#86efac">$1$2$1</span>');
  out = out.replace(comments, '<span style="color:#64748b;font-style:italic">$1</span>');
  out = out.replace(numbers, '<span style="color:#fb923c">$1</span>');

  if (lang === "Swift") {
    out = out.replace(swiftKeywords, '<span style="color:#c084fc">$1</span>');
  } else {
    out = out.replace(tsKeywords, '<span style="color:#c084fc">$1</span>');
  }

  return out;
}

export default function CodeShowcase() {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true, margin: "-80px" });
  const [active, setActive] = useState(0);
  const [copied, setCopied] = useState(false);

  const file = files[active];

  const handleCopy = () => {
    navigator.clipboard.writeText(file.code).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  };

  return (
    <section id="code" className="relative py-16 px-6">
      <div className="max-w-5xl mx-auto" ref={ref}>
        <motion.p
          initial={{ opacity: 0, y: 10 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.5 }}
          className="section-label mb-4"
        >
          Code
        </motion.p>

        <motion.h2
          initial={{ opacity: 0, y: 20 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6, delay: 0.1 }}
          className="text-3xl sm:text-4xl font-bold text-white mb-8"
        >
          Code Showcase
        </motion.h2>

        <motion.div
          initial={{ opacity: 0, y: 24 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6, delay: 0.2 }}
          className="card overflow-hidden"
        >
          {/* Tab bar */}
          <div className="flex overflow-x-auto border-b border-white/[0.07] bg-black/20">
            {files.map((f, i) => (
              <button
                key={f.name}
                onClick={() => setActive(i)}
                className={`flex-shrink-0 px-4 py-3 text-[11px] font-semibold tracking-wide transition-all border-b-2 ${
                  active === i
                    ? f.color === "cyan"
                      ? "border-cyan-400 text-cyan-300 bg-white/[0.04]"
                      : "border-indigo-400 text-indigo-300 bg-white/[0.04]"
                    : "border-transparent text-white/35 hover:text-white/60"
                }`}
              >
                {f.name}
              </button>
            ))}
          </div>

          {/* File meta bar */}
          <div className="flex items-center justify-between px-5 py-2.5 bg-black/10 border-b border-white/[0.05]">
            <div className="flex items-center gap-3">
              <span className={`text-[10px] font-bold tracking-widest uppercase px-2 py-0.5 rounded ${
                file.color === "cyan"
                  ? "bg-cyan-500/15 text-cyan-400"
                  : "bg-indigo-500/15 text-indigo-400"
              }`}>
                {file.lang}
              </span>
              <span className="text-white/30 text-[11px]">{file.project}</span>
            </div>
            <button
              onClick={handleCopy}
              className="flex items-center gap-1.5 text-[11px] text-white/40 hover:text-white/70 transition-colors"
            >
              {copied ? <Check size={12} className="text-green-400" /> : <Copy size={12} />}
              {copied ? "Copied" : "Copy"}
            </button>
          </div>

          {/* Code block */}
          <div className="overflow-x-auto overflow-y-auto max-h-[520px]">
            <pre className="p-6 text-[12px] leading-[1.7] font-mono text-white/75">
              <code
                dangerouslySetInnerHTML={{
                  __html: highlight(file.code, file.lang),
                }}
              />
            </pre>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
