#!/bin/bash

#
# Ref system: CentOS6 64bit
#

V=1.2.21                # this is the vesion of tcnative to build/package
RELEASE=0               # An internal package build number
NAME="tomcat-native"         # The resulting package name
DESC="The mission of the Tomcat Native Library (TCN) is to provide a free library of C data structures and routines.  This library contains additional utility interfaces for Java."
URI="http://tomcat.apache.org/download-native.cgi"
LIC="Apache Software License" # Package license to use
PROV="tcnative"         # The resulting package provides name
EMAIL="you@example.com" # The contact email built into the package
ARCH=`uname -i`         # Current system arch
DEPS="-d apr-devel -d openssl-devel" #this is a list of dependant packages that will be automatically installed with your package, centos example
NEEDED="apr-devel openssl-devel apr apr-util apr-util-devel openssl wget" # OS level packages needed for tcnative
FAKEROOT="$PWD/src-$$/usr"

echo "Ensuring CentOS dependant packages..."
if [ "`id -u`" -eq "0" ];then
  yum -q -y install $NEEDED
else
  echo "  - You are not root, so make sure all your dependancies are already installed like $NEEDED, an OpenJDK, and fpm via gem"
fi

if hash fpm 2>/dev/null; then
  echo "Detected fpm installed"
else
  if [ "`id -u`" -eq "0" ];then
    echo "Auto installing rubygems and fpm..."
    yum -q -y install rubygems
    gem install fpm
  else
    echo "ERROR: fpm not found, install with 'gem install fpm' but make sure you have the CentOS package rubygems installed first"
    exit 1
  fi
fi

################################
#
# Try to auto detect the JDK
#
if [ -x "/usr/java/default/jre/bin/java" ];then

  echo "Oracle JDK detected. Version:"
  /usr/java/default/jre/bin/java -version
  if [ ! -d "/usr/java/default/include" ];then
    echo "ERROR: JDK include dir not found at: /usr/java/default/include"
    exit 1
  fi

  JHOME="/usr/java/default"

elif [ -x "/usr/lib/jvm/java/bin/java" ];then

  echo "OpenJDK detected. Version:"
  /usr/lib/jvm/java/bin/java -version

  if [ ! -d "/usr/lib/jvm/java-openjdk/include" ];then
    echo "Please make sure the devel version of your OpenJDK is installed. Hint: yum install java-1.8.0-openjdk-devel"
    exit 1
  fi

  JHOME="/usr/lib/jvm/java-openjdk"

else

  echo "No JDK detected by looking in /usr/java/default and /usr/lib/jvm/jre-openjdk. A JDK must be installed to continue. Hint: 'yum install java-1.8.0-openjdk'"
  exit 1

fi

if [ ! -f tomcat-native-$V-src.tar.gz ];then
#   echo "Downloading tomcat-native-$V-src.tar.gz from upstream"
  wget -q "https://www-us.apache.org/dist/tomcat/tomcat-connectors/native/$V/source/tomcat-native-$V-src.tar.gz"
fi

if [ -n $JHOME ];then
  echo "Using JDK found at $JHOME"
else
  echo "No JDK found."
  exit 1
fi

echo "Creating $FAKEROOT to install and package from"
mkdir -p "$FAKEROOT" # this is used as a fake root to install tcnative before we package it
tar zxf tomcat-native-$V-src.tar.gz
cd /tmp/tomcat-native-$V-src/native
echo "Running configure..."
./configure --with-apr=/usr \
            --with-java-home="$JHOME" \
            --with-ssl=yes --libdir="$FAKEROOT/lib64" \
            --prefix="$FAKEROOT/" > /dev/null 2>&1
if [ $? -ne 0 ];then
echo "CONFIG FAILED"
exit 1
fi


echo "Compiling..."
make > /dev/null 2>&1
if [ $? -ne 0 ];then echo "COMPILE FAILED"; exit 1; fi

echo "Installing into \"$FAKEROOT\"..."
make install > /dev/null 2>&1
if [ $? -ne 0 ];then echo "INSTALL FAILED"; exit 1; fi

cd ../../..

# create a simple post install script to automatically setup sym links for tomcat
#TODO - verify that this is only needed for oracles java
echo "# Oracle JRE
if [ -d /usr/java/default/lib/amd64 ];then
  ln -s /usr/lib64/libtcnative-1.so.0 /usr/java/default/lib/amd64/libtcnative-1.so
fi
# Oracle JDK
if [ -d /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.212.b04-0.el7_6.x86_64 ];then
  ln -s /usr/lib64/libtcnative-1.so.0 /usr/lib/jvm/jre/lib/amd64/libtcnative-1.so
fi" > /tmp/$$-post.sh

cd $FAKEROOT
cd ..



# find and delete all empty dirs in $FAKEROOT
find . -type d -empty -delete

###################################################
# Build the RPM with fpm
# (dear fpm guy, you are awesome thank you)
#
fpm --url "$URI" --license "$LIC" --provides "$PROV" -p "../$NAME-$V-$RELEASE.$ARCH.rpm" -m "$EMAIL" --no-rpm-sign -v "$V" --iteration "$RELEASE" -a "$ARCH" --after-install "/tmp/$$-post.sh" -s dir -t rpm -n "$NAME"  $DEPS  --verbose  --description "$DESC" *

if [ $? -eq 0 ];then
  cd ..
  echo -e "Done!\nCleaning up $FAKEROOT..."
  rm -rf `dirname $FAKEROOT`
  rm -f $$-post.sh
  echo "########################################################"
  echo
  rpm -qpil $NAME-$V-$RELEASE.$ARCH.rpm
else
  echo "Something bad happened. Unable to create the RPM. See error above."
  exit 2
fi