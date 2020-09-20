#!/bin/bash
#####################################################################
# This script written by Storm Dragon
# Modified from the script located at: http://www.wuputah.com/2013/02/18/quickly-install-an-archlinux-vm-in-15-minutes/
# This script released under the terms of the WTFPL: http://wtfpl.net
#####################################################################

# confirm you can access the internet
if [[ ! $(curl -s -I http://www.google.com/ | head -n 1) =~ "200 OK" ]] ; then
echo "No internet connection detected. Press control+c to exit, or any key to continue."
read -n1 continue
fi

#get information
echo
echo "Welcome! Before I create your Arch Linux installation, I need to ask you a couple questions."
continue=false
while [ "$continue" = "false" ] ; do
read -p "In which timezone di you reside? (a)laska, (e)astern, (c)entral, (m)ountain, (p)ecific " timeZone
case "${timeZone^}" in
"A")
timeZone="Anchorage"
continue=true
;;
"E")
timeZone="New_York"
continue=true
;;
"C")
timeZone="Chicago"
continue=true
;;
"M")
timeZone="Denver"
continue=true
;;
"P")
timeZone="Los_Angeles"
continue=true
;;
default)
echo "Sorry, that timezone isn't available, please try again."
esac
done

#get hostname
continue=false
while [ "$continue" = "false" ] ; do
read -p "What should this computer be called? This is what is known as the hostname: " -e -i arch-vm hostName
if [ -n "$hostName" ] ; then
continue=true
fi
done

#get root password
continue=false
while [ "$continue" = "false" ] ; do
read -p "What do you want to use as the root password? " rootPassword
read -p "Please confirm, enter the password again: " comparePassword
if [ "$rootPassword" = "$comparePassword" ] ; then
continue=true
fi
done

#get username
continue=false
while [ "$continue" = "false" ] ; do
read -p "What would you like your username to be? Usernames should contain no spaces and be the name you want to use to login to the system: " userName
if [ -n "$userName" ] ; then
continue=true
fi
done

#get user password
continue=false
while [ "$continue" = "false" ] ; do
read -p "What do you want to use as the password for $userName? " userPassword
read -p "Please confirm, enter the password for $userName again: " comparePassword
if [ "$userPassword" = "$comparePassword" ] ; then
continue=true
fi
done

#Optionally disable key echo
read -p "Would you like to disable key echo in speakup? (y/n) " keyEcho
if [ "${keyEcho^}" = "Y" ] ; then
keyEcho="yes"
else
keyEcho="no"
fi

#install extra packages
read -p "Would you like to install tintin-alteraeon? (y/n) " ttaa
if [ "${ttaa^}" = "Y" ] ; then
ttaa="yes"
else
ttaa="no"
fi

read -p "Would you like to install tintin-empiremud? (y/n) " ttem
if [ "${ttem^}" = "Y" ] ; then
ttem="yes"
else
ttem="no"
fi

#mate
read -p "Would you like to install the mate desktop? (y/n) " mate
if [ "${mate^}" = "Y" ] ; then
mate="yes"
else
mate="no"
fi

#Verify information
echo
echo "----------------------------------------------------------------------"
echo "You are in the same timezone as: $timeZone"
echo "This computer will be called: $hostName"
echo "Your root password will be: $rootPassword"
echo
echo "Your user account is: $userName"
echo "Your user account password is: $userPassword"
echo "Disable character echo for speakup: $keyEcho"
echo
echo "Install extra package tintin-alteraeon: $ttaa"
echo "Install extra package tintin-empiremud: $ttem"
echo "Install extra package mate desktop: $mate"
echo
echo "Note: When you press enter a lot of things will happen and you may wish to turn off speech during this process."
echo "To do so, if you have a numeric keypad, press inumpad insert pluss numpad enter."
echo "If you are using a laptop, press and hold control, then press and hold capslock, finally press enter."
echo "This is a toggle, so to renable speech, simply press the same keyboard shortcut again."
read -p "Continue with the installation? (y/n): " continue
if [ "${continue^}" != "Y" ] ; then
exit 0
fi

# make a single partition.
parted -s /dev/sda mktable msdos
parted -s /dev/sda mkpart primary 0% 100%

# make filesystem
mkfs.ext4 /dev/sda1

# set up /mnt
mount /dev/sda1 /mnt

# install packages
pacstrap /mnt base base base-devel espeak alsa-utils grub bash-completion wget screen git sox opusfile opus-tools bc irssi surfraw elinks youtube-{dl,viewer} perl-term-read{key,line-gnu} perl-lwp-protocol-https mplayer 

# generate fstab
genfstab -p /mnt >> /mnt/etc/fstab

#copy sound state
alsactl store
cp /var/lib/alsa/asound.state /mnt/var/lib/alsa/asound.state

# chroot
arch-chroot /mnt /bin/bash << EOF

# set hostname
echo "$hostName" > /etc/hostname

# set timezone
ln -s /usr/share/zoneinfo/America/$timeZone /etc/localtime

# set locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf

#enable internet for the vm
systemctl enable dhcpcd

# install and configure grub bootloader
grub-install --target=i386-pc --recheck /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# set root password
echo root:$rootPassword | chpasswd

#Create user account
useradd -m -g users -G wheel,audio -s /bin/bash $userName

# set user password
echo $userName:$userPassword | chpasswd

#allow users of group wheel to use sudo without password for next section
sed -i 's/# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

