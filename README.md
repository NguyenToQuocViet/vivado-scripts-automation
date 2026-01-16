# Vivado Scripts Automation

A collection of automation scripts and utilities for EDA workflows, RTL design, and hardware development.

## 🚀 Features

- **Automated Scaffolding**: Create a standardized directory structure (`rtl/`, `tb/`, `sim/`, `work/`) in one command.
- **Workflow Orchestration**: Integrated `Makefile` to handle Vivado project creation and GUI launching in batch mode.
- **TCL Integration**: Uses TCL scripts to automate source file management and project settings.

## 🛠 Prerequisites

- **Vivado Design Suite** (Tested on v2025.2)
- **Linux/Unix Environment** (Zsh or Bash)
- **GNU Make**

## 📖 How to Use

### 1. Generate a New Project
Run the generator script with your project name:
```bash
./gen_project.sh <project_name>
