///|
let light_theme_style : Array[String] = [
  // Surface and hover colors retain the beige hue; adjust only lightness.
  "--tuzi-theme-background: #e8e0ba", "--tuzi-theme-foreground: #17344d", "--tuzi-theme-surface: oklch(from var(--tuzi-theme-background) calc(l - 0.025) c h)",
  "--tuzi-theme-hover: oklch(from var(--tuzi-theme-background) calc(l - 0.05) c h)",
  "--tuzi-pane-header-hover-background: oklch(from var(--tuzi-theme-background) calc(l - 0.075) c h)",
  // Fills derive from beige; borders and focus lines use blue.
   "--tuzi-marked-background: oklch(from var(--tuzi-theme-background) calc(l - 0.065) c h)",
  "--tuzi-selection-background: oklch(from var(--tuzi-theme-background) calc(l - 0.05) c h)",
  "--tuzi-theme-border: var(--tuzi-theme-foreground)", "--tuzi-theme-indicator: var(--tuzi-theme-border)",
  "--tuzi-scrollbar-thumb: oklch(from var(--tuzi-theme-background) calc(l - 0.1) c h)",
  "--tuzi-entry-secondary-foreground: oklch(from var(--tuzi-theme-background) calc(l - 0.22) c h)",
  "--tuzi-scrollbar-track: var(--tuzi-theme-background)", "--tuzi-checkbox-checkmark: oklch(from var(--tuzi-theme-background) calc(l - 0.55) c h)",
  // General auxiliary text remains blue; entry metadata uses beige.
   "--tuzi-theme-muted-foreground: color-mix(in oklab, var(--tuzi-theme-foreground) 78%, var(--tuzi-theme-background))",
  // Map component roles to the palette above; keep color tuning in one place.
   "--rui-background: var(--tuzi-theme-background)", "--rui-foreground: var(--tuzi-theme-foreground)",
  "--rui-card: var(--tuzi-theme-background)", "--rui-card-foreground: var(--tuzi-theme-foreground)",
  "--rui-popover: var(--tuzi-theme-background)", "--rui-popover-foreground: var(--tuzi-theme-foreground)",
  "--rui-primary: oklch(from var(--tuzi-theme-background) calc(l - 0.1) c h)", "--rui-primary-foreground: var(--tuzi-theme-foreground)",
  "--tuzi-emphasis-foreground: var(--tuzi-theme-foreground)", "--rui-secondary: var(--tuzi-theme-surface)",
  "--rui-secondary-foreground: var(--tuzi-theme-foreground)", "--rui-muted: var(--tuzi-theme-surface)",
  "--rui-muted-foreground: var(--tuzi-theme-muted-foreground)", "--rui-accent: var(--tuzi-theme-hover)",
  "--rui-accent-foreground: var(--tuzi-theme-foreground)", "--rui-border: var(--tuzi-theme-border)",
  "--rui-input: var(--tuzi-theme-border)", "--rui-outline-background: var(--tuzi-theme-background)",
  "--rui-outline-border: var(--tuzi-theme-border)", "--rui-outline-hover-bg: var(--tuzi-theme-hover)",
  "--rui-ghost-hover-bg: var(--tuzi-theme-hover)", "--rui-select-hover-bg: var(--tuzi-theme-hover)",
  "--rui-field-label-checked-bg: var(--tuzi-marked-background)", "--rui-ring: var(--tuzi-theme-indicator)",
  "--tuzi-selection-indicator: var(--tuzi-theme-indicator)", "--tuzi-checkbox-background: var(--tuzi-theme-background)",
  "--tuzi-checkbox-border: var(--tuzi-theme-border)", "--tuzi-checkbox-hover-background: var(--tuzi-theme-hover)",
  "--tuzi-checkbox-checked-background: var(--rui-primary)", "--tuzi-checkbox-checked-border: var(--tuzi-theme-indicator)",
]

///|
let dark_theme_style : Array[String] = [
  "--tuzi-scrollbar-thumb: var(--rui-border)", "--tuzi-scrollbar-track: transparent",
  "--tuzi-entry-secondary-foreground: var(--rui-muted-foreground)", "--tuzi-emphasis-foreground: var(--rui-primary)",
  "--tuzi-selection-background: #3a3a3a", "--tuzi-selection-indicator: var(--rui-muted-foreground)",
  "--tuzi-marked-background: #303030", "--tuzi-pane-header-hover-background: color-mix(in oklab, var(--rui-muted) 90%, var(--rui-foreground))",
]
