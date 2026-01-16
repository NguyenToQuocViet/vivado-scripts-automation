
PROJECT_NM = CPU_PROJECT
VIVADO = /home/quocviet/Data/Vivado/2025.2/Vivado/bin/vivado
MODE = -mode batch

.PHONY: all create clean open

all: create

create:
	@echo "Building Vivado Project..."
	cd work && $(VIVADO) $(MODE) -source ../create_project.tcl

open:
	@echo "Opening Vivado GUI..."
	cd work && $(VIVADO) $(PROJECT_NM).xpr & 

clean:
	@echo "Cleaning up..."
	rm -rf work/*
	rm -f *.log *.jou 
	rm -rf .Xil
