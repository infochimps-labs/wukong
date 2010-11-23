#!/usr/bin/env bash
set -x  # turn on tracing

# A url directory with the scripts you'd like to stuff into the machine
REMOTE_FILE_URL_BASE="http://github.com/infochimps/wukong"

# echo "`date` Broaden the apt universe"
# sudo bash -c 'echo "deb http://ftp.us.debian.org/debian  lenny  multiverse restricted universe" >> /etc/apt/sources.list.d/multiverse.list'

# Do a non interactive apt-get so the user is never prompted for input
export DEBIAN_FRONTEND=noninteractive

# Update package index and update the basic system files to newest versions
echo "`date` Apt update" 
sudo apt-get -y update  ;
sudo dpkg --configure -a
echo "`date` Apt upgrade, could take a while" 
sudo apt-get -y safe-upgrade
echo "`date` Apt install" 
sudo apt-get -f install ;

echo "`date` Installing base packages"
# libopenssl-ruby1.8 ssl-cert 
sudo apt-get install -y unzip build-essential git-core ruby ruby1.8-dev rubygems ri irb build-essential wget git-core zlib1g-dev libxml2-dev;
echo "`date` Unchaining rubygems from the tyrrany of ubuntu" 
sudo gem install --no-rdoc --no-ri rubygems-update --version=1.3.7 ; sudo /var/lib/gems/1.8/bin/update_rubygems; sudo gem update --no-rdoc --no-ri --system ; gem --version ;

echo "`date` Installing wukong and related gems" 
sudo gem install --no-rdoc --no-ri addressable extlib htmlentities configliere yard wukong right_aws uuidtools cheat
sudo gem list 

echo "`date` Wukong bootstrap complete: `date`" 
true
