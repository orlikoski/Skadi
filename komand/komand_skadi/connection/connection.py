import komand
import logging
from .schema import ConnectionSchema
# Custom imports below
import paramiko
import base64
import StringIO


class Connection(komand.Connection):

    def __init__(self):
        super(self.__class__, self).__init__(self.schema)

    def connect_key(self, params):
        logging.info("connecting via key")
        key = base64.b64decode(params.get('key')).strip()
        fd = StringIO.StringIO(key)
        k = paramiko.RSAKey.from_private_key(fd, password=params.get('password'))
        s = paramiko.SSHClient()
        s.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        s.load_system_host_keys()
        s.connect(params.get('host'), params.get('port'),
                  username=params.get('username'), pkey=k)
        return s

    def connect_password(self, params):
        logging.info("connecting via password")
        s = paramiko.SSHClient()
        s.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        s.load_system_host_keys()
        s.connect(params.get('host'), params.get('port'),
                  params.get('username'), params.get('password'))
        return s

    def client(self, host=None):
        if host:
            self.parameters['host'] = host
        if self.parameters.get('key'):
            return self.connect_key(self.parameters)
        else:
            return self.connect_password(self.parameters)

    def connect(self, params):
        logging.info("connecting")
