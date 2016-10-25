## NAME
CyLR CDQR Forensics Virtual Machine (CCF-VM) by Alan Orlikoski

## Purpose
The CCF-VM was designed to provide an all-in-one solution to parsing collected data, making it easily searchable with built-in common searches, enable searching of single and multiple hosts simultaneously (stacking).  It was very important that this was done with open source solutions.

## Download locations
*  CCF-VM archive: https://drive.google.com/open?id=0B5z7g7P2BWJAZ2RPa291Mzgwems
    *  MD5: fe7f32392cc1d242d64e2ee053f8a48d
*  CCF-VM User Guide: https://drive.google.com/open?id=0B5z7g7P2BWJAWTM2d0NQZjV6MHc
    *  MD5: 1e9c7cfe535cc2ba5fe9ffe3b8442575

## Open source solutions installed
*  Ubuntu 16.04: https://www.ubuntu.com/
*  Plaso: https://github.com/log2timeline/plaso
*  Efetch Elasticsearch output module: https://github.com/maurermj08/efetch
*  Elasticsearch: https://www.elastic.co/
*  Elasticsearch-kopf: https://github.com/lmenezes/elasticsearch-kopf
*  Kibana: https://www.elastic.co/products/kibana
*  Cold Disk Quick Response (CDQR): https://github.com/rough007/CDQR
*  CyLR: https://github.com/rough007/CyLR

