#!/bin/bash

export ovpn_data_path=/home/ubuntu/data/ovpn.conf
export container_name="openvpn"

userInterface(){
    read  -p "Select your desired protocol:[udp/tcp] " PROTOCOL
    case "$PROTOCOL" in
        udp)
            export PROTOCOL="udp"
            ;;
    
        tcp)
            export PROTOCOL="tcp"
            ;;
        *)
            export PROTOCOL="udp"
            ;;
    esac

    read -p "What is your desired port?[default: 1194] " PORT
    if [[ -z $PORT ]]; then export PORT=1194; else export PORT; fi
    if [[ $PORT -lt 1001 ]] || [[ $PORT -gt 65536 ]]; then echo "Error: Port must be between 1001 and 65536!"; exit 1; fi

    read -p "Enter your public IP address: " IPaddr
    export IPaddr
    
    read -p "Do you want to enable ovpn file passpharse?[yes/no] " iywpass
    case "$iywpass" in
        yes)
            export iywpass=""
            passwordState="Enable"
            ;;
        no)
            export iywpass="nopass"
            passwordState="Disable"
            ;;
        *)
            export iywpass=""
            passwordState="Enable"
            ;;
    esac
}

summery(){
    divider====================================
    divider=$divider$divider

    header="\n %-15s %10s %13s %12s\n"
    format=" %-15s %10d %13s %12s\n"

    totalwidth=55

    echo -e "\nSUMMERY:"
    printf "$header" "IP addrres" Port Protocol Passpharse
    printf "%$totalwidth.${totalwidth}s\n" "$divider"
    printf "$format" \
        $IPaddr $PORT $PROTOCOL $passwordState

    read -p "Are you confident in your information?[yes/no] " confident

    echo $ovpn_data_path
    if [[ $confident == "No" ]]; then echo "Please run script again."; exit 1; fi
}

## Installing Docker either debian or ubuntu based.
preConfiguration(){
    echo -e "\nInstalling Docker..."
    if [[ -f /etc/debian_version ]]; then
        echo "APT is here!"
        sudo apt install -y docker docker.io docker-compose
    else
        echo "YUM is here!"
        sudo yum install -y yum-utils
        sudo yum-config-manager \
            --add-repo \
            https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install docker-ce docker-ce-cli containerd.io docker-compose-plugin
    fi

    if [[ $? != 0 ]]; then echo -e "\nFix your Proble.\nSuggestion: sudo apt -y update"; exit 1; fi 
}

configuration(){
    sudo rm -rf $ovpn_data_path
    sudo mkdir -p $ovpn_data_path
    cd $ovpn_data_path
    cat <<EOF > $ovpn_data_path/docker-compose.yml
version: '2'
services:
  openvpn:
    cap_add:
     - NET_ADMIN
    image: kylemanna/openvpn
    container_name: $container_name
    ports:
     - "${PORT}:1194/${PROTOCOL}"
    restart: always
    volumes:
     - ${ovpn_data_path}:/etc/openvpn
EOF

    docker-compose run --rm openvpn ovpn_genconfig -u ${PROTOCOL}://$IPaddr
    docker-compose run --rm openvpn ovpn_initpki

    docker-compose up -d openvpn



    ## Enabling multi-client
    sudo echo "duplicate-cn" >> $ovpn_data_path/openvpn.conf
    sudo docker restart $container_name

    echo -e "\nWhat is your client name?"
    read CLIENTNAME
    export CLIENTNAME

    docker-compose run --rm openvpn easyrsa build-client-full $CLIENTNAME
    docker-compose run --rm openvpn ovpn_getclient $CLIENTNAME > /home/ubuntu/${CLIENTNAME}.ovpn
}

if [[ $(id -u) != 0 ]]; then
    echo "Please run as SuperUser!"
    exit 1
fi
userInterface
summery
preConfiguration
configuration