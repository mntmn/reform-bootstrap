#!/bin/bash

mount -t debugfs none /sys/kernel/debug

# or gadget
echo host > /sys/kernel/debug/ci_hdrc.0/role
