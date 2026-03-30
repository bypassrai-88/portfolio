"use client";

import { motion } from "framer-motion";
import { useInView } from "framer-motion";
import { useRef, useState } from "react";
import Image from "next/image";
import {
  ExternalLink,
  Layers,
  Brain,
  ShieldCheck,
  Smartphone,
  Globe,
  Database,
  X,
} from "lucide-react";

const screenshots = [
  { src: "/screenshots/intuned-1.png", label: "Home Feed" },
  { src: "/screenshots/intuned-2.png", label: "Profile" },
  { src: "/screenshots/intuned-3.png", label: "Discover" },
  { src: "/screenshots/intuned-4.png", label: "RSS Upload" },
  { src: "/screenshots/intuned-5.png", label: "Sign In" },
  { src: "/screenshots/intuned-6.png", label: "Sign Up" },
];

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
    icon: Layers,
    text: "MVVM architecture — clean separation of Views, ViewModels, and data Models throughout the entire codebase",
  },
  {
    icon: Smartphone,
    text: "Full iOS social media app — nearly 100 distinct features built in Swift",
  },
  {
    icon: Brain,
    text: "ML processors that categorize content and drive user interaction algorithms",
  },
  {
    icon: ShieldCheck,
    text: "Robust user authentication — login, session management, and security flows",
  },
  {
    icon: Database,
    text: "Backend handles DMs, comments, real-time updates, media storage (image/audio/video)",
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
  const [lightbox, setLightbox] = useState<string | null>(null);

  return (
    <>
    <section id="projects" className="relative py-16 px-6">
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
          Recent Projects
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
              <div className="mb-6">
                <p className="text-xs font-bold tracking-widest uppercase text-white/30 mb-1">
                  01 — Web Application
                </p>
                <h3 className="text-2xl sm:text-3xl font-bold text-white">
                  Bypassr AI
                </h3>
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
                A production full-stack AI writing suite covering essay drafting, grammar, link-aware
                summarization, translation, and paraphrasing. The same codebase powers two
                distinct product experiences ({'"writing suite"'} and{" "}
                {'"humanizer"'}) switched entirely through a build-time environment variable. One codebase,
                no forked repos, two different markets.
              </p>

              {/* Highlights */}
              <div className="grid sm:grid-cols-2 gap-3 mb-8">
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

              {/* CTA */}
              <a
                href="https://bypassrai.com"
                target="_blank"
                rel="noopener noreferrer"
                className="group w-full flex items-center justify-center gap-3 px-6 py-4 rounded-xl font-semibold text-sm tracking-wide text-white transition-all duration-300 hover:shadow-[0_0_40px_rgba(99,102,241,0.5)]"
                style={{
                  background: "linear-gradient(135deg, #6366f1 0%, #4f46e5 50%, #22d3ee 100%)",
                }}
              >
                Visit Bypassr AI
                <ExternalLink size={15} className="group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-transform" />
              </a>
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
              <div className="mb-6">
                <p className="text-xs font-bold tracking-widest uppercase text-white/30 mb-1">
                  02 — iOS Application
                </p>
                <h3 className="text-2xl sm:text-3xl font-bold text-white">
                  In-Tuned
                </h3>
              </div>

              {/* Tags */}
              <div className="flex flex-wrap gap-2 mb-6">
                {[
                  "Swift",
                  "iOS",
                  "MVVM",
                  "Machine Learning",
                  "Backend",
                  "Real-time",
                  "Media Storage",
                ].map((t) => (
                  <ProjectTag key={t} label={t} />
                ))}
              </div>

              <p className="text-white/60 leading-relaxed mb-6 max-w-3xl text-[0.95rem]">
                Led full-scale iOS social media app development with nearly 100 distinct
                features, architected using <span className="text-cyan-400 font-semibold">MVVM</span> for
                clean separation of views, view models, and data models. Built AI-driven ML
                processors that categorize content and drive interaction. Implemented robust
                auth, real-time updates, private messaging, comment sections, and scalable
                media storage for image, audio, and video.
              </p>

              <div className="grid sm:grid-cols-2 gap-3 mb-8">
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

              {/* Screenshots inside the card */}
              <div className="border-t border-white/[0.06] pt-6">
                <p className="text-[10px] font-bold tracking-widest uppercase text-white/30 mb-4">
                  UI Screenshots
                </p>
                <div className="grid grid-cols-3 sm:grid-cols-6 gap-2">
                  {screenshots.map((s) => (
                    <button
                      key={s.src}
                      onClick={() => setLightbox(s.src)}
                      className="group relative rounded-xl overflow-hidden border border-white/[0.08] hover:border-cyan-500/40 transition-all"
                      style={{ aspectRatio: "9/19.5" }}
                      aria-label={s.label}
                    >
                      <Image
                        src={s.src}
                        alt={s.label}
                        fill
                        className="object-cover group-hover:scale-105 transition-transform duration-300"
                        sizes="(max-width: 640px) 33vw, 16vw"
                      />
                      <div className="absolute inset-0 bg-black/0 group-hover:bg-black/25 transition-colors flex items-end p-1.5 opacity-0 group-hover:opacity-100">
                        <p className="text-white text-[9px] font-semibold leading-tight">{s.label}</p>
                      </div>
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </motion.div>
        </div>
      </div>
    </section>

    {/* Lightbox */}
    {lightbox && (
      <div
        className="fixed inset-0 z-50 bg-black/90 backdrop-blur-sm flex items-center justify-center p-6"
        onClick={() => setLightbox(null)}
      >
        <button
          className="absolute top-5 right-5 text-white/60 hover:text-white transition-colors"
          onClick={() => setLightbox(null)}
          aria-label="Close"
        >
          <X size={24} />
        </button>
        <div
          className="relative max-h-[90vh] max-w-[360px] w-full rounded-2xl overflow-hidden"
          onClick={(e) => e.stopPropagation()}
        >
          <Image
            src={lightbox}
            alt="In-Tuned screenshot"
            width={360}
            height={780}
            className="w-full h-auto object-contain"
          />
        </div>
      </div>
    )}
  </>
  );
}
