#!/bin/bash

LOG_FILE="${HOME}/docker-script-install.log"

show_spinner()
{
    local pid="$1"
    local spin='-\|/'
    local i=0

    while kill -0 "$pid" 2>/dev/null
    do
        i=$(( (i+1) %4 ))
        printf "\r${spin:$i:1}"
        sleep .15
    done

    wait "$pid"
    local status=$?
    printf "\r \r"
    return "$status"
}

run_with_spinner()
{
    local message="$1"
    shift

    echo "$message"
    "$@" >> "$LOG_FILE" 2>&1 &
    local pid=$!

    show_spinner "$pid"
    local status=$?

    if [[ $status -ne 0 ]]; then
        echo "      This step failed. Review ${LOG_FILE} for details."
    fi

    return "$status"
}

command_is_available()
{
    command -v "$1" >/dev/null 2>&1
}

prompt_component_action()
{
    local label="$1"
    local installed="$2"
    local result_var="$3"
    local choice

    if [[ "$installed" == "yes" ]]; then
        echo "${label} appears to already be installed."
        while true
        do
            read -rp "Would you like to [u]pdate it or [s]kip it? " choice
            case "$choice" in
                [uU])
                    printf -v "$result_var" "update"
                    break
                    ;;
                [sS])
                    printf -v "$result_var" "skip"
                    break
                    ;;
                *)
                    echo "Please enter 'u' to update or 's' to skip."
                    ;;
            esac
        done
    else
        while true
        do
            read -rp "${label} (y/n): " choice
            case "$choice" in
                [yY])
                    printf -v "$result_var" "install"
                    break
                    ;;
                [nN])
                    printf -v "$result_var" "skip"
                    break
                    ;;
                *)
                    echo "Please enter 'y' or 'n'."
                    ;;
            esac
        done
    fi

    echo ""
}

set_app_action()
{
    local enabled="$1"
    local label="$2"
    local compose_file="$3"
    local result_var="$4"

    if [[ "$enabled" != [yY] ]]; then
        printf -v "$result_var" "skip"
        return
    fi

    if [[ -f "$compose_file" ]]; then
        prompt_component_action "$label" "yes" "$result_var"
    else
        printf -v "$result_var" "install"
    fi
}

docker_cmd()
{
    if [[ "$OS" == "1" ]]; then
        docker "$@"
    else
        sudo docker "$@"
    fi
}

docker_compose_cmd()
{
    if [[ "$OS" == "1" ]]; then
        docker compose "$@"
    else
        sudo docker compose "$@"
    fi
}

run_compose_in_dir()
{
    local app_dir="$1"
    shift

    (
        cd "$app_dir" || exit 1
        docker_compose_cmd "$@"
    )
}

download_to_file()
{
    local url="$1"
    local destination="$2"

    curl -fsSL "$url" -o "$destination"
}

replace_line_in_file()
{
    local file="$1"
    local search_line="$2"
    local replacement_line="$3"

    awk -v replacement_line="$replacement_line" -v search_line="$search_line" '
        $0 == search_line { $0 = replacement_line }
        { print }
    ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
}

install_standard_compose_app()
{
    local app_name="$1"
    local app_dir="$2"
    local compose_url="$3"

    mkdir -p "$app_dir"
    run_with_spinner "    1. Downloading the ${app_name} compose file..." download_to_file "$compose_url" "${app_dir}/docker-compose.yml"
    run_with_spinner "    2. Pulling images and starting ${app_name}..." run_compose_in_dir "$app_dir" up -d
}

update_standard_compose_app()
{
    local app_name="$1"
    local app_dir="$2"

    run_with_spinner "    1. Pulling the latest ${app_name} images..." run_compose_in_dir "$app_dir" pull
    run_with_spinner "    2. Restarting ${app_name} with the updated images..." run_compose_in_dir "$app_dir" up -d
}

