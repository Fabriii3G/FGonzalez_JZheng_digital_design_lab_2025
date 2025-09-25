transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+C:/Users/snipe/OneDrive/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3 {C:/Users/snipe/OneDrive/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3/lab3_params.sv}
vlog -sv -work work +incdir+C:/Users/snipe/OneDrive/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3 {C:/Users/snipe/OneDrive/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3/pixclk_en.sv}
vlog -sv -work work +incdir+C:/Users/snipe/OneDrive/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3 {C:/Users/snipe/OneDrive/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3/tick_1hz.sv}
vlog -sv -work work +incdir+C:/Users/snipe/OneDrive/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3 {C:/Users/snipe/OneDrive/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3/fsm_memoria.sv}
vlog -sv -work work +incdir+C:/Users/snipe/OneDrive/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3 {C:/Users/snipe/OneDrive/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3/vga_timing_640x480.sv}
vlog -sv -work work +incdir+C:/Users/snipe/OneDrive/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3 {C:/Users/snipe/OneDrive/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3/card_bank.sv}
vlog -sv -work work +incdir+C:/Users/snipe/OneDrive/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3 {C:/Users/snipe/OneDrive/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3/vga_cards.sv}
vlog -sv -work work +incdir+C:/Users/snipe/OneDrive/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3 {C:/Users/snipe/OneDrive/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3/top_lab3_avance.sv}

vlog -sv -work work +incdir+C:/Users/snipe/OneDrive/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3 {C:/Users/snipe/OneDrive/Desktop/FGonzalez_JZheng_digital_design_lab_2025/Laboratorio3/tb_fsm_memoria.sv}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver -L rtl_work -L work -voptargs="+acc"  tb_fsm_memoria

add wave *
view structure
view signals
run -all
