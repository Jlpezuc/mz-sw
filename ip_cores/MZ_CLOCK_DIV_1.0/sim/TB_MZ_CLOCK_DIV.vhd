----------------------------------------------------------------------------------
-- Testbench de MZ_CLOCK_DIV_CORE (nucleo del divisor programable): para cada divisor
-- 1, 2, 3, 5, 10, 100 se carga el valor con enable = 0 -> 1 y se miden en 3000 ciclos
-- los periodos de clk_out, los ciclos en alto y los pulsos de flag_out.
-- Ejecutar:  xvhdl ../hdl/MZ_CLOCK_DIV_CORE.vhd TB_MZ_CLOCK_DIV.vhd
--            xelab TB_MZ_CLOCK_DIV -s tb ; xsim tb -R
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TB_MZ_CLOCK_DIV is
end TB_MZ_CLOCK_DIV;

architecture sim of TB_MZ_CLOCK_DIV is
    signal clk     : std_logic := '0';
    signal resetn  : std_logic := '0';
    signal enable  : std_logic := '0';
    signal divider : std_logic_vector(31 downto 0) := (others => '0');
    signal running, clko, flag : std_logic;
    signal fin     : boolean := false;
begin
    dut : entity work.MZ_CLOCK_DIV_CORE
        port map (clk => clk, resetn => resetn, enable => enable, divider => divider,
                  running => running, clk_out => clko, flag_out => flag);
    clk <= not clk after 5 ns when not fin;

    stim : process
        constant CYC : integer := 3000;
        type int_arr is array (0 to 5) of integer;
        constant DIVS : int_arr := (1, 2, 3, 5, 10, 100);
        variable edges, high, flags, exp_edges, exp_high : integer;
        variable prev : std_logic;
    begin
        wait for 25 ns; resetn <= '1';
        for i in DIVS'range loop
            -- secuencia de software: enable = 0, divisor, enable = 1
            enable <= '0'; wait for 100 ns;
            assert running = '0' report "running con enable = 0" severity failure;
            divider <= std_logic_vector(to_unsigned(DIVS(i), 32)); wait for 20 ns;
            enable <= '1';
            wait for 60 ns;   -- sincronizador + arranque
            assert running = '1' report "no arranca" severity failure;
            edges := 0; high := 0; flags := 0; prev := '0';
            for c in 1 to CYC loop
                wait until rising_edge(clk); wait for 1 ns;
                if clko = '1' and prev = '0' then edges := edges + 1; end if;
                if clko = '1' then high := high + 1; end if;
                if flag = '1' then flags := flags + 1; end if;
                prev := clko;
            end loop;
            exp_edges := CYC / DIVS(i);
            exp_high  := CYC * ((DIVS(i) + 1) / 2) / DIVS(i);
            report "DIVIDER=" & integer'image(DIVS(i)) & ": " & integer'image(edges) & " periodos (esp. " & integer'image(exp_edges)
                   & "), " & integer'image(high) & " alto (esp. " & integer'image(exp_high) & "), " & integer'image(flags) & " flags";
            if DIVS(i) = 1 then
                assert high = CYC and flags = CYC report "DIVIDER=1 debe ser paso directo" severity failure;
                for c in 1 to 10 loop
                    wait until falling_edge(clk); wait for 1 ns;
                    assert clko = '0' report "DIVIDER=1: clk_out no sigue a clk" severity failure;
                end loop;
            else
                assert abs(edges - exp_edges) <= 1 report "periodo incorrecto" severity failure;
                assert abs(high - exp_high) <= (DIVS(i) + 1) / 2 report "ciclo de trabajo incorrecto" severity failure;
                assert abs(flags - exp_edges) <= 1 report "flags incorrectos" severity failure;
            end if;
        end loop;
        -- divisor 0 se trata como 1
        enable <= '0'; wait for 100 ns; divider <= (others => '0'); wait for 20 ns; enable <= '1'; wait for 100 ns;
        wait until rising_edge(clk); wait for 1 ns;
        assert clko = '1' and flag = '1' report "divider 0 no se trata como 1" severity failure;
        -- resetn = 0 para las salidas
        resetn <= '0'; wait for 30 ns;
        assert running = '0' and clko = '0' report "resetn no para el divisor" severity failure;
        report "TB_OK" severity note;
        fin <= true; wait;
    end process;
end sim;
