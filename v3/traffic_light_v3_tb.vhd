library IEEE;
use IEEE.std_logic_1164.all;

-- Self-checking testbench for the traffic light v3 (pedestrian button)
entity my_t_l_v3_tb is
end my_t_l_v3_tb;

architecture sim of my_t_l_v3_tb is

    component my_t_l_v3
        port ( CLK, RST, PED_BTN : in  std_logic;
               R, G, Y, W        : out std_logic );
    end component;

    constant CLK_PERIOD : time := 10 ns;

    signal CLK        : std_logic := '0';
    signal RST        : std_logic := '0';
    signal PED_BTN    : std_logic := '0';
    signal R, G, Y, W : std_logic;
    signal sim_done   : boolean := false;

begin

    dut: my_t_l_v3 port map ( CLK => CLK, RST => RST, PED_BTN => PED_BTN,
                              R => R, G => G, Y => Y, W => W );

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

    -- Safety rule, checked at every moment of the simulation
    safety: assert not (W = '1' and (G = '1' or Y = '1'))
        report "SAFETY: pedestrians walking while cars can move!"
        severity failure;

    stim: process

        -- Check that the light shows the given color for n ticks
        procedure expect(color : string; n : integer; tag : string) is
        begin
            for i in 1 to n loop
                if color = "red" then
                    assert (R = '1' and G = '0' and Y = '0' and W = '1')
                        report tag & ": red expected, tick " & integer'image(i)
                        severity error;
                elsif color = "green" then
                    assert (R = '0' and G = '1' and Y = '0' and W = '0')
                        report tag & ": green expected, tick " & integer'image(i)
                        severity error;
                else
                    assert (R = '0' and G = '0' and Y = '1' and W = '0')
                        report tag & ": yellow expected, tick " & integer'image(i)
                        severity error;
                end if;
                wait for CLK_PERIOD;
            end loop;
        end procedure;

    begin
        RST <= '1';                      --    0 -   10 ns  reset
        wait for 10 ns;
        RST <= '0';

        -- A: nobody presses the button -> green lasts 15 ticks
        expect("red",     5, "A");       --   10 -   60 ns
        expect("green",  15, "A");       --   60 -  210 ns
        expect("yellow",  2, "A");       --  210 -  230 ns

        -- B: press in green tick 3 -> green ends 4 ticks later (7 total)
        expect("red",     5, "B");       --  230 -  280 ns
        expect("green",   2, "B");       --  280 -  300 ns  green tick 1-2
        PED_BTN <= '1';                  --  300 ns         press
        expect("green",   1, "B");       --  300 -  310 ns  green tick 3
        PED_BTN <= '0';                  --  310 ns         release
        expect("green",   4, "B");       --  310 -  350 ns  green tick 4-7
        expect("yellow",  2, "B");       --  350 -  370 ns

        -- C: press in green tick 13 -> normal 15 ticks end first
        expect("red",     5, "C");       --  370 -  420 ns
        expect("green",  12, "C");       --  420 -  540 ns  green tick 1-12
        PED_BTN <= '1';                  --  540 ns         press
        expect("green",   1, "C");       --  540 -  550 ns  green tick 13
        PED_BTN <= '0';                  --  550 ns         release
        expect("green",   2, "C");       --  550 -  570 ns  green tick 14-15
        expect("yellow",  2, "C");       --  570 -  590 ns

        -- E: press during red -> ignored, next green lasts 15 ticks
        PED_BTN <= '1';                  --  590 ns         press
        expect("red",     5, "E");       --  590 -  640 ns
        PED_BTN <= '0';                  --  640 ns         release
        expect("green",  15, "E");       --  640 -  790 ns
        expect("yellow",  2, "E");       --  790 -  810 ns

        -- G: button held down -> green is shortened every cycle,
        --    cars still get green (no lock-up). The press is registered
        --    on the edge after green tick 1, then 4 more ticks -> 5 total.
        PED_BTN <= '1';                  --  810 ns         hold
        expect("red",     5, "G");       --  810 -  860 ns
        expect("green",   5, "G");       --  860 -  910 ns
        expect("yellow",  2, "G");       --  910 -  930 ns
        expect("red",     5, "G");       --  930 -  980 ns
        expect("green",   5, "G");       --  980 - 1030 ns
        PED_BTN <= '0';                  -- 1030 ns         release
        expect("yellow",  2, "G");       -- 1030 - 1050 ns

        -- H: reset while a request is pending -> request is erased
        expect("red",     5, "H");       -- 1050 - 1100 ns
        PED_BTN <= '1';                  -- 1100 ns         press
        expect("green",   1, "H");       -- 1100 - 1110 ns  request registered
        PED_BTN <= '0';
        RST <= '1';                      -- 1110 ns         reset
        wait for 1 ns;
        assert (R = '1' and W = '1')
            report "H: reset did not go to red immediately"
            severity error;
        wait for CLK_PERIOD - 1 ns;
        RST <= '0';                      -- 1120 ns
        expect("red",     5, "H");       -- 1120 - 1170 ns
        expect("green",  15, "H");       -- 1170 - 1320 ns  not shortened

        report "Test finished";
        sim_done <= true;
        wait;
    end process;

end sim;