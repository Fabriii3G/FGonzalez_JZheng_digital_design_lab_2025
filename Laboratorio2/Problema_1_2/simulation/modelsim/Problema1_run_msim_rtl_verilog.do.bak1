transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio2/Problema1 {C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio2/Problema1/alu_pkg.sv}
vlog -sv -work work +incdir+C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio2/Problema1 {C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio2/Problema1/sum_res_mul.sv}
vlog -sv -work work +incdir+C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio2/Problema1 {C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio2/Problema1/alu.sv}

vlog -sv -work work +incdir+C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio2/Problema1 {C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio2/Problema1/tb_alu.sv}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver -L rtl_work -L work -voptargs="+acc"  tb_alu

add wave *
view structure
view signals
run -all
