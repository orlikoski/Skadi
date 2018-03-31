#!/usr/bin/python
from concurrent import futures
import time, grpc, rc_pb2, rc_pb2_grpc, subprocess, os

rcpy = "/var/lib/automation/rc.py"

_ONE_DAY_IN_SECONDS = 60 * 60 * 24


class RC(rc_pb2_grpc.RCServicer):

    def ExecuteRC(self, request, context):
        input_args = [request.service]
        if request.flag:
            input_args.append(request.flag)
        if request.arg1:
            input_args.append(request.arg1)
        if request.arg2:
            input_args.append(request.arg2)

        command = ["/usr/bin/python3",rcpy]
        return rc_pb2.RCReply(message=runcommand(command,input_args))

def runcommand(command,input_args):
    for item in input_args:
        command.append(item)
    cmdout = subprocess.check_output(command)
    print cmdout.decode("utf-8")
    return cmdout.decode("utf-8")


def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    rc_pb2_grpc.add_RCServicer_to_server(RC(), server)
    server.add_insecure_port('[::]:10101')
    server.start()
    try:
        while True:
            time.sleep(_ONE_DAY_IN_SECONDS)
    except KeyboardInterrupt:
        server.stop(0)


if __name__ == '__main__':
    serve()

