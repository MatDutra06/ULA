library ieee;
use ieee.std_logic_1164.all;

entity ula_top is
  generic (DEBOUNCE_CYCLES : positive := 500000);
  port (clk : in std_logic;
        reset_btn : in std_logic;
        confirm_btn : in std_logic;
        sw : in std_logic_vector(3 downto 0);
        led_result : out std_logic_vector(3 downto 0);
        led_zero, led_negative, led_carry, led_overflow : out std_logic);
end entity;

architecture rtl of ula_top is
  type state_type is (GET_OP, GET_A, GET_B, SHOW_RESULT);
  signal state : state_type := GET_OP;
  signal op_reg : std_logic_vector(2 downto 0) := (others => '0');
  signal a_reg, b_reg : std_logic_vector(3 downto 0) := (others => '0');
  signal confirm_pulse : std_logic;
  signal reset_sync1, reset_sync2 : std_logic := '0';
  signal alu_result : std_logic_vector(3 downto 0);
  signal alu_z, alu_n, alu_c, alu_v : std_logic;
begin
  -- Synchronize reset deassertion and button input to the board clock.
  process(clk, reset_btn)
  begin
    if reset_btn = '1' then
      reset_sync1 <= '1'; reset_sync2 <= '1';
    elsif rising_edge(clk) then
      reset_sync1 <= '0'; reset_sync2 <= reset_sync1;
    end if;
  end process;

  db : entity work.debounce
    generic map (STABLE_CYCLES => DEBOUNCE_CYCLES)
    port map (clk => clk, rst => reset_sync2, btn => confirm_btn,
              pulse => confirm_pulse);

  arithmetic_unit : entity work.ula
    port map (a => a_reg, b => b_reg, op => op_reg,
              result => alu_result, z => alu_z, n => alu_n,
              c => alu_c, v => alu_v);

  process(clk, reset_sync2)
  begin
    if reset_sync2 = '1' then
      state <= GET_OP;
      op_reg <= (others => '0');
      a_reg <= (others => '0');
      b_reg <= (others => '0');
    elsif rising_edge(clk) then
      if confirm_pulse = '1' then
        case state is
          when GET_OP =>
            op_reg <= sw(2 downto 0);
            state <= GET_A;
          when GET_A =>
            a_reg <= sw;
            state <= GET_B;
          when GET_B =>
            b_reg <= sw;
            state <= SHOW_RESULT;
          when SHOW_RESULT =>
            state <= GET_OP;
        end case;
      end if;
    end if;
  end process;

  -- Hide stale data until both operands have been captured.
  led_result <= alu_result when state = SHOW_RESULT else (others => '0');
  led_zero <= alu_z when state = SHOW_RESULT else '0';
  led_negative <= alu_n when state = SHOW_RESULT else '0';
  led_carry <= alu_c when state = SHOW_RESULT else '0';
  led_overflow <= alu_v when state = SHOW_RESULT else '0';
end architecture;
