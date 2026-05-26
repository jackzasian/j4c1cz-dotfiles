/* Omarchy theme for Zen Browser — auto-generated on theme switch. Do not edit. */

:root {
  --zen-primary-color: {{ accent }} !important;
  --zen-branding-dark: {{ background }} !important;
  --zen-branding-paper: {{ color7 }} !important;
  --zen-background-opacity: 0.72 !important;
  --zen-main-browser-background: color-mix(in srgb, {{ background }} 72%, transparent) !important;
  --zen-main-browser-background-toolbar: color-mix(in srgb, {{ background }} 65%, transparent) !important;
  --toolbar-bgcolor: color-mix(in srgb, {{ background }} 65%, transparent) !important;
  --toolbar-color: {{ foreground }} !important;
  --lwt-accent-color: {{ accent }} !important;
  --lwt-text-color: {{ foreground }} !important;
  --zen-urlbar-background: color-mix(in srgb, {{ background }} 55%, transparent) !important;
  --zen-colors-primary-foreground: {{ foreground }} !important;
  --zen-secondary-btn-color: {{ foreground }} !important;
  --link-color: {{ color4 }} !important;
}

#navigator-toolbox,
#zen-toolbar-background,
.zen-toolbar-background,
#zen-appcontent-navbar-container {
  background-color: color-mix(in srgb, {{ background }} 65%, transparent) !important;
  backdrop-filter: blur(18px) saturate(1.15) !important;
}

#sidebar-box,
#zen-sidebar-splitter {
  background-color: transparent !important;
}

.urlbar-background,
#urlbar-background {
  background-color: color-mix(in srgb, {{ background }} 55%, transparent) !important;
  backdrop-filter: blur(20px) saturate(1.2) !important;
}

.urlbarView-row[selected] {
  background-color: color-mix(in srgb, {{ accent }} 75%, transparent) !important;
  color: {{ foreground }} !important;
}

* {
  font-family: "JetBrainsMono Nerd Font", "JetBrains Mono", monospace !important;
}