installApps()
{
    clear
    OS="$REPLY" ## <-- This $REPLY is about OS Selection
    echo "We can install Docker-CE, Docker-Compose, NGinX Proxy Manager, and Portainer-CE."
    echo "Please select 'y' for each item you would like to install."
    echo "NOTE: Without Docker you cannot use Docker-Compose, NGinx Proxy Manager, or Portainer-CE."
    echo "       You also must have Docker-Compose for NGinX Proxy Manager to be installed."
    echo ""
    echo ""
    
    ISACT=$( (sudo systemctl is-active docker ) 2>&1 )
    if command_is_available docker; then
        DOCKER_INSTALLED="yes"
    else
        DOCKER_INSTALLED="no"
    fi

    if [[ "$DOCKER_INSTALLED" == "yes" ]] && docker compose version >/dev/null 2>&1; then
        COMPOSE_INSTALLED="yes"
    else
        COMPOSE_INSTALLED="no"
    fi

    prompt_component_action "Docker-CE" "$DOCKER_INSTALLED" DOCK_ACTION
    prompt_component_action "Docker Compose" "$COMPOSE_INSTALLED" DCOMP_ACTION

    read -rp "Do you want to choose any Docker based applications to install or update as well? (y/n): " INSTALLAPPS
    echo ""
    echo ""

    NPM_ACTION="skip"
    NAVID_ACTION="skip"
    PORT_ACTION="skip"
    REMOTELY_ACTION="skip"
    GUAC_ACTION="skip"
    KUMA_ACTION="skip"
    RUST_ACTION="skip"
    BESZEL_ACTION="skip"

    if [[ "$INSTALLAPPS" == [yY] ]]; then
        read -rp "NGinX Proxy Manager (y/n): " NPM
        read -rp "Navidrome (y/n): " NAVID
        read -rp "Portainer-CE (y/n): " PTAIN
        read -rp "Remotely - Remote Desktop Support (y/n): " REMOTELY
        read -rp "Guacamole - Remote Desktop Protocol in the Browser (y/n): " GUAC
        read -rp "Uptime Kuma - An Uptime Monitor with Notifications (y/n): " KUMA
        read -rp "RustDesk Server - a Remote Desktop / Access Relay Server (y/n): " RUST
        read -rp "Beszel Monitoring Hub - a lightweight system mointoring solution (y/n): " BESZEL

        echo ""
        echo ""

        set_app_action "$NPM" "NGinX Proxy Manager" "${HOME}/docker/nginx-proxy-manager/docker-compose.yml" NPM_ACTION
        set_app_action "$NAVID" "Navidrome" "${HOME}/docker/navidrome/docker-compose.yml" NAVID_ACTION
        set_app_action "$REMOTELY" "Remotely" "${HOME}/docker/remotely/docker-compose.yml" REMOTELY_ACTION
        set_app_action "$GUAC" "Guacamole" "${HOME}/docker/guacamole/docker-compose.yml" GUAC_ACTION
        set_app_action "$KUMA" "Uptime Kuma" "${HOME}/docker/uptime-kuma/docker-compose.yml" KUMA_ACTION
        set_app_action "$RUST" "RustDesk Server" "${HOME}/docker/rustdesk/docker-compose.yml" RUST_ACTION
        set_app_action "$BESZEL" "Beszel" "${HOME}/docker/beszel/docker-compose.yml" BESZEL_ACTION
    fi

    if [[ "$PTAIN" == [yY] ]]; then
        echo ""
        echo ""
        PS3="Please choose either Portainer-CE or just Portainer Agent: "
        select _ in \
            " Full Portainer-CE (Web GUI for Docker, Swarm, and Kubernetes)" \
            " Portainer Agent - Remote Agent to Connect from Portainer-CE" \
            " Nevermind -- I don't need Portainer after all."
        do
            case $REPLY in
                1)
                    PORT="1"
                    set_app_action "y" "Portainer-CE" "${HOME}/docker/portainer/docker-compose.yml" PORT_ACTION
                    break
                    ;;
                2)
                    PORT="2"
                    set_app_action "y" "Portainer Agent" "${HOME}/docker/portainer/docker-compose.yml" PORT_ACTION
                    break
                    ;;
                3)
                    PORT="3"
                    PORT_ACTION="skip"
                    break
                    ;;
                *) echo "Invalid selection, please try again..." ;;
            esac
        done
    fi
    
    startInstall
}

