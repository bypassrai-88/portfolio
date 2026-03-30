"use client";

import React, { useRef } from "react";
import { motion } from "framer-motion";
import { useInView } from "framer-motion";
import { Mail, Phone, ArrowUpRight } from "lucide-react";

function GithubIcon({ size = 16, className }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" className={className}>
      <path d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z" />
    </svg>
  );
}

type IconComponent = React.ComponentType<{ size?: number; className?: string }>;

const contactItems: { icon: IconComponent; label: string; value: string; href: string; color: string }[] = [
  {
    icon: Mail as IconComponent,
    label: "Email",
    value: "connora888@gmail.com",
    href: "mailto:connora888@gmail.com",
    color: "indigo",
  },
  {
    icon: Phone as IconComponent,
    label: "Phone",
    value: "(805) 623-3940",
    href: "tel:8056233940",
    color: "cyan",
  },
  {
    icon: GithubIcon as IconComponent,
    label: "GitHub",
    value: "github.com/connor833",
    href: "https://github.com/connor833",
    color: "indigo",
  },
];

export default function Contact() {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true, margin: "-80px" });

  return (
    <section id="contact" className="relative py-28 px-6">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 opacity-[0.05]"
        style={{
          background:
            "radial-gradient(ellipse 60% 50% at 50% 50%, #6366f1, transparent)",
        }}
      />

      <div className="max-w-3xl mx-auto text-center" ref={ref}>
        <motion.p
          initial={{ opacity: 0, y: 10 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.5 }}
          className="section-label mb-4"
        >
          Contact
        </motion.p>

        <motion.h2
          initial={{ opacity: 0, y: 24 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6, delay: 0.1 }}
          className="text-3xl sm:text-4xl font-bold text-white mb-5"
        >
          Let&apos;s Build Something
        </motion.h2>

        <motion.p
          initial={{ opacity: 0, y: 16 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6, delay: 0.18 }}
          className="text-white/50 text-base leading-relaxed mb-14 max-w-lg mx-auto"
        >
          Whether it&apos;s a new opportunity, a collaboration, or just a conversation about
          software — I&apos;m always open to connecting.
        </motion.p>

        <div className="grid sm:grid-cols-3 gap-5">
          {contactItems.map((item, i) => (
            <motion.a
              key={item.label}
              href={item.href}
              target={item.label === "GitHub" ? "_blank" : undefined}
              rel={item.label === "GitHub" ? "noopener noreferrer" : undefined}
              initial={{ opacity: 0, y: 24 }}
              animate={inView ? { opacity: 1, y: 0 } : {}}
              transition={{ duration: 0.55, delay: 0.25 + i * 0.1 }}
              className="card p-6 flex flex-col items-center gap-3 group"
            >
              <div
                className={`w-11 h-11 rounded-xl flex items-center justify-center ${
                  item.color === "cyan"
                    ? "bg-cyan-600/20 group-hover:bg-cyan-600/35"
                    : "bg-indigo-600/20 group-hover:bg-indigo-600/35"
                } transition-colors`}
              >
                <item.icon
                  size={18}
                  className={
                    item.color === "cyan" ? "text-cyan-400" : "text-indigo-400"
                  }
                />
              </div>
              <div className="text-center">
                <p className="text-white/40 text-xs font-semibold tracking-wider uppercase mb-1">
                  {item.label}
                </p>
                <p className="text-white/80 group-hover:text-white transition-colors text-sm font-medium break-all">
                  {item.value}
                </p>
              </div>
              <ArrowUpRight
                size={14}
                className="text-white/20 group-hover:text-indigo-400 transition-colors mt-auto"
              />
            </motion.a>
          ))}
        </div>
      </div>
    </section>
  );
}
