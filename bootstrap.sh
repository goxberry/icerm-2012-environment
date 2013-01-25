#!/bin/sh

# Import Git submodules needed for Vagrant startup
git submodule init
git submodule update

# Boot up and provision environment
vagrant up

# Ensure all packages up-to-date
vagrant provision