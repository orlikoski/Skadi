#!/bin/bash
tempdir=$(mktemp -d)
buildccf_tgz="$tempdir/buildccf.tgz"
pubkey="LS0tLS1CRUdJTiBQVUJMSUMgS0VZLS0tLS0KTUlJQ0lqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FnOEFNSUlDQ2dLQ0FnRUF5c2E1MHRJUkNsZm56VVNYeE9zeQpkRTcxUlFXendsajJ1cHFLaHEyVlJtem9HRVdQSWllZ1NDUGtGUEJKUXZlVnFLN3JqdGJxaUF4aElwZ3lWS052CkF5M3pMMGNPcmFEUXYySUs1R0t0SWhqVkltZWw0cXQzc1QrWDBvWUxOTWhtMHRrSUxqWW52aUZjU1lEY1hIbzAKa0Z1WUhTOXdPRjY5d3ZiZWpXTldpOUZjMmZvVWxPL1dFK0g0QitRTUtxRitjZlVXUUFKM3ZYMVNuTmV3bDMwRgpFQkdWV3oxWkszNXgyaGgxamlRdVNIdzIrbXNZc2wxcC85dlkyOFVMZmg0bEJwRFVPcHA0aU1LSUpDRS84SmpKCndWLzFNTjZYWjBNUFI3U1Q2VVk2TmhHVG1oUFVkV0pjUW1wOVg2cjV6a1MzZ2tGNzNnN01oUFo1NTMyTCt1Q3AKUG4raUtUbGorNHpGM2o5c1Z1Y0p5TnZMMEx2QnZjZDhXbUNPMFhIS0RRY1MxQTF2M3p5MVlZRVdzb0xVSWZMaApVajlFcFEyMzh2bWlscW1WdXZjRnRxaFJsbFBUV3dEcEFtOW5aTlFnaUVKNjBzbHVUUVNEVzNhYjA0Y2ZLZldJCmt3aDc4bUUxNnIzem0yNnRaMUN6ZTBPVzNKdFNPbVpDc3dicis4RDU0ZVZmaUZya01LdnZ0K1ErVWU4UjZyeVQKUWJIZThSWnZJeTZvMXdPNDEwZUJnQ3pVV1BkR3ZiQzRxVHJFdG5MdXBzOXZYV2xFa0dzNUUvbjdWdTZWcldJYwpVdlQwLzErS1VXNFlWSEFtME1BOFRGS21EcnQ5dHBqaXVDRUZ2OURXVFV2NXVVYk8yTFd2WXlCK2F0cVpRaWYwCmVhQTV5ZzZyOUNnbmNXQS95TEp3TFZjQ0F3RUFBUT09Ci0tLS0tRU5EIFBVQkxJQyBLRVktLS0tLQo="
buildccf_pem="$tempdir/buildccf.pem"
buildccf_sig="$tempdir/buildccf.sig"
buildccf_sh="$tempdir/buildccf.sh"
update_sh="$tempdir/update.sh"

wget -O $buildccf_tgz https://raw.githubusercontent.com/rough007/CCF-VM/master/scripts/buildccf.tgz
wget -O $buildccf_sig https://raw.githubusercontent.com/rough007/CCF-VM/master/scripts/buildccf.sig
echo $pubkey |base64 -d > $buildccf_pem

verify=openssl dgst -sha256 -verify $buildccf_pem -signature $buildccf_sig $buildccf_tgz
if [ $verify -ne "Verified OK" ]
then
  echo "Installer failed to verify. Exiting"
  exit 1
fi

echo "Installer verified, installation starting"
echo ""
tar xzf $buildccf_tgz -C $tempdir

# Installs and Configures CDQR and CyLR
echo "Installing CDQR and CyLR"
$update

echo ""
echo "Verifying version of CDQR"
/usr/local/bin/cdqr.py --version


$buildccf_sh
rm -rf $tempdir
