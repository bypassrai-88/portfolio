"use client";

import { motion } from "framer-motion";
import { useInView } from "framer-motion";
import { useRef } from "react";
import { Briefcase } from "lucide-react";

const jobs = [
  {
    role: "Technical Support Specialist",
    company: "Davis Research",
    location: "Calabasas, California",
    period: "Mar 2024 – Apr 2025",
    bullets: [
      "Monitored and secured virtual and physical server environments; scanned for vulnerabilities and ensured uptime, reliability, and cybersecurity compliance.",
      "Delivered company-wide technical presentations — including a featured session on artificial intelligence — demonstrating technical leadership and cross-team communication.",
      "Developed and deployed Python-based automation tools, including custom language models that categorized large survey datasets into structured classifications.",
      "Managed and optimized Windows Server and virtualized environments — system patching, configuration, and troubleshooting to minimize downtime and improve efficiency.",
    ],
    tags: ["Python", "Cybersecurity", "AI/ML", "Windows Server", "Automation"],
  },
  {
    role: "C# Tutor",
    company: "Independent",
    location: "Thousand Oaks, California",
    period: "Aug 2024 – May 2025",
    bullets: [
      "Developed customized learning plans that resulted in measurably improved student performance.",
      "Facilitated interactive sessions that increased student engagement and comprehension.",
      "Fostered a collaborative environment, boosting student confidence and programming skills.",
    ],
    tags: ["C#", "Teaching", "Mentorship"],
  },
];

export default function Experience() {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true, margin: "-80px" });

  return (
    <section id="experience" className="relative py-28 px-6">
      <div className="max-w-5xl mx-auto" ref={ref}>
        <motion.p
          initial={{ opacity: 0, y: 10 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.5 }}
          className="section-label mb-4"
        >
          Experience
        </motion.p>

        <motion.h2
          initial={{ opacity: 0, y: 20 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6, delay: 0.1 }}
          className="text-3xl sm:text-4xl font-bold text-white mb-14"
        >
          Work History
        </motion.h2>

        <div className="relative pl-8">
          {/* Vertical line */}
          <div className="timeline-line" />

          <div className="space-y-12">
            {jobs.map((job, i) => (
              <motion.div
                key={job.role + job.company}
                initial={{ opacity: 0, x: -20 }}
                animate={inView ? { opacity: 1, x: 0 } : {}}
                transition={{ duration: 0.6, delay: 0.2 + i * 0.15 }}
                className="relative"
              >
                {/* Dot */}
                <div className="timeline-dot absolute -left-[2.35rem] top-1.5" />

                <div className="card p-7">
                  {/* Header row */}
                  <div className="flex flex-wrap items-start justify-between gap-3 mb-1">
                    <div className="flex items-start gap-3">
                      <div className="w-9 h-9 rounded-lg bg-indigo-600/20 flex items-center justify-center flex-shrink-0 mt-0.5">
                        <Briefcase size={16} className="text-indigo-400" />
                      </div>
                      <div>
                        <h3 className="text-white font-bold text-lg leading-tight">
                          {job.role}
                        </h3>
                        <p className="text-indigo-400 font-semibold text-sm">
                          {job.company}
                          <span className="text-white/35 font-normal">
                            {" "}
                            · {job.location}
                          </span>
                        </p>
                      </div>
                    </div>
                    <span className="text-xs text-white/40 font-medium whitespace-nowrap pt-1">
                      {job.period}
                    </span>
                  </div>

                  {/* Bullets */}
                  <ul className="mt-5 space-y-2.5">
                    {job.bullets.map((b) => (
                      <li
                        key={b}
                        className="flex items-start gap-3 text-white/60 text-[0.88rem] leading-relaxed"
                      >
                        <span className="mt-2 w-1.5 h-1.5 rounded-full bg-indigo-500/60 flex-shrink-0" />
                        {b}
                      </li>
                    ))}
                  </ul>

                  {/* Tags */}
                  <div className="flex flex-wrap gap-2 mt-5">
                    {job.tags.map((tag) => (
                      <span
                        key={tag}
                        className="px-2.5 py-0.5 text-[10px] font-semibold tracking-wider uppercase rounded-md bg-white/[0.04] border border-white/[0.08] text-white/40"
                      >
                        {tag}
                      </span>
                    ))}
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
