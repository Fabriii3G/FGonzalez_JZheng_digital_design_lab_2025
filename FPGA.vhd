library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity FPGA is
    port(
        SW    : in  std_logic_vector(9 downto 0);   -- switches (A, B, Cin)
        KEY   : in  std_logic_vector(0 downto 0);   -- KEY0 = botón enter
        HEX0  : out std_logic_vector(6 downto 0);   -- resultado Y
        HEX1  : out std_logic_vector(6 downto 0);   -- en blanco
        HEX2  : out std_logic_vector(6 downto 0);   -- B
        HEX3  : out std_logic_vector(6 downto 0);   -- A
        LEDR  : out std_logic_vector(0 downto 0)    -- Cout
    );
end FPGA;

architecture Structural of FPGA is
    -- Señales internas
    signal A, B, Y : std_logic_vector(3 downto 0);
    signal A_reg, B_reg : std_logic_vector(3 downto 0);
    signal Cin, Cin_reg, Cout : std_logic;

    -- Componentes
    component Fullsub_4bits
        port (
            A1, B1 : in  std_logic_vector(3 downto 0);
            Cin1   : in  std_logic;
            Cout1  : out std_logic;
            Y1     : out std_logic_vector(3 downto 0)
        );
    end component;

    component Hex7Seg
        port(
            N   : in  std_logic_vector(3 downto 0);
            HEX : out std_logic_vector(6 downto 0)
        );
    end component;

begin
    -- Conexión directa de switches
    A   <= SW(3 downto 0);
    B   <= SW(7 downto 4);
    Cin <= SW(8);

    -- Registro controlado por KEY0 (activo en 0 en DE10-Standard)
    process(KEY(0))
    begin
        if falling_edge(KEY(0)) then
            A_reg   <= A;
            B_reg   <= B;
            Cin_reg <= Cin;
        end if;
    end process;

    -- DUT (usa valores registrados)
    U_SUB: Fullsub_4bits
        port map(
            A1    => A_reg,
            B1    => B_reg,
            Cin1  => Cin_reg,
            Cout1 => Cout,
            Y1    => Y
        );

    -- Decodificadores a 7 segmentos
    U_HEX_Y : Hex7Seg port map(N => Y, HEX => HEX0);
    U_HEX_B : Hex7Seg port map(N => B_reg, HEX => HEX2);
    U_HEX_A : Hex7Seg port map(N => A_reg, HEX => HEX3);

    -- HEX1 en blanco (activo bajo, todos en '1')
    HEX1 <= (others => '1');

    -- Cout en LED0
    LEDR(0) <= Cout;

end Structural;
