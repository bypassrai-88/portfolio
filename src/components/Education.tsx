"use client";

import { motion } from "framer-motion";
import { useInView } from "framer-motion";
import { useRef } from "react";
import { GraduationCap, Trophy, Star, Activity } from "lucide-react";

const achievements = [
  {
    icon: GraduationCap,
    label: "Graduated Cum Laude",
    desc: "Bachelor of Science in Computer Science",
  },
  {
    icon: Star,
    label: "Dean's List",
    desc: "Every semester at California Lutheran University",
  },
  {
    icon: Trophy,
    label: "Scholar Athlete Award",
    desc: "Recognized for academic excellence and athletic performance",
  },
  {
    icon: Activity,
    label: "Division III Baseball",
    desc: "Competed collegiately — discipline, teamwork, and peak performance",
  },
];

export default function Education() {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true, margin: "-80px" });

  return (
    <section id="education" className="relative py-16 px-6">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 opacity-[0.025]"
        style={{
          background:
            "radial-gradient(ellipse 70% 50% at 50% 100%, #22d3ee, transparent)",
        }}
      />

      <div className="max-w-5xl mx-auto" ref={ref}>
        <motion.p
          initial={{ opacity: 0, y: 10 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.5 }}
          className="section-label mb-4"
        >
          Education
        </motion.p>

        <motion.h2
          initial={{ opacity: 0, y: 20 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6, delay: 0.1 }}
          className="text-3xl sm:text-4xl font-bold text-white mb-14"
        >
          Academic Background
        </motion.h2>

        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.7, delay: 0.2 }}
          className="card p-8 md:p-10"
        >
          <div className="flex flex-wrap items-start justify-between gap-6 mb-8">
            <div>
              <h3 className="text-2xl sm:text-3xl font-bold text-white mb-1">
                Computer Science
              </h3>
              <p className="text-indigo-400 font-semibold text-base">
                California Lutheran University
                <span className="text-white/40 font-normal">
                  {" "}
                  · Thousand Oaks, CA
                </span>
              </p>
            </div>
            <div className="text-right">
              <span className="inline-block px-3 py-1.5 rounded-lg bg-indigo-600/20 border border-indigo-500/25 text-indigo-300 text-xs font-bold tracking-widest uppercase">
                Bachelor&apos;s Degree
              </span>
              <p className="text-white/35 text-xs font-medium mt-2">
                Aug 2021 – May 2025
              </p>
            </div>
          </div>

          <div className="grid sm:grid-cols-2 gap-4">
            {achievements.map((a, i) => (
              <motion.div
                key={a.label}
                initial={{ opacity: 0, y: 16 }}
                animate={inView ? { opacity: 1, y: 0 } : {}}
                transition={{ duration: 0.5, delay: 0.3 + i * 0.1 }}
                className="flex items-start gap-4 p-4 rounded-xl bg-white/[0.025] border border-white/[0.05]"
              >
                <div className="w-9 h-9 rounded-lg bg-cyan-600/20 flex items-center justify-center flex-shrink-0">
                  <a.icon size={16} className="text-cyan-400" />
                </div>
                <div>
                  <p className="text-white font-semibold text-sm">{a.label}</p>
                  <p className="text-white/45 text-xs leading-relaxed mt-0.5">
                    {a.desc}
                  </p>
                </div>
              </motion.div>
            ))}
          </div>
        </motion.div>
      </div>
    </section>
  );
}
