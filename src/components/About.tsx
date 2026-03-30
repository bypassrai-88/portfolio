"use client";

import { motion } from "framer-motion";
import { useInView } from "framer-motion";
import { useRef } from "react";
import { Brain, Shield, Code2, Server, Globe, Layers } from "lucide-react";

const traits = [
  {
    icon: Globe,
    label: "Web Development",
    desc: "Building modern, performant web apps with Next.js, React, Node.js, PHP, and REST APIs.",
    color: "cyan",
  },
  {
    icon: Layers,
    label: "Full-Stack Engineering",
    desc: "End-to-end product ownership — polished frontends, scalable backends, clean architecture.",
    color: "indigo",
  },
  {
    icon: Brain,
    label: "AI & Machine Learning",
    desc: "Building language models and ML-driven systems for real-world data problems.",
    color: "indigo",
  },
  {
    icon: Shield,
    label: "Cybersecurity",
    desc: "Securing server infrastructure, scanning vulnerabilities, ensuring compliance.",
    color: "indigo",
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
              Building web products that{" "}
              <span className="gradient-text">look great</span> and{" "}
              <span className="gradient-text">scale further</span>.
            </h2>
            <p className="text-white/60 leading-relaxed mb-5 text-[0.95rem]">
              I&apos;m a Software Engineer specializing in modern web development —
              full-stack applications built with Next.js, React, Node.js, and PHP,
              paired with clean UI design and fast, reliable backends. I graduated
              Cum Laude in Computer Science from California Lutheran University,
              Dean&apos;s List every semester.
            </p>
            <p className="text-white/60 leading-relaxed text-[0.95rem]">
              Beyond the web, I bring depth in AI automation, iOS development, and
              cybersecurity — having built production ML pipelines, a full-scale
              iOS social app, and secured enterprise server environments. I care
              as much about the product experience as the code underneath it.
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
                <div className={`w-9 h-9 rounded-lg flex items-center justify-center mb-3 ${t.color === "cyan" ? "bg-cyan-600/20" : "bg-indigo-600/20"}`}>
                  <t.icon size={18} className={t.color === "cyan" ? "text-cyan-400" : "text-indigo-400"} />
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
