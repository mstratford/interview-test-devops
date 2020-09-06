# Automation Test

In this test, I have created a docker image that will serve the static files in the `content` directory on port `8080`.

## Requirements

To run this docker container, you'll need one of these:

- Docker
- Vagrant (and libvirt or virtualbox backend)

## Running

- To run with docker:

If you've got a unix-like system with `make` available, just `make build` to build the docker image and `make run` to run the image.
If you want to stop the container, just `make stop`.

If you don't have make, just copy the commands from the respective `.sh`files for your host OS.

- To run with vagrant:

A vagrantfile has been provided. Just `vagrant up`, it'll start a VM, install docker and run the container.

When you have changed the content, you can `vagrant provision` to re-build the docker container with the new content.

As always, to stop the VM, just `vagrant halt`.