#Set up console keymap
cp /usr/share/kbd/keymaps/i386/qwerty/us.map.gz /usr/share/kbd/keymaps/i386/qwerty/altus.map.gz
gunzip /usr/share/kbd/keymaps/i386/qwerty/altus.map.gz
sed -i 's/alt-and-altgr/two-alt-keys/' /usr/share/kbd/keymaps/i386/qwerty/altus.map
gzip /usr/share/kbd/keymaps/i386/qwerty/altus.map
echo -e "KEYMAP=altus\nFONT=Lat2-Terminus16" > /etc/vconsole.conf

#Disable character echo if selected
if [ "$keyEcho" = "yes" ] ; then
mkdir -p /etc/speakup/
echo 0 > /etc/speakup/key_echo
fi

#Create config file /etc/xdg/surfraw/conf
curl http://stormdragon.tk/scripts/vm-files/surfraw-conf > /etc/xdg/surfraw/conf

#Create login sound file.
mkdir -p http://stormdragon.tk/scripts/vm-files/loginsound.service > /usr/lib/systemd/system/
curl http://stormdragon.tk/scripts/vm-files/loginsound.service > /usr/lib/systemd/system/loginsound.service
systemctl enable loginsound

#Switch to user account and install cower, pacaur and espeakup-git
su - $userName
git clone https://aur.archlinux.org/cower.git
cd ~/cower
makepkg -si --noconfirm --skippgpcheck --skipinteg
cd
rm -rf cower
cower -d pacaur
cd pacaur
makepkg -si --noconfirm --skippgpcheck --skipinteg
cd
rm -rf pacaur
pacaur -S --noconfirm espeakup-git
mkdir -p ~/.speakup
echo "default_voice=en-us" > ~/.speakup/espeakup
#enable espeakup
sudo systemctl enable espeakup
sudo systemctl enable speakupconf

#Install additional packages if requested
if [ "$ttaa" = "yes" -o "$ttem" = "yes" ] ; then
cower -d tintin
cd tintin
makepkg -si --noconfirm --skippgpcheck --skipinteg
cd
rm -rf tintin
if [ "$ttaa" = "yes" ] ; then
git clone --depth=1 https://github.com/stormdragon2976/tintin-alteraeon.git
fi
if [ "$ttem" = "yes" ] ; then
git clone --depth=1 https://github.com/stormdragon2976/tintin-empiremud.git
fi
fi

#Create config file .inputrc
curl http://stormdragon.tk/scripts/vm-files/inputrc > ~/.inputrc

#Create config file .bashrc
curl http://stormdragon.tk/scripts/vm-files/bashrc > ~/.bashrc

#Create config file .bash_aliases
curl http://stormdragon.tk/scripts/vm-files/bash_aliases > ~/.bash_aliases

#Create config file .bash_functions
curl http://stormdragon.tk/scripts/vm-files/bash_functions > ~/.bash_functions

#create configuration file .xinitrc
curl http://stormdragon.tk/scripts/vm-files/xinitrc > ~/.xinitrc

#create configuration file .config/pacaur/config
mkdir -p ~/.config/pacaur/
curl http://stormdragon.tk/scripts/vm-files/pacaur-config > ~/.config/pacaur/config

#create configuration file .config/youtube-viewer/youtube-viewer.conf
mkdir -p ~/.config/youtube-viewer/
curl http://stormdragon.tk/scripts/vm-files/youtube-viewer.conf > ~/.config/youtube-viewer/youtube-viewer.conf

#create configuration file .mplayer/config
mkdir -p ~/.mplayer/
curl http://stormdragon.tk/scripts/vm-files/mplayer-config > ~/.mplayer/config

#create configuration file .elinks/elinks.conf
mkdir -p ~/.elinks/
curl http://stormdragon.tk/scripts/vm-files/elinks.conf > ~/.elinks/elinks.conf

#install mate if requested
if [ "$mate" = "yes" ] ; then
pacaur -S --needed --noconfirm xf86-video-{vesa,ati,intel,nouveau} xorg-server xorg-xinit orca qt-at-spi libao dotconf slim pidgin mate mate-extra seamonkey speech-dispatcher-git
#configure slim
sudo sed -i -e "s/#default_user        simone/default_user        $userName/" -e 's/#auto_login          no/auto_login          yes/' /etc/slim.conf
fi

#exit user account
logout

# end section sent to chroot
EOF

#Fix sudo to require a password
sed -i -e 's/%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' -e 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /mnt/etc/sudoers

# unmount
umount -R /mnt

#Quick mate tutorial
if [ "$mate" = "yes" ] ; then
espeak -v en-us -a 150 "Installation complete. You will need to configure speech-dispatcher when the VM is first loaded. See the message on your screen for details."
cat << EOF
When you launch the VM, before starting mate, type:
spd-conf
When it asks for 2 letter language, enter: en-us
When it asks for sound output type: libao
Failure to select libao will leave you without speech in mate
To launch mate, or restart it, or stop it use systemctl, as in:
sudo systemctl start slim
After you have started mate once, to make sure things work as expected, if you want it to start automatically, type:
sudo systemctl enable slim
For your convenience, aliases have been made to make starting, restarting, and stopping easier:
mate-start
mate-stop
mate-restart
Remember, to get into mate's menu, it is alt+f1, not control+escape.
EOF
fi

echo "Installation complete! Type poweroff to shut down this live invironment,"
echo "then you can boot into your newly installed virtual machine!"
exit 0
