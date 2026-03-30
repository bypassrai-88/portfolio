import Navbar from "@/components/Navbar";
import Hero from "@/components/Hero";
import About from "@/components/About";
import Skills from "@/components/Skills";
import Projects from "@/components/Projects";
import InTunedGallery from "@/components/InTunedGallery";
import Education from "@/components/Education";
import CodeShowcase from "@/components/CodeShowcase";
import Contact from "@/components/Contact";
import Footer from "@/components/Footer";

export default function Home() {
  return (
    <main className="relative min-h-screen">
      <Navbar />
      <Hero />
      <About />
      <Skills />
      <Projects />
      <InTunedGallery />
      <Education />
      <CodeShowcase />
      <Contact />
      <Footer />
    </main>
  );
}
