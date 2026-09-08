#!/bin/false
# BROKEN FIXTURE: .slidev.conf is never read (pre-feature behaviour).
# Proves the "config file is loaded" tests actually detect a regression.

export PLAYWRIGHT_IMAGE="${PLAYWRIGHT_IMAGE:-mcr.microsoft.com/playwright:v1.57.0-noble}"
