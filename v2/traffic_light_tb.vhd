library IEEE;
use IEEE.std_logic_1164.all;

-- Step 1: empty entity (a testbench has no ports)
entity my_t_lmb_tb is
end my_t_lmb_tb;

architecture sim of my_t_lmb_tb is

    -- Step 2: component declaration of the DUT
    component my_t_lmb
        PORT ( CLK, RST : in  std_logic;
               R, G, Y  : out std_logic );
    end component;

    constant CLK_PERIOD : time := 10 ns;

    -- Step 3: one signal per DUT port (+ end-of-simulation flag)
    signal CLK      : std_logic := '0';
    signal RST      : std_logic := '0';
    signal R, G, Y  : std_logic;
    signal sim_done : boolean := false;

begin

    -- Step 4: instantiate the DUT
    dut: my_t_lmb port map ( CLK => CLK,
                             RST => RST,
                             R   => R,
                             G   => G,
                             Y   => Y );

    -- Clock generator: 10 ns period, rising edges at 5, 15, 25 ... ns
    clk_gen: process
    begin
        if sim_done then
            wait;                  -- stop the clock when the test is over
        end if;
        CLK <= '0';
        wait for CLK_PERIOD / 2;
        CLK <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Step 5: test scenario
    stim: process
    begin
        -- 1) 0-10 ns: initial reset
        --    Expected: red, TM = 0
        RST <= '1';
        wait for 10 ns;

        -- 2) 10-180 ns: release reset, let the light run on its own
        --    One full cycle = 11 ticks = 110 ns
        --    Expected: red 5 ticks, green 4 ticks, yellow 2 ticks,
        --              then red again for 5 ticks and switch to green
        RST <= '0';
        wait for 170 ns;

        -- 3) 180-190 ns: assert reset while green is on
        --    Expected: red immediately (no wait for clock edge), TM = 0
        RST <= '1';
        wait for 10 ns;

        -- 4) 190-320 ns: release reset, run one more full cycle
        --    Expected: red lasts exactly 5 ticks again after reset
        RST <= '0';
        wait for 130 ns;

        sim_done <= true;
        wait;
    end process;

end sim;