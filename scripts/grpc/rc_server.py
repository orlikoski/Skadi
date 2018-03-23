from concurrent import futures
import time

import grpc

import rc_pb2
import rc_pb2_grpc
import subprocess


import os 
dir_path = os.path.dirname(os.path.realpath(__file__))


_ONE_DAY_IN_SECONDS = 60 * 60 * 24


class RC(rc_pb2_grpc.RCServicer):

    def ExecuteRC(self, request, context):
        args = [str(arg) for arg in request.arg]
        command = ["python", dir_path+"/../rc.py", str(request.service), str("--" + request.flag)]
        command.extend(args)
        cmd = subprocess.call(command)
        return rc_pb2.RCReply(message="SUCCESS")      


def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    rc_pb2_grpc.add_RCServicer_to_server(RC(), server)
    server.add_insecure_port('[::]:50051')
    server.start()
    try:
        while True:
            time.sleep(_ONE_DAY_IN_SECONDS)
    except KeyboardInterrupt:
        server.stop(0)


if __name__ == '__main__':
    serve()

