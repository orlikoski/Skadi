#!/usr/bin/python3
import os, sys, argparse

# Add all ElasticSearch Parser Options
def add_es_parsers(subparsers):
    es_parsers = subparsers.add_parser('es',
                                        help='ElasticSearch Commands')
    group = es_parsers.add_mutually_exclusive_group(required=False)
    group.add_argument('--delete',
                        nargs=1,
                        metavar="index_name",
                        help="Base64 encoded index name to delete")
    group.add_argument('--list',
                        action='store_true',
                        help="Lists names of the current ES indexes")

# Add all TimeSketch Parser Options
def add_ts_parsers(subparsers):
    ts_parsers = subparsers.add_parser('ts',
                                        help='TimeSketch Commands')
    group = ts_parsers.add_mutually_exclusive_group(required=False)
    group.add_argument('--delete',
                        nargs=1,
                        metavar="timesketch_name",
                        help="Delete the Base64 encoded timesketch name provided")
    group.add_argument('--deleteall',
                        action='store_true',
                        help="Delete all databases in TimeSketch. WARNING!!!! ****** THIS ALSO DELETS ALL USER ACCOUNTS ******")

# Add all Operating System Parser Options
def add_os_parsers(subparsers):
    server_commands = ["restart","stop"]
    os_parsers = subparsers.add_parser('os',
                                        help='Operating System Commands')
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
                                        help='Data Processing Commands')

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




if __name__ == "__main__":
    main()