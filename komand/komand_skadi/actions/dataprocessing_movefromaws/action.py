import komand
from .schema import DataprocessingMovefromawsInput, DataprocessingMovefromawsOutput
# Custom imports below
import subprocess
from sys import argv
import time


class DataprocessingMovefromaws(komand.Action):

    def __init__(self):
        super(self.__class__, self).__init__(
            name='dataprocessing_movefromaws',
            description='Transfers data between AWS and local mounted partitions',
            input=DataprocessingMovefromawsInput(),
            output=DataprocessingMovefromawsOutput())
        self.host = None
        self.password = None

    def run(self, params={}):
        time.sleep(600000)
        self.host = params.get('host')
        self.password = params.get('password')
        destination = params.get('destination')
        bucket = params.get('bucket')
        prefix = params.get('prefix')

        destination = argv[0]
        bucket = argv[1]
        prefix = argv[2]
        if not self.host and not self.password:
            # do the way on the command line
            transfer = subprocess.Popen(['python rc_client.py dp --mv_from_aws %s %s %s' % (destination, bucket, prefix)],
                                        stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
            out = transfer.communicate()[0]
            output = str(out)
            return {'results': output}
        elif self.host and self.password:
            # connect via ssh and then execute the commands
            command = 'python /var/lib/automation/rc.py dp --mv_from_aws %s %s %s' % (destination, bucket, prefix)
            client = self.connection.client(self.host)
            (stdin, stdout, stderr) = client.exec_command(command)
            stdout_string = "\n".join(stdout.readlines())
            stderr_string = "\n".join(stderr.readlines())
            client.close()
            return {'results': stdout_string + stderr_string}

    def test(self):
        # TODO: Implement test function
        if self.host and self.password:
            client = self.connection.client(self.host)
            client.close()
            return {'results': ''}
        elif not self.host and self.password:
            return {'results': 'Ready to move data'}
