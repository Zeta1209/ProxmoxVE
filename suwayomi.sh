#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2025 zeta
# Author: zeta (credit to tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Suwayomi/Suwayomi-Server

APP="Suwayomi"
var_tags="${var_tags:-manga;reader}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

# Mount point variables
MOUNT_ENABLED="no"
HOST_PATH=""
LXC_PATH=""

header_info "$APP"
variables
color
catch_errors

# Enhanced advanced_settings function with mount point support
enhanced_advanced_settings() {
  # First run the original advanced_settings function
  advanced_settings
  
  # Add mount point configuration at the end
  if (whiptail --backtitle "Proxmox VE Helper Scripts" --defaultno --title "MOUNT POINT" --yesno "Do you want to add a mount point from host to LXC?\n\nThis allows you to share folders between your Proxmox host and the Suwayomi container (e.g., for manga storage)." 12 70); then
    MOUNT_ENABLED="yes"
    
    while true; do
      if HOST_PATH=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Enter the host path (e.g., /mnt/manga)\n\nThis should be a directory on your Proxmox host that you want to share with the container." 10 70 --title "HOST PATH" 3>&1 1>&2 2>&3); then
        if [ -z "$HOST_PATH" ]; then
          whiptail --msgbox "Host path cannot be empty." 8 58
          continue
        elif [ ! -d "$HOST_PATH" ]; then
          if whiptail --backtitle "Proxmox VE Helper Scripts" --defaultno --title "CREATE HOST PATH" --yesno "Host path '$HOST_PATH' does not exist.\n\nWould you like to create it?" 10 70; then
            mkdir -p "$HOST_PATH"
            echo -e "${NETWORK}${BOLD}${DGN}Host Path: ${BGN}$HOST_PATH (created)${CL}"
            break
          else
            continue
          fi
        else
          echo -e "${NETWORK}${BOLD}${DGN}Host Path: ${BGN}$HOST_PATH${CL}"
          break
        fi
      else
        MOUNT_ENABLED="no"
        return
      fi
    done

    while true; do
      if LXC_PATH=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Enter the LXC mount point (e.g., /media/manga)\n\nThis is where the host directory will appear inside the container." 10 70 "/media/manga" --title "LXC MOUNT POINT" 3>&1 1>&2 2>&3); then
        if [ -z "$LXC_PATH" ]; then
          whiptail --msgbox "LXC mount point cannot be empty." 8 58
          continue
        else
          echo -e "${NETWORK}${BOLD}${DGN}LXC Mount Point: ${BGN}$LXC_PATH${CL}"
          break
        fi
      else
        MOUNT_ENABLED="no"
        return
      fi
    done
    
    echo -e "${NETWORK}${BOLD}${DGN}Mount Point: ${BGN}Enabled${CL}"
  else
    MOUNT_ENABLED="no"
    echo -e "${NETWORK}${BOLD}${DGN}Mount Point: ${BGN}Disabled${CL}"
  fi
}

# Enhanced build_container function to add mount point
enhanced_build_container() {
  # Call the original build_container function first
  build_container

  # Add mount point if enabled
  if [ "$MOUNT_ENABLED" == "yes" ] && [ -n "$HOST_PATH" ] && [ -n "$LXC_PATH" ]; then
    msg_info "Adding Mount Point"
    LXC_CONFIG="/etc/pve/lxc/${CT_ID}.conf"
    
    # Find the next available mount point number
    MOUNT_NUM=0
    while grep -q "^mp${MOUNT_NUM}:" "$LXC_CONFIG" 2>/dev/null; do
      MOUNT_NUM=$((MOUNT_NUM + 1))
    done
    
    # Add the mount point to the LXC config
    echo "mp${MOUNT_NUM}: ${HOST_PATH},mp=${LXC_PATH}" >> "$LXC_CONFIG"
    
    msg_ok "Added Mount Point: $HOST_PATH -> $LXC_PATH"
    
    # Stop the container to apply mount point
    msg_info "Restarting container to apply mount point"
    pct stop "$CT_ID"
    sleep 2
    pct start "$CT_ID"
    
    # Wait for container to be fully started
    for i in {1..30}; do
      if pct status "$CT_ID" | grep -q "status: running"; then
        sleep 2
        break
      fi
      sleep 1
      if [ "$i" -eq 30 ]; then
        msg_error "Container failed to restart properly"
        exit 1
      fi
    done
    
    # Create the mount point directory in the container and set ownership
    pct exec "$CT_ID" -- mkdir -p "$LXC_PATH"
    pct exec "$CT_ID" -- chown suwayomi:suwayomi "$LXC_PATH"
    
    msg_ok "Mount point configured and ready"
  fi
}

