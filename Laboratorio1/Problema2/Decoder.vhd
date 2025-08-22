library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_std.ALL;

entity decoder is
	port(num_bin: in STD_LOGIC_VECTOR (3 downto 0);
	selector : in STD_LOGIC;
	Output : out STD_LOGIC_VECTOR (0 to 6)
	);
end decoder;

architecture ar_decodificador of decoder is
signal output_aux : std_logic_vector (0 to 6);
begin
output_aux <= "0000001" when num_bin="0000" else
				  "1001111" when num_bin="0001" else
				  "0010010" when num_bin="0010" else
				  "0000110" when num_bin="0011" else
				  "1001100" when num_bin="0100" else			  
				  "0100100" when num_bin="0101" else
				  "0100000" when num_bin="0110" else
				  "0001110" when num_bin="0111" else
				  "0000000" when num_bin="1000" else
				  "0000100" when num_bin="1001" else
				  "0001000" when num_bin="1010" else
				  "1100000" when num_bin="1011" else
				  "0110001" when num_bin="1100" else
				  "1000010" when num_bin="1101" else
				  "0110000" when num_bin="1110" else
				  "0111000" when num_bin="1111";
Output <= output_aux when selector = '0' else
not output_aux;

end ar_decodificador;