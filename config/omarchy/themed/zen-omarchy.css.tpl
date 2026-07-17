/* Omarchy theme for Zen Browser — auto-generated on theme switch. Do not edit. */
/* Color tokens only; sidebar/toolbar transparency is handled by the Transparent Zen mod. */

:root {
  --zen-primary-color: {{ accent }} !important;
  --zen-branding-dark: {{ background }} !important;
  --zen-branding-paper: {{ color7 }} !important;
  --toolbar-color: {{ foreground }} !important;
  --lwt-accent-color: {{ accent }} !important;
  --lwt-text-color: {{ foreground }} !important;
  --zen-urlbar-background: color-mix(in srgb, {{ background }} 55%, transparent) !important;
  --zen-colors-primary-foreground: {{ foreground }} !important;
  --zen-secondary-btn-color: {{ foreground }} !important;
  --link-color: {{ color4 }} !important;
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
