#!/bin/bash

read -p 'Utilisateur système: ' SYSUSER

getent passwd $SYSUSER > /dev/null
if [ $? -ne 0 ]; then
    useradd -m -s /bin/bash $SYSUSER
fi

mount /dev/cdrom /mnt
mount /dev/cdrom /mnt
bash /mnt/Linux/install.sh
umount /dev/cdrom

# Installation de sudo
apt-get install -y sudo
adduser $SYSUSER sudo

# Désactivation d'IPv6
sed -i '/^net\.ipv6\.conf\.all\.disable_ipv6/d' /etc/sysctl.conf
sed -i '/^net\.ipv6\.conf\.all\.autoconf/d' /etc/sysctl.conf
sed -i '/^net\.ipv6\.conf\.default\.disable_ipv6/d' /etc/sysctl.conf
sed -i '/^net\.ipv6\.conf\.default\.autoconf/d' /etc/sysctl.conf
cat <<EOF >>/etc/sysctl.conf
# désactivation de ipv6 pour toutes les interfaces
net.ipv6.conf.all.disable_ipv6 = 1

# désactivation de l’auto configuration pour toutes les interfaces
net.ipv6.conf.all.autoconf = 0

# désactivation de ipv6 pour les nouvelles interfaces (ex:si ajout de carte réseau)
net.ipv6.conf.default.disable_ipv6 = 1

# désactivation de l’auto configuration pour les nouvelles interfaces
net.ipv6.conf.default.autoconf = 0
EOF
sysctl -p


# Installation et configuration de VIM
apt install -y vim
VIM_DEFAULTS=$(ls -a /usr/share/vim/vim*/defaults.vim | tail -n 1)
cat <<EOF > /etc/vim/vimrc.local
" This file loads the default vim options at the beginning and prevents
" that they are being loaded again later. All other options that will be set,
" are added, or overwrite the default settings. Add as many options as you
" whish at the end of this file.

" Load the defaults
source $VIM_DEFAULTS

" Prevent the defaults from being loaded again later, if the user doesn't have a local vimrc (~/.vimrc)
let skip_defaults_vim = 1

" Set the mouse mode to 'r'
if has('mouse')
  set mouse=r
endif

" Toggle paste/nopaste automatically when copy/paste with right click in insert mode:
let &t_SI .= "\<Esc>[?2004h"
let &t_EI .= "\<Esc>[?2004l"

inoremap <special> <expr> <Esc>[200~ XTermPasteBegin()

function! XTermPasteBegin()
  set pastetoggle=<Esc>[201~
  set paste
  return ""
endfunction
EOF

# Configuration SSH
apt-get install -y ssh
sed -i '/^Port/d' /etc/ssh/sshd_config
sed -i '/^PermitRootLogin/d' /etc/ssh/sshd_config
sed -i '/^AllowGroups/d' /etc/ssh/sshd_config
cat <<EOF >>/etc/ssh/sshd_config
Port 60022
PermitRootLogin without-password
AllowGroups ssh
EOF
sed -i '/Port/d' /etc/ssh/ssh_config
cat <<EOF >>/etc/ssh/ssh_config
Port 60022
EOF
adduser $SYSUSER ssh
service ssh restart

# Configuration du bash root
cp /etc/skel/.bashrc /root/.bashrc