## Credits
Thank you for the wonderful writeup, link is here (http://diftdisk.blogspot.com/2016/06/viewing-log2timeline-output-with-kibana.html), by Michael Maurer that gave me the knowledge to put many of the pieces together. 

## CCF-VM Useful information
*  IP Address:
    * Set to DHCP
*  Credentials:
    *  Username: cdqr
    *  Password: Changemen0w!
*  Access Kibana instance: 
    *  http://\<CCF-VM IP address or localhost\>:5601
*  Access Elasticsearch-kopf management instance: 
    *  http://\<CCF-VM IP address or localhost\>:9200/_plugin/kopf/#!/cluster

## Analyzing Data in Three Easy Steps
1.	Collect information from host
2.	Process / parse collected data
3.	Start reviewing data

## Collect information from host
The CyLR tool can assist with collecting data from Windows hosts but any tool can be used to collect the forensic image or collect the artifacts.  SFTP can be used to transfer the files securely to the CCF-VM.


## CyLR Collection Example
To execute CyLR on the host to SFTP the data directly to the CCF-VM use the following command:  
```
CyLR.exe -u cdqr -p Changemen0w! -s <CCF-VM IP address> -m
```

Sample output
```
Collecting File: C:\Windows\System32\config\BBI
Collecting File: C:\Windows\System32\config\BCD-Template
Collecting File: C:\Windows\System32\config\COMPONENTS
Collecting File: C:\Windows\System32\config\DEFAULT
Collecting File: C:\Windows\System32\config\DRIVERS
Collecting File: C:\Windows\System32\config\ELAM
Collecting File: C:\Windows\System32\config\SAM
Collecting File: C:\Windows\System32\config\SECURITY
Collecting File: C:\Windows\System32\config\SOFTWARE
Collecting File: C:\Windows\System32\config\SYSTEM
Collecting File: C:\Windows\System32\config\userdiff
Collecting File: C:\Windows\System32\config\VSMIDK
…
Collecting File: C:\Windows\System32\winevt\logs\OAlerts.evtx
Collecting File: C:\Windows\System32\winevt\logs\PreEmptive.evtx
Collecting File: C:\Windows\System32\winevt\logs\Security.evtx
Collecting File: C:\Windows\System32\winevt\logs\Setup.evtx
Collecting File: C:\Windows\System32\winevt\logs\System.evtx
Collecting File: C:\Windows\System32\winevt\logs\Windows Azure.evtx
Collecting File: C:\Windows\System32\winevt\logs\Windows PowerShell.evtx
Collecting File: C:\Windows\System32\drivers\etc\hosts
Collecting File: C:\$MFT
Extraction complete. 0:00:11.8929015 elapsed
```

NOTE:
*  File is uploaded to the user, “cdqr”, home directory of the CCF-VM (/home/cdqr) 
 

## Process / parse collected data
The CCF-FM has a customized version of CDQR (Linux 2.02 with Elasticsearch).  This write up makes the assumption that the source is either a .zip file with artifacts, a directory with artifacts in it, or a directory with forensic system image files in it (example collect.E01).   The CCF-VM uses the Cold Disk Quick Response (CDQR) tool to process individual artifacts or entire system images.

The best practice is to put all of the artifacts into one folder (or zip file).
 

## Examples of using CDQR to process the data and output to into Elasticsearch
If the data is from a windows host, in a .zip file, “example_hostname.zip”, then use the following command
```
cdqr.py example_hostname.zip -p win --max_cpu -z --elk example_index
```
If the data is from a windows host, in a directory, “example_dirname”, then use the following command
```
cdqr.py example_dirname -p win --max_cpu --elk example_index
```
If the data is from a mac host, is a forensic image file(s) then use the following command
```
cdqr.py example_dirname/example_hostname.E01 -p mac --max_cpu --elk example_index
```

## Successful example output from CDQR
```
cdqr@ForensicVM:~$ cdqr.py  example_hostname.zip -p win --max_cpu -z --elk test
CDQR Version: Linux 2.02 with Elasticsearch
Plaso Version: 1.4
Using parser: win
Number of cpu cores to use: 8
Attempting to extract .zip file source file:  example_hostname.zip
All files extracted to folder:  example_hostname
Source data:  example_hostname
Destination Folder: Results
Database File: Results/ example_hostname.db
SuperTimeline CSV File: Results/ example_hostname.SuperTimeline.csv


Results/ example_hostname.log
Processing started at: 2016-10-22 16:05:43.122780
Parsing image
"log2timeline.py" "-p" "--partition" "all" "--vss_stores" "all" "--parsers" "appcompatcache,bagmru,binary_cookies,ccleaner,chrome_cache,chrome_cookies,chrome_extension_activity,chrome_history,chrome_preferences,explorer_mountpoints2,explorer_programscache,filestat,firefox_cache,firefox_cache2,firefox_cookies,firefox_downloads,firefox_history,google_drive,java_idx,mcafee_protection,mft,mrulist_shell_item_list,mrulist_string,mrulistex_shell_item_list,mrulistex_string,mrulistex_string_and_shell_item,mrulistex_string_and_shell_item_list,msie_zone,msiecf,mstsc_rdp,mstsc_rdp_mru,opera_global,opera_typed_history,prefetch,recycle_bin,recycle_bin_info2,rplog,safari_history,symantec_scanlog,userassist,usnjrnl,windows_boot_execute,windows_boot_verify,windows_run,windows_sam_users,windows_services,windows_shutdown,windows_task_cache,windows_timezone,windows_typed_urls,windows_usb_devices,windows_usbstor_devices,windows_version,winevt,winevtx,winfirewall,winjob,winrar_mru,winreg,winreg_default" "--hashers" "md5" "--workers" "8" "Results/ example_hostname.db" " example_hostname"
Parsing ended at: 2016-10-22 16:08:27.212356
Parsing duration was: 0:02:44.089576

Process to export to ELK started
Exporting results to the ELK server
"psort.py" "-o" "elastic" "Results/ example_hostname.db" "--case_name" "cdqr-test"
All entries have been inserted into database with case: cdqr-test

Process to export to ELK completed
ELK export process duration was: 0:02:37.332287

Removing uncompressed files in directory:  example_hostname

Total  duration was: 0:05:21.421863 
```

##  MORE SECTIONS IN THE USER GUIDE
The following sections are in the User Guide and have more detailed information there

## Elasticsearch-KOPF Cluster Management
Elasticsearch-KOPF cluster management interface: http://<CCF-VM IP Address or localhost>:9200/_plugin/kopf/#!/cluster
 
## Kibana Interface
Kibana interface: http://<CCF-VM IP address or localhost>:5601

## Using Kibana Pre-built Items
There are multiple ways to interface with the data and this document will show the following pre-built items included: Searches, Visualizations and Dashboards.  These were made to provide a way to easily start looking at data and maximize the data provided by CDQR and Plaso.  

They were made to be hierarchical so that Searches are used to make Visualizations which are then used to make Dashboards.  This means that changes to the saved searches will be automatically updated in the Visualizations and Dashboards that use them.

## Searches
16 pre-built searches in the CCF-VM.  Table below contains the list of the built in Kibana Searches in CCF-VM.

| Name               | Search String                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
|--------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Anti-Virus         | parser:mcafee_protection OR parser:symantec_scanlog OR parser:ccleaner                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| Appcompatcache     | parser:appcompatcache                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| File System        | parser:filestat OR parser:recycle_bin                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| Firewall           | parser:winfirewall OR parser:mac_appfirewall_log                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| Internet History   | parser:binary_cookies OR parser:chrome_cache OR parser:chrome_preferences OR parser:firefox_cache OR parser:firefox_cache2 OR parser:java_idx OR parser:msiecf OR parser:opera_global OR parser:opera_typed_history OR parser:safari_history OR parser:chrome_cookies OR parser:chrome_extension_activity OR parser:chrome_history OR parser:firefox_cookies OR parser:firefox_downloads OR parser:firefox_history OR parser:google_drive OR parser:windows_typed_urls                                        |
| Linux              | parser:bsm_log OR parser:popularity_contest OR parser:selinux OR parser:utmp OR parser:utmpx                                                                                                                                                                                                                                                                                                                                                                                                                  |
| Mac                | parser:mac_keychain OR parser:mac_securityd OR parser:mactime OR parser:plist OR parser:airport OR parser:apple_id OR parser:ipod_device OR parser:macosx_bluetooth OR parser:macosx_install_history OR parser:macuser OR parser:maxos_software_update OR parser:plist_default OR parser:spotlight OR parser:spotlight_volume OR parser:time_machine OR parser:appusage OR parser:mackeeper_cache                                                                                                             |
| MFT                | parser:mft                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| Persistence        | parser:appcompatcache OR parser:bagmru OR parser:mrulist_shell_item_list OR parser:mrulist_string OR parser:mrulistex_shell_item_list OR parser:mrulistex_string OR parser:mrulistex_string_and_shell_item OR parser:mrulistex_string_and_shell_item_list OR parser:msie_zone OR parser:mstsc_rdp OR parser:mstsc_rdp_mru OR parser:userassist OR parser:windows_boot_execute OR parser:windows_boot_verify OR parser:windows_run OR parser:windows_sam_users OR parser:windows_services OR parser:winrar_mru |
| Prefetch           | parser:prefetch                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| Registry           | parser:winreg OR parser:winreg_default                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| Scheduled Tasks    | parser:winjob OR parser:windows_task_cache                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| Search by MD5      | parser:mft AND md5_hash:*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| System Information | parser:rplog OR parser:explorer_mountpoints2 OR parser:explorer_programscache OR parser:windows_shutdown OR parser:windows_timezone OR parser:windows_usb_devices OR parser:windows_usbstor_devices OR parser:windows_version                                                                                                                                                                                                                                                                                 |
| USNJRNL            | parser:usnjrnl                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |

## Visualizations
15 pre-built Visualizations in the CCF-VM.  Table below contains the list of the built in Kibana Visualizations in CCF-VM.

| Name             | Saved Search Used                    |
|------------------|--------------------------------------|
| Anti-Virus       | Anti-Virus                           |
| Appcompat        | Appcompatcache                       |
| File System      | File System                          |
| Firewall         | Firewall                             |
| Internet History | Internet History                     |
| Linux            | Linux                                |
| MAC              | Mac                                  |
| OS Version       | System Information                   |
| Parser Results   | <no filtering: all results in index> |
| Persistence      | Persistence                          |
| Prefetch         | Prefetch                             |
| Registry         | Registry                             |
| Scheduled Tasks  | Scheduled Tasks                      |
| User Information | <no filtering: all results in index> |


## Dashboards
Six pre-built Dashboards in the CCF-VM.  Table below contains the list of the built in Kibana Dashboards in CCF-VM.

| Name                               | Saved Visualization(s) Used   |
|------------------------------------|-------------------------------|
| IR_01 Parser Details               | Parser Results                |
| IR_02 General Information          | OS Version / User Information |
| IR_03 Anti-Virus / Firewall        | Anti-Virus / Firewall         |
| IR_04 Appcompat / Internet History | Appcompat / Internet History  |
| IR_05 Linux / Mac                  | Linux / Mac                   |
| IR_06 Persistence / Prefetch       | Persistence / Prefetch        |

## Using Indices Intelligently
By default, CCF-VM has an index of “case_cdqr-*” and this allows for searching all data uploaded by CDQR.
 
##  Search just one host or collection of artifacts
To view data from just one host/collection of artifacts a new index is required.  To create a new index replace the “logstash-\*” in the upper white box with “case_cdqr-\<index_name\>\*”.  This must match what was used in the CDQR command line.   In this example, “case_cdqr-test*” is used.

Next, the white box under the “Time-field name” entry must have “datetime” populated in it and the “Create” button turned green.  If that does not happen then check the index name to ensure it is accurate.

## Data Cleanup
To remove the index go to the Elasticsearch-KOPF cluster management interface: http://<CCF-VM IP address or localhost>:9200/_plugin/kopf/#!/cluster# CCF-VM