library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity FPGA is
    port(
        SW    : in  std_logic_vector(9 downto 0);   -- switches (A y B)
        KEY   : in  std_logic_vector(3 downto 0);   -- botones (KEY3 es la señal de resta)
        HEX0  : out std_logic_vector(6 downto 0)    -- display de 7 segmentos
    );
end FPGA;

architecture Structural of FPGA is

    -- Señales internas
    signal A, B : std_logic_vector(3 downto 0);
    signal Cin  : std_logic := '0';   -- Cin = 0
    signal Cout : std_logic;
    signal Y    : std_logic_vector(3 downto 0);
    signal Y_latched : std_logic_vector(3 downto 0);

    -- Instancia del restador de 4 bits
    component Fullsub_4bits
        port (
            A1, B1 : in  std_logic_vector(3 downto 0);
            Cin1   : in  std_logic;
            Cout1  : out std_logic;
            Y1     : out std_logic_vector(3 downto 0)
        );
    end component;

begin

    -- Mapeo de switches a entradas
    A <= SW(9 downto 6);  -- A = SW9..SW6
    B <= SW(5 downto 2);  -- B = SW5..SW2

    -- Instancia del restador de 4 bits
    U1: Fullsub_4bits port map(
        A1   => A,
        B1   => B,
        Cin1 => Cin,
        Cout1 => Cout,
        Y1   => Y
    );

    -- El botón KEY3 sirve para "capturar" el resultado
    process(KEY(3))
    begin
        if falling_edge(KEY(3)) then
            Y_latched <= Y;  -- almacena el resultado cuando presiono el botón
        end if;
    end process;
    -- Decoder 7 segmentos (HEX0)
    process(Y_latched)
    begin
        case Y_latched is
            when "0000" => HEX0 <= "1000000"; -- 0
            when "0001" => HEX0 <= "1111001"; -- 1
            when "0010" => HEX0 <= "0100100"; -- 2
            when "0011" => HEX0 <= "0110000"; -- 3
            when "0100" => HEX0 <= "0011001"; -- 4
            when "0101" => HEX0 <= "0010010"; -- 5
            when "0110" => HEX0 <= "0000010"; -- 6
            when "0111" => HEX0 <= "1111000"; -- 7
            when "1000" => HEX0 <= "0000000"; -- 8
            when "1001" => HEX0 <= "0010000"; -- 9
            when "1010" => HEX0 <= "0001000"; -- A
            when "1011" => HEX0 <= "0000011"; -- b
            when "1100" => HEX0 <= "1000110"; -- C
            when "1101" => HEX0 <= "1000010"; -- d
            when "1110" => HEX0 <= "0000110"; -- E
            when "1111" => HEX0 <= "0001110"; -- F
            when others => HEX0 <= "1111111"; -- apagado
        end case;
    end process;

end Structural;
