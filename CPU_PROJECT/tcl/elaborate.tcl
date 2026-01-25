# Elaborate design - syntax check without synthesis
set project_name [file tail [file dirname [pwd]]]

open_project ${project_name}.xpr

# Update compile order
update_compile_order -fileset sources_1

puts "========== Elaborating Design =========="

# Elaborate RTL design
synth_design -rtl -name rtl_1

# Check for errors
if {[get_msg_config -count -severity ERROR] > 0} {
    puts "ERROR: Syntax errors found!"
    exit 1
}

# Report hierarchy
report_compile_order -used_in synthesis

puts "SUCCESS: Design elaborated, no syntax errors"
puts "Ready for simulation!"

close_design
close_project
