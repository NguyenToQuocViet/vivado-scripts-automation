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
