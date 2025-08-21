library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Fullsub_4bits_TB is
end Fullsub_4bits_TB;

architecture Structural of Fullsub_4bits_TB is
    component Fullsub_4bits
        port (
            A1, B1 : in  std_logic_vector(3 downto 0);
            Cin1   : in  std_logic;
            Cout1  : out std_logic;
            Y1     : out std_logic_vector(3 downto 0)
        );
    end component;

    -- Señales de prueba
    signal A1   : std_logic_vector(3 downto 0) := (others => '0');
    signal B1   : std_logic_vector(3 downto 0) := (others => '0');
    signal Cin1 : std_logic := '0';
    signal Cout1: std_logic;
    signal Y1   : std_logic_vector(3 downto 0);

begin
    uut: Fullsub_4bits port map(
        A1    => A1,
        B1    => B1,
        Cin1  => Cin1,
        Cout1 => Cout1,
        Y1    => Y1
    );

    A1 <= "0000",
          "1010" after 20 ns,
          "1110" after 40 ns,
          "1011" after 60 ns,
          "1110" after 80 ns;

    B1 <= "0000",
          "1000" after 20 ns,
          "1000" after 40 ns,
          "1001" after 60 ns,
          "1011" after 80 ns;

    Cin1 <= '0',
            '0' after 20 ns,
            '0' after 40 ns,
            '0' after 60 ns,
            '0' after 80 ns;

end Structural;
