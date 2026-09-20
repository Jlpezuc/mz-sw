----------------------------------------------------------------------------------
-- Testbench de MZ_AVERAGER_8CH_CHANNEL: MAX_AVG_LOG2 = 12, cant_datos = 1000 -> 512 muestras
--   1) rampa 1000..1511 -> promedio 1255 (1255.5 truncado)
--   2) tras el sync, constante -3000 -> promedio -3000 (acumulador con signo, sin desbordar)
--   3) cant_datos = 100000 -> se limita a 4096 muestras
-- Ejecutar:  xvhdl ../hdl/MZ_AVERAGER_8CH_CHANNEL.vhd TB_MZ_AVERAGER_8CH_CHANNEL.vhd
--            xelab TB_MZ_AVERAGER_8CH_CHANNEL -s tb ; xsim tb -R
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TB_MZ_AVERAGER_8CH_CHANNEL is
end TB_MZ_AVERAGER_8CH_CHANNEL;

architecture sim of TB_MZ_AVERAGER_8CH_CHANNEL is
    constant N        : integer := 16;
    constant LOG2     : integer := 12;
    signal clk        : std_logic := '0';
    signal resetn     : std_logic := '0';
    signal enable     : std_logic := '0';
    signal cant       : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(1000, 32));
    signal sync       : std_logic := '0';
    signal flag       : std_logic := '0';
    signal din        : std_logic_vector(N-1 downto 0) := (others => '0');
    signal davg       : std_logic_vector(N-1 downto 0);
    signal done       : std_logic;
    signal fin        : boolean := false;
begin
    dut : entity work.MZ_AVERAGER_8CH_CHANNEL
        generic map (N => N, MAX_AVG_LOG2 => LOG2, valores_con_signo_ch => '1', sincronizar_clock_base => '1')
        port map (clk_ch => clk, resetn_ch => resetn, enable_ch => enable, cant_datos => cant,
                  clock_base_sync => sync, flag_new_data => flag, dato_in => din, dato_avg => davg, avg_done_ch => done);

    clk <= not clk after 5 ns when not fin;

    stim : process
        procedure muestra(v : integer) is
        begin
            din <= std_logic_vector(to_signed(v, N));
            wait until rising_edge(clk); flag <= '1';
            wait until rising_edge(clk); wait until rising_edge(clk); flag <= '0';
            wait until rising_edge(clk); wait until rising_edge(clk);
        end procedure;
        procedure pulso_sync is
        begin
            wait until rising_edge(clk); sync <= '1';
            wait until rising_edge(clk); wait until rising_edge(clk); sync <= '0';
        end procedure;
    begin
        wait for 20 ns; resetn <= '1'; wait for 20 ns; enable <= '1';
        -- 1) rampa de 512 muestras (cant = 1000 -> 512)
        for i in 0 to 511 loop muestra(1000 + i); end loop;
        wait for 100 ns;
        assert done = '1' report "1) avg_done no activo" severity failure;
        assert to_integer(signed(davg)) = 1255 report "1) promedio = " & integer'image(to_integer(signed(davg))) & " (esperado 1255)" severity failure;
        report "1) OK promedio rampa = " & integer'image(to_integer(signed(davg)));
        -- muestra extra sin sync: no debe reiniciar
        muestra(50000); wait for 50 ns;
        assert to_integer(signed(davg)) = 1255 report "1b) reinicio sin sync" severity failure;
        -- 2) sync y 512 muestras de -3000
        pulso_sync;
        for i in 0 to 511 loop muestra(-3000); end loop;
        wait for 100 ns;
        assert done = '1' and to_integer(signed(davg)) = -3000 report "2) promedio = " & integer'image(to_integer(signed(davg))) & " (esperado -3000)" severity failure;
        report "2) OK promedio constante negativa = " & integer'image(to_integer(signed(davg)));
        -- 3) recarga con cant = 100000 -> limite 4096 muestras de 7 -> 7
        enable <= '0'; cant <= std_logic_vector(to_unsigned(100000, 32));
        pulso_sync; muestra(1); muestra(1); wait for 50 ns;
        enable <= '1';
        for i in 0 to 4095 loop muestra(7); end loop;
        wait for 100 ns;
        assert done = '1' and to_integer(signed(davg)) = 7 report "3) promedio = " & integer'image(to_integer(signed(davg))) & " (esperado 7)" severity failure;
        report "3) OK limite 4096 muestras, promedio = " & integer'image(to_integer(signed(davg)));
        report "TB_OK" severity note;
        fin <= true; wait;
    end process;
end sim;
