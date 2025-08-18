library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Fullsub_TB is
end Fullsub_TB;

architecture Structural of Fullsub_TB is
    -- Declaración del componente bajo prueba
    component FullSub
        port(
            A, B, Cin : in std_logic;
            Cout, Y   : out std_logic
        );
    end component;

    -- Señales internas
    signal A_sig, B_sig, Cin_sig : std_logic := '0';
    signal Cout_sig, Y_sig       : std_logic := '0';

begin
    --Device Under Test
    dut: FullSub port map(
        A    => A_sig,
        B    => B_sig,
        Cin  => Cin_sig,
        Cout => Cout_sig,
        Y    => Y_sig
    );

    -- Estímulos
    A_sig   <= '0' after 20 ns,
               '1' after 40 ns,
               '0' after 60 ns;

    B_sig   <= '0' after 20 ns,
               '0' after 40 ns,
               '1' after 60 ns;

    Cin_sig <= '1' after 20 ns,
               '1' after 40 ns,
               '1' after 60 ns;

end Structural;
