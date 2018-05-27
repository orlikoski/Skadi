#!/bin/bash
set -e
plaso_files=( "cfreds.plaso" "macos.plaso" "ubuntu.plaso" "victimpc.plaso" "winxp.plaso" )
zip_files=( "lr.zip" )


for i in "${plaso_files[@]}"
do
  set -x
  cdqr.py --plaso_db $i Results_ts_$i --es_ts test_$i
  cdqr.py --plaso_db $i Results_kb_$i --es_kb test_$i
  set +x
done

for i in "${zip_files[@]}"
do
  set -x
  cdqr.py -z -p datt --max_cpu $i Results_ts_datt_$i
  cdqr.py -z -p lin $i Results_ts_lin_$i
  cdqr.py -z -p mac $i Results_ts_mac_$i
  cdqr.py -z -p win --max_cpu $i Results_ts_win_$i
  cdqr.py -z --max_cpu $i Results_ts_default_$i
  set +x
done

echo "All tests complete"
