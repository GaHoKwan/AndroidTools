#!/bin/bash
echo -e "\e[40;32;1m"
clear
username=`whoami`
thisDir=`pwd`

addRulesFunc(){
	read mIdVendor mIdProduct
	echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\""$mIdVendor"\", ATTR{idProduct}==\""$mIdProduct"\", MODE=\"0600\", OWNER=\"$username\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
}

addhosts(){
echo -e "安装或更新hosts请按1，还原hosts请按2"
echo -ne "\n选择:"
read hostchoose
case $hostchoose in
	1)
		curl https://raw.githubusercontent.com/txthinking/google-hosts/master/hosts > $thisDir/hosts
		sudo mv  /etc/hosts /etc/hosts.bak
		sudo cp -f $thisDir/hosts /etc/hosts
		rm -rf $thisDir/hosts
		echo -e "hosts安装完成！"
	;;
	2)
		if [ `grep -rl youtube /etc/hosts` == "/etc/hosts" ]; then
			sudo mv /etc/hosts.bak /etc/hosts
		else
			echo -e "host已被还原过或者你没有安装过hosts"
		fi
	;;
esac
read -p "按回车键继续..."
}

addRules(){
	clear
	lsusb
	echo -e "\nOK 上面列出了所有USB列表,大致内容如下:\n"
	echo -e "\033[40;37;7mBus 00x Device 00x: ID \033[40;34;7mxxxx\033[40;32;1m:\033[40;33;7mxxxx\033[40;30;0m \033[40;31;7mxxxxxxxxxxxxx\033[40;31;0m"
	echo -e "\e[40;32;1m"
	echo -e "如上，蓝色字符串为idVendor,黄色字符串为idProduct\n红色的是一些厂商信息(也可能没有)"
	echo -e "找第三个里面有没有你的手机厂商的名字,如:HUAWEI,ZTE 什么的"
	echo -e "当然没找到没关系,第三个什么都没有的就是了\n把idVendor和idProduct 打在下面,空格隔开,如:19d2 ffd0"
	echo -ne "\n输入:"
	addRulesFunc
	echo -e "添加成功"
}


installadb(){
	echo -e "\n配置adb环境变量..."
	sudo apt-get update
	sudo apt-get install android-tools-adb android-tools-fastboot
	sed -i "s/apar/$username/g" 51-android.rules >> /dev/null
	sudo cp 51-android.rules /etc/udev/rules.d/
	sudo chmod a+rx /etc/udev/rules.d/51-android.rules
	echo "export PATH=$PATH:~/bin/" | sudo tee -a /etc/profile
	source /etc/profile
	sudo adb kill-server
	sudo adb devices
	echo "\n配置环境完成"
}

changecoronlanguage(){
echo -e "请输入coron项目所在目录(可以把目录拖进来,)"
read coronDir
echo -e "输入1即可把coron项目环境改成中文"
echo -e "输入2即可把coron项目环境改回英文"
echo -ne "\n输入(任意字符退出):"
read languagechoose
case $languagechoose in
	1)
		cd $coronDir
		patch -p1<$thisDir/coron.patch
		cd $thisDir
		read -p "按回车键继续..."
	;;
	2)
		cd $coronDir
		patch -R -p1<$thisDir/coron.patch
		cd $thisDir
		read -p "按回车键继续..."
	;;
	*)
		main
	;;
esac
}

zipcenop(){
	echo -e "这是刷机包或者apk&jar伪加密工具"
	echo -e "请把需要加密的刷机包或者apk&jar拖进来"
	read cenopfile
	echo -ne "\n选择:"
	echo -e "输入1加密，输入2解密，输入任意字符退出"
	echo -ne "\n选择:"
	read cenopmode
case $cenopmode in
	1)
		java -jar $thisDir/ZipCenOp.jar e ${cenopfile//\'//}
		read -p "按回车键继续..."
	;;
	2)
		java -jar $thisDir/ZipCenOp.jar r ${cenopfile//\'//}
		read -p "按回车键继续..."
	;;
	*)
		main
	;;
