set BUG_FLAGS "+define+BUG_DATA_CORRUPTION"


if {![file exists work]} {
    vlib work
    vmap work work
}

vlog -sv ../tb/interface/axi4lite_if.sv
vlog -sv +cover $BUG_FLAGS ../rtl/axi4lite_subordinate.sv
vlog -sv ../tb/assertions/axi4lite_assertions.sv
vlog -sv $BUG_FLAGS ../tb/axi4lite_pkg.sv
vlog -sv $BUG_FLAGS ../tb/tb_uvm.sv 


vsim -coverage work.tb_uvm -sv_seed random
add wave /tb_uvm/axiif/*
run -all
coverage save -onexit axi4lite_coverage.ucdb
