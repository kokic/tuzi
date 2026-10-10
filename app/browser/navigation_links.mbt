///|
let navigation_links : FixedArray[NavigationLink] = [
  { label: "Navigation: Compiler Explorer", url: "https://godbolt.org/", },
  { label: "Navigation: Excalidraw", url: "https://excalidraw.com/", },
  { label: "Navigation: HexEd.it", url: "https://https://hexed.it/", },
  { label: "Navigation: Homebrew Packages", url: "https://brew.sh/", },
  {
    label: "Navigation: KaTeX Supported Functions",
    url: "https://katex.org/docs/supported.html",
  },
  { label: "Navigation: Try Pandoc!", url: "https://pandoc.org/try/", },
  {
    label: "Navigation: Browse the winget repository",
    url: "https://winstall.app/",
  },
]

///|
struct NavigationLink {
  label : String
  url : String
}