esac
}

installrepo(){
	mkdir -p ~/bin
	curl https://raw.githubusercontent.com/baidurom/repo/stable/repo > ~/bin/repo
 	chmod a+x ~/bin/repo
}

repoSource(){
	if [ ! -f ~/bin/repo ]; then
	installrepo
	fi
	clear
	echo -e "------ 同步源码 ------"
	echo -e "请输入存放源码的地址(可直接把文件夹拖进来):"
	echo -ne "\n输入:"
	read sDir
	echo -e "请输入要同步源码的版本号:"
	echo -e "高通(4.0 4.1 4.2 4.3 4.4),联发科(mtk-4.0 mtk-4.2)"
	echo -ne "\n输入:"
	read version
	cd $sDir
	repo init -u https://github.com/baidurom/manifest.git -b "coron-"$($version)
	repo sync
	cd $thisDir
	read -p "按回车键继续..."
}

fastrepoSource(){
	if [ ! -f ~/bin/repo ]; then
	installrepo
	fi
	clear
	echo -e "------ 跳过谷歌验证,快速同步源码 ------"
	echo -e "请输入存放源码的地址(可直接把文件夹拖进来):"
	echo -ne "\n输入:"
	read sDir
	echo -e "请输入要同步源码的版本号:"
	echo -e "高通(4.0 4.1 4.2 4.3 4.4),联发科(mtk-4.0 mtk-4.2)"
	echo -ne "\n输入:"
	read version
	cd $sDir
	repo init --repo-url git://github.com/baidurom/repo.git -u https://github.com/baidurom/manifest.git -b "coron-"$($version) --no-repo-verify
	repo sync -c --no-clone-bundle --no-tags -j4
	cd $thisDir
	read -p "按回车键继续..."
}

