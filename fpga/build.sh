#!/bin/bash
set -e
set -x

mkdir -p _build

# Synthesis with Yosys
yosys -s run_yosys.ys

# Place and route with nextpnr-himbaechel for GW2A-18C
nextpnr-himbaechel --json _build/hardware.json \
                   --write _build/hardware_pnr.json \
                   --device GW2A-LV18PG256C8/I7 \
                   --vopt cst=top.cst \
                   --vopt family=GW2A-18C \
                   --report _build/hardware.pnr \
                   --top top 

# Pack bitstream with Gowin tools
gowin_pack -d GW2A-18C -o _build/hardware.fs _build/hardware_pnr.json

ls -al _build

echo "Build complete! Use openFPGALoader or Gowin Programmer to flash _build/hardware.fs"