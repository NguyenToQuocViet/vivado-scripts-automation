#!/bin/bash

# ================================
# Vivado Project Generator
# Supports: SystemVerilog, TCL-based workflow, RTL development
# ================================

if [ -z "$1" ]; then
    echo "Error: No project name provided"
    echo "Usage: ./gen_project.sh <project_name>"
    exit 1
fi

PROJECT_NAME=$1

# Detect Vivado path
VIVADO_PATH=$(unalias vivado 2>/dev/null; command -v vivado)

if [ -z "$VIVADO_PATH" ]; then
    VIVADO_PATH="$HOME/Data/Vivado/2025.2/Vivado/bin/vivado"
fi

# ================================
# Create directory structure
# ================================
echo "[INFO] Creating directory structure for: ${PROJECT_NAME}"
mkdir -p $PROJECT_NAME/rtl
mkdir -p $PROJECT_NAME/tb
mkdir -p $PROJECT_NAME/sim
mkdir -p $PROJECT_NAME/work
mkdir -p $PROJECT_NAME/tcl
mkdir -p $PROJECT_NAME/constrs

# Create initial SystemVerilog files
touch $PROJECT_NAME/rtl/${PROJECT_NAME}_top.sv
touch $PROJECT_NAME/tb/${PROJECT_NAME}_tb.sv

# ================================
# Generate create_project.tcl
# ================================
cat << 'EOF' > $PROJECT_NAME/create_project.tcl
# Project creation script
set project_name [lindex $::argv 0]
set part_name "xc7z020clg484-1"

set rtl_dir    "../rtl"
set tb_dir     "../tb"
set work_dir   "."

# Create project
create_project -force $project_name $work_dir -part $part_name

