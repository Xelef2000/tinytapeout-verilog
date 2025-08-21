#!/bin/bash
set -e
set -x

mkdir -p _build

# Synthesis with Yosys, defining the target FPGA
yosys -D ECP5_FPGA -s run_yosys.ys

# Place and Route for a specific ECP5 device
nextpnr-ecp5 --25k --package CABGA256 --ignore-loops --speed 6 --json _build/hardware.json --textcfg _build/hardware.config --report _build/hardware.pnr --lpf top.lpf

# Pack bitstream
ecppack --svf _build/hardware.svf _build/hardware.config _build/hardware.bit

ls -al _build