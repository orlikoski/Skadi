#!/usr/bin/python3
import  argparse, base64,  os, requests, subprocess, sys, boto3


# Add all ElasticSearch Parser Options
def add_es_parsers(subparsers):
    es_parsers = subparsers.add_parser('es',
                                        help="ElasticSearch Commands. Use 'rc.py es -h' to see all options")
    group = es_parsers.add_mutually_exclusive_group(required=False)
    group.add_argument('--delete',
                        nargs=1,
                        metavar="index_name",
                        help="Base64 encoded index name to delete")
    group.add_argument('--list',
                        action='store_true',
                        help="Lists the current ES indices and their status")

# Add all TimeSketch Parser Options
def add_ts_parsers(subparsers):
    ts_parsers = subparsers.add_parser('ts',
                                        help="TimeSketch Commands. Use 'rc.py ts -h' to see all options")
    group = ts_parsers.add_mutually_exclusive_group(required=False)
    group.add_argument('--useradd',
                        nargs=2,
                        metavar=("b64_username","b64_password"),
                        help="Create a TimeSketch user with the base64 encoded username and  password provided")

    group.add_argument('--delete',
                        nargs=1,
                        metavar="timesketch_name",
                        help="Delete the Base64 encoded timesketch name provided")

# Add all Operating System Parser Options
def add_os_parsers(subparsers):
    server_commands = ["restart","stop"]
    os_parsers = subparsers.add_parser('os',
                                        help="'Operating System Commands. Use 'rc.py os -h' to see all options")
    group = os_parsers.add_mutually_exclusive_group(required=False)
    group.add_argument('--server',
                        nargs=1,
                        choices=server_commands,
                        help="Restart or Stop Server")
    group.add_argument('--service',
                        nargs=2,
                        metavar=("action","service_names"),
                        help="Control System Services. Actions: 'start' 'stop' 'restart'. The service name(s) must be space delimited, if more than one, and Base64 encoded")

# Add all Data Processing Parser Options
def add_dp_parsers(subparsers):
    dp_parsers = subparsers.add_parser('dp',
                                        help="Data Processing Commands. Use 'rc.py dp -h' to see all options")
    group = dp_parsers.add_mutually_exclusive_group(required=False)
    group.add_argument('--cdqr',
                        nargs=1,
                        metavar="cdqr_args",
                        help="Execute CDQR with the base64 encoded arguments provided")
    group.add_argument('--mv_local',
                        nargs=2,
                        metavar=("src_local","dest_local"),
                        help="Move data on locally mounted partitions")
    group.add_argument('--mv_aws',
                    nargs=*,
                    metavar=("src","dest","bucket","prefix"),
                    help="Transfers data between AWS and local mounted partitions")

############ Base64 Functions ######################
def myb64decode(encoded_string):
    decoded_string = base64.b64decode(encoded_string).decode('utf-8').strip()
    return decoded_string

############ Web Request Output Handling ######################
def web_results(r):
    print(r)
    print(r.text)

############ ElasticSearch Functions ######################
# Delete an ElasticSearch index by name
def es_del_index(server, indexname):
    decoded_index = myb64decode(indexname[0])
    print("Deleting ElasticSearch index: " + decoded_index + " from " + server)
    url = "http://" + server + ":9200/" + decoded_index + "?pretty"
    web_results(requests.delete(url))

# List all ElasticSearch indices
def es_list_index(server):
    print("List all ElasticSearch indices from " + server)
    #curl -XGET 'localhost:9200/_cat/indices?v&pretty'
    url = "http://" + server + ":9200/_cat/indices?v&pretty"
    web_results(requests.get(url))

def es_main(args):
    print("Executing ElasticSearch command")
    es_server='localhost'
    # Delete an ElasticSearch index by name
    if args.delete:
        print("Attempting to delete an index")
        es_del_index(es_server, args.delete)
    elif args.list:
        print("Attempting to list all indices")
        es_list_index(es_server)
    else:
        print("Arguments passed: ", args)
        print("ERROR: Unable to parse ElasticSearch command. Exiting")
        exit(1)

############ TimeSketch Functions ######################
def create_ts_user(ts,userinfo):
    username = myb64decode(userinfo[0])
    password = myb64decode(userinfo[1])
    print("Creating TimeSketch user:", username)
    margs = " add_user -u " + username + " -p " + password
    cmd = subprocess.Popen(ts + " " + margs, shell=True).wait()

def delete_ts(ts,enc_name):
    ts_name = myb64decode(enc_name[0])
    print("Deleting TimeSketch Index named:", ts_name)
    margs = "purge -i " + ts_name
    cmd = subprocess.Popen("echo y|" + ts + " " + margs, shell=True).wait()

def ts_main(args):
    ts_exec = "/usr/local/bin/tsctl"
    print("Executing TimeSketch command")
    # Create TimeSketch user with the provided base64 encoded username and password
    if args.useradd:
        print("Attempting to create TimeSketch user")
        create_ts_user(ts_exec, args.useradd)
    elif args.delete:
        print("Attempting to delete TimeSketch index")
        delete_ts(ts_exec, args.delete)
    else:
        print("Arguments passed: ", args)
        print("ERROR: Unable to parse TimeSketch command. Exiting")
        exit(1)

