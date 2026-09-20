----------------------------------------------------------------------------------
-- MZ_CLOCK_DIV_CORE : divisor de reloj programable
--
--   clk_out = clk / divider,  para cualquier divider >= 1 (valor en tiempo de ejecucion)
--
-- * divider = 1 : clk_out = clk (paso directo), flag_out = '1'.
-- * divider par : ciclo de trabajo 50 %.
-- * divider impar : alto (divider+1)/2 ciclos, bajo (divider-1)/2 ciclos.
-- * flag_out : pulso de un ciclo de clk en cada flanco de subida de clk_out.
--
-- 'enable' y 'divider' vienen del dominio AXI; 'enable' se sincroniza con dos
-- registros y el divisor se carga en el flanco de subida del enable sincronizado
-- (el software escribe el divisor con enable = 0 y luego pone enable = 1). Mientras
-- enable = 0 o resetn = 0 las salidas estan a '0'.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MZ_CLOCK_DIV_CORE is
    port (
        clk      : in  std_logic;                       -- reloj a dividir
        resetn   : in  std_logic;                       -- activo bajo (p. ej. 'locked' del clocking wizard)
        enable   : in  std_logic;                       -- dominio AXI
        divider  : in  std_logic_vector(31 downto 0);   -- dominio AXI, estable mientras enable = 0
        running  : out std_logic;                       -- '1' cuando el contador esta en marcha
        clk_out  : out std_logic;
        flag_out : out std_logic
    );
end MZ_CLOCK_DIV_CORE;

architecture Behavioral of MZ_CLOCK_DIV_CORE is
    signal en_meta, en_sync, en_ant : std_logic := '0';
    signal div_r   : unsigned(31 downto 0) := to_unsigned(1, 32);
    signal half_r  : unsigned(31 downto 0) := to_unsigned(1, 32);   -- ceil(divider/2)
    signal count   : unsigned(31 downto 0) := (others => '0');
    signal clk_r   : std_logic := '0';
    signal flag_r  : std_logic := '0';
    signal run_r   : std_logic := '0';
    attribute ASYNC_REG : string;
    attribute ASYNC_REG of en_meta : signal is "TRUE";
    attribute ASYNC_REG of en_sync : signal is "TRUE";
begin
    process (clk, resetn)
    begin
        if resetn = '0' then
            en_meta <= '0'; en_sync <= '0'; en_ant <= '0';
            div_r  <= to_unsigned(1, 32);
            half_r <= to_unsigned(1, 32);
            count  <= (others => '0');
            clk_r  <= '0';
            flag_r <= '0';
            run_r  <= '0';
        elsif rising_edge(clk) then
            en_meta <= enable;
            en_sync <= en_meta;
            en_ant  <= en_sync;
            if en_sync = '1' and en_ant = '0' then
                -- arranque: cargar el divisor (>= 1) y empezar un periodo
                if unsigned(divider) = 0 then
                    div_r  <= to_unsigned(1, 32);
                    half_r <= to_unsigned(1, 32);
                else
                    div_r  <= unsigned(divider);
                    half_r <= (unsigned(divider) + 1) / 2;
                end if;
                count  <= (others => '0');
                clk_r  <= '1';
                flag_r <= '1';
                run_r  <= '1';
            elsif en_sync = '1' then
                -- contador ciclico 0 .. div_r-1
                if count >= div_r - 1 then
                    count  <= (others => '0');
                    clk_r  <= '1';
                    flag_r <= '1';
                else
                    count <= count + 1;
                    flag_r <= '0';
                    if count + 1 >= half_r then
                        clk_r <= '0';
                    end if;
                end if;
            else
                count  <= (others => '0');
                clk_r  <= '0';
                flag_r <= '0';
                run_r  <= '0';
            end if;
        end if;
    end process;

    -- divider = 1: paso directo (clk_out es una senal logica, no un reloj de BUFG)
    clk_out  <= clk when (run_r = '1' and div_r = 1) else clk_r;
    flag_out <= '1' when (run_r = '1' and div_r = 1) else flag_r;
    running  <= run_r;
end Behavioral;
