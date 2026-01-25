#!/bin/bash

if [ -z "$1" ]; then
    echo "Error: No project's name found"
    echo "Usage: ./gen_project.sh <project_name>"
    exit 1
fi

PROJECT_NAME=$1

VIVADO_PATH=$(unalias vivado 2>/dev/null; command -v vivado)

if [ -z "$VIVADO_PATH" ]; then
    VIVADO_PATH="$HOME/Data/Vivado/2025.2/Vivado/bin/vivado"
fi
# ----------------------------

# Tao cau truc thu muc
echo "[INFO] Creating directory structure for: ${PROJECT_NAME}"
mkdir -p $PROJECT_NAME/rtl
mkdir -p $PROJECT_NAME/tb
mkdir -p $PROJECT_NAME/sim
mkdir -p $PROJECT_NAME/work

# Khoi tao 2 file dau tien
touch $PROJECT_NAME/rtl/${PROJECT_NAME}_top.v
touch $PROJECT_NAME/tb/${PROJECT_NAME}_tb.v

# create_project.tcl
cat << EOF > $PROJECT_NAME/create_project.tcl
set project_name $PROJECT_NAME
set part_name "xc7z020clg484-1"

set rtl_dir  "../rtl"
set tb_dir   "../tb"
set work_dir "."

create_project -force \$project_name \$work_dir -part \$part_name

add_files [glob -nocomplain \$rtl_dir/*.v]
add_files -fileset sim_1 [glob -nocomplain \$tb_dir/*.v]

update_compile_order -fileset sources_1

puts "Project \$project_name created successfully in [pwd]"
exit
EOF

# Makefile
cat << 'EOF' > $PROJECT_NAME/Makefile
PROJECT_NM = $(shell basename $(CURDIR))
VIVADO = vivado
MODE = -mode batch

.PHONY: all build run sim clean open help

# Default
all: build

# Tao project
create:
	@echo "Creating Vivado Project..."
	cd work && $(VIVADO) $(MODE) -source ../create_project.tcl

# BUILD = Elaborate design
build:
	@echo "Elaborating design (checking syntax)..."
	cd work && $(VIVADO) $(MODE) -source ../tcl/elaborate.tcl

# RUN = Simulation
run:
	@echo "Running simulation..."
	cd work && $(VIVADO) $(MODE) -source ../tcl/sim.tcl

# SIM = waveform GUI
sim:
	@echo "Opening simulation waveform..."
	cd work && $(VIVADO) -mode gui -source ../tcl/sim.tcl

# SYNTH = Synthesis 
synth:
	@echo "Running Synthesis..."
	cd work && $(VIVADO) $(MODE) -source ../tcl/synth.tcl

# IMPL = Implementation
impl:
	@echo "Running Implementation..."
	cd work && $(VIVADO) $(MODE) -source ../tcl/impl.tcl

# Clean
clean:
	@echo "Cleaning up..."
	rm -rf work/.Xil work/xsim.dir work/*.wdb work/*.jou work/*.log
	@echo "Keep project file intact"

# Deep clean 
distclean:
	@echo "Deep cleaning..."
	rm -rf work/*
	rm -f *.log *.jou
	rm -rf .Xil/

# Open GUI
open:
	@echo "Opening Vivado GUI..."
	cd work && $(VIVADO) $(PROJECT_NM).xpr &

# Help
help:
	@echo "RTL Development Workflow:"
	@echo "  make create"
	@echo "  make build"
	@echo "  make run"
	@echo "  make sim"
	@echo ""
	@echo "Synthesis Workflow:"
	@echo "  make synth"
	@echo "  make impl"
	@echo ""
	@echo "Utilities:"
	@echo "  make clean"
	@echo "  make distclean"
	@echo "  make open"
EOF
