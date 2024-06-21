#!/bin/bash

: '

打包: termux-rootfs
1). 重置 termux， 清除app的数据
2). 启动 termux， cd ..
3). pkg install busybox p7zip file patchelf binutils
4). cd ~/.. && tar -czvf ../t.tar.gz  .
5). termux-setup-storage
6). mv -f ../t.tar.gz /sdcard/
7). 拉取到电脑上：adb pull /sdcard/t.tar.gz && mv  -f t.tar.gz  termux-rootfs-arm64.tar.gz


'

action=$1
if [ "$action" == "" ]; then action=安装; fi

. ./scripts/common.sh
. ./ezapp/tmx/tmx-patch

SWNAME=tmx
SWVER=1.8.19

# 注意安装顺序，后装者依赖前装者
DEB_PATH1=./downloads/${SWNAME}.deb
TMX_PATH="./downloads/termux-rootfs.tar.xz"

DIR_DESKTOP_FILES=/usr/share/applications
DSK_FILE=${SWNAME}.desktop
DSK_PATH=${DIR_DESKTOP_FILES}/${DSK_FILE}
app_dir=/exbin/z
WBOXDIR=${app_dir}
WBOXUSR=${app_dir}/usr
WB_PATH=${APP_INTERNAL_DIR}/z
WB_PORT=1026


function create_files1() {

	(cd ${WBOXDIR}/usr/bin && ln -sf bzdiff bzcmp )
	(cd ${WBOXDIR}/usr/bin && ln -sf bzmore bzless)
	(cd ${WBOXDIR}/usr/bin && ln -sf unzip  zipinfo)

	echo "正在处理 7zip"
	cat <<- EOF > ${WBOXDIR}/usr/bin/7z
		#!/data/data/com.zzvm/files/z/usr/bin/sh
		"/data/data/com.zzvm/files/z/usr/lib/p7zip/7z" "\$@"
	EOF
	chmod a+x ${WBOXDIR}/usr/bin/7z

	echo "正在创建必要的文件"
	mkdir -p                  ${WBOXDIR}/usr/tmp
	rm -rf                    ${WBOXDIR}/usr/etc/resolv.conf
	echo "nameserver 8.8.8.8">${WBOXDIR}/usr/etc/resolv.conf
	chmod 666                 ${WBOXDIR}/usr/etc/resolv.conf

	echo "正在更换软件仓库地址"
	mkdir -p ${WBOXDIR}/usr/etc/apt/sources.list.d 2>/dev/null
	echo "deb https://mirrors.tuna.tsinghua.edu.cn/termux/apt/termux-main stable main" > ${WBOXDIR}/usr/etc/apt/sources.list
	echo "deb https://mirrors.tuna.tsinghua.edu.cn/termux/apt/termux-x11 x11 main"     > ${WBOXDIR}/usr/etc/apt/sources.list.d/x11.list


	echo "调整文件夹权限"
	chown droidvm -R ${WBOXDIR}
	chmod a+x     -R ${WBOXDIR}
	chmod 777        ${WBOXDIR}/usr/tmp

}

function create_files2() {
	: '测试用的指令
	apt remove -y file
	apt -oDebug::*=1 reinstall file

	apt remove -y busybox
	apt -oDebug::*=1 reinstall busybox

	readelf -d `which busybox`
	'

	chmod a+x ./ezapp/tmx/tmx-patch
	chmod a+x ./ezapp/tmx/tmx-dpkg-deb

	[ -f ${WBOXDIR}/usr/bin/dpkg-deb.ori ] || mv -f ${WBOXDIR}/usr/bin/dpkg-deb  ${WBOXDIR}/usr/bin/dpkg-deb.ori
	rm -rf ${WBOXDIR}/usr/bin/dpkg-deb
	(cd ${WBOXDIR}/usr/bin/ && ln -sf ../../../tools/zzswmgr/ezapp/tmx/tmx-dpkg-deb  dpkg-deb)
	chmod a+x ${WBOXDIR}/usr/bin/dpkg-deb
}

