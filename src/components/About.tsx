"use client";

import { motion } from "framer-motion";
import { useInView } from "framer-motion";
import { useRef } from "react";
import { Brain, Shield, Code2, Server } from "lucide-react";

const traits = [
  {
    icon: Brain,
    label: "AI & Machine Learning",
    desc: "Building language models and ML-driven systems for real-world data problems.",
  },
  {
    icon: Code2,
    label: "Full-Stack Engineering",
    desc: "End-to-end product development — from polished UIs to scalable backends.",
  },
  {
    icon: Shield,
    label: "Cybersecurity",
    desc: "Securing server infrastructure, scanning vulnerabilities, ensuring compliance.",
  },
  {
    icon: Server,
    label: "Server & DevOps",
    desc: "Managing Windows Server, virtual environments, CI/CD, Docker, and AWS.",
  },
];

export default function About() {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true, margin: "-80px" });

  return (
    <section id="about" className="relative py-28 px-6">
      <div className="max-w-5xl mx-auto" ref={ref}>
        {/* Label */}
        <motion.p
          initial={{ opacity: 0, y: 10 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.5 }}
          className="section-label mb-4"
        >
          About Me
        </motion.p>

        <div className="grid md:grid-cols-2 gap-12 items-start">
          {/* Text block */}
          <motion.div
            initial={{ opacity: 0, x: -30 }}
            animate={inView ? { opacity: 1, x: 0 } : {}}
            transition={{ duration: 0.7, delay: 0.1 }}
          >
            <h2 className="text-3xl sm:text-4xl font-bold text-white mb-6 leading-tight">
              Engineering software that{" "}
              <span className="gradient-text">thinks</span> and{" "}
              <span className="gradient-text">scales</span>.
            </h2>
            <p className="text-white/60 leading-relaxed mb-5 text-[0.95rem]">
              I&apos;m a Software Engineer with a Computer Science degree from California
              Lutheran University — graduated Cum Laude, Dean&apos;s List every
              semester, and Scholar Athlete. My background spans technical
              support, server management, and cybersecurity, with a strong focus
              on AI and automation.
            </p>
            <p className="text-white/60 leading-relaxed text-[0.95rem]">
              I&apos;ve built Python-based language models that classify large
              survey datasets, secured enterprise server environments, and
              developed full-scale iOS and web applications. I write clean,
              deliberate code and care about the product experience as much as
              the underlying system.
            </p>
          </motion.div>

          {/* Trait cards */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {traits.map((t, i) => (
              <motion.div
                key={t.label}
                initial={{ opacity: 0, y: 20 }}
                animate={inView ? { opacity: 1, y: 0 } : {}}
                transition={{ duration: 0.5, delay: 0.2 + i * 0.1 }}
                className="card p-5"
              >
                <div className="w-9 h-9 rounded-lg bg-indigo-600/20 flex items-center justify-center mb-3">
                  <t.icon size={18} className="text-indigo-400" />
                </div>
                <p className="text-white font-semibold text-sm mb-1">
                  {t.label}
                </p>
                <p className="text-white/50 text-xs leading-relaxed">{t.desc}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
