#!/bin/bash

# TODO : Feature
# Add docker support

docker_install(){
  # Installation of Docker
  # TODO : Support
  # Add multiple arch support
  case ${LINUX_OS} in
    'debian')
      if  ! [[ ${LINUX_VER} -eq 8 ]]
      then
        whiptail --title 'Docker Mangement' \
          --msgbox "Sorry but your linux version ${LINUX_VER} is not supported yet.

Docker installation will be aborted" ${WT_HEIGHT} ${WT_WIDTH}
        return 1
      fi

      ${LINUX_PKG_MGR} purge lxc-docker*
      ${LINUX_PKG_MGR} purge docker.io*
      NEED_UPDATE=true && do_fullupdate
      ${LINUX_PKG_MGR} install apt-transport-https ca-certificates
      apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 \
                  --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

      if  [[ ${LINUX_VER} -eq 8 ]]
      then
        echo "deb https://apt.dockerproject.org/repo debian-jessie main" > \
          /etc/apt/sources.list.d/docker.list
      fi
      NEED_UPDATE=true && do_fullupdate
      ${LINUX_PKG_MGR} install docker-engine
      systemctl start docker
      systemctl enable docker
      docker run hello-world
      ;;
    'ubuntu')
      return 0
      ;;
    *)
      echo "Programmer error : Option ${LINUX_OS} uknown in ${FUNCNAME}."
      ;;
  esac

  echo =================================================================
  echo You can take a look at log above
  echo Press Enter to continue
  echo =================================================================
  read
  if ( whiptail --title 'Docker Management' --yesno 'Does everything was OK ?' \
    ${WT_HEIGHT} ${WT_WIDTH} )
  then
    return 0
  else
    return 1
  fi
}

docker_management() {
  # Check if docker is installed, if not propose to install it, if yes, just go
  # to docker management menu
  local major_kernel_ver=$( uname -r | cut -d. -f1 )
  local minor_kernel_ver=$( uname -r | cut -d. -f2 )
  if ! type -t docker > /dev/null
  then
    if [[ ${major_kernel_ver} -lt 3 ]] || \
      [[ ${major_kernel_ver} -ge 3 && ${minor_kernel_ver} -lt 10 ]]
    then
      whiptail --title 'Docker Management' \
        --msgbox "Sorry but your kernel version \
(${major_kernel_ver}.${minor_kernel_ver} is not supported by docker.

Docker can't be installed on your computer. Process aborted." \
      ${WT_HEIGHT} ${WT_WIDTH}
      return 1;
    elif ( whiptail --title 'Docker Management' \
      --yesno "Docker does not seems to be installed yet.

Do you want to install it now ?" ${WT_HEIGHT} ${WT_WIDTH} )
    then
      docker_install
      RET=$? ; [[ ${RET} -eq 1 ]] && return 1
    fi
  fi
}
