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

## AUTHOR

* [Alan Orlikoski](https://github.com/rough007)
