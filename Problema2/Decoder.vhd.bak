library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Hex7Seg is
    port(
        N   : in  std_logic_vector(3 downto 0);
        HEX : out std_logic_vector(6 downto 0)  -- {g,f,e,d,c,b,a}, activo en bajo
    );
end Hex7Seg;

architecture Structural of Hex7Seg is
    -- Señales intermedias (una por segmento)
    signal seg_a, seg_b, seg_c, seg_d, seg_e, seg_f, seg_g : std_logic;
begin
    -- Segmento a
    seg_a <= (not N(3) and not N(2) and not N(1) and N(0)) or
             (not N(3) and N(2) and not N(1) and not N(0)) or
             (N(3) and not N(2) and N(1) and N(0)) or
             (N(3) and N(2) and not N(1) and N(0));

    -- Segmento b
    seg_b <= (not N(3) and N(2) and not N(1) and N(0)) or
             (N(2) and N(1) and not N(0)) or
             (N(3) and N(1) and N(0)) or
             (N(3) and N(2) and not N(0));

    -- Segmento c
    seg_c <= (not N(3) and not N(2) and N(1) and not N(0)) or
             (N(3) and N(2) and not N(0)) or
             (N(3) and N(2) and N(1));

    -- Segmento d
    seg_d <= (not N(3) and not N(2) and not N(1) and N(0)) or
             (not N(3) and N(2) and not N(1) and not N(0)) or
             (N(2) and N(1) and N(0)) or
             (N(3) and not N(2) and N(1) and not N(0));

    -- Segmento e
    seg_e <= (not N(3) and N(0)) or
             (not N(3) and N(2) and not N(1)) or
             (not N(2) and not N(1) and N(0));

    -- Segmento f
    seg_f <= (not N(3) and not N(2) and N(0)) or
             (not N(3) and not N(2) and N(1)) or
             (not N(3) and N(1) and N(0)) or
             (N(3) and N(2) and not N(1) and N(0));

    -- Segmento g
    seg_g <= (not N(3) and not N(2) and not N(1)) or
             (not N(3) and N(2) and N(1) and N(0)) or
             (N(3) and N(2) and not N(1) and not N(0));

    -- Salida activa en bajo
    HEX <= (not seg_g) & (not seg_f) & (not seg_e) &
           (not seg_d) & (not seg_c) & (not seg_b) & (not seg_a);

end Structural;
