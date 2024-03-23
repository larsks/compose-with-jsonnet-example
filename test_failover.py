import signal
import requests
import time
import pytest
import subprocess

from contextlib import contextmanager

public_vip = "100.64.64.100"
public_url = f"http://{public_vip}/api"


class Compose:
    """A convenience class for running `docker compose` command lines"""

    def up(self, *services):
        if services is None:
            services = []
        self.run("up", "-d", *services)

    def down(self, *services):
        if services is None:
            services = []
        self.run("down", *services)

    def run(self, *args):
        subprocess.check_call(["docker", "compose"] + list(args))

    @contextmanager
    def bounce(self, *services):
        """A context manager that will bring down services on enter and then bring them
        back up on exit.
        """
        self.down(*services)
        yield
        self.up(*services)


class Timeout:
    """A context manager that uses SIGALRM to implement a timeout."""

    def __init__(self, timeout):
        self.timeout = timeout

    def __enter__(self):
        signal.signal(signal.SIGALRM, self.handler)
        signal.alarm(self.timeout)

    def __exit__(self, *args):
        signal.alarm(0)

    def handler(self, signum, frame):
        signal.signal(signal.SIGALRM, signal.SIG_DFL)
        raise TimeoutError()


@pytest.fixture(scope="session")
def compose():
    return Compose()


@pytest.fixture(scope="session")
def stack(compose):
    compose.up()
    while True:
        try:
            res = requests.get(public_url)
            res.raise_for_status()
        except requests.exceptions.RequestException:
            time.sleep(1)
        else:
            break
    yield
    compose.down()


def wait_for_node_change(initial_node):
    with Timeout(10):
        while True:
            try:
                res = requests.get(public_url)
                new_node = res.json()["hostname"]
                if new_node != initial_node:
                    return new_node
            except requests.exceptions.RequestException:
                pass

            time.sleep(0.5)


def test_backend_failure(compose, stack):
    res = requests.get(public_url)
    assert res.status_code == 200
    initial_node = res.json()["hostname"]
    with compose.bounce(f"{initial_node}-whoami"):
        new_node = wait_for_node_change(initial_node)
    wait_for_node_change(new_node)


def test_haproxy_failure(compose, stack):
    res = requests.get(public_url)
    assert res.status_code == 200
    initial_node = res.json()["hostname"]
    with compose.bounce(f"{initial_node}-haproxy"):
        wait_for_node_change(initial_node)


def test_vrrpd_failure(compose, stack):
    res = requests.get(public_url)
    assert res.status_code == 200
    initial_node = res.json()["hostname"]
    with compose.bounce(f"{initial_node}-vrrpd"):
        wait_for_node_change(initial_node)


def test_node_failure(compose, stack):
    res = requests.get(public_url)
    assert res.status_code == 200
    initial_node = res.json()["hostname"]
    with compose.bounce(initial_node):
        wait_for_node_change(initial_node)
