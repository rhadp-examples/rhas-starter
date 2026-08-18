import logging
import sys

import pytest

from jumpstarter_testing.pytest import JumpstarterTest


log = logging.getLogger(__name__)


class TestBootProcess(JumpstarterTest):
    selector = "type=qemu"

    def test_boot(self, client):
        """Test the boot process of the device."""
        log.info("Testing boot process")
        client.power.on()
        
        with client.console.pexpect() as console:
            console.expect_exact("login:", timeout=60)
            console.sendline("root")
            console.expect_exact("Password:", timeout=10)
            console.sendline("password")
            console.expect_exact("]#", timeout=10)

    def test_auto_app(self, client):
        with client.console.pexpect() as console:
            console.sendline("auto-apps")
            console.expect_exact("Hello from AutoSD!", timeout=30)
            print(console.before.decode())

#    @pytest.mark.skip(reason="only enabled to test pipeline failures")
#    def test_fail(self):
#        pytest.fail("failure")
