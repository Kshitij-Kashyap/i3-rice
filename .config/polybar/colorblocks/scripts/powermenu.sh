#!/bin/sh

# rofi theme
theme="$HOME/.config/polybar/colorblocks/scripts/rofi/powermenu.rasi"

get_options() {
  echo " Poweroff"
  echo " Reboot"
  echo " Hibernate"
  echo " Lock"
  echo " Suspend"
  echo " Log out"
}

main() {

  # get choice from rofi
  choice=$( (get_options) | rofi -dmenu -i -fuzzy -p "" -theme "$theme")

  # run the selected command
  case $choice in
  ' Poweroff')
    systemctl poweroff
    ;;
  ' Reboot')
    systemctl reboot
    ;;
  ' Hibernate')
    systemctl hibernate
    ;;
  ' Lock')
    lock
    ;;
  ' Suspend')
    systemctl suspend
    ;;
  ' Log out')
    i3-msg exit
    ;;
  esac

  # done
  set -e
}

main &

exit 0
