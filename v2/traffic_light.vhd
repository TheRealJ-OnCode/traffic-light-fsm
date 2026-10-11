--entity
library IEEE;
use IEEE.std_logic_1164.all;
entity my_t_lmb is 
PORT (
	CLK,RST : in std_logic;
    R,G,Y : out std_logic
) ;
end my_t_lmb;
--arch
architecture my_t_lmb_arch of my_t_lmb is 
	type state_type  is (ST0,ST1,ST2);
    signal PS,NS :state_type;
	signal TM : integer range 0 to 10;
	
begin
	sync_proc:process(RST,CLK)
    begin
    	if(RST = '1') then 
    		PS <= ST0;
        elsif (rising_edge(CLK)) then
            PS<= NS;
         end if;
	end process sync_proc;
    --counter 
    counter_proc : process(CLK,RST)
    begin
    	if(RST = '1') then  TM <= 0;
        elsif(rising_edge(CLK)) then  
      	if (TM = 10) then
            TM <= 0;
        else
            TM <= TM + 1;
        end if;
    end if;
    end process counter_proc;
	--comb_proc 
	comb_proc : process (PS, TM)
    begin 
        case PS is
          WHEN ST0 =>
              if(TM = 4) then NS <= ST1;
              else NS <= ST0;
              end if;
              R  <= '1';
              G  <= '0';
              Y  <= '0';
            
        WHEN ST1 =>
			  if(TM = 8) then NS <= ST2;
              else NS <= ST1;
              end if;
              R  <= '0';
              G  <= '1';
              Y  <= '0';

        WHEN ST2 =>
         	  if(TM = 10) then NS <= ST0;
              else NS <= ST2;
              end if;
              R  <= '0';
              G  <= '0';
              Y  <= '1';
    	end case;
    end process comb_proc;
    
end my_t_lmb_arch;