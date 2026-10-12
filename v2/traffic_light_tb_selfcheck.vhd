library IEEE;
use IEEE.std_logic_1164.all;

-- Self-checking testbench for the traffic light (v2)
-- Checks every clock tick with assert: exactly one lamp on, correct color
entity my_t_lmb_tb is
end my_t_lmb_tb;

architecture sim of my_t_lmb_tb is

    component my_t_lmb
        port ( CLK, RST : in  std_logic;
               R, G, Y  : out std_logic );
    end component;

    constant CLK_PERIOD : time := 10 ns;

    signal CLK      : std_logic := '0';
    signal RST      : std_logic := '0';
    signal R, G, Y  : std_logic;
    signal sim_done : boolean := false;

begin

    dut: my_t_lmb port map ( CLK => CLK,
                             RST => RST,
                             R   => R,
                             G   => G,
                             Y   => Y );

    -- Clock generator: 10 ns period, rising edges at 5, 15, 25 ... ns
    clk_gen: process
    begin
        if sim_done then
            wait;
        end if;
        CLK <= '0';
        wait for CLK_PERIOD / 2;
        CLK <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Checks happen in the middle of each tick (10, 20, 30 ... ns)
    stim: process
    begin
        RST <= '1';
        wait for 10 ns;
        RST <= '0';

        for tur in 1 to 3 loop

            -- Red: TM 0-4
            for i in 0 to 4 loop
                assert (R = '1' and G = '0' and Y = '0')
                    report "Red should be on, TM = " & integer'image(i)
                    severity error;
                wait for CLK_PERIOD;
            end loop;

            -- Green: TM 5-8
            for i in 5 to 8 loop
                assert (R = '0' and G = '1' and Y = '0')
                    report "Green should be on, TM = " & integer'image(i)
                    severity error;
                wait for CLK_PERIOD;
            end loop;

            -- Yellow: TM 9-10
            for i in 9 to 10 loop
                assert (R = '0' and G = '0' and Y = '1')
                    report "Yellow should be on, TM = " & integer'image(i)
                    severity error;
                wait for CLK_PERIOD;
            end loop;

        end loop;

        report "Test finished";
        sim_done <= true;
        wait;
    end process;

end sim;