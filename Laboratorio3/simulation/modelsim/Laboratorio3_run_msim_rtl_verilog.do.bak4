transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3 {C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3/lab3_params.sv}
vlog -sv -work work +incdir+C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3 {C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3/tick_1hz.sv}
vlog -sv -work work +incdir+C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3 {C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3/vgaController.sv}
vlog -sv -work work +incdir+C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3 {C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3/gen_pixclk.sv}
vlog -sv -work work +incdir+C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3 {C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3/timer_15s.sv}
vlog -sv -work work +incdir+C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3 {C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3/bcd7seg.sv}
vlog -sv -work work +incdir+C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3 {C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3/btn_onepulse.sv}
vlog -sv -work work +incdir+C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3 {C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3/tick_20hz.sv}
vlog -sv -work work +incdir+C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3 {C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3/fsm_control.sv}
vlog -sv -work work +incdir+C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3 {C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3/vga_cards.sv}
vlog -sv -work work +incdir+C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3 {C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3/fsm_memoria.sv}
vlog -sv -work work +incdir+C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3 {C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3/vga_top_libro.sv}
vlog -sv -work work +incdir+C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3 {C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3/videoGen.sv}
vlog -sv -work work +incdir+C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3 {C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3/game_datapath.sv}

vlog -sv -work work +incdir+C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3 {C:/Users/snipe/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3/tb_fsm_control.sv}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver -L rtl_work -L work -voptargs="+acc"  tb_fsm_control

add wave *
view structure
view signals
run -all
