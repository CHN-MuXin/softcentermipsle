#!/bin/sh

source /jffs/softcenter/scripts/base.sh
eval `dbus export unblockmusic_`
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'

ROUTE_IP=$(nvram get lan_ipaddr)
ipt_n="iptables -t nat"
serverCrt="/jffs/softcenter/bin/Music/server.crt"
serverKey="/jffs/softcenter/bin/Music/server.key"

create_autostart(){
	if [ ! -L "/jffs/softcenter/init.d/S99unblockmusic.sh" ];then
		ln -sf /jffs/softcenter/scripts/unblockmusic_config.sh /jffs/softcenter/init.d/S99unblockmusic.sh
	fi
}

remove_autostart(){
	rm -f /jffs/softcenter/init.d/*unblockmusic.sh
}

add_rule()
{
	echo_date 加载nat规则...
	echo_date Load nat rules...
	ipset -! -N music hash:ip
	wget -q -t 99 -T 10 "https://httpdns.n.netease.com/httpdns/v2/d?session_id=1609320571828_26796&domain=clientlog.music.163.com,interface.music.163.com,m7.music.126.net,m701.music.126.net,m8.music.126.net,m801.music.126.net,m9.music.126.net,music.163.com,p1.music.126.net,p2.music.126.net,p3.music.126.net,p4.music.126.net,p5.music.126.net,p6.music.126.net,vodkgeyttp8.vod.126.net,vodkgeyttp9.vod.126.net" | grep -Eo '[0-9]+?\.[0-9]+?\.[0-9]+?\.[0-9]+?' | sort | uniq | awk '{print "ipset -! add music "$1}' | sh
	rm -rf /tmp/163.txt
	$ipt_n -N cloud_music
	$ipt_n -A cloud_music -d 0.0.0.0/8 -j RETURN
	$ipt_n -A cloud_music -d 10.0.0.0/8 -j RETURN
	$ipt_n -A cloud_music -d 127.0.0.0/8 -j RETURN
	$ipt_n -A cloud_music -d 169.254.0.0/16 -j RETURN
	$ipt_n -A cloud_music -d 172.16.0.0/12 -j RETURN
	$ipt_n -A cloud_music -d 192.168.0.0/16 -j RETURN
	$ipt_n -A cloud_music -d 224.0.0.0/4 -j RETURN
	$ipt_n -A cloud_music -d 240.0.0.0/4 -j RETURN
	$ipt_n -A cloud_music -p tcp --dport 80 -j REDIRECT --to-ports 5200
	$ipt_n -A cloud_music -p tcp --dport 443 -j REDIRECT --to-ports 5300
	$ipt_n -I PREROUTING -p tcp -m set --match-set music dst -j cloud_music
}

del_rule(){
	echo_date 移除nat规则...
	echo_date Unload nat rules...
	$ipt_n -D PREROUTING -p tcp -m set --match-set music dst -j cloud_music 2>/dev/null
	$ipt_n -F cloud_music  2>/dev/null
	$ipt_n -X cloud_music  2>/dev/null
	ipset flush music 2>/dev/null
	rm -f /tmp/etc/dnsmasq.user/dnsmasq-music.conf
	service restart_dnsmasq
}

set_firewall(){

	rm -f /tmp/etc/dnsmasq.user/dnsmasq-music.conf
	echo "ipset=/.music.163.com/music" >> /tmp/etc/dnsmasq.user/dnsmasq-music.conf
	echo "ipset=/interface.music.163.com/music" >> /tmp/etc/dnsmasq.user/dnsmasq-music.conf
	echo "ipset=/interface3.music.163.com/music" >> /tmp/etc/dnsmasq.user/dnsmasq-music.conf
	echo "ipset=/apm.music.163.com/music" >> /tmp/etc/dnsmasq.user/dnsmasq-music.conf
	echo "ipset=/apm3.music.163.com/music" >> /tmp/etc/dnsmasq.user/dnsmasq-music.conf
	echo "ipset=/clientlog.music.163.com/music" >> /tmp/etc/dnsmasq.user/dnsmasq-music.conf
	echo "ipset=/clientlog3.music.163.com/music" >> /tmp/etc/dnsmasq.user/dnsmasq-music.conf
	echo "ipset=/.music.126.net/music" >> /tmp/etc/dnsmasq.user/dnsmasq-music.conf
	echo "ipset=/.acstatic-dun.126.net/music" >> /tmp/etc/dnsmasq.user/dnsmasq-music.conf
	echo "ipset=/.vod.126.net/music" >> /tmp/etc/dnsmasq.user/dnsmasq-music.conf
	service restart_dnsmasq
	add_rule
}

start_unblockmusic(){
	stop_unblockmusic
	[ $unblockmusic_enable -eq 0 ] && exit 0
	
	echo_date 开启unblockmusic
	echo_date Enable unblockmusic
	if [ "$unblockmusic_musicapptype" = "default" ]; then
		nohup /jffs/softcenter/bin/UnblockNeteaseMusic -p 5200 -sp 5300 -m 0 -c "${serverCrt}" -k "${serverKey}" -e -l /tmp/unblockmusic.log -sl 2 2>&1 &
	else
		nohup /jffs/softcenter/bin/UnblockNeteaseMusic -p 5200 -sp 5300 -o "$unblockmusic_musicapptype" -m 0 -c "${serverCrt}" -k "${serverKey}" -e -l /tmp/unblockmusic.log -sl 2 2>&1 &
	fi
	mkdir -p /var/wwwext
	cp -f /jffs/softcenter/bin/Music/ca.crt /www/ext
	set_firewall
	create_autostart
}

stop_unblockmusic(){
	echo_date 关闭unblockmusic
	echo_date Disable unblockmusic
	kill -9 $(busybox ps -w | grep UnblockNeteaseMusic | grep -v grep | awk '{print $1}') >/dev/null 2>&1
	rm -f /tmp/unblockmusic.log

	del_rule
	remove_autostart
}

case $ACTION in
start)
	if [ "$unblockmusic_enable" == "1" ]; then
		start_unblockmusic
	fi
	;;
stop)
	stop_unblockmusic
	;;
*)
	if [ "$unblockmusic_enable" == "1" ]; then
		start_unblockmusic
	else
		stop_unblockmusic
	fi
	;;
esac

