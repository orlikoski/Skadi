#!/bin/bash

echo "System Health Checks"
# system health checks
declare -a services=('elasticsearch' 'postgresql' 'celery' 'neo4j' 'redis' 'kibana' 'timesketch')
# Ensure all Services are started
for item in "${services[@]}"
do
    echo "  Bringing up $item"
    sudo systemctl restart $item
    sleep 1
done

echo ""

for item in "${services[@]}"
do
    echo "  $item service is: $(systemctl is-active $item)"
done

unzip -o /opt/CyLR/CyLR_linux-x64.zip -d /tmp/ > /dev/null 2>&1
cylr_version=$(/tmp/CyLR --version |grep Version)
rm /tmp/CyLR > /dev/null 2>&1

echo ""
echo ""
echo "Installed Software Version Checks (Where it is supported)"
/usr/bin/log2timeline.py --version 2>&1 >/dev/null |awk '{ printf "Plaso Version %s\n", $5 }'
/usr/local/bin/cdqr.py --version |awk '{split($0,a,":");printf "%s%s\n", a[1], a[2]}'
echo $cylr_version
docker --version |awk '{split($3,a,",");printf "%s Version %s\n", $1, a[1]}'
echo "ELK Version $(curl --silent -XGET 'localhost:9200' |awk '/number/{print substr($3, 2, length($3)-3)}')"
pip show timesketch |grep Version:|awk '{split($0,a,":");printf "TimeSketch %s%s\n", a[1], a[2]}'
redis-server --version|awk '{ split($3,a, "=");printf "%s Version %s\n", $1, a[2] }'
neo4j --version |awk '{printf "Neo4j Version %s\n", $2}'
echo "Celery Version $(celery --version |awk '{print$1}')"
echo "Cerebro Version $cerebro_version"
echo ""
echo ""