############ Operating System Functions ######################
def os_server(args):
    print("WARNING!! There will not be any acknowledgment if this worked due to stopping the server")
    print("WARNING!! This requires sudo privledges and the process will hang if a password is required")
    print("WARNING!! It is advised to only use this function with key-pair authentication")
    if args[0].lower() == "stop":
        print("Attempging to shut the server down")
        print("sudo shutdown -h now")
        cmd = subprocess.Popen("sudo /sbin/shutdown -h now", shell=True).wait()
    elif args[0].lower() == "restart":
        print("Attempging to restart the server")
        print("sudo shutdown -r now")
        cmd = subprocess.Popen("sudo /sbin/shutdown -r now", shell=True).wait()
    else:
        print("Arguments passed: ", args)
        print("ERROR: Unable to parse Operating System command. Exiting")
        exit(1)

def os_service(args):
    print("WARNING!! This requires sudo privledges and the process will hang if a password is required")
    print("WARNING!! It is advised to only use this function with key-pair authentication")
    command = args[0].lower()
    accepted_commands = ["start","stop","restart"]
    if command not in accepted_commands:
        print("ERROR: Command " + command + " does not match accepted commands")
        print("ERROR: Accepted commands are: 'start' 'stop' 'restart'")
        exit(1)

    service_list_array = myb64decode(args[1]).split()

    if command == "stop":
        for service in service_list_array:
            print("Stoping:",service)
            cmd = subprocess.Popen("sudo /bin/systemctl stop " + service, shell=True).wait()
    elif command == "restart" or command == "start":
        for service in service_list_array:
            print("Starting / Restarting:",service)
            cmd = subprocess.Popen("sudo /bin/systemctl restart " + service, shell=True).wait()
    else:
        print("Arguments passed: ", args)
        print("ERROR: Unable to parse Operating System command. Exiting")
        exit(1)

def os_main(args):
    print("Executing Operating System command")
    # Create TimeSketch user with the provided base64 encoded username and password
    if args.server:
        print("Attempting to stop or restart the server")
        os_server(args.server)
    elif args.service:
        print("Attempting to stop/start/restart a service")
        os_service(args.service)
    else:
        print("Arguments passed: ", args)
        print("ERROR: Unable to parse TimeSketch command. Exiting")
        exit(1)

############ Data Processing Functions ######################
def dp(cdqr,args):
    parsed_args = myb64decode(args[0])
    print("Executing CDQR command")
    cmd = subprocess.Popen(cdqr + " " + parsed_args, shell=True).wait()

def mv_local(args):
    src = myb64decode(args[0])
    dest = myb64decode(args[1])
    print("Locally moving file at " + src + " to " + dest)
    cmd = subprocess.Popen("mv " + src + " " + dest, shell=True).wait()

def mv_aws(args):
    if len(args) < 3:
        print("Must provide at least 3 arguments!")
        return
    src = myb64decode(args[0])
    dest = myb64decode(args[1])
    bucket = myb64decode(args[2])
    s3 = boto3.client('s3')
    if os.path.dir(src):
        #src is local dir
        for (dirpath, dirnames, filenames) in os.walk(src):
            for filename in files:
                local_path = os.path.join(root, filename)
                client.upload_file(local_path, bucket, filename)
        
        print("Successfully moved files from %s"%src)
    elif os.path.isfile(src):
        #src is local file
        client.upload_file(src, bucket, os.basename(src))
        print("Successfully moved %s"%os.basename(src))
    else:
        #src is aws bucket
        try:
            #allow for prefix use
            prefix = myb64decode(args[3])
        except:
            prefix = None
        for key in client.list_objects(Bucket = bucket, Prefix = prefix)['Contents']:
            #Assume key is file with extension
            client.download_file(Bucket = bucket, Key = key['key'], Filename = dest + '/' + key['key'])
        print("Successfully retreived files from %s"%bucket)
        
def dp_main(args):
    cdqr_exec = "/usr/local/bin/cdqr.py"
    if args.cdqr:
        print("Attempting to process data with CDQR")
        process_cdqr(cdqr_exec, args.cdqr)
    elif args.mv_local:
        print("Attempting to move files locally")
        mv_local(args.mv_local)
    elif args.mv_aws:
        print("Attempting to move files to/from AWS bucket")
        mv_aws(args.mv_aws)
    else:  
        print("Arguments passed: ", args)
        print("ERROR: Unable to parse Data Processing command. Exiting")
        exit(1)
 
# Main Program
def main():
    version = "CCF-VM Automation Engine 0.0.1"

    # Build Parser Options
    parser = argparse.ArgumentParser(description='CCF-VM Automation Engine')
    subparsers = parser.add_subparsers(help='Automation Options', dest='auto_type')
    add_es_parsers(subparsers)
    add_ts_parsers(subparsers)
    add_os_parsers(subparsers)
    add_dp_parsers(subparsers)
    parser.add_argument('-v','--version',
                        action='version',
                        version=version)
    args=parser.parse_args()

    # Parse arguments and call appropriate function based on auto_type
    if args.auto_type == 'es':
        es_main(args)
    elif args.auto_type == 'ts':
        ts_main(args)
    elif args.auto_type == 'os':
        os_main(args)
    elif args.auto_type == 'dp':
        dp_main(args)
    else:
        print("ERROR: Invalid command type. Exiting")
        exit(1)

    print("SUCCESS: CCF-VM Automation Engine Completed")


if __name__ == "__main__":
    main()
