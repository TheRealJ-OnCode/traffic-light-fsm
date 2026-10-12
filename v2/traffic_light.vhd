--entity
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
ENTITY my_t_lmb IS
    PORT (
        CLK, RST : IN STD_LOGIC;
        R, G, Y : OUT STD_LOGIC
    );
END my_t_lmb;
--arch
ARCHITECTURE my_t_lmb_arch OF my_t_lmb IS
    TYPE state_type IS (ST0, ST1, ST2);
    SIGNAL PS, NS : state_type;
    SIGNAL TM : INTEGER RANGE 0 TO 10;

BEGIN
    sync_proc : PROCESS (RST, CLK)
    BEGIN
        IF (RST = '1') THEN
            PS <= ST0;
        ELSIF (rising_edge(CLK)) THEN
            PS <= NS;
        END IF;
    END PROCESS sync_proc;
    --counter 
    counter_proc : PROCESS (CLK, RST)
    BEGIN
        IF (RST = '1') THEN
            TM <= 0;
        ELSIF (rising_edge(CLK)) THEN
            IF (TM = 10) THEN
                TM <= 0;
            ELSE
                TM <= TM + 1;
            END IF;
        END IF;
    END PROCESS counter_proc;
    --comb_proc 
    comb_proc : PROCESS (PS, TM)
    BEGIN
        CASE PS IS
            WHEN ST0 =>
                IF (TM = 4) THEN
                    NS <= ST1;
                ELSE
                    NS <= ST0;
                END IF;
                R <= '1';
                G <= '0';
                Y <= '0';

            WHEN ST1 =>
                IF (TM = 8) THEN
                    NS <= ST2;
                ELSE
                    NS <= ST1;
                END IF;
                R <= '0';
                G <= '1';
                Y <= '0';

            WHEN ST2 =>
                IF (TM = 10) THEN
                    NS <= ST0;
                ELSE
                    NS <= ST2;
                END IF;
                R <= '0';
                G <= '0';
                Y <= '1';
        END CASE;
    END PROCESS comb_proc;

END my_t_lmb_arch;