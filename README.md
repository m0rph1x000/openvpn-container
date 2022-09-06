# OpenVPN on Contaner via Docker-compose
OpenVPN deployment in two ways are preferred as follows:
1. Via a __Bash__ script ([Bash script method](/bash/))
2. Via __Ansible__ roles which is more robust and idempotence ([Ansible method](/ansible/)).

### Which one is better?
Each has its pros and cons, but we recommend using _Ansible_ over Bash because it's more robust and _idempotence_.

In summary, the advantages and disadvantages of each are listed in the following table:

|  | Bash Script | Ansible |
|:- | :-: | :-: | 
| __Cofig__ | Interactive shell interface | Config files | 
| __Usage__ | Easy to use | Easy for Ansible experts |
| __Idempotency__ | No | Yes |

## Quick Started
Clone the repository in twe methods:
```
git clone https://github.com/m0rph1x000/openvpn-container.git
```

**NOTE** If you would to use the _Bash_ method clone the repository on your desired node (hosts), else clone the repository on your own local machine (_manager_ node in _Ansible_).

### Bash script
Just execute the following command:

```
wget -O - https://raw.githubusercontent.com/m0rph1x000/openvpn-container/main/bash/install.sh | sudo bash
```

If you want to have script on your host perform the following instruction:

```bash
# be aware that you are on the clone path.
cd openvpn-container/bash
# change mode to executable
chmod 0755 install.sh
sudo ./install.sh
```