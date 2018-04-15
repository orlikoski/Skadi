import komand
from .schema import TimesketchCreateuserInput, TimesketchCreateuserOutput
# Custom imports below
import subprocess
from sys import argv

class TimesketchCreateuser(komand.Action):

    def __init__(self):
        super(self.__class__, self).__init__(
                name='timesketch_createuser',
                description='Create a TimeSketch user with the base64 encoded username and  password provided',
                input=TimesketchCreateuserInput(),
                output=TimesketchCreateuserOutput())
        self.host = None
        self.password = None

    def run(self, params={}):
        self.host = params.get('host')
        self.password = params.get('password')
        b64_username = params.get('b64_username')
        b64_password = params.get('b64_password')
        b64_username = argv[0]
        b64_password = argv[1]
        if not self.host and not self.password:
            # do the way on the command line
            transfer = subprocess.Popen(['python rc.py ts --useradd %s %s' % (b64_username, b64_password)],
                                        stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
            out = transfer.communicate()[0]
            output = str(out)
            return {'results': output}
        elif self.host and self.password:
            # connect via ssh and then execute the commands
            command = 'python /var/lib/automation/rc.py ts --useradd %s %s' % (b64_username, b64_password)
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
            return {'results': 'Ready to add TimeSketch user'}
