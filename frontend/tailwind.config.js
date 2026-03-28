/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        forge: {
          bg: "#060608",
          surface: "#0e0e12",
          surface2: "#16161c",
          border: "rgba(255,255,255,0.07)",
          accent: "#e8ff47",
          accent2: "#47ffb8",
          accent3: "#ff6b35",
          muted: "#6b6b7a",
        }
      },
      fontFamily: {
        syne: ["Syne", "sans-serif"],
        sans: ["DM Sans", "sans-serif"],
      }
    }
  },
  plugins: []
}