function elfPatch() {

	create_files1

	# 字符串等长替换！
	sed -i "s|data/data/com.termux/files|data/data/com.zzvm/files/z|g"	$WBOXDIR/usr/bin/*
	sed -i "s|data/data/com.termux/files|data/data/com.zzvm/files/z|g"	$WBOXDIR/usr/bin/bash
	sed -i "s|data/data/com.termux/files|data/data/com.zzvm/files/z|g"	$WBOXDIR/usr/bin/which
	sed -i "s|data/data/com.termux/files|data/data/com.zzvm/files/z|g"	$WBOXDIR/usr/bin/cmp
	sed -i "s|data/data/com.termux/files|data/data/com.zzvm/files/z|g"	$WBOXDIR/usr/bin/dpkg
	sed -i "s|data/data/com.termux/files|data/data/com.zzvm/files/z|g"	$WBOXDIR/usr/bin/dpkg-deb
	sed -i "s|data/data/com.termux/files|data/data/com.zzvm/files/z|g"	$WBOXDIR/usr/bin/dpkg-divert
	sed -i "s|data/data/com.termux/files|data/data/com.zzvm/files/z|g"	$WBOXDIR/usr/bin/dpkg-fsys-usrunmess
	sed -i "s|data/data/com.termux/files|data/data/com.zzvm/files/z|g"	$WBOXDIR/usr/bin/dpkg-query
	sed -i "s|data/data/com.termux/files|data/data/com.zzvm/files/z|g"	$WBOXDIR/usr/bin/dpkg-realpath
	sed -i "s|data/data/com.termux/files|data/data/com.zzvm/files/z|g"	$WBOXDIR/usr/bin/dpkg-split
	sed -i "s|data/data/com.termux/files|data/data/com.zzvm/files/z|g"	$WBOXDIR/usr/bin/dpkg-trigger	
	sed -i "s|data/data/com.termux/files|data/data/com.zzvm/files/z|g"	$WBOXDIR/usr/bin/apt
	sed -i "s|data/data/com.termux/files|data/data/com.zzvm/files/z|g"	$WBOXDIR/usr/bin/apt-get
	sed -i "s|data/data/com.termux/files|data/data/com.zzvm/files/z|g"	$WBOXDIR/usr/bin/apt-key
	sed -i "s|data/data/com.termux/files|data/data/com.zzvm/files/z|g"	`realpath $WBOXDIR/usr/lib/libgnutls.so`
	sed -i "s|data/data/com.termux/files|data/data/com.zzvm/files/z|g"	`realpath $WBOXDIR/usr/lib/libapt-pkg.so`
	sed -i "s|data/data/com.termux/files|data/data/com.zzvm/files/z|g"	`realpath $WBOXDIR/usr/lib/libapt-private.so`
	sed -i "s|data/data/com.termux/files|data/data/com.zzvm/files/z|g"	`realpath $WBOXDIR/usr/lib/apt/methods/copy`
	sed -i "s|data/data/com.termux/files|data/data/com.zzvm/files/z|g"	`realpath $WBOXDIR/usr/lib/apt/methods/file`
	sed -i "s|data/data/com.termux/files|data/data/com.zzvm/files/z|g"	`realpath $WBOXDIR/usr/lib/apt/methods/gpgv`
	sed -i "s|data/data/com.termux/files|data/data/com.zzvm/files/z|g"	`realpath $WBOXDIR/usr/lib/apt/methods/http`
	sed -i "s|data/data/com.termux/files|data/data/com.zzvm/files/z|g"	`realpath $WBOXDIR/usr/lib/apt/methods/rsh`
	sed -i "s|data/data/com.termux/files|data/data/com.zzvm/files/z|g"	`realpath $WBOXDIR/usr/lib/apt/methods/store`
	sed -i "s|data/data/com.termux/cache|data/data/com.zzvm/files/z|g"	$WBOXDIR/usr/bin/cmp
	sed -i "s|data/data/com.termux/cache|data/data/com.zzvm/files/z|g"	$WBOXDIR/usr/bin/dpkg
	sed -i "s|data/data/com.termux/cache|data/data/com.zzvm/files/z|g"	$WBOXDIR/usr/bin/dpkg-deb
	sed -i "s|data/data/com.termux/cache|data/data/com.zzvm/files/z|g"	$WBOXDIR/usr/bin/dpkg-divert
	sed -i "s|data/data/com.termux/cache|data/data/com.zzvm/files/z|g"	$WBOXDIR/usr/bin/dpkg-fsys-usrunmess
	sed -i "s|data/data/com.termux/cache|data/data/com.zzvm/files/z|g"	$WBOXDIR/usr/bin/dpkg-query
	sed -i "s|data/data/com.termux/cache|data/data/com.zzvm/files/z|g"	$WBOXDIR/usr/bin/dpkg-realpath
	sed -i "s|data/data/com.termux/cache|data/data/com.zzvm/files/z|g"	$WBOXDIR/usr/bin/dpkg-split
	sed -i "s|data/data/com.termux/cache|data/data/com.zzvm/files/z|g"	$WBOXDIR/usr/bin/dpkg-trigger	
	sed -i "s|data/data/com.termux/cache|data/data/com.zzvm/files/z|g"	$WBOXDIR/usr/bin/apt
	sed -i "s|data/data/com.termux/cache|data/data/com.zzvm/files/z|g"	$WBOXDIR/usr/bin/apt-get
	sed -i "s|data/data/com.termux/cache|data/data/com.zzvm/files/z|g"	$WBOXDIR/usr/bin/apt-key
	sed -i "s|data/data/com.termux/cache|data/data/com.zzvm/files/z|g"	`realpath $WBOXDIR/usr/lib/libgnutls.so`
	sed -i "s|data/data/com.termux/cache|data/data/com.zzvm/files/z|g"	`realpath $WBOXDIR/usr/lib/libapt-pkg.so`
	sed -i "s|data/data/com.termux/cache|data/data/com.zzvm/files/z|g"	`realpath $WBOXDIR/usr/lib/libapt-private.so`
	sed -i "s|data/data/com.termux/cache|data/data/com.zzvm/files/z|g"	`realpath $WBOXDIR/usr/lib/apt/methods/copy`
	sed -i "s|data/data/com.termux/cache|data/data/com.zzvm/files/z|g"	`realpath $WBOXDIR/usr/lib/apt/methods/file`
	sed -i "s|data/data/com.termux/cache|data/data/com.zzvm/files/z|g"	`realpath $WBOXDIR/usr/lib/apt/methods/gpgv`
	sed -i "s|data/data/com.termux/cache|data/data/com.zzvm/files/z|g"	`realpath $WBOXDIR/usr/lib/apt/methods/http`
	sed -i "s|data/data/com.termux/cache|data/data/com.zzvm/files/z|g"	`realpath $WBOXDIR/usr/lib/apt/methods/rsh`
	sed -i "s|data/data/com.termux/cache|data/data/com.zzvm/files/z|g"	`realpath $WBOXDIR/usr/lib/apt/methods/store`

	sed -i "s|data/data/com.termux/files|data/data/com.zzvm/files/z|g"		`realpath $WBOXDIR/usr/var/lib/dpkg/info/termux-keyring.list`
	sed -i "s|data/data/com.termux/files|data/data/com.zzvm/files/z|g"		`realpath $WBOXDIR/usr/var/lib/dpkg/info/termux-keyring.md5sums`
	sed -i "s|data/data/com.termux/files|data/data/com.zzvm/files/z|g"		`realpath $WBOXDIR/usr/var/lib/dpkg/info/apt.list`
	sed -i "s|data/data/com.termux/files|data/data/com.zzvm/files/z|g"		`realpath $WBOXDIR/usr/var/lib/dpkg/info/apt.md5sums`
	sed -i "s|data/data/com.termux/files|data/data/com.zzvm/files/z|g"		`realpath $WBOXDIR/usr/var/lib/dpkg/info/apt.conffiles`
	# sed -i "s|data/data/com.termux/files|data/data/com.zzvm/files/z|g"		$WBOXDIR/usr/var/lib/dpkg/info/*


	echo "正在对 termux 做 eflPatch (bionic libc 系列的软件)"
	WBOX_RUN_PATH=${APP_INTERNAL_DIR}/z/usr/lib
	WBOX_INTERPRT=
	WBOX_FORCERPT=
	# wboxPatchElfFiles $WBOXDIR/usr
	wboxPatchElfFiles $WBOXDIR/usr/bin
	wboxPatchElfFiles $WBOXDIR/usr/lib
	# wboxPatchElfFiles $WBOXDIR/usr/var/lib
	# wboxPatchElfFiles $WBOXDIR/usr/lib/apt
	# wboxPatchElfFiles $WBOXDIR/usr/lib/bash
	# wboxPatchElfFiles $WBOXDIR/usr/lib/cmake
	# wboxPatchElfFiles $WBOXDIR/usr/lib/engines-1.1
	# wboxPatchElfFiles $WBOXDIR/usr/lib/gawk
	# wboxPatchElfFiles $WBOXDIR/usr/lib/pkgconfig
	# wboxPatchElfFiles $WBOXDIR/usr/lib/p7zip

	cd ${ZZSWMGR_MAIN_DIR}
	create_files2

	echo "patch 已完成"
}



function sw_download() {
	# tmpdns=`cd /exbin && droidexec ./vm_getHostByName.sh gitlab.com`
	# exit_if_fail $? "DNS解析失败"
	# echo "$tmpdns" >> /etc/hosts

	# termux rootfs
	swUrl=${APP_URL_DLSERVER}/termux-rootfs-arm64.tar.gz
	download_file_axel "${TMX_PATH}" "${swUrl}"
	exit_if_fail $? "下载失败，网址：${swUrl}"

}

function sw_install() {

	command -v patchelf >/dev/null 2>&1 || sudo apt-get install -y patchelf
	exit_if_fail $? "patchelf 安装失败"

	command -v readelf >/dev/null 2>&1 || sudo apt-get install -y binutils
	exit_if_fail $? "readelf 安装失败"

	command -v file >/dev/null 2>&1 || sudo apt-get install -y file
	exit_if_fail $? "file 安装失败"

	command -v unzip >/dev/null 2>&1 || sudo apt-get install -y unzip
	exit_if_fail $? "unzip 安装失败"
	
	echo "正在解压 termux-rootfs 到 ${WBOXDIR} . . ."
	mkdir -p ${WBOXDIR} 2>/dev/null
	tar -xzf ${TMX_PATH} --overwrite -C ${WBOXDIR}
	exit_if_fail $? "解压失败，软件包：${DEB_PATH}"

	elfPatch
}

function sw_create_desktop_file() {

	# 保留备用
	# echo "正在生成桌面文件"
	# tmpfile=${DIR_DESKTOP_FILES}/${SWNAME}.desktop
	# cat <<- EOF > ${tmpfile}
	# 	[Desktop Entry]
	# 	Name=${SWNAME}
	# 	GenericName=${SWNAME}
	# 	Exec=tmx
	# 	Terminal=true
	# 	Type=Application
	# 	Icon=/exbin/tools/zzswmgr/ezapp/tmx/tmx.png
	# EOF
	# cp2desktop ${tmpfile}


	cat <<- EOF > ${app_dir}/tmx-init
		#!${WB_PATH}/usr/bin/bash
		export CONSOLE_ENV=android
		export HOME=${WB_PATH}/home
		cd ~
		clear
		export app_home=${APP_INTERNAL_DIR}
		export tools_dir=${APP_INTERNAL_DIR}/tools
		export CURRENT_OS_DIR=${APP_INTERNAL_DIR}/vm/${CURRENT_OS_NAME}
		export TERMUX_PREFIX=${WB_PATH}
		export        PREFIX=${WB_PATH}/usr
		export LD_PRELOAD=${WB_PATH}/usr/lib/libtermux-exec.so
		export PATH=${WB_PATH}:${WB_PATH}/usr/bin:/exbin
		export TMPDIR=${WB_PATH}/usr/tmp
		export TERM=vt100
		export LANG=C.UTF-8
		. ${WB_PATH}/hostvars.rc
		busybox telnetd -p ${WB_PORT} -l ${WB_PATH}/usr/bin/bash

		# echo "欢迎使用termux"
		# # pkg update -y --allow-unauthenticated
		# exec ${WB_PATH}/usr/bin/bash

	EOF
	chmod a+x ${app_dir}/tmx-init

	cat <<- EOF > /usr/bin/${SWNAME}
		#!/bin/bash

		echo "export      DISPLAY=\${DISPLAY}"      > ${app_dir}/hostvars.rc
		echo "export PULSE_SERVER=\${PULSE_SERVER}" >>${app_dir}/hostvars.rc

		cd ${app_dir}

		ps ax|grep busybox|grep telnet|grep ${WB_PORT} >/dev/null 2>/dev/null
		if [ \$? -ne 0 ]; then
			droidexec ./tmx-init
			# sleep 0.5
		fi
		echo "termux官方网站：https://termux.dev/"
		echo "termux移植来的，仅用于运行wbox，非全功能termux!"
		echo "不支持 termux-api等与app极度相关的扩展功能"
		echo ""
		echo -e "您也可以通过telnet连接本机的\e[96m${WB_PORT}\e[0m端口来使用termux"
		# echo -e "\e[96m要安装 mobox, 请运行：./mobox-installer/setup.sh \e[0m"
		echo ""
		exec telnet 127.0.0.1 ${WB_PORT}

	EOF
	chmod a+x /usr/bin/${SWNAME}

	# gxmessage -title "提示" "安装已完成，双击桌面上 tmx 图标即可启动" -center  &

}

if [ "${action}" == "卸载" ]; then
	echo "暂不支持卸载"
	exit 1

	rm -rf ${WBOXDIR}
	rm -rf /usr/bin/${SWNAME}
	rm2desktop ${SWNAME}.desktop

else

	sw_download
	sw_install
	sw_create_desktop_file
fi

