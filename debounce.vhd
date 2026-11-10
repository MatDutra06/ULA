library ieee;
use ieee.std_logic_1164.all;

entity debounce is
  generic (STABLE_CYCLES : positive := 500000);
  port (clk : in std_logic; rst : in std_logic; btn : in std_logic;
        pulse : out std_logic);
end entity;

architecture rtl of debounce is
  signal sync1, sync2 : std_logic := '0';
  signal stable : std_logic := '0';
  signal count : natural range 0 to STABLE_CYCLES-1 := 0;
  signal pulse_r : std_logic := '0';
begin
  pulse <= pulse_r;
  process(clk, rst)
  begin
    if rst = '1' then
      sync1 <= '0'; sync2 <= '0'; stable <= '0';
      count <= 0; pulse_r <= '0';
    elsif rising_edge(clk) then
      -- Synchronize the asynchronous button input.
      sync1 <= btn;
      sync2 <= sync1;
      pulse_r <= '0';
      if sync2 = stable then
        count <= 0;
      elsif count = STABLE_CYCLES-1 then
        -- Accept a change only after a stable interval.
        stable <= sync2;
        count <= 0;
        if sync2 = '1' then
          pulse_r <= '1';
        end if;
      else
        count <= count + 1;
      end if;
    end if;
  end process;
end architecture;
