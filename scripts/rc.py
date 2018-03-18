#!/usr/bin/python3
<<<<<<< 4d57449efdcb8abcd810b11a1231b14400fcf45c
import os, sys, argparse, requests, base64
=======
import os, sys, argparse, requests, base64, subprocess
>>>>>>> TimeSketch functions are complete

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
<<<<<<< 4d57449efdcb8abcd810b11a1231b14400fcf45c
                        help="Lists the current ES indexes and their status")
=======
                        help="Lists the current ES indices and their status")
>>>>>>> TimeSketch functions are complete

# Add all TimeSketch Parser Options
def add_ts_parsers(subparsers):
    ts_parsers = subparsers.add_parser('ts',
                                        help="TimeSketch Commands. Use 'rc.py ts -h' to see all options")
    group = ts_parsers.add_mutually_exclusive_group(required=False)
<<<<<<< 4d57449efdcb8abcd810b11a1231b14400fcf45c
=======
    group.add_argument('--useradd',
                        nargs=2,
                        metavar=("b64_username","b64_password"),
                        help="Create a TimeSketch user with the base64 encoded username and  password provided")

>>>>>>> TimeSketch functions are complete
    group.add_argument('--delete',
                        nargs=1,
                        metavar="timesketch_name",
                        help="Delete the Base64 encoded timesketch name provided")
<<<<<<< 4d57449efdcb8abcd810b11a1231b14400fcf45c
    group.add_argument('--deleteall',
                        action='store_true',
                        help="Delete all databases in TimeSketch. WARNING!!!! ****** THIS ALSO DELETS ALL USER ACCOUNTS ******")
=======
>>>>>>> TimeSketch functions are complete

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
<<<<<<< 4d57449efdcb8abcd810b11a1231b14400fcf45c
    es_server='localhost'
    # Delete an ElasticSearch index by name
    if args.delete:
        es_del_index(es_server, args.delete)
    elif args.list:
        es_list_index(es_server)
    else:
        print(args)
    exit(1)
############ TimeSketch Functions ######################
def ts_main(args):
    exit(1)
=======
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
>>>>>>> TimeSketch functions are complete

############ Operating System Functions ######################
def os_main(args):
    exit(1)

############ Data Processing Functions ######################
def dp_main(args):
    exit(1)

# Main Program
def main():
    version = "CCF-VM Automation Engine 0.0.1"
    cdqr_exec = "/usr/local/bin/cdqr.py"
<<<<<<< 4d57449efdcb8abcd810b11a1231b14400fcf45c
    ts_exec = "/usr/local/bin/tsctl"
=======
>>>>>>> TimeSketch functions are complete

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

<<<<<<< 4d57449efdcb8abcd810b11a1231b14400fcf45c
=======
    print("SUCCESS: CCF-VM Automation Engine Completed")


>>>>>>> TimeSketch functions are complete
if __name__ == "__main__":
    main()