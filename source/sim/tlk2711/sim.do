vlib work 
vmap work work 

vlog -incr +acc ../src_code/*.v
vlog -incr +acc ../ip/*/*_sim_netlist.v

vlog ./glbl.v 
vlog ./tlk2711_tb.v 

vsim -voptargs="+acc" +notimingchecks -novopt -L work -L secureip -L unisims_ver -L simprims_ver  work.tlk2711_tb glbl   
   
do wave.do

run -all


