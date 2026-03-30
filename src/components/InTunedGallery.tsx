"use client";

import { motion } from "framer-motion";
import { useInView } from "framer-motion";
import { useRef, useState } from "react";
import { ImagePlus, X } from "lucide-react";
import Image from "next/image";

const SLOT_COUNT = 6;

const placeholderLabels = [
  "Home Feed",
  "Profile View",
  "Messaging",
  "Content Upload",
  "Discover",
  "Notifications",
];

export default function InTunedGallery() {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true, margin: "-80px" });
  const [lightbox, setLightbox] = useState<string | null>(null);

  const screenShotPaths = Array.from({ length: SLOT_COUNT }, (_, i) => {
    return `/screenshots/intuned-${i + 1}.png`;
  });

  return (
    <>
      <section id="intuned-gallery" className="relative py-28 px-6">
        <div className="max-w-5xl mx-auto" ref={ref}>
          <motion.p
            initial={{ opacity: 0, y: 10 }}
            animate={inView ? { opacity: 1, y: 0 } : {}}
            transition={{ duration: 0.5 }}
            className="section-label mb-4"
          >
            In-Tuned — UI Showcase
          </motion.p>

          <motion.h2
            initial={{ opacity: 0, y: 20 }}
            animate={inView ? { opacity: 1, y: 0 } : {}}
            transition={{ duration: 0.6, delay: 0.1 }}
            className="text-3xl sm:text-4xl font-bold text-white mb-4"
          >
            App Screenshots
          </motion.h2>

          <motion.p
            initial={{ opacity: 0, y: 16 }}
            animate={inView ? { opacity: 1, y: 0 } : {}}
            transition={{ duration: 0.6, delay: 0.18 }}
            className="text-white/50 text-sm mb-12 max-w-xl"
          >
            Drop your screenshots into{" "}
            <code className="text-indigo-400 bg-indigo-950/50 px-1.5 py-0.5 rounded text-xs">
              public/screenshots/
            </code>{" "}
            named{" "}
            <code className="text-indigo-400 bg-indigo-950/50 px-1.5 py-0.5 rounded text-xs">
              intuned-1.png
            </code>{" "}
            through{" "}
            <code className="text-indigo-400 bg-indigo-950/50 px-1.5 py-0.5 rounded text-xs">
              intuned-6.png
            </code>{" "}
            and they will appear here automatically.
          </motion.p>

          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-6 gap-4">
            {screenShotPaths.map((src, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, y: 20 }}
                animate={inView ? { opacity: 1, y: 0 } : {}}
                transition={{ duration: 0.5, delay: 0.2 + i * 0.07 }}
                className="relative"
              >
                <ScreenshotSlot
                  src={src}
                  label={placeholderLabels[i]}
                  index={i + 1}
                  onClick={() => setLightbox(src)}
                />
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Lightbox */}
      {lightbox && (
        <div
          className="fixed inset-0 z-50 bg-black/90 backdrop-blur-sm flex items-center justify-center p-6"
          onClick={() => setLightbox(null)}
        >
          <button
            className="absolute top-5 right-5 text-white/60 hover:text-white transition-colors"
            onClick={() => setLightbox(null)}
            aria-label="Close"
          >
            <X size={24} />
          </button>
          <div
            className="relative max-h-[90vh] max-w-[400px] w-full rounded-2xl overflow-hidden"
            onClick={(e) => e.stopPropagation()}
          >
            <Image
              src={lightbox}
              alt="In-Tuned screenshot"
              width={400}
              height={860}
              className="w-full h-auto object-contain"
            />
          </div>
        </div>
      )}
    </>
  );
}

function ScreenshotSlot({
  src,
  label,
  index,
  onClick,
}: {
  src: string;
  label: string;
  index: number;
  onClick: () => void;
}) {
  const [loaded, setLoaded] = useState(false);
  const [error, setError] = useState(false);

  if (error || !src) {
    return (
      <div className="screenshot-slot group">
        <div className="w-10 h-10 rounded-xl bg-indigo-600/15 border border-indigo-500/20 flex items-center justify-center mb-3">
          <ImagePlus size={18} className="text-indigo-500/60" />
        </div>
        <p className="text-[10px] font-semibold text-white/30 tracking-wide text-center px-2">
          {label}
        </p>
        <p className="text-[9px] text-white/20 mt-1">intuned-{index}.png</p>
      </div>
    );
  }

  return (
    <button
      onClick={onClick}
      className="screenshot-slot relative overflow-hidden group cursor-pointer w-full"
      aria-label={`View ${label} screenshot`}
    >
      <Image
        src={src}
        alt={label}
        fill
        className={`object-cover transition-opacity duration-300 ${
          loaded ? "opacity-100" : "opacity-0"
        }`}
        onLoad={() => setLoaded(true)}
        onError={() => setError(true)}
        sizes="(max-width: 640px) 50vw, (max-width: 768px) 33vw, 16vw"
      />
      {!loaded && (
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          <ImagePlus size={18} className="text-indigo-500/60" />
        </div>
      )}
      <div className="absolute inset-0 bg-black/0 group-hover:bg-black/30 transition-colors flex items-end p-2 opacity-0 group-hover:opacity-100">
        <p className="text-white text-[10px] font-semibold">{label}</p>
      </div>
    </button>
  );
}
