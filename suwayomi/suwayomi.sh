#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community
# License: MIT
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

# Override build_container to handle mount points
original_build_container() {
  if [ "$VERBOSE" == "yes" ]; then set -x; fi

  NET_STRING="-net0 name=eth0,bridge=$BRG$MAC,ip=$NET$GATE$VLAN$MTU"
  case "$IPV6_METHOD" in
  auto) NET_STRING="$NET_STRING,ip6=auto" ;;
  dhcp) NET_STRING="$NET_STRING,ip6=dhcp" ;;
  static)
    NET_STRING="$NET_STRING,ip6=$IPV6_ADDR"
    [ -n "$IPV6_GATE" ] && NET_STRING="$NET_STRING,gw6=$IPV6_GATE"
    ;;
  none) ;;
  esac
  if [ "$CT_TYPE" == "1" ]; then
    FEATURES="keyctl=1,nesting=1"
  else
    FEATURES="nesting=1"
  fi

  if [ "$ENABLE_FUSE" == "yes" ]; then
    FEATURES="$FEATURES,fuse=1"
  fi

  if [[ $DIAGNOSTICS == "yes" ]]; then
    post_to_api
  fi

  TEMP_DIR=$(mktemp -d)
  pushd "$TEMP_DIR" >/dev/null
  if [ "$var_os" == "alpine" ]; then
    export FUNCTIONS_FILE_PATH="$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/alpine-install.func)"
  else
    export FUNCTIONS_FILE_PATH="$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/install.func)"
  fi

  export DIAGNOSTICS="$DIAGNOSTICS"
  export RANDOM_UUID="$RANDOM_UUID"
  export CACHER="$APT_CACHER"
  export CACHER_IP="$APT_CACHER_IP"
  export tz="$timezone"
  export APPLICATION="$APP"
  export app="$NSAPP"
  export PASSWORD="$PW"
  export VERBOSE="$VERBOSE"
  export SSH_ROOT="${SSH}"
  export SSH_AUTHORIZED_KEY
  export CTID="$CT_ID"
  export CTTYPE="$CT_TYPE"
  export ENABLE_FUSE="$ENABLE_FUSE"
  export ENABLE_TUN="$ENABLE_TUN"
  export PCT_OSTYPE="$var_os"
  export PCT_OSVERSION="$var_version"
  export PCT_DISK_SIZE="$DISK_SIZE"
  export PCT_OPTIONS="
    -features $FEATURES
    -hostname $HN
    -tags $TAGS
    $SD
    $NS
    $NET_STRING
    -onboot 1
    -cores $CORE_COUNT
    -memory $RAM_SIZE
    -unprivileged $CT_TYPE
    $PW
  "
  
  # Add mount point to PCT_OPTIONS if enabled
  if [ "$MOUNT_ENABLED" == "yes" ] && [ -n "$HOST_PATH" ] && [ -n "$LXC_PATH" ]; then
    PCT_OPTIONS="$PCT_OPTIONS -mp0 $HOST_PATH,mp=$LXC_PATH"
  fi
  
  # This executes create_lxc.sh and creates the container and .conf file
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/create_lxc.sh)" $?

  LXC_CONFIG="/etc/pve/lxc/${CTID}.conf"

  # USB passthrough for privileged LXC (CT_TYPE=0)
  if [ "$CT_TYPE" == "0" ]; then
    cat <<EOF >>"$LXC_CONFIG"