installsdk(){
echo
echo "下载和配置 Android SDK!!"
echo "请确保 unzip 已经安装"
echo
sudo apt-get install unzip -y
if [ `getconf LONG_BIT` = "64" ];then
	echo
	echo "正在下载 Linux 64位 系统的Android SDK"
	wget http://dl.google.com/android/adt/adt-bundle-linux-x86_64-20140702.zip
	echo "下载完成!!"
	echo "展开文件"
	mkdir ~/adt-bundle
	mv adt-bundle-linux-x86_64-20140702.zip ~/adt-bundle/adt_x64.zip
	cd ~/adt-bundle
	unzip adt_x64.zip
	mv -f adt-bundle-linux-x86_64-20140702/* .
	echo "正在配置"
	echo -e '\n# Android tools\nexport PATH=${PATH}:~/adt-bundle/sdk/tools\nexport PATH=${PATH}:~/adt-bundle/sdk/platform-tools\nexport PATH=${PATH}:~/bin' >> ~/.bashrc
	echo -e '\nPATH="$HOME/adt-bundle/sdk/tools:$HOME/adt-bundle/sdk/platform-tools:$PATH"' >> ~/.profile
	echo "完成!!"
else
	echo
	echo "正在下载 Linux 32位 系统的Android SDK"
	wget http://dl.google.com/android/adt/adt-bundle-linux-x86-20140702.zip
	echo "下载完成!!"
	echo "展开文件"
	mkdir ~/adt-bundle
	mv adt-bundle-linux-x86-20140702.zip ~/adt-bundle/adt_x86.zip
	cd ~/adt-bundle
	unzip adt_x86.zip
	mv -f adt-bundle-linux-x86_64-20140702/* .
	echo "正在配置"
	echo -e '\n# Android tools\nexport PATH=${PATH}:~/adt-bundle/sdk/tools\nexport PATH=${PATH}:~/adt-bundle/sdk/platform-tools\nexport PATH=${PATH}:~/bin' >> ~/.bashrc
	echo -e '\nPATH="$HOME/adt-bundle/sdk/tools:$HOME/adt-bundle/sdk/platform-tools:$PATH"' >> ~/.profile
	echo "完成!!"
fi
rm -Rf ~/adt-bundle/adt-bundle-linux-x86_64-20140702
rm -Rf ~/adt-bundle/adt-bundle-linux-x86-20140702
rm -f ~/adt-bundle/adt_x64.zip
rm -f ~/adt-bundle/adt_x86.zip
read -p "按回车键继续..."
}

installia32(){
		echo -e "\n开始配置32位运行环境..."
		echo -e "请选择使用的系统版本:"
		echo -e "\t1. ubuntu 12.04 及以下"
		echo -e "\t2. 其他(包括deepin等基于ubuntu 的系统)"
		echo -en "选择:"
		read kind
		if [ "$kind" == "1" ]; then
			sudo apt-get install ia32-libs
		elif [ "$kind" == "2" ]; then
#start
		cd /etc/apt/sources.list.d #进入apt源列表
		echo "deb http://old-releases.ubuntu.com/ubuntu/ raring main restricted universe multiverse" | sudo tee ia32-libs-raring.list
#添加ubuntu 13.04的源，因为13.10的后续版本废弃了ia32-libs
		sudo apt-get update #更新一下源
		sudo apt-get install ia32-libs #安装ia32-libs
		sudo rm ia32-libs-raring.list #恢复源
		sudo apt-get update #再次更新下源
#end
		else
			initSystemConfigure
		fi
}

installJavaSE(){
	sudo apt-get update
	echo -e "\n删除自带的openjdk..."
	sleep 1
	sudo apt-get purge openjdk-* icedtea-* icedtea6-*
	echo -e "\n开始安装oracle java developement kit..."
	sleep 1
	sudo add-apt-repository ppa:webupd8team/java
	sudo apt-get update && sudo apt-get install oracle-java6-installer oracle-java7-installer
	read -p "按回车键继续..."
	echo "alias java-switch='sudo update-alternatives --config java'" | sudo tee -a /etc/profile
	source /etc/profile
	echo -e "你可以使用java-switch命令来切换java版本"
}

DevEnvSetup(){
	echo -e "\n开始安装ROM编译环境..."
	sudo apt-get install bison ccache libc6 build-essential curl flex g++-multilib g++ gcc-multilib git-core gnupg gperf x11proto-core-dev tofrodos libx11-dev:i386 libgl1-mesa-dev libreadline6-dev:i386 libgl1-mesa-glx:i386 lib32ncurses5-dev libncurses5-dev:i386 lib32readLine-gplv2-dev lib32z1-dev libesd0-dev libncurses5-dev libsdl1.2-dev libwxgtk2.8-dev python-markdown libxml2 libxml2-utils lzop squashfs-tools xsltproc pngcrush schedtool zip zlib1g-dev:i386 zlib1g-dev	
	sudo ln -s /usr/lib/i386-linux-gnu/mesa/libGL.so.1 /usr/lib/i386-linux-gnu/libGL.so 
}

initSystemConfigure(){
clear
echo -e "请输入你想安装的环境"
echo -e "\t1.ia32运行库"
echo -e "\t2.JavaSE(Oracle Java JDK)"
echo -e "\t3.aosp&cm&recovery编译环境"
echo -e "\t4.adb运行环境"
echo -e "\t5.AndroidSDK运行环境"
echo -e "\t6.coron项目中文环境"
echo -e "\t7.hosts环境"
echo -e "\t8.安卓开发必备环境(上面12345）"
echo -ne "\n选择:"
read configurechoose
case $configurechoose in
	1)
		installia32
		read -p "按回车键继续..."
	;;
	2)
		installJavaSE
		read -p "按回车键继续..."
	;;
	3)
		DevEnvSetup
		read -p "按回车键继续..."
	;;
	4)
		installadb
		read -p "按回车键继续..."
	;;
	5)
		installsdk
	;;
	6)
		changecoronlanguage
	;;
	7)
		addhosts
	;;
	8)
		echo -e "\n开始安卓开发环境..."
		echo -e "请选择使用的系统版本:"
		echo -e "\t1. ubuntu 12.04 及以下(此项不安装编译环境）"
		echo -e "\t2. 其他(包括deepin等基于ubuntu的系统)"
		echo -en "选择:"
		read kind
		if [ "$kind" == "1" ]; then
			installrepo
			installia32
			installJavaSE
			installadb
			installsdk
		elif [ "$kind" == "2" ]; then
			installrepo
			installia32
			installJavaSE
			installadb
			installsdk
			DevEnvSetup
		else
			initSystemConfigure
		fi
		read -p "按回车键继续..."
	;;
esac
}

logcat(){
echo -e "这是抓取log的工具，过程中按ctrl+c退出"
echo -e "输入1将把所有的log输出到$thisDir/log"
echo -e "输入2把你想过滤的内容输出到终端并保存到文件"
echo -ne "\n选择:"
read logcatmode
case $logcatmode in
	1)
		adb logcat -b main -b system -b radio > $thisDir/log
	;;
	2)
		echo -e "输入你想过滤的内容"
		read ignoretext
		adb logcat -b main -b system -b radio |grep $ignoretext|tee $thisDir/log
	;;
	*)
		echo -e "请输入正确的命令"
		sleep 2
	;;
esac
}

clean(){
	echo -e "正在清理残留文件"
	rm -rf log
	rm -rf screenshot.png
	read -p "按回车键继续..."
}
 
main(){
clear 
echo -e "Android开发环境一键搭载脚本及开发工具"
echo "--作者：Modificator & 嘉豪仔_Kwan"
echo -e "			输入命令号码 :\n"
echo -e "\t\t1. 使用root权限启动adb"
echo -e "\t\t2. 设置环境变量"
echo -e "\t\t3. 安装安卓厨房（Android-Kitchen)"
echo -e "\t\t4. 依然无法识别手机？没关系，选这个"
echo -e "\t\t5. 同步源码"
echo -e "\t\t6. 快速同步源码(跳过谷歌认证)"
echo -e "\t\t7. 伪加密工具"
echo -e "\t\t8. 抓取log工具"
echo -e "\t\t9. 手机截图"
echo -e "\t\t0. 离开脚本"
echo -ne "\n选择:"
read inp
case $inp in
	1)
		sudo adb kill-server
		sudo adb devices
		read -p "按回车键继续..."
		main
	;;
	2)
		initSystemConfigure
		main
	;;
	3)
		echo "安装安卓厨房"
		sudo apt-get install git -y
		cd ~/
		git clone https://github.com/kuairom/Android_Kitchen_cn
		echo "安卓厨房已下载到主文件夹的Android_Kitchen_cn目录里！"
		read -p "按回车键继续..."
		main
	;;
	4)
		addRules
		main
	;;
	5)
		repoSource
		main
	;;
	6)
		fastrepoSource
		main
	;;
	7)
		zipcenop
		main
	;;
	8)
		logcat
		main
	;;
	9)
		adb shell /system/bin/screencap -p /data/local/tmp/screenshot.png
		cd $thisDir
		adb pull /data/local/tmp/screenshot.png
		if [ "$?" == "0" ]; then
		echo -e "截图文件已经输出到$thisDir"
		fi
		read -p "按回车键继续..."
		main
	;;
	0)
		cd $thisDir
		echo -e "正在清理环境文件"
		rm -rf 51-android.rules coron.patch ZipCenOp.jar
		echo -e "输入c清理残留文件否则直接退出"
		echo -ne "\n输入c清理或者按回车退出:"
		read cleanchoose
		if [ "$cleanchoose" == "c" ]; then
			clean
		fi
		echo -e "\e[0m"
	;;
	*)
	main
	;;
esac
}
echo -e "正在检测更新，请稍候......"
	git pull
	if [ ! -f 'ZipCenOp.jar' ]; then
		echo -e "正在解压工具，请稍候......"
		tar -xvf tools.tar
	else
		echo -e "工具已存在，跳过解压......"
	fi
sleep 1
echo -e "说明：本脚本仅适用于Ubuntu及各大Ubuntu发行版使用，并且建议在14.04Lts版本下使用"
read -p "按回车键继续..."
main
