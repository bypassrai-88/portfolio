"use client";

import { motion } from "framer-motion";
import { useInView } from "framer-motion";
import { useRef } from "react";
import {
  ExternalLink,
  Layers,
  Brain,
  ShieldCheck,
  Smartphone,
  Globe,
  Database,
} from "lucide-react";

function GithubIcon({ size = 16, className }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" className={className}>
      <path d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z" />
    </svg>
  );
}

const bypassrHighlights = [
  {
    icon: Layers,
    text: "Dual-mode architecture via build-time env var (NEXT_PUBLIC_SITE_VARIANT)",
  },
  {
    icon: Brain,
    text: "Anthropic (Claude) orchestration: essays, grammar, summarize, translate, paraphrase",
  },
  {
    icon: Globe,
    text: "URL-aware summarizer: fetches HTML server-side, extracts OG metadata, strips markup",
  },
  {
    icon: Database,
    text: "Supabase auth + usage accounting; Stripe subscriptions on full product path",
  },
  {
    icon: ShieldCheck,
    text: "SSRF-minded hostname checks, redirect handling, quotas by billing period",
  },
];

const intunedHighlights = [
  {
    icon: Smartphone,
    text: "Full iOS social media app — nearly 100 distinct features",
  },
  {
    icon: Brain,
    text: "ML processors that categorize content and drive user interaction",
  },
  {
    icon: ShieldCheck,
    text: "Smooth user authentication — login, session management, security",
  },
  {
    icon: Database,
    text: "Backend handles DMs, comments, real-time updates, and all content",
  },
  {
    icon: Layers,
    text: "Efficient media storage for image, audio, and video assets at scale",
  },
];

function ProjectTag({ label }: { label: string }) {
  return (
    <span className="inline-block px-2.5 py-1 text-[10px] font-semibold tracking-wider uppercase rounded-md bg-indigo-600/15 border border-indigo-500/20 text-indigo-300">
      {label}
    </span>
  );
}

