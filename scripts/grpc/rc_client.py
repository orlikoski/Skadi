#!/usr/bin/python
"""The Python implementation of the GRPC rc.RC client."""
from __future__ import print_function
import grpc, rc_pb2, rc_pb2_grpc


def run():                         
    # Collect arguments
    service_arg = sys.argv[1]
    flag_arg = sys.argv[2]
    arg_arg = sys.argv[3] + " " + sys.argv[4]

    channel = grpc.insecure_channel('localhost:10101')
    stub = rc_pb2_grpc.RCStub(channel)
    response = stub.ExecuteRC(rc_pb2.RCRequest(service=service_arg, flag=flag_arg,arg=arg_arg))
    print("RC client received: " + response.message)

if __name__ == '__main__':
    run()

