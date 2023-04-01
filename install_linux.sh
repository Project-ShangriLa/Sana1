#!/bin/sh
sudo yum -y install ImageMagick
sudo rpm -ivh lib/GraphicsMagick-1.3.20-3.el7.x86_64.rpm
sudo yum -y install ImageMagick-devel
sudo yum -y install ipa-gothic-fonts.noarch

