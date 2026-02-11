#!/bin/bash
# Guess who was stuck troubleshooting an issue because stubborn systemd kept a cache with wrong image value? Me!
# This is just in case something similar happens. It can also get version tag stuck and will launch the old version despite it saying it will launch "latest". Dumb issue.
sudo rm -rf /run/systemd/generator/*
sudo systemctl daemon-reexec
