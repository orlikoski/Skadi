#!/usr/bin/python
"""The Python implementation of the GRPC rc.RC client."""
from __future__ import print_function
import grpc, rc_pb2, rc_pb2_grpc, sys


def main():                         
    unapproved_chars = set('`~!#$&*()\t{[|\\;\'\"<>?')
    strtest = ','.join(sys.argv)
    if any((char in unapproved_chars) for char in strtest):
        print("ERROR!! Unapproved chars in string. Exiting")
        exit(1)

    count = len(sys.argv)
    if not sys.argv[1]:
        print("WARNING: No server information found. Please provide a routable domain name or IP address. Exiting")
        exit(1)
    
    server = sys.argv[1]
    channel = grpc.insecure_channel(server+':10101')
    stub = rc_pb2_grpc.RCStub(channel)


    print("Attempting to send command to server\n")
    response = ""
    if count == 3:
        response = stub.ExecuteRC(rc_pb2.RCRequest(service=sys.argv[2]))
    elif count == 4:
        response = stub.ExecuteRC(rc_pb2.RCRequest(service=sys.argv[2],flag=sys.argv[3]))
    elif count == 5:
        response = stub.ExecuteRC(rc_pb2.RCRequest(service=sys.argv[2],flag=sys.argv[3],arg1=sys.argv[4]))
    elif count == 6:
        response = stub.ExecuteRC(rc_pb2.RCRequest(service=sys.argv[2],flag=sys.argv[3],arg1=sys.argv[4],arg2=sys.argv[5]))
    else:
        print("WARNING!! Invalid number of arguments. Exiting")

    print(response.message)
    print("COMPLETE")

if __name__ == '__main__':
    main()