startInstall() 
{
    clear
    if [[ "$DOCK_ACTION" == "update" ]]; then
        DOCKER_ACTION_LABEL="Updating"
    else
        DOCKER_ACTION_LABEL="Installing"
    fi

    if [[ "$DCOMP_ACTION" == "update" ]]; then
        COMPOSE_ACTION_LABEL="Updating"
    else
        COMPOSE_ACTION_LABEL="Installing"
    fi

    echo "#######################################################"
    echo "###         Preparing for Installation              ###"
    echo "#######################################################"
    echo ""
    sleep 3s


#######################################################
###           Install for Arm64 / Raspbian          ###
#######################################################

    if [[ "$OS" == "7" ]]; then
        echo "    1. Installing System Updates..."
        (sudo apt update && sudo apt upgrade -y) > ~/docker-script-install.log 2>&1 &
        ## Show a spinner for activity progress
        pid=$!   # Process ID of the previous running command
        spin='-\|/'
        i=0
        while kill -0 $pid 2>/dev/null
        do
            i=$(( (i+1) %4 ))
            printf "\r${spin:$i:1}"
            sleep .25
        done
        printf "\r"

        echo "    2. Install Prerequisite Packages..."
        (sudo apt install curl wget git -y) >> ~/docker-script-install.log 2>&1 &
        ## Spinner time...
        pid=$!   # Process ID of the previous running command
        spin='-\|/'
        i=0
        while kill -0 $pid 2>/dev/null
        do
            i=$(( (i+1) %4 ))
            printf "\r${spin:$i:1}"
            sleep .25
        done
        printf "\r"

        if [[ "$DOCK_ACTION" != "skip" ]]; then
            echo "    3. ${DOCKER_ACTION_LABEL} Docker-CE (Community Edition)..."
            sleep 2s

        
            curl -fsSL https://get.docker.com | sh >> ~/docker-script-install.log 2>&1 &
            # Time to spin
            pid=$!   # Process ID of the previous running command
            spin='-\|/'
            i=0
            while kill -0 $pid 2>/dev/null
            do
                i=$(( (i+1) %4 ))
                printf "\r${spin:$i:1}"
                sleep .25
            done
            printf "\r"

            echo "      - docker-ce version is now:"
            DOCKERV=$(docker -v)
            echo "          "${DOCKERV}
            sleep 3s

            if [[ "$OS" == "7" ]]; then
                echo "    5. Starting Docker Service"
                sudo systemctl start docker >> ~/docker-script-install.log 2>&1
            fi
        fi
    fi

#######################################################
###           Install for Debian / Ubuntu           ###
#######################################################

    if [[ "$OS" == [234] ]]; then
        echo "    1. Installing System Updates... this may take a while...be patient. If it is being done on a Digial Ocean VPS, you should run updates before running this script."
        (sudo apt update && sudo apt upgrade -y) > ~/docker-script-install.log 2>&1 &
        ## Show a spinner for activity progress
        pid=$! # Process Id of the previous running command
        spin='-\|/'
        i=0
        while kill -0 $pid 2>/dev/null
        do
            i=$(( (i+1) %4 ))
            printf "\r${spin:$i:1}"
            sleep .1
        done
        printf "\r"

        echo "    2. Install Prerequisite Packages..."
        sleep 2s

        sudo apt install curl wget git -y >> ~/docker-script-install.log 2>&1
        
        if [[ "$DOCK_ACTION" != "skip" ]]; then
            echo "    3. ${DOCKER_ACTION_LABEL} Docker-CE (Community Edition)..."
            sleep 2s

        
            curl -fsSL https://get.docker.com | sh >> ~/docker-script-install.log 2>&1
            echo "      - docker-ce version is now:"
            DOCKERV=$(docker -v)
            echo "          "${DOCKERV}
            sleep 3s

            if [[ "$OS" == 2 ]]; then
                echo "    5. Starting Docker Service"
                sudo systemctl start docker >> ~/docker-script-install.log 2>&1
            fi
        fi

    fi
        
    
#######################################################
###              Install for CentOS 7 or 8          ###
#######################################################
    if [[ "$OS" == "1" ]]; then
        if [[ "$DOCK_ACTION" != "skip" ]]; then
            echo "    1. Updating System Packages..."
            sudo yum check-update > ~/docker-script-install.log 2>&1

            echo "    2. Installing Prerequisite Packages..."
            sudo dnf install git curl wget -y >> ~/docker-script-install.log 2>&1

            if [[ "$DOCK_ACTION" != "skip" ]]; then
                echo "    3. ${DOCKER_ACTION_LABEL} Docker-CE (Community Edition)..."

                sleep 2s
                (curl -fsSL https://get.docker.com/ | sh) >> ~/docker-script-install.log 2>&1

                echo "    4. Starting the Docker Service..."

                sleep 2s


                sudo systemctl start docker >> ~/docker-script-install.log 2>&1

                echo "    5. Enabling the Docker Service..."
                sleep 2s

                sudo systemctl enable docker >> ~/docker-script-install.log 2>&1

                echo "      - docker version is now:"
                DOCKERV=$(docker -v)
                echo "        "${DOCKERV}
                sleep 3s
            fi
        fi
    fi

#######################################################
###               Install for Arch Linux            ###
#######################################################

    if [[ "$OS" == "5" ]]; then
        read -rp "Do you want to install system updates prior to installing Docker-CE? (y/n): " UPDARCH
        if [[ "$UPDARCH" == [yY] ]]; then
            echo "    1. Installing System Updates... this may take a while...be patient."
            (sudo pacman -Syu --noconfirm) > ~/docker-script-install.log 2>&1 &
            ## Show a spinner for activity progress
            pid=$! # Process Id of the previous running command
            spin='-\|/'
            i=0
            while kill -0 $pid 2>/dev/null
            do
                i=$(( (i+1) %4 ))
                printf "\r${spin:$i:1}"
                sleep .1
            done
            printf "\r"
        else
            echo "    1. Skipping system update..."
            sleep 2s
        fi

        echo "    2. Installing Prerequisite Packages..."
        sudo pacman -Sy git curl wget --noconfirm >> ~/docker-script-install.log 2>&1

        if [[ "$DOCK_ACTION" != "skip" ]]; then
            echo "    3. ${DOCKER_ACTION_LABEL} Docker-CE (Community Edition)..."
            sleep 2s

            sudo pacman -Sy docker --noconfirm >> ~/docker-script-install.log 2>&1

            echo "    - docker-ce version is now:"
            DOCKERV=$(docker -v)
            echo "        "${DOCKERV}
            sleep 3s
        fi
    fi

#######################################################
###               Install for Open Suse             ###
#######################################################

    if [[ "$OS" == "6" ]]; then
        # install system updates first
        read -rp "Do you want to install system updates prior to installing Docker-CE? (y/n): " UPDSUSE
        if [[ "$UPDSUSE" == [yY] ]]; then
            echo "    1. Installing System Updates... this may take a while...be patient."

            (sudo zypper -n update) > docker-script-install.log 2>&1 &
            ## Show a spinner for activity progress
            pid=$! # Process Id of the previous running command
            spin='-\|/'
            i=0
            while kill -0 $pid 2>/dev/null
            do
                i=$(( (i+1) %4 ))
                printf "\r${spin:$i:1}"
                sleep .1
            done
            printf "\r"
        else
            echo "    1. Skipping system update..."
            sleep 2s
        fi

        echo "    2. Installing Prerequisite Packages..."
        sudo zypper -n install git curl wget >> ~/docker-script-install.log 2>&1

        if [[ "$DOCK_ACTION" != "skip" ]]; then
            echo "    3. ${DOCKER_ACTION_LABEL} Docker-CE (Community Edition)..."
            sleep 2s

            curl -fsSL https://get.docker.com | sh >> ~/docker-script-install.log 2>&1
            echo "Giving the Docker service time to start..."
        
            sudo systemctl start docker >> ~/docker-script-install.log 2>&1
            sleep 5s &
            pid=$! # Process Id of the previous running command
            spin='-\|/'
            i=0
            while kill -0 $pid 2>/dev/null
            do
                i=$(( (i+1) %4 ))
                printf "\r${spin:$i:1}"
                sleep .1
            done
            printf "\r"
            sudo systemctl enable docker >> ~/docker-script-install.log 2>&1

            echo "    - docker-ce version is now:"
            DOCKERV=$(docker -v)
            echo "        "${DOCKERV}
            sleep 3s
        fi
    fi

    if [[ "$ISACT" != "active" ]]; then
        if [[ "$DOCK_ACTION" == "install" ]]; then
            # add current user to docker group so sudo isn't needed
            echo ""
            echo "  - Attempting to add the currently logged in user to the docker group..."

            sleep 2s
            sudo usermod -aG docker "${USER}" >> ~/docker-script-install.log 2>&1
            echo "  - You'll need to log out and back in to finalize the addition of your user to the docker group."
            echo ""
            echo ""
            sleep 3s
        fi
    fi

    if [[ "$DCOMP_ACTION" != "skip" ]]; then
        echo "############################################"
        echo "######     Install Docker-Compose     ######"
        echo "############################################"

        # install docker compose
        echo ""
        echo "    1. ${COMPOSE_ACTION_LABEL} Docker Compose..."
        echo ""
        echo ""
        sleep 2s

        ######################################
        ###     Install Raspbian / Arm64   ###
        ######################################

        if [[ "$OS" == "7" ]]; then
            echo "    1. Installing dependencies..."
            (sudo apt-get install -y libffi-dev libssl-dev python3-dev python3 python3-pip) >> ~/docker-script-install.log 2>&1 &
            # Show our spinner
            pid=$!   # Process ID of the previous running command
            spin='-\|/'
            i=0
            while kill -0 $pid 2>/dev/null
            do
                i=$(( (i+1) %4 ))
                printf "\r${spin:$i:1}"
                sleep .25
            done
            printf "\r"

            (sudo pip3 install docker-compose) >> ~/docker-script-install.log 2>&1 &
            # Show the spinner again...
            pid=$!   # Process ID of the previous running command
            spin='-\|/'
            i=0
            while kill -0 $pid 2>/dev/null
            do
                i=$(( (i+1) %4 ))
                printf "\r${spin:$i:1}"
                sleep .25
            done
            printf "\r"
        fi

        ######################################
        ###        Install Arch Linux      ###
        ######################################

        if [[ "$OS" == "5" ]]; then
            sudo pacman -Sy docker-compose --noconfirm > ~/docker-script-install.log 2>&1
        fi

        echo ""

        echo "      - Docker Compose Version is now: " 
        DOCKCOMPV=$(docker compose version)
        echo "        "${DOCKCOMPV}
        echo ""
        echo ""
        sleep 3s
    fi

    ##########################################
    #### Test if Docker Service is Running ###
    ##########################################
    ISACT=$( (sudo systemctl is-active docker ) 2>&1 )
    if [[ "$ISACT" != "active" ]]; then
        echo "Giving the Docker service time to start..."
        X=0
        while [[ "$ISACT" != "active" ]] && [[ $X -le 10 ]]; do
            sudo systemctl start docker >> ~/docker-script-install.log 2>&1
            sleep 10s &
            pid=$! # Process Id of the previous running command
            spin='-\|/'
            i=0
            while kill -0 $pid 2>/dev/null
            do
                i=$(( (i+1) %4 ))
                printf "\r${spin:$i:1}"
                sleep .1
            done
            printf "\r"
            ISACT=`sudo systemctl is-active docker`
            let X=X+1
            echo "$X"
        done
    fi

    echo "################################################"
    echo "######      Creating a Docker Network    #######"
    echo "################################################"

    if docker_cmd network inspect my-main-net >/dev/null 2>&1; then
        echo "Docker network my-main-net already exists."
    else
        run_with_spinner "Creating the Docker network my-main-net..." docker_cmd network create my-main-net
    fi
    sleep 2s

    if [[ "$NPM_ACTION" == "install" ]]; then
        echo "##########################################"
        echo "###     Install NGinX Proxy Manager    ###"
        echo "##########################################"
        echo ""

        install_standard_compose_app "NGinX Proxy Manager" "${HOME}/docker/nginx-proxy-manager" "https://gitlab.com/bmcgonag/docker_installs/-/raw/main/docker_compose.nginx_proxy_manager.yml"

        echo "    3. You can find NGinX Proxy Manager files at ./docker/nginx-proxy-manager"
        echo ""
        echo "    Navigate to your server hostname / IP address on port 81 to setup"
        echo "    NGinX Proxy Manager admin account."
        echo ""
        echo "    The default login credentials for NGinX Proxy Manager are:"
        echo "        username: admin@example.com"
        echo "        password: changeme"

        echo ""       
        sleep 3s
    elif [[ "$NPM_ACTION" == "update" ]]; then
        echo "##########################################"
        echo "###      Update NGinX Proxy Manager    ###"
        echo "##########################################"
        echo ""

        update_standard_compose_app "NGinX Proxy Manager" "${HOME}/docker/nginx-proxy-manager"

        echo "    NGinX Proxy Manager was updated in place."
        echo "    Existing configuration and persistent data were left intact."
        echo ""
        sleep 3s
    fi

    if [[ "$PORT" == "1" ]] && [[ "$PORT_ACTION" == "install" ]]; then
        echo "########################################"
        echo "###      Installing Portainer-CE     ###"
        echo "########################################"
        echo ""
        echo "    1. Preparing to Install Portainer-CE"
        echo ""
        echo "    2. Creating the folder structure for Portainer."
        echo "    3. You can find Portainer-CE files in ./docker/portainer"

        mkdir -p "${HOME}/docker/portainer/portainer_data"
        run_with_spinner "    4. Downloading the Portainer-CE compose file..." download_to_file "https://gitlab.com/bmcgonag/docker_installs/-/raw/main/docker_compose_portainer_ce.yml" "${HOME}/docker/portainer/docker-compose.yml"
        run_with_spinner "    5. Pulling images and starting Portainer-CE..." run_compose_in_dir "${HOME}/docker/portainer" up -d

        echo ""
        echo "    Navigate to your server hostname / IP address on port 9000 and create your admin account for Portainer-CE"

        echo ""
        echo ""
        echo ""
        sleep 3s
    elif [[ "$PORT" == "1" ]] && [[ "$PORT_ACTION" == "update" ]]; then
        echo "########################################"
        echo "###        Updating Portainer-CE     ###"
        echo "########################################"
        echo ""

        update_standard_compose_app "Portainer-CE" "${HOME}/docker/portainer"

        echo "    Portainer-CE was updated in place."
        echo "    Existing Portainer data was left intact."
        echo ""
        sleep 3s
    fi

    if [[ "$PORT" == "2" ]] && [[ "$PORT_ACTION" == "install" ]]; then
        echo "###########################################"
        echo "###      Installing Portainer Agent     ###"
        echo "###########################################"
        echo ""
        echo "    1. Preparing to install Portainer Agent"
        echo "    2. Creating the folder structure for Portainer."
        echo "    3. You can find Portainer-Agent files in ./docker/portainer"

        if ! docker_cmd volume inspect portainer_data >/dev/null 2>&1; then
            run_with_spinner "    4. Creating the Portainer data volume..." docker_cmd volume create portainer_data
        fi
        mkdir -p "${HOME}/docker/portainer"
        run_with_spinner "    5. Downloading the Portainer Agent compose file..." download_to_file "https://gitlab.com/bmcgonag/docker_installs/-/raw/main/docker_compose_portainer_ce_agent.yml" "${HOME}/docker/portainer/docker-compose.yml"
        run_with_spinner "    6. Pulling images and starting the Portainer Agent..." run_compose_in_dir "${HOME}/docker/portainer" up -d

        echo ""
        echo "    From Portainer or Portainer-CE add this Agent instance via the 'Endpoints' option in the left menu."
        echo "       ####     Use the IP address of this server and port 9001"
        echo ""
        echo ""
        echo ""
        sleep 3s
    elif [[ "$PORT" == "2" ]] && [[ "$PORT_ACTION" == "update" ]]; then
        echo "###########################################"
        echo "###       Updating Portainer Agent      ###"
        echo "###########################################"
        echo ""

        update_standard_compose_app "Portainer Agent" "${HOME}/docker/portainer"

        echo "    The Portainer Agent was updated in place."
        echo "    Existing data and connectivity settings were left intact."
        echo ""
        sleep 3s
    fi

    if [[ "$NAVID_ACTION" == "install" ]]; then
        echo "###########################################"
        echo "###        Installing Navidrome         ###"
        echo "###########################################"
        echo ""
        echo "    1. Preparing to install Navidrome"

        install_standard_compose_app "Navidrome" "${HOME}/docker/navidrome" "https://gitlab.com/bmcgonag/docker_installs/-/raw/main/docker_compose_navidrome.yml"

        echo "    3. You can find your Navidrome files in ./docker/navidrome"
        echo ""
        echo "    Navigate to your server hostname / IP address on port 4533 to setup"
        echo "    your new Navidrome admin account."
        echo ""      
        sleep 3s
    elif [[ "$NAVID_ACTION" == "update" ]]; then
        echo "###########################################"
        echo "###         Updating Navidrome         ###"
        echo "###########################################"
        echo ""

        update_standard_compose_app "Navidrome" "${HOME}/docker/navidrome"

        echo "    Navidrome was updated in place."
        echo "    Existing media and configuration were left intact."
        echo ""
        sleep 3s
    fi

    if [[ "$REMOTELY_ACTION" == "install" ]]; then
        echo "##########################################"
        echo "###          Install Remotely          ###"
        echo "##########################################"
    
        echo "    Starging the Remotely Install..."
        echo ""
        echo ""
        sleep 3s
        echo "    Creating a random password for Postrgres."
        postgrespw=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

        mkdir -p "${HOME}/docker/remotely"
        run_with_spinner "    1. Downloading the Remotely compose file..." download_to_file "https://gitlab.com/bmcgonag/docker_installs/-/raw/main/docker_compose_remotely.yml" "${HOME}/docker/remotely/docker-compose.yml"
        
        echo "    2. Pulling the necessary environment variable file..."

        run_with_spinner "    2. Downloading the Remotely environment file..." download_to_file "https://gitlab.com/bmcgonag/docker_installs/-/raw/main/remotely_env" "${HOME}/docker/remotely/.env"
        replace_line_in_file "${HOME}/docker/remotely/.env" "POSTGRES_PASSWORD=changeMe1" "POSTGRES_PASSWORD=${postgrespw}"

        echo "    3. Running the docker-compose.yml to pull and start Remotely..."
        echo ""

        run_with_spinner "    3. Pulling images and starting Remotely..." run_compose_in_dir "${HOME}/docker/remotely" up -d

        echo "    4. You can find the Remotely folder at ~/docker/remotely..."
        echo ""
        echo "      Navigate to your server hostname / IP address on port 5000, unless you changed it,"
        echo "      to setup your new Remotely installation."
        echo ""
        echo "      You will likely want to create a reverse proxy entry in NGinX Proxy Manager"
        echo "      for your new Remotely server.  If so, also make sure to set the"
        echo "      'Require https' option in the Remotely Settings to true (checked)."
        echo ""
        echo ""
        sleep 3s
    elif [[ "$REMOTELY_ACTION" == "update" ]]; then
        echo "##########################################"
        echo "###          Update Remotely           ###"
        echo "##########################################"
        echo ""

        if [[ -f "${HOME}/docker/remotely/.env" ]]; then
            update_standard_compose_app "Remotely" "${HOME}/docker/remotely"
            echo "    Remotely was updated in place."
            echo "    The existing environment file and data were left intact."
        else
            echo "    Remotely was detected, but ${HOME}/docker/remotely/.env is missing."
            echo "    Skipping the update to avoid overwriting the existing configuration."
        fi
        echo ""
        sleep 3s
    fi

    if [[ "$GUAC_ACTION" == "install" ]]; then
        echo "##########################################"
        echo "###         Installing Guacamole       ###"
        echo "##########################################"
    
        install_standard_compose_app "Guacamole" "${HOME}/docker/guacamole" "https://gitlab.com/bmcgonag/docker_installs/-/raw/main/docker_compose_guacamole.yml"

        echo "    3. You can find the Guacamole folder at ~/docker/guacamole..."
        echo ""
        echo "      You can now navigate in your browser to yoru server IP at"
        echo "      port number 8080 to reach the Guacamole login page."
        echo ""
        echo "      Use the default credentials to loging the first time:"
        echo "          username: guacadmin"
        echo "          password: guacadmin"
        echo ""
        echo "      It is highly recommended that you create a new admin user, and"
        echo "      delete / disable the default user."
        echo ""
        echo ""
        sleep 3s
    elif [[ "$GUAC_ACTION" == "update" ]]; then
        echo "##########################################"
        echo "###          Updating Guacamole       ###"
        echo "##########################################"
        echo ""

        update_standard_compose_app "Guacamole" "${HOME}/docker/guacamole"

        echo "    Guacamole was updated in place."
        echo "    Existing connection data and configuration were left intact."
        echo ""
        sleep 3s
    fi

    if [[ "$RUST_ACTION" == "install" ]]; then
        echo "##########################################"
        echo "###         Installing RustDesk        ###"
        echo "##########################################"
    
        echo ""
        read -rp "Please enter a FQDN (fully qualified domain name) or IP address for your RustDesk server (e.g. rust.mydomain.com): " RUSTFQDN
        echo ""
        echo ""
        echo "    1. Pulling a the RustDesk docker-compose.yml file."

        mkdir -p "${HOME}/docker/rustdesk/hbbr" "${HOME}/docker/rustdesk/hbbs"
        run_with_spinner "    1. Downloading the RustDesk compose file..." download_to_file "https://gitlab.com/bmcgonag/docker_installs/-/raw/main/docker_compose_rustdesk-server.yml" "${HOME}/docker/rustdesk/docker-compose.yml"

        echo ""
        echo ""
        echo "    2. Pulling the environment variable file needed (.env)..."
        run_with_spinner "    2. Downloading the RustDesk environment file..." download_to_file "https://gitlab.com/bmcgonag/docker_installs/-/raw/main/rustdesk_env" "${HOME}/docker/rustdesk/.env"
        echo ""
        echo ""
        echo "    3. Creating your encryption key..."

        run_with_spinner "    3. Generating the RustDesk encryption key..." bash -c "cd \"${HOME}/docker/rustdesk/hbbs\" && ssh-keygen -q -t ed25519 -N '' -f ./id_ed25519"

        yoursecretkey=$(<"${HOME}/docker/rustdesk/hbbs/id_ed25519.pub")

        secondpartsecretkey=$(echo "$yoursecretkey" | cut -d ' ' -f 2)

        rm "${HOME}/docker/rustdesk/hbbs/id_ed25519.pub"

        echo "$secondpartsecretkey" > "${HOME}/docker/rustdesk/hbbs/id_ed25519.pub"
        replace_line_in_file "${HOME}/docker/rustdesk/.env" "RUSTDESK_FQDN=" "RUSTDESK_FQDN=$RUSTFQDN"
        replace_line_in_file "${HOME}/docker/rustdesk/.env" "RUSTDESK_SECRET_KEY=" "RUSTDESK_SECRET_KEY=$secondpartsecretkey"
        
        sleep 3s

        echo "    4. Running the docker-compose.yml to pull and start the RustDesk Server..."
        echo ""

        run_with_spinner "    4. Pulling images and starting the RustDesk Server..." run_compose_in_dir "${HOME}/docker/rustdesk" up -d

        echo "    5. Your RustDesk server should now be running."
        echo ""
        echo "      You can setup a RustDesk client with the FQDN you provided,"
        echo "      and the secret key: $secondpartsecretkey "
        echo ""
        echo "      If needed you can find this key again with the command:"
        echo "          cat ${HOME}/docker/rustdesk/hbbs/id_ed25519.pub"
        echo ""
        sleep 3s
    elif [[ "$RUST_ACTION" == "update" ]]; then
        echo "##########################################"
        echo "###          Updating RustDesk         ###"
        echo "##########################################"
        echo ""

        if [[ -f "${HOME}/docker/rustdesk/.env" ]]; then
            update_standard_compose_app "RustDesk Server" "${HOME}/docker/rustdesk"
            echo "    RustDesk Server was updated in place."
            echo "    The existing .env file, encryption key, and persistent data were left intact."
        else
            echo "    RustDesk Server was detected, but ${HOME}/docker/rustdesk/.env is missing."
            echo "    Skipping the update to avoid regenerating server identity or configuration."
        fi
        echo ""
        sleep 3s
    fi

    if [[ "$KUMA_ACTION" == "install" ]]; then
        echo "##########################################"
        echo "###         Installing Uptime Kuma     ###"
        echo "##########################################"
    
        install_standard_compose_app "Uptime Kuma" "${HOME}/docker/uptime-kuma" "https://gitlab.com/bmcgonag/docker_installs/-/raw/main/docker_compose_uptime_kuma.yml"

        echo "    3. You can find the Uptime Kuma folder at ~/docker/uptime-kuma..."
        echo ""
        echo "      You can now navigate in your browser to yoru server IP at"
        echo "      port number 3001 to reach the Uptime Kuma login page."
        echo ""
        echo "      You'll create your initial user as an admin on the first login."
        echo ""
        echo ""
        sleep 3s
    elif [[ "$KUMA_ACTION" == "update" ]]; then
        echo "##########################################"
        echo "###         Updating Uptime Kuma      ###"
        echo "##########################################"
        echo ""

        update_standard_compose_app "Uptime Kuma" "${HOME}/docker/uptime-kuma"

        echo "    Uptime Kuma was updated in place."
        echo "    Existing monitor data and configuration were left intact."
        echo ""
        sleep 3s
    fi

    if [[ "$BESZEL_ACTION" == "install" ]]; then
        echo "##########################################"
        echo "###         Installing Beszel          ###"
        echo "##########################################"
    
        install_standard_compose_app "Beszel" "${HOME}/docker/beszel" "https://gitlab.com/bmcgonag/docker_installs/-/raw/main/docker_compose_beszel.yml"

        echo "    3. You can find the Beszel folder at ~/docker/beszel..."
        echo ""
        echo "      You can now navigate in your browser to yoru server IP at"
        echo "      port number 8090 to reach the Uptime Kuma login page."
        echo ""
        echo "      You'll create your initial user as an admin on the first login."
        echo ""
        echo ""
        sleep 3s
    elif [[ "$BESZEL_ACTION" == "update" ]]; then
        echo "##########################################"
        echo "###           Updating Beszel         ###"
        echo "##########################################"
        echo ""

        update_standard_compose_app "Beszel" "${HOME}/docker/beszel"

        echo "    Beszel was updated in place."
        echo "    Existing monitoring data and configuration were left intact."
        echo ""
        sleep 3s
    fi

    echo "All selected Docker components have been processed."
    echo ""
    echo "New installations were created and existing installations were updated in place where requested."
    echo "If you add more Docker applications to this server, make sure to add them to the my-main-net network."
    echo "You can then use them by container name in NGinX Proxy Manager if so desired."

    exit 0
}

echo ""
echo ""

clear
echo ""
echo ""
echo "Let's figure out which OS / Distro you are running."
echo ""
echo ""
echo "    From some basic information on your system, you appear to be running: "
echo "        --  OS Name        " $(lsb_release -i)
echo "        --  Description        " $(lsb_release -d)
echo "        --  OS Version        " $(lsb_release -r)
echo "        --  Code Name        " $(lsb_release -c)
echo ""
echo "------------------------------------------------------"
echo ""

PS3="Please select the number for your OS / distro: "
select _ in \
    "CentOS 7 / 8 / Fedora" \
    "Debian 10 / 11" \
    "Ubuntu 18.04" \
    "Ubuntu 20.04 / 21.04 / 22.04+" \
    "Arch Linux" \
    "Open Suse"\
    "Arm64 / Raspbian"\
    "End this Installer"
do
  case $REPLY in
    1) installApps ;;
    2) installApps ;;
    3) installApps ;;
    4) installApps ;;
    5) installApps ;;
    6) installApps ;;
    7) installApps ;;
    8) exit ;;
    *) echo "Invalid selection, please try again..." ;;
  esac
done
