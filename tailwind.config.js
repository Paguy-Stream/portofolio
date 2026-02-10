/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./*.qmd",
    "./**/*.qmd",
    "./*.html",
    "./**/*.html",
    "./_site/**/*.html",
    "./styles/*.css"
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}