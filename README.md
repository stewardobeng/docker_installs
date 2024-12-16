# docker_installs
This script will help install any, or all, of Docker-CE, Docker-Compose, NGinX Proxy Manager, and Portainer-CE.

## Reason for Making this Script
I got tired of running individual commands all the time, so I created some scripts to make this very easy. 

## Using this script

You can use the script by simply pulling it down with wget or curl, changing the permissions, and running it. 

1. Pull down a copy with the command

`wget -O install-docker.sh https://gitlab.com/bmcgonag/docker_installs/-/raw/main/install_docker_nproxyman.sh?ref_type=heads`

2. Change the permission to make the file executable:

`chmod +x install-docker.sh`

3. Run it with

`./install-docker.sh`

## Contributing by making changes

1. Clone the repo
`git clone https://gitlab.com/bmcgonag/docker_installs.git`


## Prompts from the script:
First, you'll be prompted to select the number for your OS / Distro.  Currently I support RaspbianOS (latest), CentOS 7 and 8, Debian 10 and 11, Ubuntu 18.04 20.04 22.04 23.04 24.04 and on, Arch Linux, and Open Suse (tested on Leap 15.4). 

Next, you'll be asked to answer "y" to any of the four software packages you'd like to install. 
- Docker-CE (you'll need this for the others to work)
- Docker-Compose (you'll need this for any of the applications to start properly)
Note: I try to detect if Docker and Docker Compose are already installed and running...and won't prompt if they are found.

Next, you'll be asked if you want to install any applications with Docker and Docker compose. This is a yes / no (y/n) question. If you answer 'y', you'll be asked to answer y/n for each application I offer.

- NGinx Proxy Manager
- Navidrome (music player)
- Remotely (Remote Desktop Support Tool)
- Guacamole (Remote Desktop Protocol in the Browser)
- RustDesk Server
- Uptime Kuma
- Portainer-CE
  - if you answer y to Portainer, you'll be asked another question

Do you want 
  1. full Portainer-CE with the web UI, or 
  2. just Portainer-agent (which you connect to another full portainer instance). 

Make that selection, and the install will continue.

Answering "n" to any of them will cause them to be skipped.

### RustDesk Install
- You'll be asked to provide an FQDN for the install. This can be a domain / subdomain name, or IP address
- The system will auto generate the key for your server, so you can use it in a secured way (others can't just connect by knowing the URL).  You'll be shown the key in the text when it is generated, but you can also find it in the docker/rustdesk/hbbs folder afterward if needed. The file is id_ed25519.pub. 
  - When the key is generated, you'll be asked to provide a password for the key, you can just press enter and leave the key blank (and I recommend you do in this case). 

### Remotely Install
- Remotely needs a postgres password generated, so th escript auto-generates a 32 character random password for you, and applies it to the .env file.  There should be nothing for you to use on this, it's just an FYI.

### NOTE
* You must have Docker-CE (or some version of Docker) installed in order to run any of the other three packages.
* You must have Docker-Compose installed in order to run NGinX Proxy Manager, Portainer-CE, or any of the apps offered with this script.

Before prompting to install Docker or Docker-Compose, I do try to see if you already have them installed, and I skip the prompt if you do (or I try to anyway).

## Recent changes
 - Updated Remotely to use Postgres with randomly generate postgres db password
 - Added RustDesk
 - Add Uptime Kuma

## Future Work
- [X] Make it work for Raspberry Pi
- [X] Make it work for Arch
- [X] Make it work for OpenSuse
- [X] Maybe add a few other default containers to pull down and start running
- [ ] Prompt for Credentials to use in NGinX Proxy Manager db settings vs. using the defaults.
- [X] Set all Conteiners on a single docker network
- [ ] Clean it up and split out functions to other files to make it easier to run / work on.

## Contributing
If you find issues, please let me know. I'm always open to new contributors helping me add Distro support, more software packages, etc.  Just clone the project and make a pull request with any changes you add. 

## Licensing
My script is offered without warranty against defect, and is free for you to use any way / time you want.  You may modify it in any way you see fit.  Please see the individual project pages of the software packages for their licensing.

## Contributors
@binuengoor
