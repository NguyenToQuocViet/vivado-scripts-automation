#!/bin/bash

if [ -z "$1" ]; then
    echo "Error: Chua nhap ten du an"
    echo "Usage: ./gen_project.sh <project_name>"
    exit 1
fi

PROJECT_NAME=$1

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
cat << EOF > $PROJECT_NAME/Makefile

PROJECT_NM = $PROJECT_NAME
VIVADO = vivado
MODE = -mode batch

.PHONY: all create clean open

all: create

create:
	@echo "Building Vivado Project..."
	cd work && \$(VIVADO) \$(MODE) -source ../create_project.tcl

open:
	@echo "Opening Vivado GUI..."
	cd work && \$(VIVADO) \$(PROJECT_NM).xpr & 

clean:
	@echo "Cleaning up..."
	rm -rf work/*
	rm -f *.log *.jou 
	rm -rf .Xil
EOF

echo "[SUCCESS] Project '$PROJECT_NAME' đã sẵn sàng!"
echo "Run: cd $PROJECT_NAME && make create"
