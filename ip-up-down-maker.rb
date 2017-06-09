`wget -c http://ftp.apnic.net/stats/apnic/delegated-apnic-latest`

`cat delegated-apnic-latest | awk -F '|' '/CN/&&/ipv4/ {print $4 "/" 32-log($5)/log(2)}'|cat >ip.txt`

ips = File.readlines("./ip.txt")
cmds = ips.map{|ip| "route add #{ip.strip} \"${OLDGW}\"" }.join("\n")
up_texts = %(
#!/bin/sh
export PATH="/bin:/sbin:/usr/sbin:/usr/bin"

OLDGW=`netstat -nr | grep '^default' | grep -v 'ppp' | sed 's/default *\\([0-9\\.]*\\) .*/\\1/' | tr -d '[:space:]'`

if [ ! -e /tmp/pptp_oldgw ]; then
    echo "${OLDGW}" > /tmp/pptp_oldgw
fi

dscacheutil -flushcache

#{cmds}

)

File.open("ip-up", 'w'){|f| f.write(up_texts)}
File.chmod(0755, "ip-up")

cmds = ips.map{|ip| "route delete #{ip.strip} \"${OLDGW}\"" }.join("\n")
down_texts = %(
#!/bin/sh
export PATH="/bin:/sbin:/usr/sbin:/usr/bin"

OLDGW=`netstat -nr | grep '^default' | grep -v 'ppp' | sed 's/default *\\([0-9\\.]*\\) .*/\\1/' | tr -d '[:space:]'`

if [ ! -e /tmp/pptp_oldgw ]; then
    echo "${OLDGW}" > /tmp/pptp_oldgw
fi

dscacheutil -flushcache

#{cmds}

)

File.open("ip-down", 'w'){|f| f.write(down_texts)}
File.chmod(0755, "ip-down")