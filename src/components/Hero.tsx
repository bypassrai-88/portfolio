"use client";

import { motion } from "framer-motion";
import { Mail, Phone, ArrowDown, ExternalLink } from "lucide-react";

function GithubIcon({ size = 16, className }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" className={className}>
      <path d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z" />
    </svg>
  );
}

const fadeUp = (delay = 0) => ({
  initial: { opacity: 0, y: 30 },
  animate: { opacity: 1, y: 0 },
  transition: { duration: 0.7, delay, ease: [0.25, 0.1, 0.25, 1.0] as [number, number, number, number] },
});

export default function Hero() {
  return (
    <section
      id="hero"
      className="relative min-h-screen flex flex-col items-center justify-center grid-bg overflow-hidden px-6"
    >
      {/* Ambient blobs */}
      <div
        aria-hidden
        className="pointer-events-none absolute top-[-10%] left-[15%] w-[600px] h-[600px] rounded-full opacity-[0.07]"
        style={{
          background:
            "radial-gradient(circle, #6366f1 0%, transparent 70%)",
          filter: "blur(60px)",
        }}
      />
      <div
        aria-hidden
        className="pointer-events-none absolute bottom-[5%] right-[10%] w-[500px] h-[500px] rounded-full opacity-[0.06]"
        style={{
          background:
            "radial-gradient(circle, #22d3ee 0%, transparent 70%)",
          filter: "blur(60px)",
        }}
      />

      <div className="relative z-10 max-w-4xl mx-auto text-center">
        {/* Status badge */}
        <motion.div
          {...fadeUp(0.1)}
          className="inline-flex items-center gap-2 mb-8 px-4 py-2 rounded-full border border-[rgba(99,102,241,0.3)] bg-[rgba(99,102,241,0.08)] text-xs font-semibold tracking-widest uppercase text-indigo-300"
        >
          <span className="relative flex h-2 w-2">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-indigo-400 opacity-75" />
            <span className="relative inline-flex rounded-full h-2 w-2 bg-indigo-400" />
          </span>
          Available for opportunities
        </motion.div>

        {/* Name */}
        <motion.h1
          {...fadeUp(0.2)}
          className="text-6xl sm:text-7xl md:text-8xl font-black tracking-tight text-white mb-4 leading-[1.0]"
        >
          Connor
          <br />
          <span className="gradient-text text-glow">Adams</span>
        </motion.h1>

        {/* Title */}
        <motion.p
          {...fadeUp(0.35)}
          className="text-lg sm:text-xl text-white/50 font-medium tracking-widest uppercase mb-6 mt-2"
        >
          Software Engineer
        </motion.p>

        {/* Tagline */}
        <motion.p
          {...fadeUp(0.45)}
          className="text-base sm:text-lg text-white/60 max-w-2xl mx-auto leading-relaxed mb-10"
        >
          Building intelligent systems at the intersection of{" "}
          <span className="text-indigo-400 font-semibold">AI</span>,{" "}
          <span className="text-cyan-400 font-semibold">full-stack engineering</span>, and{" "}
          <span className="text-indigo-400 font-semibold">cybersecurity</span>.
        </motion.p>

        {/* CTA buttons */}
        <motion.div
          {...fadeUp(0.55)}
          className="flex flex-wrap justify-center gap-4 mb-12"
        >
          <a
            href="#projects"
            className="inline-flex items-center gap-2 px-7 py-3 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white font-semibold text-sm tracking-wide transition-all duration-200 hover:shadow-[0_0_30px_rgba(99,102,241,0.5)]"
          >
            View Projects
            <ExternalLink size={14} />
          </a>
          <a
            href="#contact"
            className="inline-flex items-center gap-2 px-7 py-3 rounded-xl border border-[rgba(99,102,241,0.35)] text-white/80 hover:text-white hover:border-indigo-500 font-semibold text-sm tracking-wide transition-all duration-200"
          >
            Get In Touch
          </a>
        </motion.div>

        {/* Contact chips */}
        <motion.div
          {...fadeUp(0.65)}
          className="flex flex-wrap justify-center gap-3"
        >
          <a
            href="mailto:connora888@gmail.com"
            className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/5 border border-white/10 text-white/60 hover:text-white hover:bg-white/10 text-xs font-medium transition-all"
          >
            <Mail size={13} className="text-indigo-400" />
            connora888@gmail.com
          </a>
          <a
            href="tel:8056233940"
            className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/5 border border-white/10 text-white/60 hover:text-white hover:bg-white/10 text-xs font-medium transition-all"
          >
            <Phone size={13} className="text-cyan-400" />
            (805) 623-3940
          </a>
          <a
            href="https://github.com/connor833"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/5 border border-white/10 text-white/60 hover:text-white hover:bg-white/10 text-xs font-medium transition-all"
          >
            <GithubIcon size={13} />
            github.com/connor833
          </a>
        </motion.div>
      </div>

      {/* Scroll indicator */}
      <motion.a
        href="#about"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1.2 }}
        className="absolute bottom-10 left-1/2 -translate-x-1/2 flex flex-col items-center gap-1 text-white/30 hover:text-white/60 transition-colors"
      >
        <span className="text-[10px] font-semibold tracking-widest uppercase">
          Scroll
        </span>
        <motion.div
          animate={{ y: [0, 6, 0] }}
          transition={{ repeat: Infinity, duration: 1.8, ease: "easeInOut" }}
        >
          <ArrowDown size={14} />
        </motion.div>
      </motion.a>
    </section>
  );
}
