set project_name test
set part_name "xc7z020clg484-1"

set rtl_dir  "../rtl"
set tb_dir   "../tb"
set work_dir "."

create_project -force $project_name $work_dir -part $part_name

add_files [glob -nocomplain $rtl_dir/*.v]
add_files -fileset sim_1 [glob -nocomplain $tb_dir/*.v]

update_compile_order -fileset sources_1

puts "Project $project_name created successfully in [pwd]"
exit
