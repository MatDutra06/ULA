library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ula is
  port (a, b : in std_logic_vector(3 downto 0);
        op : in std_logic_vector(2 downto 0);
        result : out std_logic_vector(3 downto 0);
        z, n, c, v : out std_logic);
end entity;

architecture combinational of ula is
begin
  process(a, b, op)
    variable r : std_logic_vector(3 downto 0);
    variable ext : unsigned(4 downto 0);
    variable carry_flag, overflow_flag : std_logic;
    variable rhs : std_logic_vector(3 downto 0);
  begin
    r := (others => '0');
    ext := (others => '0');
    carry_flag := '0'; overflow_flag := '0';
    rhs := b;
    case op is
      when "000" | "001" | "110" | "111" =>
        -- Arithmetic is performed modulo 16.
        if op = "110" or op = "111" then
          rhs := "0001";
        end if;
        if op = "000" or op = "110" then
          ext := ('0' & unsigned(a)) + ('0' & unsigned(rhs));
          r := std_logic_vector(ext(3 downto 0));
          carry_flag := ext(4);
          overflow_flag := (not (a(3) xor rhs(3))) and (a(3) xor r(3));
        else
          -- Carry=1 means no borrow on subtraction.
          ext := ('0' & unsigned(a)) + ('0' & unsigned(not rhs)) + to_unsigned(1, 5);
          r := std_logic_vector(ext(3 downto 0));
          carry_flag := ext(4);
          overflow_flag := (a(3) xor rhs(3)) and (a(3) xor r(3));
        end if;
      when "010" => r := a and b;
      when "011" => r := a or b;
      when "100" => r := a xor b;
      when "101" => r := not a;
      when others => r := (others => '0');
    end case;
    result <= r;
    if r = "0000" then z <= '1'; else z <= '0'; end if;
    n <= r(3);
    c <= carry_flag;
    v <= overflow_flag;
  end process;
end architecture;
