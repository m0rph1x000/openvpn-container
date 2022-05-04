#!/bin/bash

export ovpnDataPath=/opt/openvpn/cfg
export containerName="openVPN"

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
    
    read -p "Do you want to enable ovpn file password?[yes/no] " iywpass
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
    printf "$header" "IP addrres" Port Protocol Password
    printf "%$totalwidth.${totalwidth}s\n" "$divider"
    printf "$format" \
        $IPaddr $PORT $PROTOCOL $passwordState

    read -p "Are you confident in your information?[yes/no] " confident
    if [[ $confident == "No" ]]; then echo "Please run script again."; exit 1; fi
}

## Installing Docker either debian or ubuntu based.
preConfiguration(){
    echo -e "\nInstalling Docker..."
    if [[ -f /etc/debian_version ]]; then
        echo "APT is here!"
        sudo apt install -y docker docker.io
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
    sudo rm -rf $ovpnDataPath
    sudo mkdir -p $ovpnDataPath

    sudo docker run -v $ovpnDataPath:/etc/openvpn --log-driver=none --rm \
        kylemanna/openvpn ovpn_genconfig -u ${PROTOCOL}://${IPaddr}:$PORT

    ## Generating and retrieving CA certificate and client certificates
    sudo docker run -v $ovpnDataPath:/etc/openvpn --log-driver=none --rm \
        -it kylemanna/openvpn ovpn_initpki

    ## Start the OpenVPN server service
    sudo docker run -v $ovpnDataPath:/etc/openvpn -d --name $containerName -p ${PORT}:1194/${PROTOCOL} \
        --cap-add=NET_ADMIN kylemanna/openvpn

    ## Enabling multi-client
    sudo echo "duplicate-cn" >> $ovpnDataPath/openvpn.conf
    sudo docker restart $containerName

    echo -e "\nWhat is your desired name of .ovpn file name?"
    read ovpnFileName
    export ovpnFileName
    echo "Where you store .ovpn file?"
    read ovpnCaFilePath
    export $ovpnCaFilePath
    sudo docker run -v $ovpnDataPath:/etc/openvpn --log-driver=none --rm -it kylemanna/openvpn easyrsa \
        build-client-full $ovpnFileName $iywpass
    sudo docker run -v $ovpnDataPath:/etc/openvpn --log-driver=none --rm kylemanna/openvpn ovpn_getclient \
        $ovpnFileName > ${ovpnCaFilePath}/${ovpnFileName}.ovpn
}

if [[ $(id -u) != 0 ]]; then
    echo "Please run as SuperUser!"
    exit 1
fi
userInterface
summery
preConfiguration
configuration