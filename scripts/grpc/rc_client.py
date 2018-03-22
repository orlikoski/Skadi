"""The Python implementation of the GRPC rc.RC client."""

from __future__ import print_function

import grpc

import rc_pb2
import rc_pb2_grpc


def run():                         
    channel = grpc.insecure_channel('localhost:50051')
    stub = rc_pb2_grpc.RCStub(channel)
    
    response = stub.ExecuteRC(rc_pb2.RCRequest(service='dp', flag='mv_local',arg=["$(echo a| base64)", "$(echo a| base64)"]))
    print("RC client received: " + response.message)
    
                                                                      
if __name__ == '__main__':
    run()
