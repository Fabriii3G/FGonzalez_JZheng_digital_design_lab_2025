library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity FullSub is
    port(
        A, B, Cin : in std_logic;
        Cout, Y   : out std_logic
    );
end FullSub;

architecture Structural of FullSub is
    -- Señales internas
    signal AxorB, AxorBxorCin : std_logic;
    signal notA, term1, term2, term3 : std_logic;
begin
    -- XOR intermedio
    AxorB <= A xor B;
    Y     <= AxorB xor Cin;

    -- NOT de A
    notA <= not A;

    -- Términos de la ecuación de Cout
    term1 <= notA and B;
    term2 <= notA and Cin;
    term3 <= B and Cin;

    -- Salida Cout
    Cout <= term1 or term2 or term3;

end Structural;
