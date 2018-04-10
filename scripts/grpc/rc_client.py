#!/usr/bin/python
"""The Python implementation of the GRPC rc.RC client."""
from __future__ import print_function
import grpc, rc_pb2, rc_pb2_grpc, sys, argparse


def parse_input(commands):
    count = len(commands)
    if count == 1:
        response = stub.ExecuteRC(rc_pb2.RCRequest(service=commands[0]))
    elif count == 2:
        response = stub.ExecuteRC(rc_pb2.RCRequest(service=commands[0],flag=commands[1]))
    elif count == 3:
        response = stub.ExecuteRC(rc_pb2.RCRequest(service=commands[0],flag=commands[1],arg1=commands[2]))
    elif count == 4:
        response = stub.ExecuteRC(rc_pb2.RCRequest(service=commands[0],flag=commands[1],arg1=commands[2],arg2=commands[3]))
    else:
        print("WARNING!! Invalid number of arguments. Exiting")
        exit(1)
    return response


def main():
    version = "Skadi Automation Engine Version: 1.0.0"
    parser = argparse.ArgumentParser(description=version)
    parser.add_argument('server',nargs=1, help='Routable Domain Name or IP address of Skadi server')
    parser.add_argument('commands', type=str, nargs='+')
    parser.add_argument('-v','--version', action='version', version=version)
    args=parser.parse_args()

    unapproved_chars = set('`~!#$&*()\t{[|\\;\'\"<>?')
    strtest = ','.join(sys.argv)
    if any((char in unapproved_chars) for char in strtest):
        print("ERROR!! Unapproved chars in string. Exiting")
        exit(1)

    if args.server:
        channel = grpc.insecure_channel(args.server[0]+':10101')
        stub = rc_pb2_grpc.RCStub(channel)
    else:
        print("ERROR!! No server information provided. Exiting")

    response = ""
    if args.commands:
        response = parse_input(args.commands)
    else:
        print("WARNING: No commands provided. Exiting")

    print("Attempting to send command to server\n")


    print(response.message)

    print("COMPLETE")
if __name__ == '__main__':
    main()

