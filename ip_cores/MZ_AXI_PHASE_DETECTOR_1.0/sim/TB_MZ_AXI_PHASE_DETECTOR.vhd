----------------------------------------------------------------------------------
-- TB_MZ_AXI_PHASE_DETECTOR : testbench del contador de fase (proceso de S_COUNTER_CLK
-- de MZ_AXI_PHASE_DETECTOR_S00_AXI). El bus AXI no se usa: se mira S_COUNTER_OUT.
--
-- Comprueba:
--   1. cuenta normal: B llega N ciclos despues de A -> S_COUNTER_OUT = N - 1 (igual que el
--      diseno original: la cuenta empieza a 0 el ciclo siguiente al flanco de A)
--   2. se pierde un flanco de B: el siguiente A REINICIA la cuenta (no acumula N + T)
--   3. A y B en el mismo ciclo sin cuenta en marcha -> 0; con cuenta en marcha -> captura y reinicia
--   4. flanco de A asincrono (entre flancos de reloj) -> cuenta N o N+1, nunca otra cosa
--
-- xvhdl --work work ../hdl/MZ_AXI_PHASE_DETECTOR_S00_AXI.vhd TB_MZ_AXI_PHASE_DETECTOR.vhd
-- xelab TB_MZ_AXI_PHASE_DETECTOR -s tb && xsim tb -R
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TB_MZ_AXI_PHASE_DETECTOR is
end TB_MZ_AXI_PHASE_DETECTOR;

architecture sim of TB_MZ_AXI_PHASE_DETECTOR is
    constant TCLK : time := 10 ns;
    signal clk     : std_logic := '0';
    signal aresetn : std_logic := '0';
    signal sig_a   : std_logic := '0';
    signal sig_b   : std_logic := '0';
    signal count   : std_logic_vector(31 downto 0);
    signal done    : boolean := false;
    -- AXI sin usar
    signal zero32 : std_logic_vector(31 downto 0) := (others => '0');
    signal zero4  : std_logic_vector(3 downto 0)  := (others => '0');
    signal zero3  : std_logic_vector(2 downto 0)  := (others => '0');
    signal open_v : std_logic_vector(31 downto 0);
    signal open_r : std_logic_vector(1 downto 0);
    signal open_b : std_logic;
begin
    clk <= not clk after TCLK / 2 when not done;

    dut : entity work.MZ_AXI_PHASE_DETECTOR_S00_AXI
        generic map (C_S_AXI_DATA_WIDTH => 32, C_S_AXI_ADDR_WIDTH => 4)
        port map (
            S_COUNTER_CLK => clk, S_SIG_A => sig_a, S_SIG_B => sig_b, S_COUNTER_OUT => count,
            S_REG0_OUT => open_v, S_REG1_OUT => open_v, S_REG2_OUT => open_v, S_REG3_OUT => open_v,
            S_AXI_ACLK => clk, S_AXI_ARESETN => aresetn,
            S_AXI_AWADDR => zero4, S_AXI_AWPROT => zero3, S_AXI_AWVALID => '0', S_AXI_AWREADY => open_b,
            S_AXI_WDATA => zero32, S_AXI_WSTRB => zero4, S_AXI_WVALID => '0', S_AXI_WREADY => open_b,
            S_AXI_BRESP => open_r, S_AXI_BVALID => open_b, S_AXI_BREADY => '0',
            S_AXI_ARADDR => zero4, S_AXI_ARPROT => zero3, S_AXI_ARVALID => '0', S_AXI_ARREADY => open_b,
            S_AXI_RDATA => open_v, S_AXI_RRESP => open_r, S_AXI_RVALID => open_b, S_AXI_RREADY => '0');

    stim : process
        -- pulso de A (alineado con el reloj), B n ciclos despues
        procedure pulso(signal s : out std_logic; ancho : integer) is
        begin
            s <= '1'; wait for ancho * TCLK; s <= '0';
        end procedure;
        procedure check(expected : integer; msg : string) is
        begin
            wait for 6 * TCLK;   -- latencia del sincronizador + captura
            assert to_integer(unsigned(count)) = expected
                report msg & ": cuenta = " & integer'image(to_integer(unsigned(count))) & ", esperado " & integer'image(expected)
                severity failure;
            report msg & " OK (" & integer'image(expected) & ")";
        end procedure;
        variable c1, c2 : integer;
    begin
        wait for 3 * TCLK; wait until rising_edge(clk); wait for 1 ns;
        aresetn <= '1';
        wait for 5 * TCLK;

        -- 1. cuenta normal: A, 100 ciclos, B
        pulso(sig_a, 3); wait for 97 * TCLK; pulso(sig_b, 3);
        check(99, "1 cuenta normal");

        -- 2. flanco de B perdido: A, (sin B), A a los 1176 ciclos, B 100 despues -> 99, no 1275
        wait for 20 * TCLK;
        pulso(sig_a, 3); wait for 1173 * TCLK; pulso(sig_a, 3); wait for 97 * TCLK; pulso(sig_b, 3);
        check(99, "2 B perdido, A reinicia");

        -- 3a. A y B en el mismo ciclo sin cuenta en marcha -> 0
        wait for 20 * TCLK;
        sig_a <= '1'; sig_b <= '1'; wait for 3 * TCLK; sig_a <= '0'; sig_b <= '0';
        check(0, "3a A y B coinciden (sin cuenta)");
        -- 3b. cuenta en marcha (A hace 50), luego A y B a la vez -> captura 49 y arranca otra; B 30 despues -> 29
        wait for 20 * TCLK;
        pulso(sig_a, 3); wait for 47 * TCLK;
        sig_a <= '1'; sig_b <= '1'; wait for 3 * TCLK; sig_a <= '0'; sig_b <= '0';
        check(49, "3b A y B coinciden (con cuenta): captura");
        wait for 21 * TCLK; pulso(sig_b, 3);
        check(29, "3b nueva cuenta tras la coincidencia");

        -- 4. A asincrono: flanco 3 ns / 7 ns despues del flanco de reloj -> 98..100 (+-1 de cuantizacion)
        wait for 20 * TCLK; wait until rising_edge(clk); wait for 3 ns;
        sig_a <= '1'; wait for 3 * TCLK; sig_a <= '0';
        wait until rising_edge(clk); wait for 96 * TCLK; pulso(sig_b, 3);
        wait for 6 * TCLK; c1 := to_integer(unsigned(count));
        wait for 20 * TCLK; wait until rising_edge(clk); wait for 7 ns;
        sig_a <= '1'; wait for 3 * TCLK; sig_a <= '0';
        wait until rising_edge(clk); wait for 96 * TCLK; pulso(sig_b, 3);
        wait for 6 * TCLK; c2 := to_integer(unsigned(count));
        assert (c1 >= 98 and c1 <= 100) and (c2 >= 98 and c2 <= 100)
            report "4 A asincrono: " & integer'image(c1) & " / " & integer'image(c2) severity failure;
        report "4 A asincrono OK (" & integer'image(c1) & " / " & integer'image(c2) & ")";

        report "TB_MZ_AXI_PHASE_DETECTOR: TODO OK";
        done <= true;
        wait;
    end process;
end sim;
