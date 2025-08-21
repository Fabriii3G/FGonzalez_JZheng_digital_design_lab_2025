library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Fullsub_4bits is
    port (
        A1, B1 : in  std_logic_vector(3 downto 0);
        Cin1   : in  std_logic;
        Cout1  : out std_logic;
        Y1     : out std_logic_vector(3 downto 0)
    );
end Fullsub_4bits;

architecture Structural of Fullsub_4bits is
    -- Declaración del componente de 1 bit
    component FullSub
        port(
            A, B, Cin : in std_logic;
            Cout, Y   : out std_logic
        );
    end component;

    -- Señales internas para los acarreos (préstamos)
    signal C: std_logic_vector(3 downto 1);

begin
    -- Restador bit 0 (LSB)
    FS0: FullSub port map(
        A    => A1(0),
        B    => B1(0),
        Cin  => Cin1,
        Cout => C(1),
        Y    => Y1(0)
    );

    -- Restador bit 1
    FS1: FullSub port map(
        A    => A1(1),
        B    => B1(1),
        Cin  => C(1),
        Cout => C(2),
        Y    => Y1(1)
    );

    -- Restador bit 2
    FS2: FullSub port map(
        A    => A1(2),
        B    => B1(2),
        Cin  => C(2),
        Cout => C(3),
        Y    => Y1(2)
    );

    -- Restador bit 3 (MSB)
    FS3: FullSub port map(
        A    => A1(3),
        B    => B1(3),
        Cin  => C(3),
        Cout => Cout1,
        Y    => Y1(3)
    );

end Structural;
