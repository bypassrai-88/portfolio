"use client";

import { motion } from "framer-motion";
import { useInView } from "framer-motion";
import { useRef } from "react";

const skillGroups = [
  {
    category: "Languages",
    skills: ["Java", "Python", "TypeScript", "PHP", "C++", "C#", "Swift", "Ruby", "SQL"],
  },
  {
    category: "Web Development",
    skills: ["Next.js", "React", "Node.js", "REST APIs", "Tailwind CSS", "HTML", "CSS", "Responsive Design", "PHP"],
  },
  {
    category: "UI & Design",
    skills: ["Component Design", "Mobile-First", "Animations", "Accessibility", "UI/UX"],
  },
  {
    category: "AI & Data",
    skills: ["Machine Learning", "Artificial Intelligence", "Language Models", "Data Classification"],
  },
  {
    category: "Infrastructure & DevOps",
    skills: ["AWS", "Docker", "GitLab CI/CD", "DevOps Practices", "Server Management"],
  },
  {
    category: "Architecture & Patterns",
    skills: ["MVVM", "MVC", "REST APIs", "Component Architecture", "Modular Design"],
  },
  {
    category: "Databases & Security",
    skills: ["MySQL", "SQL Databases", "Cybersecurity", "Windows Server", "Virtualization"],
  },
];

export default function Skills() {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true, margin: "-80px" });

  return (
    <section id="skills" className="relative py-16 px-6">
      {/* Background accent */}
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 opacity-[0.03]"
        style={{
          background:
            "radial-gradient(ellipse 80% 50% at 50% 0%, #6366f1, transparent)",
        }}
      />

      <div className="max-w-5xl mx-auto relative z-10" ref={ref}>
        <motion.p
          initial={{ opacity: 0, y: 10 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.5 }}
          className="section-label mb-4"
        >
          Skills
        </motion.p>

        <motion.h2
          initial={{ opacity: 0, y: 20 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6, delay: 0.1 }}
          className="text-3xl sm:text-4xl font-bold text-white mb-12"
        >
          Technology Stack
        </motion.h2>

        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {skillGroups.map((group, gi) => (
            <motion.div
              key={group.category}
              initial={{ opacity: 0, y: 20 }}
              animate={inView ? { opacity: 1, y: 0 } : {}}
              transition={{ duration: 0.5, delay: 0.12 + gi * 0.07 }}
              className="card p-5"
            >
              <p className="text-[10px] font-bold tracking-widest uppercase text-white/35 mb-3">
                {group.category}
              </p>
              <div className="flex flex-wrap gap-1.5">
                {group.skills.map((skill) => (
                  <span key={skill} className="skill-badge">
                    {skill}
                  </span>
                ))}
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
