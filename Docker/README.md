# Docker Build Steps

## Setup the Host
Install Ubuntu 16.04 on the host machine. This can be a VM, Cloud instance, or bare iron machine.

## Install all the Components
```
sudo apt-get install git -y
git clone https://github.com/orlikoski/Skadi.git
cd Skadi/Docker
sudo bash BuildDockerSkadi.sh
```

## Visit the Skadi Portal
Open a web browser and navigate to http://\<hostname or IP address of the Host Machine\>

## Setup Kibana
Not 100% complete, but very close. The reason this is for advanced users is that the remaining items require loading sample data into the ElasticSearch in order to create the default index in Kibana as well as load the pre-made Dashboards, Visualizations, and Searches into Kibana (requires the correct indexes to work).

### Complete the remaining items:
*  Run sample data through CDQR into the ElasticSearch database (sample Virtual Machines can be found at the [DFIR Training](https://www.dfir.training/tools/virtualization-and-forensics/virtual-machines-downloads) site or by using CyLR to collect from a sample host (much faster).
  *  Sample Command: `~/cdqr.py -p win <disk image or CyLR resulting .zip file> --es_kb initial_setup`  
*  The first time logged into Kibana it asks to create a default index.  Use `case_cdqr-*` for the index and ensure that the data is fully loaded from previous step
*  In Kibana click Management -> Saved Objects -> Import and use the file that has all of the Skadi specific Dashboards/Visualizations/Searches [kibana_6.x.json](https://raw.githubusercontent.com/orlikoski/skadi/master/objects/kibana_6.x.json)
