## NAME
CyLR CDQR Forensics Virtual Machine (CCF-VM) by Alan Orlikoski

## Videos and Media
*  [Alamo ISSA 2018](https://docs.google.com/presentation/d/1Rl_wF9mUDOkPlbHiWAt-hOiJ-_X8WzTsRfgyYQi9t6M/edit?usp=sharing) Slides: Reviews CCF-VM components, walkthrough of how to install GCP version and discuss automation possibilities and risks
*  [SANS DFIR Summit 2017](https://www.youtube.com/watch?v=f5B4bngftP8) Video: A talk about using CCF-VM for Digital Forensics and Incident Response (DFIR) 
*  [ISC2 Security Congress 2017](https://drive.google.com/file/d/0B5z7g7P2BWJAckUxbUJWVVZzNDQ/view?usp=sharing) Slides: Another talk about using CCF-VM for Digital Forensics and Incident Response (DFIR) 
*  [DEFCON 25 4-hour Workshop 2017](https://media.defcon.org/DEF%20CON%2025/DEF%20CON%2025%20workshops/DEFCON-25-Workshop-Alan-Orlikoski-and-Dan-M-Free-and-Easy-DFIR-Triage-for-Everyone.pdf) Slides: Free and Easy DFIR Triage for Everyone 
*  [OSDFCON 2017](http://www.osdfcon.org/presentations/2017/Asif-Matadar_Rapid-Incident-Response.pdf) Slides: Walk-through different techniques that are required to provide forensics results for Windows and *nix environments (Including CyLR and CDQR)

## What's New
*  Google Cloud Platform (GCP) Support!!!!
*  CyLR 1.4.0
*  CDQR 4.1.1
*  Plaso 20171231
*  OS Updates

## Purpose
The CCF-VM is a free, open source collection of tools that enables the collection, processing and advanced analysis of forensic artifacts and images.  It will operate on laptops, on-prem servers, the Cloud, and can be installed on top of hardened / gold disk images. This provides the everyone the ability to collect data and convert the bits and bytes to words and numbers. All of this enables the ability to rapidly answer, "Have I been hacked? Do I need to call for help?"

## System Spec Recommendations
Minimum (more is better): 
  * CPU: 4-8 threads/cores
  * Memory: 8GB+
  * Disk Size: 100GB+

## OpenSSL signed scripted installation
This type of installation is for users with some experience with linux administration. It is ideal for those that are required to build upon a baseline (gold disk) image. It also works very well for cloud based instances as a build script. It ensures that the most recent versions of the software are used and that it is configured the same way every time.  Also note that all ciphers and keys are generated at run time and therefore are as unique as any script can make them.

This is a script that installs and configures, including the creation of systemd services if not included otherwise, the following items onto a base image of Ubuntu/Debian (need apt to work).  
 *  CDQR 4.1.3 (pulls most recent from Git repo)
 *  CyLR 1.4.0 (pulls most recent from Git repo)
 *  ElasticSearch 6.x
 *  Logstash 6.x
 *  Kibana 6.x
 *  TimeSketch 20170721
 *  Neo4j 3.3.3
 *  Celery 4.1.0
 *  Redis 4.0.8
 *  PostgreSQL 9.5.11

Installation instructions
*  Start with Ubuntu 16.04 LTS or equivalent Debian base installation
*  Log into system with an account that has sudo privledges (The name doesn't have be `cdqr` but it is nostalgic)
* The [build.ccf.sh](https://github.com/rough007/CCF-VM/blob/master/scripts/buildccf.sh) script downloads the signed [buildccf.tgz](https://github.com/rough007/CCF-VM/blob/master/scripts/buildccf.tgz) file and verifies the signature using openssl. If anything interrupts the download or if the signature doesn't match then the installation exits with an error message.
*  Start the script from a terminal using the commands below


```
sudo apt install curl -y # Ensure curl is installed
wget -O /tmp/buildccf.sh https://raw.githubusercontent.com/rough007/CCF-VM/master/scripts/buildccf.sh
chmod +x /tmp/buildccf.sh
/tmp/buildccf.sh
```

*  This could take anywhere from 5 - 60+ minutes depending on the speed of the internet connection

The final completion will look something like this (version numbers may change over time):
```
System Health Checks
  Bringing up elasticsearch
  Bringing up postgresql
  Bringing up celery
  Bringing up neo4j
  Bringing up redis
  Bringing up logstash
  Bringing up kibana
  Bringing up timesketch

  elasticsearch service is: active
  postgresql service is: active
  celery service is: active
  neo4j service is: active
  redis service is: active
  logstash service is: active
  kibana service is: active
  timesketch service is: active

Verifying versions of Plaso and CDQR
plaso - log2timeline version 20180127
CDQR Version: 4.1.3

TimeSketch Initial User Information (reset with 'tsctl add_user -u cdqr -p <password>')
Username: cdqr
Password: <random 32 character string>
```

Not 100% complete, but very close. The reason this is for advanced users is that the remaining items require loading sample data into the ElasticSearch in order to create the default index in Kibana as well as load the pre-made Dashboards, Visualizations, and Searches into Kibana (requires the correct indexes to work).

Simple steps to complete the remaining steps:
*  Run sample data through CDQR into the ElasticSearch database (sample Virtual Machines can be found at the [DFIR Training](https://www.dfir.training/tools/virtualization-and-forensics/virtual-machines-downloads) site or by using CyLR to collect from a sample host (much faster).
  *  Sample Command: `~/cdqr.py -p win <disk image or CyLR resulting .zip file> --es_kb testing`  
*  The first time logged into Kibana it asks to create a default index.  Use `case_cdqr-*` for the index and ensure that the data is fully loaded from previous step
*  In Kibana click Management -> Saved Objects -> Import and use the file that has all of the CCF-VM specific Dashboards/Visualizations/Searches [kibana_6.x.json](https://raw.githubusercontent.com/rough007/CCF-VM/master/objects/kibana_6.x.json)

That's it. The setup is complete.

## Google Cloud Platform (GCP) Information
*  Signup for GCP and create a project [Start Here](https://cloud.google.com/) free $300 to sign as of Jan 16, 2018
    *  Google Project Creation: https://cloud.google.com/resource-manager/docs/creating-managing-projects
    *  [GCP instructions](https://cloud.google.com/compute/docs/images/import-existing-image) **Start from 'Import the image to your custom images list'**  
    *  [Fantastic video showing exactly howto build GCP instance starting from the raw disk image](https://youtu.be/YlcR6ZLebTM?t=827)  
*  Install [Google Cloud SDK](https://cloud.google.com/sdk/) on host used to control GCP (laptop/desktop with Windows, MacOS or Linux that supports the GCP SDK)  
*  Download the CCF-VM Cloud image [CCF-VM_3.0.tar.gz](https://drive.google.com/file/d/1v9j0W0zXC3eEXws_pVaXzWgcI_8swT3W)
*  Run the following commands to install and log into CCF-VM Cloud  
    ```bash
    gsutil mb gs://<GCP Storage Bucket Name>/
    gsutil cp CCF-VM_3.0.tar.gz gs://<GCP Storage Bucket Name>/CCF-VM_3.0.tar.gz
    gcloud compute images create ccf-vm-image --source-uri gs://<GCP Storage Bucket Name>/CCF-VM_3.0.tar.gz
    gcloud compute instances create ccf-vm --image ccf-vm-image --machine-type n1-standard-4 --zone <GCP zone>
    gcloud compute ssh ccf-vm --zone <GCP zone>
    ```  

**HIGHLY RECOMMEND PLACING CCF-VM BEHIND A STRONG FIREWALL OR BASTION HOST**


## Download locations
*  **CCF-VM 3.0 OVF:** https://drive.google.com/open?id=1taEOJA1iY9jgtGiZ7JRNpokUagYIv2J2
    *  MD5: a320c27d60bad2939bd57c4350453476
*  **CCF-VM 3.0 GCP Cloud Image:** https://drive.google.com/file/d/1v9j0W0zXC3eEXws_pVaXzWgcI_8swT3W
    *  MD5: 12229cc444daa58c837c77b222be6a24
*  **CCF-VM User Guide:** https://drive.google.com/open?id=0B5z7g7P2BWJAWTM2d0NQZjV6MHc
    *  MD5: 1e9c7cfe535cc2ba5fe9ffe3b8442575

## Open source solutions installed
*  Cold Disk Quick Response (CDQR): https://github.com/rough007/CDQR
*  CyLR: https://github.com/rough007/CyLR
*  Plaso: https://github.com/log2timeline/plaso
*  Elasticsearch: https://www.elastic.co/
*  Kibana: https://www.elastic.co/products/kibana
*  TimeSketch: https://github.com/google/timesketch
*  Cerebro: https://github.com/lmenezes/cerebro
*  Ubuntu 16.04: https://www.ubuntu.com/

## Credits
Thank you for the wonderful writeup, link is here (http://diftdisk.blogspot.com/2016/06/viewing-log2timeline-output-with-kibana.html), by Michael Maurer that gave me the knowledge to put many of the pieces together. 

## CCF-VM Useful information
*  IP Address:
    * Set to DHCP
*  Credentials (for anything that requires them):
    *  Username: cdqr
    *  Password: Changemen0w!
*  Access Kibana instance: 
    *  http://\<CCF-VM IP address or localhost\>:5601
*  Access TimeSketch instance: 
    *  http://\<CCF-VM IP address or localhost\>:5000
*  Access Cerebro (ElasticSearch management instance): 
    *  http://\<CCF-VM IP address or localhost\>:9000

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
cdqr.py example_hostname.zip -p win --max_cpu -z --es example_index
```
If the data is from a windows host, in a directory, “example_dirname”, then use the following command
```
cdqr.py example_dirname -p win --max_cpu --es example_index
```
If the data is from a mac host, is a forensic image file(s) then use the following command
```
cdqr.py example_dirname/example_hostname.E01 -p mac --max_cpu --es example_index
```

## Successful example output from CDQR
```
CDQR Version: 3.0
Plaso Version: 1.5
Using parser: win
Number of cpu cores to use: 8
Source data: Sample_data
Destination Folder: Results
Database File: Results/Sample_data.db
SuperTimeline CSV File: Results/Sample_data.SuperTimeline.csv


Results/Sample_data.log
Processing started at: 2001-01-01 17:40:58.322694
Parsing image
"log2timeline.py" "-p" "--partition" "all" "--vss_stores" "all" "--parsers" "appcompatcache,bagmru,binary_cookies,ccleaner,chrome_cache,chrome_cookies,chrome_extension_activity,chrome_history,chrome_preferences,explorer_mountpoints2,explorer_programscache,filestat,firefox_cache,firefox_cache2,firefox_cookies,firefox_downloads,firefox_history,google_drive,java_idx,mcafee_protection,mft,mrulist_shell_item_list,mrulist_string,mrulistex_shell_item_list,mrulistex_string,mrulistex_string_and_shell_item,mrulistex_string_and_shell_item_list,msie_zone,msiecf,mstsc_rdp,mstsc_rdp_mru,network_drives,opera_global,opera_typed_history,prefetch,recycle_bin,recycle_bin_info2,rplog,safari_history,symantec_scanlog,userassist,usnjrnl,windows_boot_execute,windows_boot_verify,windows_run,windows_sam_users,windows_services,windows_shutdown,windows_task_cache,windows_timezone,windows_typed_urls,windows_usb_devices,windows_usbstor_devices,windows_version,winevt,winevtx,winfirewall,winjob,winlogon,winrar_mru,winreg,winreg_default" "--hashers" "md5" "--workers" "8" "Results/Sample_data.db" "Sample_data"
Parsing ended at: 2001-01-01 17:44:24.899715
Parsing duration was: 0:03:26.577021

Process to export to ElasticSearch started
Exporting results to the ElasticSearch server
"psort.py" "-o" "elastic" "--raw_fields" "--index_name" "case_cdqr-Sample_data" "Results/Sample_data.db"
All entries have been inserted into database with case: case_cdqr-Sample_data

Process to export to ElasticSearch completed
ElasticSearch export process duration was: 0:03:24.242369

Total  duration was: 0:06:50.819390
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
To remove the index go to the Elasticsearch-KOPF cluster management interface: http://<CCF-VM IP address or localhost>:9200/_plugin/kopf/#!/cluster

## VirtualBox Notes
To enable Bridged Networking use the following:
*  "ifconfig -a" to get interface name
*  "sudo ifconfig \<interface name\> up" to bring up the interface
*  "sudo dhclient" to get an IP address

## AUTHOR

* [Alan Orlikoski](https://github.com/rough007)
