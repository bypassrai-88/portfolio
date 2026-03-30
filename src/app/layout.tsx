import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
  display: "swap",
});

export const metadata: Metadata = {
  title: "Connor Adams — Software Engineer",
  description:
    "Software Engineer specializing in AI, full-stack development, iOS apps, and cybersecurity. Builder of Bypassr AI and In-Tuned.",
  keywords: [
    "Connor Adams",
    "Software Engineer",
    "Full Stack",
    "AI",
    "Next.js",
    "iOS",
    "Machine Learning",
  ],
  openGraph: {
    title: "Connor Adams — Software Engineer",
    description:
      "Software Engineer specializing in AI, full-stack development, and iOS apps.",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={inter.variable}>
      <body className="noise-bg">{children}</body>
    </html>
  );
}
