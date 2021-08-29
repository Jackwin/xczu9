set this_dir "."
# Set the project name
set proj_name "xczu9"
set device_value "xczu9eg-ffvb1156-2-i"

# Create project
create_project ${proj_name} ./${proj_name} -force -part $device_value

# Rebuild user ip_repo's index before adding any source files
update_ip_catalog -rebuild

set source_path ../source
set constr_path $source_path/constr
set rtl_path $source_path/src
set ip_path $source_path/ip
set sim_path $source_path/sim

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set user IP repository paths
set obj [get_filesets sources_1]
set_property "ip_repo_paths" "[file normalize "$ip_path/fpga_mgt_v1.0"]" $obj

# Set project properties

set obj [get_projects $proj_name]
set_property target_language verilog [current_project]
set_property default_lib work [current_project]

set rtlFiles [list \
    [file normalize "${rtl_path}/tlk2711/reg_mgt.v"] \
    [file normalize "${rtl_path}/reset_bridge.v"] \
    [file normalize "${rtl_path}/tlk2711/tlk2711_dma.v"] \
    [file normalize "${rtl_path}/tlk2711/tlk2711_rx_link.v"] \
    [file normalize "${rtl_path}/tlk2711/tlk2711_top.v"] \
    [file normalize "${rtl_path}/tlk2711/tlk2711_tx_cmd.v"] \
    [file normalize "${rtl_path}/tlk2711/tlk2711_tx_data.v"] \
    [file normalize "${rtl_path}/top.v"] \
    [file normalize "${rtl_path}/tlk2711_test/tlk2711.sv"] \
    [file normalize "${rtl_path}/emmc_iobuf.v"] \
]
set ipFiles [list \
    [file normalize "${ip_path}/clk_wiz_0/clk_wiz_0.xci"] \
    [file normalize "${ip_path}/vio_tlk2711_debug/vio_tlk2711_debug.xci"] \
    [file normalize "${ip_path}/ila_2711_rx/ila_2711_rx.xci"] \
    [file normalize "${ip_path}/ila_0/ila_0.xci"] \
    [file normalize "${ip_path}/vio_tlk2711/vio_tlk2711.xci"] \
]
# set RTL and ip files
set obj [get_filesets sources_1]
add_files -norecurse -fileset $obj $rtlFiles
add_files -norecurse -fileset $obj $ipFiles

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

set constrFile "$constr_path/package.xdc"
set constrFile "$constr_path/tlk2711.xdc"

add_files -norecurse -fileset $obj $constrFile

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "top" -objects $obj
set_property -name "top_auto_set" -value "0" -objects $obj

update_compile_order -fileset sources_1

