library IEEE;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use ieee.std_logic_unsigned.all ;

entity MZ_CLOCK_FLAG_DIV_CORE is
    generic (
        sincronizar_clock_base : STD_LOGIC := '1'
    );
    Port ( clk_in : in  STD_LOGIC ;
           reset : in  STD_LOGIC ;
           clock_base_sync : in std_logic;
           frec_divider : in  std_logic_vector(31 downto 0) ;
           clk_out : out  STD_LOGIC ;
           flag_out : out  STD_LOGIC );
end MZ_CLOCK_FLAG_DIV_CORE;

architecture Behavioral of MZ_CLOCK_FLAG_DIV_CORE is
--
signal COUNT : INTEGER := 1 ;
signal CLOCK : std_logic := '0' ;
signal FLAG : std_logic := '0' ;
signal MAX : INTEGER := 1 ;
signal FD_READY : std_logic := '0' ;
--
signal CLOCK_BASE_SYNC_ANT :  std_logic := '0' ;
-- sincronizador de 2 etapas: clock_base_sync puede venir de otro dominio de reloj
signal CLOCK_BASE_META, CLOCK_BASE_SYNC_R : std_logic := '0' ;
attribute ASYNC_REG : string;
attribute ASYNC_REG of CLOCK_BASE_META : signal is "TRUE";
attribute ASYNC_REG of CLOCK_BASE_SYNC_R : signal is "TRUE";
--

begin
-- Add user logic here
--
    process(clk_in,reset)
    --
    --variable MAX : INTEGER := 2 ;
    --variable FD_READY : std_logic := '0' ;
    --
    begin
        if (reset='1') then
            --
            COUNT <=  1 ;
            CLOCK <= '0' ;
            FLAG <= '0' ;
            MAX <= 1 ;
            FD_READY <= '0' ;
            CLOCK_BASE_META <= '0' ;
            CLOCK_BASE_SYNC_R <= '0' ;
            CLOCK_BASE_SYNC_ANT <= '0' ;
            --
        elsif (rising_edge(clk_in)) then
            CLOCK_BASE_META <= clock_base_sync ;
            CLOCK_BASE_SYNC_R <= CLOCK_BASE_META ;
            --
            if (FD_READY='1') then
                --
                if (COUNT >= MAX/2) then
                    CLOCK <= not CLOCK ;
                    COUNT <=  1 ;
                else
                    COUNT <= COUNT + 1 ;
                end if;
                --
                if (COUNT = MAX/2 and CLOCK = '0') then
                    FLAG <= '1' ;
                else
                    FLAG <= '0' ;
                end if ;
                --
            else
                --
                MAX <= TO_INTEGER(unsigned(frec_divider)) ;
                if ( MAX >= 2 ) then -- es valido iniciar
                    if (sincronizar_clock_base='1') then -- espera primer clock para iniciar sincronizado
                        if (CLOCK_BASE_SYNC_R='1' and CLOCK_BASE_SYNC_ANT='0') then
                            CLOCK <= '1' ;
                            FLAG <= '0' ;
                            COUNT <= 2 ; -- para compensar la deteccion con 1 clock de tardanza
                            FD_READY <= '1' ;
                        end if;
                    else -- inicia sin sincronizar
                        FD_READY <= '1' ;
                    end if;
                end if ;
                --
            end if; -- final if ready
            CLOCK_BASE_SYNC_ANT <= CLOCK_BASE_SYNC_R ; -- feed clock_sync
            --
        end if; -- Final if rise clk_in

    end process;

    -- Salidas combinacional
    clk_out <= CLOCK ;
    flag_out <= FLAG ;

--
-- end user logic

end Behavioral;