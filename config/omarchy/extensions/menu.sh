# User overrides for omarchy-menu (sourced after stock functions are defined).

# Stock omarchy-menu calls bare `walker` for Apps, which skips elephant/service
# setup and often fails to show or launch under uwsm. Use omarchy-launch-walker.
go_to_menu() {
  case "${1,,}" in
  *apps*) omarchy-launch-walker -p "Launch…" ;;
  *learn*) show_learn_menu ;;
  *trigger*) show_trigger_menu ;;
  *toggle*) show_toggle_menu ;;
  *hardware*) show_hardware_menu ;;
  *share*) show_share_menu ;;
  *reminder-set*) show_custom_reminder_input ;;
  *reminder*) show_reminder_menu ;;
  *background*) show_background_menu ;;
  *capture*) show_capture_menu ;;
  *style*) show_style_menu ;;
  *theme*) show_theme_menu ;;
  *screenrecord*) show_screenrecord_menu ;;
  *setup*) show_setup_menu ;;
  *power*) show_setup_power_menu ;;
  *install*) show_install_menu ;;
  *remove*) show_remove_menu ;;
  *update*) show_update_menu ;;
  *about*) show_about ;;
  *system*) show_system_menu ;;
  esac
}
