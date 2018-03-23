#!/usr/bin/python
"""The Python implementation of the GRPC rc.RC client."""
from __future__ import print_function
import grpc, rc_pb2, rc_pb2_grpc, sys


def run():                         
    channel = grpc.insecure_channel('localhost:10101')
    stub = rc_pb2_grpc.RCStub(channel)
    #response = stub.ExecuteRC(rc_pb2.RCRequest(service=service_arg, flag=flag_arg,arg=arg_arg))
    response = stub.ExecuteRC(rc_pb2.RCRequest(service=' '.join(sys.argv)))
    print("RC client received: " + response.message)

if __name__ == '__main__':
    run()

