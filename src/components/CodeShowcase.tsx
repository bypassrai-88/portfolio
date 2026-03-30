"use client";

import { motion } from "framer-motion";
import { useInView } from "framer-motion";
import { useRef, useState, useEffect } from "react";
import { Copy, Check, Loader2 } from "lucide-react";

const files = [
  { name: "summarize-url/route.ts",  lang: "TypeScript", project: "Bypassr AI",  file: "summarize-url.route.txt" },
  { name: "EssayWriterClient.tsx",   lang: "TypeScript", project: "Bypassr AI",  file: "EssayWriterClient.txt" },
  { name: "SummarizerClient.tsx",    lang: "TypeScript", project: "Bypassr AI",  file: "SummarizerClient.txt" },
  { name: "UserService.swift",       lang: "Swift",      project: "In-Tuned",    file: "UserService.swift" },
  { name: "ConversationService.swift", lang: "Swift",    project: "In-Tuned",    file: "ConversationService.swift" },
  { name: "PlayerViewModel.swift",   lang: "Swift",      project: "In-Tuned",    file: "PlayerViewModel.swift" },
];

function highlight(code: string, lang: string): string {
  const swiftKw = /\b(import|struct|class|func|let|var|guard|return|if|else|do|catch|try|throws|async|await|private|public|internal|static|override|init|self|nil|true|false|for|in|switch|case|default|break|continue|where|extension|protocol|enum|defer|Task|DispatchGroup|DispatchQueue|Date|UUID|NSNull|NSError|FieldValue|Firestore|Auth|Functions|Query|Timestamp|DocumentSnapshot|ListenerRegistration)\b/g;
  const tsKwPat = /\b(import|export|from|const|let|var|function|async|await|return|if|else|try|catch|throw|new|typeof|type|interface|class|extends|implements|default|null|undefined|true|false|for|of|in|switch|case|break|continue|void|string|number|boolean|Promise|Response|NextRequest|NextResponse|headers|fetch)\b/g;
  const swiftAttr = /(@Published|@MainActor|@escaping|@objc|@State|@Binding|@Environment|@ObservableObject|@StateObject|@EnvironmentObject)\b/g;
  const tsDecorator = /\b(useState|useEffect|useRef|useRouter|useCallback|useMemo)\b/g;

  let out = code
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");

  // Numbers
  out = out.replace(/\b(\d+(\.\d+)?)\b/g, '<span style="color:#fb923c">$1</span>');
  // Strings (color after numbers so numbers inside strings stay green)
  out = out.replace(/(["'`])((?:\\.|(?!\1)[^\\])*)\1/g, '<span style="color:#86efac">$1$2$1</span>');
  // Decorators/attributes
  out = out.replace(lang === "Swift" ? swiftAttr : tsDecorator, '<span style="color:#f472b6">$1</span>');
  // Keywords
  out = out.replace(lang === "Swift" ? swiftKw : tsKwPat, '<span style="color:#c084fc">$1</span>');

  return out;
}

export default function CodeShowcase() {
  const ref      = useRef(null);
  const inView   = useInView(ref, { once: true, margin: "-80px" });
  const [active, setActive]   = useState(0);
  const [code, setCode]       = useState("");
  const [loading, setLoading] = useState(false);
  const [copied, setCopied]   = useState(false);

  useEffect(() => {
    setLoading(true);
    setCode("");
    fetch(`/code/${files[active].file}`)
      .then(r => r.text())
      .then(text => { setCode(text); setLoading(false); })
      .catch(() => { setCode("// Could not load file."); setLoading(false); });
  }, [active]);

  const handleCopy = () => {
    navigator.clipboard.writeText(code).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  };

  const file = files[active];

  return (
    <section id="code" className="relative py-16 px-6">
      <div className="max-w-5xl mx-auto" ref={ref}>
        <motion.p
          initial={{ opacity: 0, y: 10 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.5 }}
          className="section-label mb-4"
        >
          Code
        </motion.p>

        <motion.h2
          initial={{ opacity: 0, y: 20 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6, delay: 0.1 }}
          className="text-3xl sm:text-4xl font-bold text-white mb-3"
        >
          Code Showcase
        </motion.h2>

        <motion.p
          initial={{ opacity: 0, y: 16 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6, delay: 0.15 }}
          className="text-white/45 text-[0.95rem] mb-8"
        >
          A few files I picked to show some of my work from the recent projects.
        </motion.p>

        <motion.div
          initial={{ opacity: 0, y: 24 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6, delay: 0.2 }}
          className="card overflow-hidden"
        >
          {/* Tab bar */}
          <div className="border-b border-white/[0.07] bg-black/20 overflow-x-auto">
            <div className="flex items-stretch min-w-max">
              <span className="flex-shrink-0 px-4 py-2.5 text-[9px] font-black tracking-widest uppercase text-indigo-400/70 border-r border-white/[0.06] flex items-center">
                Bypassr AI
              </span>
              {files.filter(f => f.project === "Bypassr AI").map(f => {
                const i = files.indexOf(f);
                return (
                  <button key={f.name} onClick={() => setActive(i)}
                    className={`flex-shrink-0 px-4 py-3 text-[11px] font-semibold tracking-wide transition-all border-b-2 ${
                      active === i ? "border-indigo-400 text-indigo-300 bg-white/[0.04]" : "border-transparent text-white/35 hover:text-white/60"
                    }`}>
                    {f.name}
                  </button>
                );
              })}
              <div className="w-px bg-white/[0.08] mx-1 self-stretch" />
              <span className="flex-shrink-0 px-4 py-2.5 text-[9px] font-black tracking-widest uppercase text-cyan-500/70 flex items-center">
                In-Tuned
              </span>
              {files.filter(f => f.project === "In-Tuned").map(f => {
                const i = files.indexOf(f);
                return (
                  <button key={f.name} onClick={() => setActive(i)}
                    className={`flex-shrink-0 px-4 py-3 text-[11px] font-semibold tracking-wide transition-all border-b-2 ${
                      active === i ? "border-cyan-400 text-cyan-300 bg-white/[0.04]" : "border-transparent text-white/35 hover:text-white/60"
                    }`}>
                    {f.name}
                  </button>
                );
              })}
            </div>
          </div>

          {/* File meta bar */}
          <div className="flex items-center justify-between px-5 py-2.5 bg-black/10 border-b border-white/[0.05]">
            <div className="flex items-center gap-3">
              <span className={`text-[10px] font-bold tracking-widest uppercase px-2 py-0.5 rounded ${
                file.project === "In-Tuned" ? "bg-cyan-500/15 text-cyan-400" : "bg-indigo-500/15 text-indigo-400"
              }`}>
                {file.lang}
              </span>
              <span className="text-white/30 text-[11px]">{file.project}</span>
              {!loading && code && (
                <span className="text-white/20 text-[11px]">{code.split("\n").length} lines</span>
              )}
            </div>
            <button onClick={handleCopy}
              className="flex items-center gap-1.5 text-[11px] text-white/40 hover:text-white/70 transition-colors">
              {copied ? <Check size={12} className="text-green-400" /> : <Copy size={12} />}
              {copied ? "Copied" : "Copy"}
            </button>
          </div>

          {/* Code block */}
          <div className="overflow-x-auto overflow-y-auto max-h-[560px]">
            {loading ? (
              <div className="flex items-center justify-center h-40">
                <Loader2 size={20} className="text-white/30 animate-spin" />
              </div>
            ) : (
              <pre className="p-6 text-[12px] leading-[1.7] font-mono text-white/75">
                <code dangerouslySetInnerHTML={{ __html: highlight(code, file.lang) }} />
              </pre>
            )}
          </div>
        </motion.div>


      </div>
    </section>
  );
}
