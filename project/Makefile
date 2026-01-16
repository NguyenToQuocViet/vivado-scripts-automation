
PROJECT_NM = project
VIVADO = vivado
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
