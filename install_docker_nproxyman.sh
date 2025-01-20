#!/bin/bash

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
    ISCOMP=$( (docker compose -v ) 2>&1 )

    #### Try to check whether docker is installed and running - don't prompt if it is
    if [[ "$ISACT" != "active" ]]; then
        read -rp "Docker-CE (y/n): " DOCK
    else
        echo "Docker appears to be installed and running."
        echo ""
        echo ""
    fi

    if [[ "$ISCOMP" == *"command not found"* ]]; then
        read -rp "Docker Compose (y/n): " DCOMP
        echo ""
        echo ""
    else
        echo "Docker Compose appears to be installed."
        echo ""
        echo ""
    fi

    read -rp "Do you want to choose any Docker based applications to install as well? (y/n): " INSTALLAPPS
    echo ""
    echo ""

    if [[ "$INSTALLAPPS" == [yY] ]]; then
        read -rp "NGinX Proxy Manager (y/n): " NPM
        read -rp "Navidrome (y/n): " NAVID
        read -rp "Portainer-CE (y/n): " PTAIN
        read -rp "Remotely - Remote Desktop Support (y/n): " REMOTELY
        read -rp "Guacamole - Remote Desktop Protocol in the Browser (y/n): " GUAC
        read -rp "Uptime Kuma - An Uptime Monitor with Notifications (y/n): " KUMA
        read -rp "RustDesk Server - a Remote Desktop / Access Relay Server (y/n): " RUST
        read -rp "Beszel Monitoring Hub - a lightweight system mointoring solution (y/n): " BESZEL
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
            PORT="$REPLY"
            case $REPLY in
                1) startInstall ;;
                2) startInstall ;;
                3) startInstall ;;
                *) echo "Invalid selection, please try again..." ;;
            esac
        done
    fi
    
    startInstall
}

