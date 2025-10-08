library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity Problema2 is
end Problema2;

architecture Behavioral of Problema2 is
    -- Declaración del componente exactamente igual a la entity original
    component FullSub
        port (
            A, B, Cin : in std_logic;
            Cout, Y   : out std_logic
        );
    end component;

    -- Señales de prueba
    signal A, B, Cin : std_logic := '0';
    signal Cout, Y   : std_logic;

begin
    -- Instancia del DUT (Device Under Test)
    dut: FullSub port map(
        A    => A,
        B    => B,
        Cin  => Cin,
        Cout => Cout,
        Y    => Y
    );

    -- Estímulos
    process
    begin
        A   <= '0' after 20 ns, '1' after 40 ns, '0' after 60 ns;
        B   <= '0' after 20 ns, '0' after 40 ns, '1' after 60 ns;
        Cin <= '1' after 20 ns, '1' after 40 ns, '1' after 60 ns;
        wait;
    end process;

end Behavioral;
