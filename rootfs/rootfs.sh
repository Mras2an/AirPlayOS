#!/bin/bash

function do_build
{
        $builder busybox $install_dir
        $builder strace $install_dir
        $builder dhcpcd $install_dir
        $builder alsa-lib $install_dir
        $builder alsa-lib $TOOLCHAIN_PATH

#       $builder alsa-utils $install_dir

        $builder libao $install_dir
        $builder libao $TOOLCHAIN_PATH
        $builder util-linux $install_dir
        $builder util-linux $TOOLCHAIN_PATH
        $builder perl $install_dir
        CROSS=$CROSS_COMPILE
        unset CROSS_COMPILE
        $builder openssl $install_dir
        $builder openssl $TOOLCHAIN_PATH
        export CROSS_COMPILE=$CROSS

#error
#       $builder  libaoNet $install_dir
#       $builder libwww $install_dir
#       $builder perl $install_dir          
}

set -e

if [[ $# -ne 1 ]]
then
	echo "usage: $(basename $0) install_dir"
	exit 1
fi

if [ -z "$TOOLCHAIN_PATH" ]
then
	echo "TOOLCHAIN_PATH variable is not set"
	exit 2
fi

target=$TARGET
scripts_dir=$(cd $(dirname $0) && pwd)
mkdir -p $1
install_dir=$(cd $1; pwd)
builder="$scripts_dir/../builder/builder.sh"

do_build

cd $install_dir
test -e init || ln -s bin/busybox init
cd -

test -e $install_dir/dev || mkdir $install_dir/dev/
test -e $install_dir/dev/ttyO0 || sudo mknod $install_dir/dev/ttyO0 c 204 64
cd $install_dir/dev/
sudo MAKEDEV -v generic console
cd -

test -e $install_dir/etc || mkdir $install_dir/etc
cp $scripts_dir/fstab $install_dir/etc
#cp $scripts_dir/inittab $install_dir/etc
#cp $scripts_dir/fstab $install_dir/etc
#cp $scripts_dir/group $install_dir/etc
#cp $scripts_dir/passwd $install_dir/etc
#cp $scripts_dir/shells $install_dir/etc
#cp $scripts_dir/hosts $install_dir/etc
test -e $install_dir/etc/shadow || cp $scripts_dir/shadow $install_dir/etc
chmod 400 $install_dir/etc/shadow

test -e $install_dir/boot || mkdir $install_dir/boot
cp $scripts_dir/boot/* $install_dir/boot

test -e $install_dir/lib || mkdir $install_dir/lib
cp -r $TOOLCHAIN_PATH/lib/* $install_dir/lib

cp -r $scripts_dir/init.d $install_dir/etc

test -e $install_dir/proc || mkdir $install_dir/proc
test -e $install_dir/sys || mkdir $install_dir/sys
test -e $install_dir/tmp || mkdir $install_dir/tmp
test -e $install_dir/run || mkdir $install_dir/run
test -e $install_dir/sys/kernel || mkdir $install_dir/sys/kernel
test -e $install_dir/sys/kernel/debug || mkdir $install_dir/sys/kernel/debug
test -e $install_dir/dev/pts || mkdir $install_dir/dev/pts
test -e $install_dir/sbin/dhcpcd || ln -s /usr/sbin/dhcpcd $install_dir/sbin/dhcpcd
test -e $install_dir/usr/share/udhcp || mkdir $install_dir/usr/share/udhcp
cp $scripts_dir/default.script $install_dir/usr/share/udhcp/
sudo chmod +x $scripts_dir/default.script

git clone https://github.com/hendrikw82/shairport.git work/shairport
cp ../builder/patch/shairport.patch work/shairport
cd work/shairport
patch -p0 < shairport.patch
make CC=${CROSS_COMPILE}gcc
cp hairtunes shairport.pl shairport  $install_dir/bin
cd -


