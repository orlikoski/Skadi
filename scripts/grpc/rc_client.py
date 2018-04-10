#!/usr/bin/python
"""The Python implementation of the GRPC rc.RC client."""
from __future__ import print_function
import grpc, rc_pb2, rc_pb2_grpc, sys, argparse


def main():
    version = "Skadi Automation Engine Version: 1.0.0"
    parser = argparse.ArgumentParser(description='Skadi Automation Engine')
    parser.add_argument('-s','--server',nargs=1,help='Routable Domain Name or IP address of Skadi server')
    parser.add_argument('-v','--version', action='version', version=version)
    args=parser.parse_args()

    unapproved_chars = set('`~!#$&*()\t{[|\\;\'\"<>?')
    strtest = ','.join(sys.argv)
    if any((char in unapproved_chars) for char in strtest):
        print("ERROR!! Unapproved chars in string. Exiting")
        exit(1)

    count = len(sys.argv)
    channel = grpc.insecure_channel('localhost:10101')
    stub = rc_pb2_grpc.RCStub(channel)


    print("Attempting to send command to server\n")
    response = ""
    if count == 2:
        response = stub.ExecuteRC(rc_pb2.RCRequest(service=sys.argv[1]))
    elif count == 3:
        response = stub.ExecuteRC(rc_pb2.RCRequest(service=sys.argv[1],flag=sys.argv[2]))
    elif count == 4:
        response = stub.ExecuteRC(rc_pb2.RCRequest(service=sys.argv[1],flag=sys.argv[2],arg1=sys.argv[3]))
    elif count == 5:
        response = stub.ExecuteRC(rc_pb2.RCRequest(service=sys.argv[1],flag=sys.argv[2],arg1=sys.argv[3],arg2=sys.argv[4]))
    else:
        print("WARNING!! Invalid number of arguments. Exiting")

    print(response.message)

    print("COMPLETE")
if __name__ == '__main__':
    main()

