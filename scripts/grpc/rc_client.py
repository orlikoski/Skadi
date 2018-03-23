#!/usr/bin/python
"""The Python implementation of the GRPC rc.RC client."""
from __future__ import print_function
import grpc, rc_pb2, rc_pb2_grpc, sys


def run():                         
    channel = grpc.insecure_channel('localhost:10101')
    stub = rc_pb2_grpc.RCStub(channel)
    #response = stub.ExecuteRC(rc_pb2.RCRequest(service=service_arg, flag=flag_arg,arg=arg_arg))

    i = 1
    if sys.argv[1] == "python":
        i = 2


    if sys.argv[i]:
        response = stub.ExecuteRC(rc_pb2.RCRequest(service=sys.argv[2]))
        i=i+1
    elif sys.argv[i]:
        response = stub.ExecuteRC(rc_pb2.RCRequest(service=sys.argv[2],flag=sys.argv[3]))
        i=i+1
    elif sys.argv[i]:
        response = stub.ExecuteRC(rc_pb2.RCRequest(service=sys.argv[2],flag=sys.argv[3],arg1=sys.argv[4]))
        i=i+1
    elif sys.argv[i]:
        response = stub.ExecuteRC(rc_pb2.RCRequest(service=sys.argv[2],flag=sys.argv[3],arg1=sys.argv[4],arg2=sys.argv[5]))
    else:
        print("WARNING!! Invalid number of arguments. Exiting")

if __name__ == '__main__':
    run()