# Add RTL files (both .v and .sv)
set rtl_files [concat [glob -nocomplain ${rtl_dir}/*.v] [glob -nocomplain ${rtl_dir}/*.sv]]
if {[llength $rtl_files] > 0} {
    add_files $rtl_files
}

# Add testbench files
set tb_files [concat [glob -nocomplain ${tb_dir}/*.v] [glob -nocomplain ${tb_dir}/*.sv]]
if {[llength $tb_files] > 0} {
    add_files -fileset sim_1 $tb_files
}

# Set SystemVerilog file type for .sv files
foreach file [get_files *.sv] {
    set_property file_type SystemVerilog $file
}

# Update compile order
update_compile_order -fileset sources_1

puts "Project $project_name created successfully"
exit
EOF

# Inject project name into TCL
sed -i "1i# Auto-generated for project: $PROJECT_NAME" $PROJECT_NAME/create_project.tcl

# ================================
# Generate tcl/elaborate.tcl
# ================================
cat << 'EOF' > $PROJECT_NAME/tcl/elaborate.tcl
# Elaboration script (Syntax check)
set project_name [file tail [file dirname [pwd]]]

# Mở project đã được tạo từ lệnh 'make create'
open_project ${project_name}.xpr

puts "========== Running Elaboration (Syntax Check) =========="
# Cờ -rtl chỉ đạo Vivado vẽ sơ đồ khối và check syntax, không tổng hợp cổng logic
synth_design -rtl -name rtl_1

puts "SUCCESS: Elaboration completed. Check logs for any syntax errors."
close_design
close_project
EOF

# ================================
# Generate tcl/lint.tcl
# ================================
cat << 'EOF' > $PROJECT_NAME/tcl/lint.tcl
# RTL Linting script using Vivado
set project_name [file tail [file dirname [pwd]]]
open_project ${project_name}.xpr

# Create reports directory if not exists
file mkdir reports

puts "========== Running RTL Linting (Check Synthesizability) =========="

# Chạy Elaboration với chế độ phân tích logic sâu
synth_design -rtl -name rtl_lint

# 1. Kiểm tra Latch - "Kẻ thù" của thiết kế RTL
set latches [get_cells -hierarchical -filter { IS_LATCH == "TRUE" }]
if {[llength $latches] > 0} {
    puts "CRITICAL WARNING: Latches detected in design: $latches"
} else {
    puts "SUCCESS: No latches detected."
}

# 2. Kiểm tra các quy tắc thiết kế (Methodology)
report_methodology -file reports/lint_methodology.txt
puts "Methodology report generated: work/reports/lint_methodology.txt"

# 3. Kiểm tra các tín hiệu không được sử dụng hoặc lơ lửng
report_drc -checks {HDRC-1} -file reports/lint_drc.txt

close_design
close_project
EOF

# ================================
# Generate tcl/sim.tcl
# ================================
cat << 'EOF' > $PROJECT_NAME/tcl/sim.tcl
# Simulation script
set project_name [file tail [file dirname [pwd]]]

open_project ${project_name}.xpr

# Set simulation runtime (run all)
set_property -name {xsim.simulate.runtime} -value {-all} -objects [get_filesets sim_1]

# Launch simulation
puts "========== Launching Simulation =========="
launch_simulation

# Run simulation
run all

puts "SUCCESS: Simulation completed"

# Keep GUI open if in GUI mode
if {[string match "*gui*" $rdi::mode]} {
    puts "Waveform window opened. Close manually when done."
} else {
    close_sim
    close_project
}
EOF

# ================================
# Generate tcl/synth.tcl
# ================================
cat << 'EOF' > $PROJECT_NAME/tcl/synth.tcl
# Synthesis script
set project_name [file tail [file dirname [pwd]]]

open_project ${project_name}.xpr

# Create reports directory
file mkdir reports

# Run synthesis
puts "========== Running Synthesis =========="
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Check result
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "ERROR: Synthesis failed!"
    exit 1
}

# Generate reports
open_run synth_1
report_utilization -file reports/utilization_synth.txt
report_timing_summary -file reports/timing_synth.txt

puts "SUCCESS: Synthesis completed"
puts "Reports: work/reports/"

close_project
EOF

# ================================
# Generate tcl/impl.tcl
# ================================
cat << 'EOF' > $PROJECT_NAME/tcl/impl.tcl
# Implementation script
set project_name [file tail [file dirname [pwd]]]

open_project ${project_name}.xpr

# Create reports directory
file mkdir reports

# Run implementation
puts "========== Running Implementation =========="
reset_run impl_1
launch_runs impl_1 -jobs 4
wait_on_run impl_1

# Check result
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "ERROR: Implementation failed!"
    exit 1
}

# Generate reports
open_run impl_1
report_utilization -file reports/utilization_impl.txt
report_timing_summary -file reports/timing_impl.txt
report_power -file reports/power.txt

puts "SUCCESS: Implementation completed"
puts "Reports: work/reports/"

close_project
EOF

# ================================
# Generate Makefile
# ================================
cat << 'EOF' > $PROJECT_NAME/Makefile
# Makefile for Vivado TCL workflow
PROJECT_NM = $(shell basename $(CURDIR))
VIVADO = vivado
MODE = -mode batch

.PHONY: all create build lint run sim synth impl clean distclean open help

# Default target
all: build

# Create project
create:
	@echo "Creating Vivado Project..."
	cd work && $(VIVADO) $(MODE) -source ../create_project.tcl -tclargs $(PROJECT_NM)

# Elaborate design (syntax check)
build:
	@echo "Elaborating design (checking syntax)..."
	cd work && $(VIVADO) $(MODE) -source ../tcl/elaborate.tcl

# Linting (Check synthesizability and quality)
lint:
	@echo "Running RTL Linting..."
	cd work && $(VIVADO) $(MODE) -source ../tcl/lint.tcl

# Run simulation (batch mode)
run:
	@echo "Running simulation..."
	cd work && $(VIVADO) $(MODE) -source ../tcl/sim.tcl

# Simulation with waveform GUI
sim:
	@echo "Opening simulation waveform..."
	cd work && $(VIVADO) -mode gui -source ../tcl/sim.tcl

# Synthesis
synth:
	@echo "Running Synthesis..."
	cd work && $(VIVADO) $(MODE) -source ../tcl/synth.tcl

# Implementation
impl:
	@echo "Running Implementation..."
	cd work && $(VIVADO) $(MODE) -source ../tcl/impl.tcl

# Clean simulation files
clean:
	@echo "Cleaning simulation files..."
	@rm -rf work/.Xil work/xsim.dir work/*.wdb work/*.jou work/*.log 2>/dev/null || true
	@echo "Project files kept intact"

# Deep clean (remove everything)
distclean:
	@echo "Deep cleaning..."
	@rm -rf work/* *.log *.jou .Xil/ 2>/dev/null || true

# Open Vivado GUI
open:
	@echo "Opening Vivado GUI..."
	cd work && $(VIVADO) $(PROJECT_NM).xpr &

# Help menu
help:
	@echo "=========================================="
	@echo "RTL Development Workflow:"
	@echo "  make create    - Create new Vivado project"
	@echo "  make build     - Elaborate design (check syntax)"
	@echo "  make lint      - RTL Linting (check latches & quality)"
	@echo "  make run       - Run simulation (batch mode)"
	@echo "  make sim       - Open simulation waveform GUI"
	@echo ""
	@echo "Synthesis & Implementation:"
	@echo "  make synth     - Run synthesis & generate reports"
	@echo "  make impl      - Run implementation & timing analysis"
	@echo ""
	@echo "Utilities:"
	@echo "  make clean     - Clean simulation junk files"
	@echo "  make distclean - Deep clean (remove work directory)"
	@echo "  make open      - Open Vivado Project GUI"
	@echo "=========================================="
EOF

# ================================
# Generate SystemVerilog templates
# ================================

# RTL top module template
cat << EOF > $PROJECT_NAME/rtl/${PROJECT_NAME}_top.sv
\`timescale 1ns / 1ps

module ${PROJECT_NAME}_top (
    input  logic clk,
    input  logic rst_n,
    // Add your ports here
    output logic [31:0] data_out
);

    // Your design logic here

endmodule
EOF

# Testbench template
cat << EOF > $PROJECT_NAME/tb/${PROJECT_NAME}_tb.sv
\`timescale 1ns / 1ps

module ${PROJECT_NAME}_tb;

    // Clock and reset
    logic clk;
    logic rst_n;
    logic [31:0] data_out;

    // Clock generation (100MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // DUT instantiation
    ${PROJECT_NAME}_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_out(data_out)
    );

    // Test sequence
    initial begin
        \$display("========== Test Start ==========");
        
        // Reset sequence
        rst_n = 0;
        #20;
        rst_n = 1;
        #10;
        
        // Add your test cases here
        
        // End simulation
        #1000;
        \$display("========== Test Completed ==========");
        \$finish;
    end

    // Waveform dump (optional)
    initial begin
        \$dumpfile("${PROJECT_NAME}_tb.vcd");
        \$dumpvars(0, ${PROJECT_NAME}_tb);
    end

endmodule
EOF

echo ""
echo "=========================================="
echo "[SUCCESS] Project '$PROJECT_NAME' created!"
echo "=========================================="
echo ""
echo "Quick Start:"
echo "  cd $PROJECT_NAME"
echo "  make create       # Create Vivado project"
echo "  make build        # Check syntax"
echo "  make run          # Run simulation"
echo ""
echo "Workflow:"
echo "  1. Edit rtl/*.sv  # Write your RTL code"
echo "  2. make build     # Check syntax"
echo "  3. Edit tb/*.sv   # Write testbench"
echo "  4. make run       # Run simulation"
echo "  5. make sim       # View waveform"
echo ""
echo "Type 'make help' for more commands"
echo "=========================================="
