"use client";

import { motion } from "framer-motion";
import { Mail, Phone, ArrowDown, ExternalLink } from "lucide-react";

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

      <div className="relative z-10 max-w-4xl mx-auto text-center pb-20">
        {/* Name */}
        <motion.h1
          {...fadeUp(0.1)}
          className="text-6xl sm:text-7xl md:text-8xl font-black tracking-tight text-white mb-4 leading-[1.0] mt-20"
        >
          Connor
          <br />
          <span className="gradient-text text-glow">Adams</span>
        </motion.h1>

        {/* Title */}
        <motion.p
          {...fadeUp(0.22)}
          className="text-lg sm:text-xl text-white/50 font-medium tracking-widest uppercase mb-6 mt-2"
        >
          Software Engineer
        </motion.p>

        {/* Tagline */}
        <motion.p
          {...fadeUp(0.32)}
          className="text-base sm:text-lg text-white/60 max-w-2xl mx-auto leading-relaxed mb-10"
        >
          Programmer focused on web and mobile development.
        </motion.p>

        {/* CTA buttons */}
        <motion.div
          {...fadeUp(0.42)}
          className="flex flex-wrap justify-center gap-4 mb-10"
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
          {...fadeUp(0.52)}
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
        </motion.div>
      </div>

      {/* Scroll indicator */}
      <motion.a
        href="#about"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.9 }}
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
