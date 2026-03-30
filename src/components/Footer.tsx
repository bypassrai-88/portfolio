"use client";

import { motion } from "framer-motion";

export default function Footer() {
  return (
    <footer className="relative border-t border-[rgba(99,102,241,0.1)] py-8 px-6">
      <div className="max-w-5xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4">
        <p className="text-white/25 text-xs font-medium tracking-widest uppercase">
          Connor Adams · Software Engineer
        </p>
        <p className="text-white/20 text-xs">
          Built with Next.js, Tailwind CSS, Framer Motion
        </p>
        <a
          href="#hero"
          className="text-white/25 hover:text-indigo-400 text-xs font-semibold tracking-widest uppercase transition-colors"
        >
          Back to Top ↑
        </a>
      </div>
    </footer>
  );
}
