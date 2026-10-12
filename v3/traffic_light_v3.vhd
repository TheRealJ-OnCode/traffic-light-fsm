library IEEE;
use IEEE.std_logic_1164.all;

entity my_t_l_v3 is
    port ( CLK, RST, PED_BTN : in  std_logic;
           R, G, Y, W        : out std_logic );
end my_t_l_v3;

architecture my_t_l_v3_arch of my_t_l_v3 is
    type state_type is (ST_R, ST_G, ST_Y);         
    signal PS, NS      : state_type;
    signal cnt         : integer range 0 to 14;
    signal ped_waiting : std_logic;
    signal wait_ticks  : integer range 0 to 3;
begin                                               

    -- State register
    sync_proc: process(CLK, RST)
    begin
        if (RST = '1') then
            PS <= ST_R;
        elsif (rising_edge(CLK)) then
            PS <= NS;
        end if;
    end process sync_proc;

    -- Per-state tick counter: restarts at 0 when the state changes
    cnt_proc: process(CLK, RST)                     
    begin
        if (RST = '1') then
            cnt <= 0;                               
        elsif (rising_edge(CLK)) then
            if (PS /= NS) then
                cnt <= 0;
            else
                cnt <= cnt + 1;
            end if;
        end if;
    end process cnt_proc;

    -- Pedestrian request flag and wait counter (only active in green)
    ped_proc: process(CLK, RST)
    begin
        if (RST = '1') then
            ped_waiting <= '0';                    
            wait_ticks  <= 0;
        elsif (rising_edge(CLK)) then
            if (PS /= ST_G) then                   
                ped_waiting <= '0';
                wait_ticks  <= 0;
            else                                   
                if (PED_BTN = '1') then
                    ped_waiting <= '1';
                end if;
                if (ped_waiting = '1' and wait_ticks < 3) then  
                    wait_ticks <= wait_ticks + 1;
                end if;
            end if;
        end if;
    end process ped_proc;

    -- Next state and outputs
    comb_proc: process(PS, cnt, ped_waiting, wait_ticks)   
    begin
        case PS is
            when ST_R =>
                if (cnt = 4) then NS <= ST_G;
                else              NS <= ST_R;
                end if;
                R <= '1'; G <= '0'; Y <= '0'; W <= '1';    

            when ST_G =>
                if (cnt = 14) or (ped_waiting = '1' and wait_ticks = 3) then  
                    NS <= ST_Y;
                else
                    NS <= ST_G;
                end if;
                R <= '0'; G <= '1'; Y <= '0'; W <= '0';

            when ST_Y =>
                if (cnt = 1) then NS <= ST_R;              
                else              NS <= ST_Y;
                end if;
                R <= '0'; G <= '0'; Y <= '1'; W <= '0';
        end case;
    end process comb_proc;

end my_t_l_v3_arch;