transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -93 -work work {D:/Lab1.Digitales/FGonzalez_JZheng_digital_design_lab_2025/Fullsub.vhd}
vcom -93 -work work {D:/Lab1.Digitales/FGonzalez_JZheng_digital_design_lab_2025/Fullsub_4bits.vhd}

vcom -93 -work work {D:/Lab1.Digitales/FGonzalez_JZheng_digital_design_lab_2025/Fullsub_4bits_TB.vhd}

vsim -t 1ps -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L cyclonev -L rtl_work -L work -voptargs="+acc"  Fullsub_4bits_TB

add wave *
view structure
view signals
run -all
