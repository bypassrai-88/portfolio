"use client";

import { motion } from "framer-motion";
import { useInView } from "framer-motion";
import { useRef } from "react";
import { Code2, FileCode, GitBranch, Terminal } from "lucide-react";

const slots = [
  {
    icon: FileCode,
    label: "Python — Language Model",
    desc: "Custom NLP classifier for survey data categorization.",
    lang: "Python",
    color: "indigo",
  },
  {
    icon: Terminal,
    label: "Swift — iOS Backend Logic",
    desc: "Core data pipeline and ML integration from In-Tuned.",
    lang: "Swift",
    color: "cyan",
  },
  {
    icon: GitBranch,
    label: "TypeScript — API Route",
    desc: "URL-aware summarizer with SSRF protection from Bypassr AI.",
    lang: "TypeScript",
    color: "indigo",
  },
  {
    icon: Code2,
    label: "Java / C++ — Algorithm",
    desc: "Data structure or algorithmic solution showcasing systems-level thinking.",
    lang: "Java / C++",
    color: "cyan",
  },
];

export default function CodeShowcase() {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true, margin: "-80px" });

  return (
    <section id="code" className="relative py-28 px-6">
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
          className="text-3xl sm:text-4xl font-bold text-white mb-3"
        >
          Code Showcase
        </motion.h2>

        <motion.p
          initial={{ opacity: 0, y: 16 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6, delay: 0.18 }}
          className="text-white/45 text-sm mb-12 max-w-xl leading-relaxed"
        >
          This section will feature selected code snippets — real files from production
          projects, demonstrating language depth, architectural thinking, and clean
          engineering. Content coming soon.
        </motion.p>

        <div className="grid sm:grid-cols-2 gap-5">
          {slots.map((slot, i) => (
            <motion.div
              key={slot.label}
              initial={{ opacity: 0, y: 24 }}
              animate={inView ? { opacity: 1, y: 0 } : {}}
              transition={{ duration: 0.55, delay: 0.2 + i * 0.1 }}
              className="card p-6 flex flex-col gap-4"
            >
              {/* Top bar - fake code editor chrome */}
              <div className="flex items-center gap-1.5 mb-1">
                <span className="w-2.5 h-2.5 rounded-full bg-red-500/50" />
                <span className="w-2.5 h-2.5 rounded-full bg-yellow-500/50" />
                <span className="w-2.5 h-2.5 rounded-full bg-green-500/50" />
                <span className="ml-auto text-[10px] text-white/25 font-mono">
                  {slot.lang.toLowerCase().replace(/ \/ /g, "-").replace(/ /g, "-")}.snippet
                </span>
              </div>

              {/* Fake code lines */}
              <div className="rounded-lg bg-black/40 border border-white/[0.05] p-4 font-mono text-[11px] space-y-1.5 min-h-[100px] flex flex-col justify-center">
                <div className="flex gap-3">
                  <span className="text-white/20 select-none w-3">1</span>
                  <span className="text-purple-400/70">{"// coming soon"}</span>
                </div>
                <div className="flex gap-3">
                  <span className="text-white/20 select-none w-3">2</span>
                  <span className="text-cyan-400/50">{"import"}</span>
                  <span className="text-white/40">{"{ ... }"}</span>
                </div>
                <div className="flex gap-3">
                  <span className="text-white/20 select-none w-3">3</span>
                  <span className="text-white/20">{"·"}</span>
                </div>
                <div className="flex gap-3">
                  <span className="text-white/20 select-none w-3">4</span>
                  <span className="text-indigo-400/50">{"function"}</span>
                  <span className="text-white/40">{"solution() {"}</span>
                </div>
                <div className="flex gap-3">
                  <span className="text-white/20 select-none w-3">5</span>
                  <span className="text-white/20 ml-4">{"// real code coming"}</span>
                </div>
                <div className="flex gap-3">
                  <span className="text-white/20 select-none w-3">6</span>
                  <span className="text-white/40">{"}"}</span>
                </div>
              </div>

              {/* Meta */}
              <div className="flex items-start gap-3">
                <div
                  className={`w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0 ${
                    slot.color === "cyan"
                      ? "bg-cyan-600/20"
                      : "bg-indigo-600/20"
                  }`}
                >
                  <slot.icon
                    size={14}
                    className={
                      slot.color === "cyan" ? "text-cyan-400" : "text-indigo-400"
                    }
                  />
                </div>
                <div>
                  <p className="text-white font-semibold text-sm">{slot.label}</p>
                  <p className="text-white/40 text-xs leading-relaxed mt-0.5">
                    {slot.desc}
                  </p>
                </div>
              </div>
            </motion.div>
          ))}
        </div>

        <motion.p
          initial={{ opacity: 0 }}
          animate={inView ? { opacity: 1 } : {}}
          transition={{ duration: 0.5, delay: 0.7 }}
          className="text-center text-white/25 text-xs mt-8 font-medium tracking-wide"
        >
          Full code samples will be added in the next iteration of this portfolio.
        </motion.p>
      </div>
    </section>
  );
}
