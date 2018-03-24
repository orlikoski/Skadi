#!/bin/bash
sudo -H python -m pip install grpcio grpcio-tools

sudo mkdir -p /var/lib/automation/
wget -O /tmp/rc.py <link> /var/lib/automation/rc.py
sudo mv /tmp/rc.py /var/lib/automation/rc.py
sudo chown root:root /var/lib/automation/rc.py
sudo chmod 755 /var/lib/automation/rc.py

python -m grpc_tools.protoc -I./ --python_out=./ rc.proto --grpc_python_out=. 

python -m grpc_tools.protoc -I./ --python_out=. --grpc_python_out=. rc.proto



syntax = "proto3";

package rc;

// The greeting service definition.
service RC {
  rpc ExecuteRC (RCRequest) returns (RCReply) {}
}

// The request message containing the requested command and arguments.
message RCRequest {
  required string service = 1;
  optional string flag = 2;
  optional string arg1 = 3;
  optional string arg2 = 4;
}

// The response message containing any error messages
message RCReply {
  repeated string message = 1;
}
