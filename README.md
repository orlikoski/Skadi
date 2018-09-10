
![](/objects/images/skadi_header.jpg?)  
(pronounced “SKAHD-ee”) is a giantess and goddess of hunting in Norse mythology  
_**Note: Skadi was formerly known as CCF-VM**_  

## Purpose
Skadi is a free, open source collection of tools that enables the collection, processing and advanced analysis of forensic artifacts and images. It scales to work effectively on laptops, desktops, servers, the cloud, and can be installed on top of hardened / gold disk images.   

## Skadi Wiki Page
The answers to common questions and information about how to get started with Skadi is stored in the [Skadi Wiki Pages](https://github.com/orlikoski/skadi/wiki).

## Skadi Community
There is a Slack community setup for developers and users of the Skadi ecosystem. It is a safe place to ask questions and share information.  

[Join the Skadi Community Slack](http://skadicommunity.herokuapp.com/)  

## Latest Releases!!
[Skadi Server 2018.3](https://drive.google.com/open?id=160zmZzR2ULwz3SxLa2d4yZYiSHywuzq_): Headless server ~2GB in size  
[Skadi Desktop 2018.3](https://drive.google.com/open?id=1x1M1-3ShYaKgHnRAbGIJ1CFs010nJ5zB): Server plus Ubuntu 16.04 Default Desktop ~3GB in size  
[Vagrant Skadi Server 2018.3](https://app.vagrantup.com/skadivm/boxes/skadi_server): Headless Skadi server available through Vagrant. Install Vagrant and VirtualBox and then [use this example Vagrant file](https://github.com/orlikoski/Skadi/tree/vagrant/Vagrant) to get started

[Skadi Portable 2018.3 ISO Image](https://drive.google.com/open?id=1SM-_Z4F-fnctERycEI0R6Hk-F8M7_WZ0): Live Boot ISO that runs Skadi from a USB drive and can install Skadi from USB drive to the host hardware (no networking or virtualization required)


[Latest Release Notes](https://github.com/orlikoski/Skadi/releases/tag/2018.3)  

### Previous Versions
Skadi Server  
[Skadi Server 2018.2](https://drive.google.com/open?id=1hLkFoHIcb9C39aQsGN4i235GZnTHmxm9)  
[Skadi Server 2018.1](https://drive.google.com/open?id=16DNRbr-uvwi9YrUeWT5HyyVd6O2eKMwe)  

Skadi Desktop  
[Skadi Desktop 2018.1](https://drive.google.com/open?id=1eq9ZVQAS8WUCNDMhQdjP9mFXdn75ekId)  
[Skadi Desktop 2018.2](https://drive.google.com/open?id=1iIf-bGBwu0xZoZMTOQma8RIppsjMf6iu)  

### Kibana, TimeSketch, Cerebro Included
  ![](/objects/images/desk_tools.jpg?)  

### 11 New Kibana Dashboards  
  ![](/objects/images/kib_dash01.JPG?)  
  ![](/objects/images/kib_dash02.JPG?)  

### TimeSketch
  ![](/objects/images/ts_shot02.JPG?)  
  ![](/objects/images/ts_shot01.JPG?)  

### Skadi Desktop (NEW!)
  ![](/objects/images/desktop.jpg?)  


## Skadi Add-on Packs  
Skadi add-on packs are installed on top of the base Skadi VM to provide extra functionality  
*  [Skadi Pack 01: Automation](https://github.com/orlikoski/Skadi/wiki/Skadi-Pack-01:-Automation): Provides two methods of integrating with any Automation tool: gRPC API or using SSH  
*  [Skadi Pack 02: Secure Networking](https://github.com/orlikoski/Skadi/wiki/Skadi-Pack-02:-Secure-Networking): Updates the firewall and authenticated reverse proxy for use in network deployment. Provides instructions for obtaining TLS/SSL certificates  

## Included Tools
The following tools are combined into one platform that all work together to provide everyone with the ability to collect data, convert the bits and bytes to words and numbers, and analyse the results quickly and easily. All of this enables the ability to rapidly hunt for host based evidence of a malicious activities.  

 - Plaso  
 - CDQR  
 - CyLR  
 - Docker  
 - ElasticSearch, Logstash, Kibana (ELK)  
 - Redis  
 - Neo4j  
 - Celery  
 - Cerebro  

## Videos and Media
*  [Alamo ISSA 2018](https://docs.google.com/presentation/d/1Rl_wF9mUDOkPlbHiWAt-hOiJ-_X8WzTsRfgyYQi9t6M/edit?usp=sharing) Slides: Reviews CCF-VM components, walkthrough of how to install GCP version and discuss automation possibilities and risks
*  [SANS DFIR Summit 2017](https://www.youtube.com/watch?v=f5B4bngftP8) Video: A talk about using CCF-VM for Digital Forensics and Incident Response (DFIR)
*  [ISC2 Security Congress 2017](https://drive.google.com/file/d/0B5z7g7P2BWJAckUxbUJWVVZzNDQ/view?usp=sharing) Slides: Another talk about using CCF-VM for Digital Forensics and Incident Response (DFIR)
*  [DEFCON 25 4-hour Workshop 2017](https://media.defcon.org/DEF%20CON%2025/DEF%20CON%2025%20workshops/DEFCON-25-Workshop-Alan-Orlikoski-and-Dan-M-Free-and-Easy-DFIR-Triage-for-Everyone.pdf) Slides: Free and Easy DFIR Triage for Everyone
*  [OSDFCON 2017](http://www.osdfcon.org/presentations/2017/Asif-Matadar_Rapid-Incident-Response.pdf) Slides: Walk-through different techniques that are required to provide forensics results for Windows and *nix environments (Including CyLR and CDQR)

## Thank you to everyone who has helped, and those that continue to, making this project a reality.

### Special Thanks to:
 - The team from [Komand](https://www.komand.com/) for their advice and support on all things Automation
 - Jackie & Jason from [@SpyglassSec](https://twitter.com/SpyglassSec) for their guidance
 - Every single one of the contributors who's efforts made the automation Addon Pack possible  

## CREATOR  
* [Alan Orlikoski](https://github.com/orlikoski)