export default function Projects() {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true, margin: "-80px" });

  return (
    <section id="projects" className="relative py-28 px-6">
      <div className="max-w-5xl mx-auto" ref={ref}>
        <motion.p
          initial={{ opacity: 0, y: 10 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.5 }}
          className="section-label mb-4"
        >
          Projects
        </motion.p>

        <motion.h2
          initial={{ opacity: 0, y: 20 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6, delay: 0.1 }}
          className="text-3xl sm:text-4xl font-bold text-white mb-14"
        >
          Featured Work
        </motion.h2>

        <div className="space-y-10">
          {/* ── Bypassr AI ── */}
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={inView ? { opacity: 1, y: 0 } : {}}
            transition={{ duration: 0.7, delay: 0.2 }}
            className="card p-8 md:p-10 relative overflow-hidden"
          >
            {/* Accent glow */}
            <div
              aria-hidden
              className="absolute top-0 right-0 w-64 h-64 opacity-[0.06] pointer-events-none"
              style={{
                background:
                  "radial-gradient(circle, #6366f1 0%, transparent 70%)",
                filter: "blur(30px)",
              }}
            />

            <div className="relative z-10">
              {/* Header */}
              <div className="flex flex-wrap items-start justify-between gap-4 mb-6">
                <div>
                  <p className="text-xs font-bold tracking-widest uppercase text-white/30 mb-1">
                    01 — Web Application
                  </p>
                  <h3 className="text-2xl sm:text-3xl font-bold text-white">
                    Bypassr AI
                  </h3>
                </div>
                <div className="flex gap-3">
                  <a
                    href="https://bypassrai.com"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-semibold tracking-wide transition-all hover:shadow-[0_0_20px_rgba(99,102,241,0.4)]"
                  >
                    Live Site <ExternalLink size={12} />
                  </a>
                </div>
              </div>

              {/* Tags */}
              <div className="flex flex-wrap gap-2 mb-6">
                {[
                  "Next.js 14",
                  "TypeScript",
                  "Supabase",
                  "Anthropic",
                  "Stripe",
                  "Tailwind CSS",
                  "Vercel",
                ].map((t) => (
                  <ProjectTag key={t} label={t} />
                ))}
              </div>

              {/* Description */}
              <p className="text-white/60 leading-relaxed mb-8 max-w-3xl text-[0.95rem]">
                A production full-stack AI writing suite — essay drafting, grammar, link-aware
                summarization, translation, and paraphrasing. The same codebase serves two
                distinct product narratives ({'"writing suite"'} vs{" "}
                {'"humanizer"'}) entirely through a build-time environment variable, with no
                forked repos. Demonstrates product engineering judgment: one maintainable
                system, multiple markets.
              </p>

              {/* Highlights */}
              <div className="grid sm:grid-cols-2 gap-3">
                {bypassrHighlights.map((h) => (
                  <div
                    key={h.text}
                    className="flex items-start gap-3 p-4 rounded-xl bg-white/[0.03] border border-white/[0.06]"
                  >
                    <div className="w-7 h-7 rounded-md bg-indigo-600/25 flex items-center justify-center flex-shrink-0 mt-0.5">
                      <h.icon size={13} className="text-indigo-400" />
                    </div>
                    <p className="text-white/55 text-xs leading-relaxed">{h.text}</p>
                  </div>
                ))}
              </div>
            </div>
          </motion.div>

          {/* ── In-Tuned ── */}
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={inView ? { opacity: 1, y: 0 } : {}}
            transition={{ duration: 0.7, delay: 0.35 }}
            className="card p-8 md:p-10 relative overflow-hidden"
          >
            <div
              aria-hidden
              className="absolute top-0 right-0 w-64 h-64 opacity-[0.06] pointer-events-none"
              style={{
                background:
                  "radial-gradient(circle, #22d3ee 0%, transparent 70%)",
                filter: "blur(30px)",
              }}
            />

            <div className="relative z-10">
              <div className="flex flex-wrap items-start justify-between gap-4 mb-6">
                <div>
                  <p className="text-xs font-bold tracking-widest uppercase text-white/30 mb-1">
                    02 — iOS Application
                  </p>
                  <h3 className="text-2xl sm:text-3xl font-bold text-white">
                    In-Tuned
                  </h3>
                </div>
                <div className="flex gap-3">
                  <a
                    href="https://github.com/connor833/In-Tuned"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-2 px-4 py-2 rounded-lg border border-white/15 hover:border-white/35 text-white/70 hover:text-white text-xs font-semibold tracking-wide transition-all"
                  >
                    <GithubIcon size={13} />
                    GitHub
                  </a>
                  <a
                    href="#intuned-gallery"
                    className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-cyan-600/80 hover:bg-cyan-500/80 text-white text-xs font-semibold tracking-wide transition-all hover:shadow-[0_0_20px_rgba(34,211,238,0.3)]"
                  >
                    Screenshots <ExternalLink size={12} />
                  </a>
                </div>
              </div>

              {/* Tags */}
              <div className="flex flex-wrap gap-2 mb-6">
                {[
                  "Swift",
                  "iOS",
                  "Machine Learning",
                  "Backend",
                  "Real-time",
                  "Media Storage",
                ].map((t) => (
                  <ProjectTag key={t} label={t} />
                ))}
              </div>

              <p className="text-white/60 leading-relaxed mb-8 max-w-3xl text-[0.95rem]">
                Led full-scale iOS social media app backend development with nearly 100
                distinct features. Built AI-driven ML processors that categorize content
                and increase user interaction. Implemented robust auth, real-time content
                updates, private messaging, comment sections, and efficient media storage
                for image, audio, and video at scale.
              </p>

              <div className="grid sm:grid-cols-2 gap-3">
                {intunedHighlights.map((h) => (
                  <div
                    key={h.text}
                    className="flex items-start gap-3 p-4 rounded-xl bg-white/[0.03] border border-white/[0.06]"
                  >
                    <div className="w-7 h-7 rounded-md bg-cyan-600/25 flex items-center justify-center flex-shrink-0 mt-0.5">
                      <h.icon size={13} className="text-cyan-400" />
                    </div>
                    <p className="text-white/55 text-xs leading-relaxed">{h.text}</p>
                  </div>
                ))}
              </div>
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}
