# Reloj de 100 MHz como objetivo (10 ns)
create_clock -name clk -period 10.000 [get_ports clk]

# Reset asíncrono: no cruce de tiempo
set_false_path -from [get_ports rst]

# (Opcional) Si usas otros relojes generados:
# derive_pll_clocks
# derive_clock_uncertainty