# USB passthrough
lxc.cgroup2.devices.allow: a
lxc.cap.drop:
lxc.cgroup2.devices.allow: c 188:* rwm
lxc.cgroup2.devices.allow: c 189:* rwm
lxc.mount.entry: /dev/serial/by-id  dev/serial/by-id  none bind,optional,create=dir
lxc.mount.entry: /dev/ttyUSB0       dev/ttyUSB0       none bind,optional,create=file
lxc.mount.entry: /dev/ttyUSB1       dev/ttyUSB1       none bind,optional,create=file
lxc.mount.entry: /dev/ttyACM0       dev/ttyACM0       none bind,optional,create=file
lxc.mount.entry: /dev/ttyACM1       dev/ttyACM1       none bind,optional,create=file
EOF
  fi

  # Start the container
  msg_info "Starting LXC Container"
  pct start "$CTID"

  # wait for status 'running'
  for i in {1..10}; do
    if pct status "$CTID" | grep -q "status: running"; then
      msg_ok "Started LXC Container"
      break
    fi
    sleep 1
    if [ "$i" -eq 10 ]; then
      msg_error "LXC Container did not reach running state"
      exit 1
    fi
  done

  if [ "$var_os" != "alpine" ]; then
    msg_info "Waiting for network in LXC container"
    for i in {1..10}; do
      if pct exec "$CTID" -- ping -c1 -W1 deb.debian.org >/dev/null 2>&1; then
        msg_ok "Network in LXC is reachable (ping)"
        break
      fi
      if [ "$i" -lt 10 ]; then
        msg_warn "No network in LXC yet (try $i/10) – waiting..."
        sleep 3
      else
        msg_warn "Ping failed 10 times. Trying HTTP connectivity check (wget) as fallback..."
        if pct exec "$CTID" -- wget -q --spider http://deb.debian.org; then
          msg_ok "Network in LXC is reachable (wget fallback)"
        else
          msg_error "No network in LXC after all checks."
          read -r -p "Set fallback DNS (1.1.1.1/8.8.8.8)? [y/N]: " choice
          case "$choice" in
          [yY]*)
            pct set "$CTID" --nameserver 1.1.1.1
            pct set "$CTID" --nameserver 8.8.8.8
            if pct exec "$CTID" -- wget -q --spider http://deb.debian.org; then
              msg_ok "Network reachable after DNS fallback"
            else
              msg_error "Still no network/DNS in LXC! Aborting customization."
              exit_script
            fi
            ;;
          *)
            msg_error "Aborted by user – no DNS fallback set."
            exit_script
            ;;
          esac
        fi
        break
      fi
    done
  fi

  msg_info "Customizing LXC Container"
  : "${tz:=Etc/UTC}"
  if [ "$var_os" == "alpine" ]; then
    sleep 3
    pct exec "$CTID" -- /bin/sh -c 'cat <<EOF >/etc/apk/repositories
http://dl-cdn.alpinelinux.org/alpine/latest-stable/main
http://dl-cdn.alpinelinux.org/alpine/latest-stable/community
EOF'
    pct exec "$CTID" -- ash -c "apk add bash newt curl openssh nano mc ncurses jq >/dev/null"
  else
    sleep 3
    pct exec "$CTID" -- bash -c "sed -i '/$LANG/ s/^# //' /etc/locale.gen"
    pct exec "$CTID" -- bash -c "locale_line=\$(grep -v '^#' /etc/locale.gen | grep -E '^[a-zA-Z]' | awk '{print \$1}' | head -n 1) && \
    echo LANG=\$locale_line >/etc/default/locale && \
    locale-gen >/dev/null && \
    export LANG=\$locale_line"

    if [[ -z "${tz:-}" ]]; then
      tz=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "Etc/UTC")
    fi
    if pct exec "$CTID" -- test -e "/usr/share/zoneinfo/$tz"; then
      pct exec "$CTID" -- bash -c "tz='$tz'; echo \"\$tz\" >/etc/timezone && ln -sf \"/usr/share/zoneinfo/\$tz\" /etc/localtime"
    else
      msg_warn "Skipping timezone setup – zone '$tz' not found in container"
    fi

    pct exec "$CTID" -- bash -c "apt-get update >/dev/null && apt-get install -y sudo curl mc gnupg2 jq >/dev/null"
  fi
  msg_ok "Customized LXC Container"

  # Run the simplified Suwayomi installation from your GitHub repository
  lxc-attach -n "$CTID" -- bash -c "$(curl -fsSL https://raw.githubusercontent.com/Zeta1209/ProxmoxVE/main/suwayomi/suwayomi-install-simple.sh)"
  
  # Force auto-login setup regardless of password setting
  msg_info "Configuring Auto-Login"
  pct exec "$CTID" -- bash -c '
    GETTY_OVERRIDE="/etc/systemd/system/container-getty@1.service.d/override.conf"
    mkdir -p $(dirname $GETTY_OVERRIDE)
    cat <<EOF >$GETTY_OVERRIDE
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear --keep-baud tty%I 115200,38400,9600 \$TERM
EOF
    systemctl daemon-reload
    systemctl restart $(basename $(dirname $GETTY_OVERRIDE) | sed "s/\.d//")
  '
  msg_ok "Auto-Login Configured"
}

# Enhanced advanced_settings function with mount point support
enhanced_advanced_settings() {
  # Run the original advanced_settings function first
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

function build_container() {
  original_build_container
}

start
build_container
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
echo -e ""
echo -e "${INFO}${YW} Console Access:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}pct enter ${CT_ID}${CL}"
