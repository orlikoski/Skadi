
![](/objects/images/skadi_header.jpg?)  
(pronounced “SKAHD-ee”) is a giantess and goddess of hunting in Norse mythology  
_**Note: Skadi was formerly known as CCF-VM**_  

## Purpose
Skadi is a free, open source collection of tools that enables the collection, processing and advanced analysis of forensic artifacts and images. It scales to work effectively on laptops, desktops, servers, the cloud, and can be installed on top of hardened / gold disk images.   

# How to Get Started and Support
## Download Latest Release
Available in OVA, Vagrant and Signed Installer formats  
[Click Here to Download the Latest Release](https://github.com/orlikoski/Skadi/releases/latest)  
[Click Here for Installation with Vagrant Instructions](https://github.com/orlikoski/Skadi/wiki/Installation-with-Vagrant-Instructions)  
[Click Here for OVA Installation Instructions](https://github.com/orlikoski/Skadi/wiki/Installation:-Importing-OVA)  
[Click Here for Signed Installer Instructions](https://github.com/orlikoski/Skadi/wiki/Installation:-OpenSSL-Signed-Installation-Guide)  

## Skadi Portal
This portal allows easy access to Skadi tools. By default it is available at the IP address of the Skadi Server.  
The default credentials are:  
- Username: `skadi`  
- Password: `skadi`  

Access the portal through a web browser at the IP address of the server. In this example the server is `192.168.1.2` and Vagrant will create a link to `localhost`  
- Example: http://192.168.1.2  
- Vagrant Example: http://localhost  

![](/objects/images/skadi_portal.jpg?)

## Included Tools
![](/objects/images/skadi_tools.jpg?)
The tools are combined into one platform that all work together to provide the ability to collect data, convert the bits and bytes to words and numbers, and analyze the results quickly and easily. This enables the ability to rapidly hunt for host based evidence of a malicious activities quickly and accurately.  
 - CDQR  
 - Cerebro  
 - CyberChef
 - CyLR  
 - Docker  
 - ElasticSearch
 - Glances
 - Grafana
 - Kibana
 - Plaso  
 - TimeSketch

### Kibana, TimeSketch, Cerebro Included
  ![](/objects/images/desk_tools.jpg?)  

### 11 Kibana Dashboards  
  ![](/objects/images/kib_dash01.JPG?)  
  ![](/objects/images/kib_dash02.JPG?)  

### TimeSketch
  ![](/objects/images/ts_shot02.JPG?)  
  ![](/objects/images/ts_shot01.JPG?)  

## Videos and Media
*  [Alamo ISSA 2018](https://docs.google.com/presentation/d/1Rl_wF9mUDOkPlbHiWAt-hOiJ-_X8WzTsRfgyYQi9t6M/edit?usp=sharing) Slides: Reviews CCF-VM components, walkthrough of how to install GCP version and discuss automation possibilities and risks
*  [SANS DFIR Summit 2017](https://www.youtube.com/watch?v=f5B4bngftP8) Video: A talk about using CCF-VM for Digital Forensics and Incident Response (DFIR)
*  [ISC2 Security Congress 2017](https://drive.google.com/file/d/0B5z7g7P2BWJAckUxbUJWVVZzNDQ/view?usp=sharing) Slides: Another talk about using CCF-VM for Digital Forensics and Incident Response (DFIR)
*  [DEFCON 25 4-hour Workshop 2017](https://media.defcon.org/DEF%20CON%2025/DEF%20CON%2025%20workshops/DEFCON-25-Workshop-Alan-Orlikoski-and-Dan-M-Free-and-Easy-DFIR-Triage-for-Everyone.pdf) Slides: Free and Easy DFIR Triage for Everyone
*  [OSDFCON 2017](http://www.osdfcon.org/presentations/2017/Asif-Matadar_Rapid-Incident-Response.pdf) Slides: Walk-through different techniques that are required to provide forensics results for Windows and *nix environments (Including CyLR and CDQR)


## Skadi Wiki Page
The answers to common questions and information about how to get started with Skadi is stored in the [Skadi Wiki Pages](https://github.com/orlikoski/skadi/wiki).

## Skadi Community
There is a Slack community setup for developers and users of the Skadi ecosystem. It is a safe place to ask questions and share information.  

[Join the Skadi Community Slack](http://skadicommunity.herokuapp.com/)


## Skadi Add-on Packs  
Skadi add-on packs are installed on top of the base Skadi VM to provide extra functionality  
*  [Skadi Pack 01: Automation](https://github.com/orlikoski/Skadi/wiki/Skadi-Pack-01:-Automation): Provides two methods of integrating with any Automation tool: gRPC API or using SSH  
*  [Skadi Pack 02: Secure Networking](https://github.com/orlikoski/Skadi/wiki/Skadi-Pack-02:-Secure-Networking): Updates the firewall and authenticated reverse proxy for use in network deployment. Provides instructions for obtaining TLS/SSL certificates  


## Thank you to everyone who has helped, and those that continue to, making this project a reality.

### Special Thanks to:
 - The team from [Komand](https://www.komand.com/) for their advice and support on all things Automation
 - Jackie & Jason from [@SpyglassSec](https://twitter.com/SpyglassSec) for their guidance
 - Every single one of the contributors who's efforts made the automation Addon Pack possible  

## CREATOR  
* [Alan Orlikoski](https://github.com/orlikoski)
