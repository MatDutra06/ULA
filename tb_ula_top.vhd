library ieee;
use ieee.std_logic_1164.all;

entity tb_ula_top is end entity;
architecture sim of tb_ula_top is
  signal clk : std_logic := '0';
  signal rst, btn : std_logic := '0';
  signal sw, leds : std_logic_vector(3 downto 0) := (others => '0');
  signal z, n, c, v : std_logic;
begin
  clk <= not clk after 10 ns; -- 50 MHz test clock.
  dut : entity work.ula_top
    generic map (DEBOUNCE_CYCLES => 3)
    port map (clk => clk, reset_btn => rst, confirm_btn => btn,
              sw => sw, led_result => leds, led_zero => z,
              led_negative => n, led_carry => c, led_overflow => v);
  process
    procedure press_button is
    begin
      btn <= '1'; wait for 200 ns;
      btn <= '0'; wait for 200 ns;
    end procedure;
  begin
    rst <= '1'; wait for 80 ns; rst <= '0'; wait for 100 ns;
    -- Signed overflow: 7 + 3 = -6 in four bits.
    sw <= "0000"; press_button;
    sw <= "0111"; press_button;
    sw <= "0011"; press_button;
    wait for 50 ns;
    assert leds = "1010" and z = '0' and n = '1' and c = '0' and v = '1'
      report "Addition test failed" severity error;
    press_button; -- Return to operation selection.
    -- Subtraction: 2 - 2 = 0, with no borrow.
    sw <= "0001"; press_button;
    sw <= "0010"; press_button;
    sw <= "0010"; press_button;
    wait for 50 ns;
    assert leds = "0000" and z = '1' and n = '0' and c = '1' and v = '0'
      report "Subtraction test failed" severity error;
    -- Reset should clear the visible result.
    rst <= '1'; wait for 80 ns;
    assert leds = "0000" and z = '0' and n = '0' and c = '0' and v = '0'
      report "Reset test failed" severity error;
    assert false report "All test cases finished" severity note;
    wait;
  end process;
end architecture;