# Override the install_script function to use enhanced advanced settings
enhanced_install_script() {
  pve_check
  shell_check
  root_check
  arch_check
  ssh_check
  maxkeys_check
  diagnostics_check

  if systemctl is-active -q ping-instances.service; then
    systemctl -q stop ping-instances.service
  fi
  NEXTID=$(pvesh get /cluster/nextid)
  timezone=$(cat /etc/timezone)
  header_info
  while true; do

    TMP_CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" \
      --title "SETTINGS" \
      --menu "Choose an option:" 20 60 6 \
      "1" "Default Settings" \
      "2" "Default Settings (with verbose)" \
      "3" "Advanced Settings" \
      "4" "Use Config File" \
      "5" "Diagnostic Settings" \
      "6" "Exit" \
      --default-item "1" 3>&1 1>&2 2>&3) || true

    if [ -z "$TMP_CHOICE" ]; then
      echo -e "\n${CROSS}${RD}Menu canceled. Exiting script.${CL}\n"
      exit 0
    fi

    CHOICE="$TMP_CHOICE"

    case $CHOICE in
    1)
      header_info
      echo -e "${DEFAULT}${BOLD}${BL}Using Default Settings on node $PVEHOST_NAME${CL}"
      VERBOSE="no"
      METHOD="default"
      base_settings "$VERBOSE"
      echo_default
      break
      ;;
    2)
      header_info
      echo -e "${DEFAULT}${BOLD}${BL}Using Default Settings on node $PVEHOST_NAME (${VERBOSE_CROPPED}Verbose)${CL}"
      VERBOSE="yes"
      METHOD="default"
      base_settings "$VERBOSE"
      echo_default
      break
      ;;
    3)
      header_info
      echo -e "${ADVANCED}${BOLD}${RD}Using Advanced Settings on node $PVEHOST_NAME${CL}"
      METHOD="advanced"
      base_settings
      enhanced_advanced_settings
      break
      ;;
    4)
      header_info
      echo -e "${INFO}${HOLD} ${GN}Using Config File on node $PVEHOST_NAME${CL}"
      METHOD="config_file"
      source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/config-file.func)
      config_file
      break
      ;;
    5)
      if [[ $DIAGNOSTICS == "yes" ]]; then
        if whiptail --backtitle "Proxmox VE Helper Scripts" --title "DIAGNOSTICS SETTINGS" --yesno "Send Diagnostics of LXC Installation?\n\nCurrent setting: ${DIAGNOSTICS}" 10 58 \
          --yes-button "No" --no-button "Back"; then
          DIAGNOSTICS="no"
          sed -i 's/^DIAGNOSTICS=.*/DIAGNOSTICS=no/' /usr/local/community-scripts/diagnostics
          whiptail --backtitle "Proxmox VE Helper Scripts" --title "DIAGNOSTICS SETTINGS" --msgbox "Diagnostics settings changed to ${DIAGNOSTICS}." 8 58
        fi
      else
        if whiptail --backtitle "Proxmox VE Helper Scripts" --title "DIAGNOSTICS SETTINGS" --yesno "Send Diagnostics of LXC Installation?\n\nCurrent setting: ${DIAGNOSTICS}" 10 58 \
          --yes-button "Yes" --no-button "Back"; then
          DIAGNOSTICS="yes"
          sed -i 's/^DIAGNOSTICS=.*/DIAGNOSTICS=yes/' /usr/local/community-scripts/diagnostics
          whiptail --backtitle "Proxmox VE Helper Scripts" --title "DIAGNOSTICS SETTINGS" --msgbox "Diagnostics settings changed to ${DIAGNOSTICS}." 8 58
        fi
      fi

      ;;
    6)
      echo -e "\n${CROSS}${RD}Script terminated. Have a great day!${CL}\n"
      exit 0
      ;;
    *)
      echo -e "\n${CROSS}${RD}Invalid option, please try again.${CL}\n"
      ;;
    esac
  done
}

start() {
  source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/tools.func)
  if command -v pveversion >/dev/null 2>&1; then
    enhanced_install_script
  else
    CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "${APP} LXC Update/Setting" --menu \
      "Support/Update functions for ${APP} LXC. Choose an option:" \
      12 60 3 \
      "1" "YES (Silent Mode)" \
      "2" "YES (Verbose Mode)" \
      "3" "NO (Cancel Update)" --nocancel --default-item "1" 3>&1 1>&2 2>&3)

    case "$CHOICE" in
    1)
      VERBOSE="no"
      set_std_mode
      ;;
    2)
      VERBOSE="yes"
      set_std_mode
      ;;
    3)
      clear
      exit_script
      exit
      ;;
    esac
    update_script
  fi
}

function update_script() {
    header_info
    check_container_storage
    check_container_resources
    if [[ ! -f /opt/suwayomi/suwayomi-server.sh ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Stopping ${APP}"
    systemctl stop suwayomi.service
    msg_ok "Stopped ${APP}"
    
    msg_info "Updating ${APP}"
    cd /opt/suwayomi
    LATEST_VERSION=$(curl -s https://api.github.com/repos/Suwayomi/Suwayomi-Server/releases/latest | grep 'tag_name' | cut -d '"' -f 4)
    wget https://github.com/Suwayomi/Suwayomi-Server/releases/download/${LATEST_VERSION}/Suwayomi-Server-${LATEST_VERSION}-linux-x64.tar.gz
    tar -xzf Suwayomi-Server-${LATEST_VERSION}-linux-x64.tar.gz --strip-components=1
    rm -f Suwayomi-Server-${LATEST_VERSION}-linux-x64.tar.gz
    chmod +x suwayomi-server.sh
    msg_ok "Updated ${APP}"
    
    msg_info "Starting ${APP}"
    systemctl start suwayomi.service
    msg_ok "Started ${APP}"
    
    msg_ok "Updated Successfully"
    exit
}

start
enhanced_build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:4567${CL}"

if [ "$MOUNT_ENABLED" == "yes" ]; then
  echo -e ""
  echo -e "${INFO}${GN} Mount Point Configuration:${CL}"
  echo -e "${TAB}${GATEWAY}${BGN}Host Path: ${HOST_PATH}${CL}"
  echo -e "${TAB}${GATEWAY}${BGN}LXC Path: ${LXC_PATH}${CL}"
  echo -e "${TAB}${INFO}${YW}The mount point is active and ready to use!${CL}"
fi
