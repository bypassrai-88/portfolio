"use client";

import { motion } from "framer-motion";
import { useInView } from "framer-motion";
import { useRef } from "react";
import { Brain, Shield, Globe, Layers, ArrowUpRight } from "lucide-react";

const traits = [
  {
    icon: Globe,
    label: "Web Development",
    desc: "I build fast, clean web apps using Next.js, React, Node.js, PHP, and REST APIs. From landing pages to full products.",
    color: "cyan",
    href: "#skills",
  },
  {
    icon: Layers,
    label: "Full-Stack Engineering",
    desc: "I work across the whole stack. Frontend that looks good, backends that hold up, and code that stays maintainable.",
    color: "indigo",
    href: "#projects",
  },
  {
    icon: Brain,
    label: "AI and Machine Learning",
    desc: "I've built custom language models and ML pipelines that categorize data and power real features in production apps.",
    color: "indigo",
    href: "#projects",
  },
  {
    icon: Shield,
    label: "Cybersecurity",
    desc: "Hands-on experience securing server infrastructure, scanning for vulnerabilities, and keeping systems compliant.",
    color: "indigo",
    href: "#experience",
  },
];

export default function About() {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true, margin: "-80px" });

  return (
    <section id="about" className="relative py-16 px-6">
      <div className="max-w-5xl mx-auto" ref={ref}>
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
              Software engineer with a full-stack background and experience across{" "}
              <span className="gradient-text">web, mobile,</span> and{" "}
              <span className="gradient-text">AI development</span>.
            </h2>
            <p className="text-white/60 leading-relaxed mb-5 text-[0.95rem]">
              I&apos;m a Software Engineer focused on web development and full-stack
              applications. I work primarily with Next.js, React, and Node.js, and
              I care a lot about getting the details right on both sides of the stack.
              I graduated Cum Laude in Computer Science from California Lutheran
              University, Dean&apos;s List every semester.
            </p>
          </motion.div>

          {/* Trait cards — clickable, scroll to section */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {traits.map((t, i) => (
              <motion.a
                key={t.label}
                href={t.href}
                initial={{ opacity: 0, y: 20 }}
                animate={inView ? { opacity: 1, y: 0 } : {}}
                transition={{ duration: 0.5, delay: 0.2 + i * 0.1 }}
                className="card p-5 group block"
              >
                <div className="flex items-start justify-between mb-3">
                  <div className={`w-9 h-9 rounded-lg flex items-center justify-center ${t.color === "cyan" ? "bg-cyan-600/20" : "bg-indigo-600/20"}`}>
                    <t.icon size={18} className={t.color === "cyan" ? "text-cyan-400" : "text-indigo-400"} />
                  </div>
                  <ArrowUpRight
                    size={13}
                    className="text-white/20 group-hover:text-indigo-400 transition-colors mt-1"
                  />
                </div>
                <p className="text-white font-semibold text-sm mb-1">
                  {t.label}
                </p>
                <p className="text-white/50 text-xs leading-relaxed">{t.desc}</p>
              </motion.a>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