startInstall() 
{
    clear
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
        (sudo apt update  && sudoa apt upgrade -y) > ~/docker-script-install.loc 2>&1 &
        ## Show a spinner for activity progress
        pid=$   # Process ID of the previous running command
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
        (sudo apt install curl wget git -y) >> ~/docker-script-install.log 2>&1
        ## Spinner time...
        pid=$   # Process ID of the previous running command
        spin='-\|/'
        i=0
        while kill -0 $pid 2>/dev/null
        do
            i=$(( (i+1) %4 ))
            printf "\r${spin:$i:1}"
            sleep .25
        done
        printf "\r"

        if [[ "$ISACT" != "active" ]]; then
            echo "    3. Installing Docker-CE (Community Edition)..."
            sleep 2s

        
            curl -fsSL https://get.docker.com | sh >> ~/docker-script-install.log 2>&1
            # Time to spin
            pid=$   # Process ID of the previous running command
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

            if [[ "$OS" == 2 ]]; then
                echo "    5. Starting Docker Service"
                sudo systemctl docker start >> ~/docker-script-install.log 2>&1
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
        
        if [[ "$ISACT" != "active" ]]; then
            echo "    3. Installing Docker-CE (Community Edition)..."
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
        if [[ "$DOCK" == [yY] ]]; then
            echo "    1. Updating System Packages..."
            sudo yum check-update > ~/docker-script-install.log 2>&1

            echo "    2. Installing Prerequisite Packages..."
            sudo dnf install git curl wget -y >> ~/docker-script-install.log 2>&1

            if [[ "$ISACT" != "active" ]]; then
                echo "    3. Installing Docker-CE (Community Edition)..."

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

        if [[ "$ISACT" != "active" ]]; then
            echo "    3. Installing Docker-CE (Community Edition)..."
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

        if [[ "$ISACT" != "active" ]]; then
            echo "    3. Installing Docker-CE (Community Edition)..."
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
        if [[ "$DOCK" == [yY] ]]; then
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

    if [[ "$DCOMP" = [yY] ]]; then
        echo "############################################"
        echo "######     Install Docker-Compose     ######"
        echo "############################################"

        # install docker compose
        echo ""
        echo "    1. Installing Docker Compose..."
        echo ""
        echo ""
        sleep 2s

        ######################################
        ###     Install Raspbian / Arm64   ###
        ######################################

        if [[ "$OS" == "7" ]]; then
            echo "    1. Installing dependencies..."
            (sudo apt-get install -y libffi-dev libssl-dev python3-dev python3 python3-pip) >> ~/docker-script-install.log 2>&1
            # Show our spinner
            pid=$   # Process ID of the previous running command
            spin='-\|/'
            i=0
            while kill -0 $pid 2>/dev/null
            do
                i=$(( (i+1) %4 ))
                printf "\r${spin:$i:1}"
                sleep .25
            done
            printf "\r"

            (sudo pip3 install docker-compose) >> ~/docker-script-install.log 2>&1
            # Show the spinner again...
            pid=$   # Process ID of the previous running command
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
    if [[ "$ISACt" != "active" ]]; then
        echo "Giving the Docker service time to start..."
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

    sudo docker network create my-main-net
    sleep 2s
    # move to home directory of user
    cd

    if [[ "$NPM" == [yY] ]]; then
        echo "##########################################"
        echo "###     Install NGinX Proxy Manager    ###"
        echo "##########################################"
    
        # pull an nginx proxy manager docker-compose file from github
        echo "    1. Pulling a default NGinX Proxy Manager docker-compose.yml file."

        mkdir -p docker/nginx-proxy-manager
        cd docker/nginx-proxy-manager

        curl https://gitlab.com/bmcgonag/docker_installs/-/raw/main/docker_compose.nginx_proxy_manager.yml -o docker-compose.yml >> ~/docker-script-install.log 2>&1

        echo "    2. Running the docker-compose.yml to install and start NGinX Proxy Manager"
        echo ""
        echo ""

        if [[ "$OS" == "1" ]]; then
          docker compose up -d
        else
          sudo docker compose up -d
        fi

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
        cd
    fi

    if [[ "$PORT" == "1" ]]; then
        echo "########################################"
        echo "###      Installing Portainer-CE     ###"
        echo "########################################"
        echo ""
        echo "    1. Preparing to Install Portainer-CE"
        echo ""
        echo "    2. Creating the folder structure for Portainer."
        echo "    3. You can find Portainer-CE files in ./docker/portainer"

        #sudo docker volume create portainer_data >> ~/docker-script-install.log 2>&1
        mkdir -p docker/portainer/portainer_data
        cd docker/portainer
        curl https://gitlab.com/bmcgonag/docker_installs/-/raw/main/docker_compose_portainer_ce.yml -o docker-compose.yml >> ~/docker-script-install.log 2>&1
        echo ""

        if [[ "$OS" == "1" ]]; then
          docker compose up -d
        else
          sudo docker compose up -d
        fi

        echo ""
        echo "    Navigate to your server hostname / IP address on port 9000 and create your admin account for Portainer-CE"

        echo ""
        echo ""
        echo ""
        sleep 3s
        cd
    fi

    if [[ "$PORT" == "2" ]]; then
        echo "###########################################"
        echo "###      Installing Portainer Agent     ###"
        echo "###########################################"
        echo ""
        echo "    1. Preparing to install Portainer Agent"
        echo "    2. Creating the folder structure for Portainer."
        echo "    3. You can find Portainer-Agent files in ./docker/portainer"

        sudo docker volume create portainer_data
        mkdir -p docker/portainer
        cd docker/portainer
        curl https://gitlab.com/bmcgonag/docker_installs/-/raw/main/docker_compose_portainer_ce_agent.yml -o docker-compose.yml >> ~/docker-script-install.log 2>&1
        echo ""
        
        if [[ "$OS" == "1" ]]; then
          docker compose up -d
        else
          sudo docker compose up -d
        fi

        echo ""
        echo "    From Portainer or Portainer-CE add this Agent instance via the 'Endpoints' option in the left menu."
        echo "       ####     Use the IP address of this server and port 9001"
        echo ""
        echo ""
        echo ""
        sleep 3s
        cd
    fi

    if [[ "$NAVID" == [yY] ]]; then
        echo "###########################################"
        echo "###        Installing Navidrome         ###"
        echo "###########################################"
        echo ""
        echo "    1. Preparing to install Navidrome"

        mkdir -p docker/navidrome
        cd docker/navidrome

        curl https://gitlab.com/bmcgonag/docker_installs/-/raw/main/docker_compose_navidrome.yml -o docker-compose.yml >> ~/docker-script-install.log 2>&1

        echo "    2. Running the docker-compose.yml to install and start Navidrome"
        echo ""
        echo ""

        if [[ "$OS" == "1" ]]; then
          docker compose up -d
        else
          sudo docker compose up -d
        fi

        echo "    3. You can find your Navidrome files in ./docker/navidrome"
        echo ""
        echo "    Navigate to your server hostname / IP address on port 4533 to setup"
        echo "    your new Navidrome admin account."
        echo ""      
        sleep 3s
        cd
    fi

    if [[ "$REMOTELY" == [yY] ]]; then
        echo "##########################################"
        echo "###          Install Remotely          ###"
        echo "##########################################"
    
        echo "    Starging the Remotely Install..."
        echo ""
        echo ""
        sleep 3s
        echo "    Creating a random password for Postrgres."
        postgrespw=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

        # pull a remotely docker-compose file from gitlab
        echo "    1. Pulling a default Remotely docker-compose.yml file."

        mkdir -p docker/remotely
        cd docker/remotely

        curl https://gitlab.com/bmcgonag/docker_installs/-/raw/main/docker_compose_remotely.yml -o docker-compose.yml >> ~/docker-script-install.log 2>&1
        
        echo "    2. Pulling the necessary environment variable file..."

        curl https://gitlab.com/bmcgonag/docker_installs/-/raw/main/remotely_env -o .env >> ~/docker-script-install.log 2>&1
        
        # replace the existing default password with our randomly generated db password
        # Define the line to replace with
        var="POSTGRES_PASSWORD=$postgrespw"

        # Define the line to search for (to be replaced)
        search_line="POSTGRES_PASSWORD=changeMe1"

        # Define the file to modify
        file=".env"

        # Use awk to replace the line
        awk -v var="$var" '/'"$search_line"'/ { $0 = var } 1' "$file" > temp && mv temp "$file"

        echo "    3. Running the docker-compose.yml to pull and start Remotely..."
        echo ""

        if [[ "$OS" == "1" ]]; then
          docker compose up -d
        else
          sudo docker compose up -d
        fi

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
        cd
    fi

    if [[ "$GUAC" == [yY] ]]; then
        echo "##########################################"
        echo "###         Installing Guacamole       ###"
        echo "##########################################"
    
        # pull a guacamole docker-compose file from gitlab
        echo "    1. Pulling a default Guacamole docker-compose.yml file."

        mkdir -p docker/guacamole
        cd docker/guacamole

        curl https://gitlab.com/bmcgonag/docker_installs/-/raw/main/docker_compose_guacamole.yml -o docker-compose.yml >> ~/docker-script-install.log 2>&1

        echo ""
        echo ""
        echo "    2. Running the docker-compose.yml to pull and start Guacamole..."
        echo ""

        if [[ "$OS" == "1" ]]; then
          docker compose up -d
        else
          sudo docker compose up -d
        fi

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
        cd
    fi

    if [[ "$RUST" == [yY] ]]; then
        echo "##########################################"
        echo "###         Installing RustDesk        ###"
        echo "##########################################"
    
        # pull a rustdesk server docker-compose file from gitlab
        echo ""
        read -rp "Please enter a FQDN (fully qualified domain name) or IP address for your RustDesk server (e.g. rust.mydomain.com): " RUSTFQDN
        echo ""
        echo ""
        echo "    1. Pulling a the RustDesk docker-compose.yml file."

        mkdir -p docker/rustdesk/{hbbr,hbbs}
        cd docker/rustdesk

        curl https://gitlab.com/bmcgonag/docker_installs/-/raw/main/docker_compose_rustdesk-server.yml -o docker-compose.yml >> ~/docker-script-install.log 2>&1

        echo ""
        echo ""
        echo "    2. Pulling the environment variable file needed (.env)..."
        curl https://gitlab.com/bmcgonag/docker_installs/-/raw/main/rustdesk_env -o .env >> ~/docker-script-install.log 2>&1
        echo ""
        echo ""
        echo "    3. Creating your encryption key..."

        cd hbbs
        # generate a secret key - this is an ed25519 key
        ssh-keygen -t ed25519 -f ./id_ed25519

        yoursecretkey=$(<id_ed25519.pub)

        secondpartsecretkey=$(echo "$yoursecretkey" | cut -d ' ' -f 2)

        rm id_ed25519.pub

        echo "$secondpartsecretkey" > id_ed25519.pub

        cd ..

        # replace the text in the sample .env we just made with actual values
        # replace the blank FQDN and secret key

        # define the line to replace with
        var="RUSTDESK_FQDN=$RUSTFQDN"
        var2="RUSTDESK_SECRET_KEY=$secondpartsecretkey"

        # Define the line to search for (be replaced)
        search_line="RUSTDESK_FQDN="
        search_line2="RUSTDESK_SECRET_KEY="

        # Define the file to modify
        file=".env"

        # Use awk to replace the line
        awk -v var="$var" '/'"$search_line"'/ { $0 = var } 1' "$file" > temp && mv temp "$file"
        awk -v var2="$var2" '/'"$search_line2"'/ { $0 = var2 } 1' "$file" > temp && mv temp "$file"
        
        sleep 3s

        echo "    4. Running the docker-compose.yml to pull and start the RustDesk Server..."
        echo ""

        if [[ "$OS" == "1" ]]; then
          docker compose up -d
        else
          sudo docker compose up -d
        fi

        currDir=$(pwd)

        echo "    5. Your RustDesk server should now be running."
        echo ""
        echo "      You can setup a RustDesk client with the FQDN you provided,"
        echo "      and the secret key: $secondpartsecretkey "
        echo ""
        echo "      If needed you can find this key again with the command:"
        echo "          cat $currDir/hbbs/id_ed25119.pub"
        echo ""
        sleep 3s
        cd
    fi

    if [[ "$KUMA" == [yY] ]]; then
        echo "##########################################"
        echo "###         Installing Uptime Kuma     ###"
        echo "##########################################"
    
        # pull an uptime kuma docker-compose file from gitlab
        echo ""
        echo ""
        echo "    1. Pulling a the Uptime Kuma docker-compose.yml file."

        mkdir -p docker/uptime-kuma
        cd docker/uptime-kuma

        curl https://gitlab.com/bmcgonag/docker_installs/-/raw/main/docker_compose_uptime_kuma.yml -o docker-compose.yml >> ~/docker-script-install.log 2>&1

        echo ""
        echo ""
        echo "    2. Running the docker-compose.yml to pull and start Uptime Kuma..."
        echo ""

        if [[ "$OS" == "1" ]]; then
          docker compose up -d
        else
          sudo docker compose up -d
        fi

        echo "    3. You can find the Uptime Kuma folder at ~/docker/uptime-kuma..."
        echo ""
        echo "      You can now navigate in your browser to yoru server IP at"
        echo "      port number 3001 to reach the Uptime Kuma login page."
        echo ""
        echo "      You'll create your initial user as an admin on the first login."
        echo ""
        echo ""
        sleep 3s
        cd
    fi

    if [[ "$BESZEL" == [yY] ]]; then
        echo "##########################################"
        echo "###         Installing Beszel          ###"
        echo "##########################################"
    
        # pull an uptime kuma docker-compose file from gitlab
        echo ""
        echo ""
        echo "    1. Pulling a the Uptime Kuma docker-compose.yml file."

        mkdir -p docker/beszel
        cd docker/beszel

        curl https://gitlab.com/bmcgonag/docker_installs/-/raw/main/docker_compose_beszel.yml -o docker-compose.yml >> ~/docker-script-install.log 2>&1

        echo ""
        echo ""
        echo "    2. Running the docker-compose.yml to pull and start Uptime Kuma..."
        echo ""

        if [[ "$OS" == "1" ]]; then
          docker compose up -d
        else
          sudo docker compose up -d
        fi

        echo "    3. You can find the Beszel folder at ~/docker/beszel..."
        echo ""
        echo "      You can now navigate in your browser to yoru server IP at"
        echo "      port number 8090 to reach the Uptime Kuma login page."
        echo ""
        echo "      You'll create your initial user as an admin on the first login."
        echo ""
        echo ""
        sleep 3s
        cd
    fi

    echo "All docker applications have been added to the docker network my-main-net"
    echo ""
    echo "If you add more docker applications to this server, make sure to add them to the my-main-net network."
    echo "You can then use them by container name in NGinX Proxy Manager if so desired."

    exit 1
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
