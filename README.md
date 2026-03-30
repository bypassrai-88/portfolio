# Connor Adams — Portfolio

Personal portfolio built with **Next.js 14 (App Router)**, **TypeScript**, **Tailwind CSS**, and **Framer Motion**. Deployable to Vercel in one click.

## Structure

```
src/
  app/
    globals.css       # Design tokens, utilities, animations
    layout.tsx        # Root layout + metadata
    page.tsx          # Page assembly
  components/
    Navbar.tsx        # Sticky nav with mobile menu
    Hero.tsx          # Full-screen hero
    About.tsx         # Summary + trait cards
    Skills.tsx        # Grouped skill badges
    Projects.tsx      # Bypassr AI + In-Tuned project cards
    InTunedGallery.tsx # iOS screenshot gallery
    Experience.tsx    # Timeline work history
    Education.tsx     # Academic background
    CodeShowcase.tsx  # Code samples placeholder
    Contact.tsx       # Contact cards
    Footer.tsx        # Footer

public/
  screenshots/        # Drop intuned-1.png through intuned-6.png here
```

## Adding In-Tuned Screenshots

1. Export screenshots from your iPhone/Simulator.
2. Rename them `intuned-1.png` through `intuned-6.png`.
3. Drop them in `public/screenshots/`.
4. The gallery renders them automatically with a lightbox.

## Local Development

```bash
npm install
npm run dev
```

Visit [http://localhost:3000](http://localhost:3000).

## Deploying to Vercel

1. Push this repo to GitHub.
2. Go to [vercel.com/new](https://vercel.com/new) → Import the repo.
3. Framework will auto-detect as **Next.js**. Click **Deploy**.

That's it — no environment variables required for the base portfolio.
