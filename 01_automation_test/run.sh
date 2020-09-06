#!/bin/bash
echo "*** Killing any exisiting running container."
docker kill web
echo "*** Running docker container webserver on port 8080."
docker run -it --rm -d -p 8080:80 --name web webserver
