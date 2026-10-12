stim: process
begin
    -- 0-10 ns: reset
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