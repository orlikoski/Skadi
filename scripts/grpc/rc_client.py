#!/usr/bin/python
"""The Python implementation of the GRPC rc.RC client."""
from __future__ import print_function
import grpc, rc_pb2, rc_pb2_grpc, sys


def run():                         
    channel = grpc.insecure_channel('localhost:10101')
    stub = rc_pb2_grpc.RCStub(channel)

    if sys.argv[4]:
        response = stub.ExecuteRC(rc_pb2.RCRequest(service=sys.argv[1],flag=sys.argv[2],arg1=sys.argv[3],arg2=sys.argv[4]))
    else:
        response = stub.ExecuteRC(rc_pb2.RCRequest(service=sys.argv[1],flag=sys.argv[2],arg1=sys.argv[3],arg2=sys.argv[4]))

if __name__ == '__main__':
    run()

