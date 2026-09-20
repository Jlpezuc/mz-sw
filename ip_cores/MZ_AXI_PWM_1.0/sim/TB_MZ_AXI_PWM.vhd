----------------------------------------------------------------------------------
-- TB_MZ_AXI_PWM : PWM con el bus AXI a 100 MHz y pwm_clk a 200 MHz (dominios distintos).
-- Escribe los registros por AXI4-Lite y mide G1 / square con pwm_clk.
--
-- Comprueba:
--   1. periodo y duty programados (periodo 1000 ciclos, duty 0.25 -> G1 alto 250 ciclos)
--   2. square = 50 % del periodo, alineada con G1
--   3. un cambio de periodo/duty escrito a mitad del periodo se aplica al inicio del
--      periodo siguiente: el pulso en curso no se acorta ni se alarga
--   4. enable = 0 apaga las salidas; al volver a 1 arranca con los valores nuevos
--
-- xvhdl --work work ../hdl/MZ_AXI_PWM_S00_AXI.vhd ../hdl/MZ_AXI_PWM.vhd TB_MZ_AXI_PWM.vhd
-- xelab TB_MZ_AXI_PWM -s tb && xsim tb -R
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TB_MZ_AXI_PWM is
end TB_MZ_AXI_PWM;

architecture sim of TB_MZ_AXI_PWM is
    constant T_AXI : time := 10 ns;   -- 100 MHz
    constant T_PWM : time := 5 ns;    -- 200 MHz
    signal aclk, pwm_clk : std_logic := '0';
    signal aresetn : std_logic := '0';
    signal done : boolean := false;
    signal G1, G2, G3, G4, enable, square : std_logic;
    -- AXI4-Lite
    signal awaddr  : std_logic_vector(3 downto 0) := (others => '0');
    signal awvalid, wvalid, bready, arvalid, rready : std_logic := '0';
    signal awready, wready, bvalid, arready, rvalid : std_logic;
    signal wdata   : std_logic_vector(31 downto 0) := (others => '0');
    signal wstrb   : std_logic_vector(3 downto 0) := "1111";
    signal bresp, rresp : std_logic_vector(1 downto 0);
    signal rdata : std_logic_vector(31 downto 0);
    signal araddr : std_logic_vector(3 downto 0) := (others => '0');
    signal prot : std_logic_vector(2 downto 0) := (others => '0');
    -- medida
    signal cnt_high, cnt_period, last_high, last_period, last_sq_high : integer := 0;
    signal g1_d : std_logic := '0';
    signal sq_high : integer := 0;
begin
    aclk    <= not aclk    after T_AXI / 2 when not done;
    pwm_clk <= not pwm_clk after T_PWM / 2 when not done;

    dut : entity work.MZ_AXI_PWM
        generic map (CONTROL_REG_DEFAULT => 0, MAX_VALUE_REG_DEFAULT => 1000, COMP_REG_DEFAULT => 0)
        port map (
            G1 => G1, G2 => G2, G3 => G3, G4 => G4, enable => enable, pwm_clk => pwm_clk, square => square,
            s00_axi_aclk => aclk, s00_axi_aresetn => aresetn,
            s00_axi_awaddr => awaddr, s00_axi_awprot => prot, s00_axi_awvalid => awvalid, s00_axi_awready => awready,
            s00_axi_wdata => wdata, s00_axi_wstrb => wstrb, s00_axi_wvalid => wvalid, s00_axi_wready => wready,
            s00_axi_bresp => bresp, s00_axi_bvalid => bvalid, s00_axi_bready => bready,
            s00_axi_araddr => araddr, s00_axi_arprot => prot, s00_axi_arvalid => arvalid, s00_axi_arready => arready,
            s00_axi_rdata => rdata, s00_axi_rresp => rresp, s00_axi_rvalid => rvalid, s00_axi_rready => rready);

    -- medida de G1 y square en pwm_clk: ancho de pulso y periodo (entre flancos de subida de G1)
    medida : process(pwm_clk)
    begin
        if rising_edge(pwm_clk) then
            g1_d <= G1;
            if G1 = '1' and g1_d = '0' then          -- flanco de subida: cierra el periodo anterior
                last_period <= cnt_period;
                last_high   <= cnt_high;
                last_sq_high <= sq_high;
                cnt_period <= 1; cnt_high <= 1;
                if square = '1' then sq_high <= 1; else sq_high <= 0; end if;
            else
                cnt_period <= cnt_period + 1;
                if G1 = '1' then cnt_high <= cnt_high + 1; end if;
                if square = '1' then sq_high <= sq_high + 1; end if;
            end if;
        end if;
    end process;

    stim : process
        procedure axi_write(addr : integer; data : unsigned(31 downto 0)) is
        begin
            wait until rising_edge(aclk);
            awaddr <= std_logic_vector(to_unsigned(addr, 4)); awvalid <= '1';
            wdata <= std_logic_vector(data); wvalid <= '1'; bready <= '1';
            wait until rising_edge(aclk) and awready = '1' and wready = '1';
            awvalid <= '0'; wvalid <= '0';
            wait until rising_edge(aclk) and bvalid = '1';
            bready <= '0';
            wait until rising_edge(aclk);
        end procedure;
        procedure espera_periodos(n : integer) is
        begin
            for i in 1 to n loop
                wait until rising_edge(G1);
            end loop;
            wait for 20 * T_PWM;   -- que se actualicen last_*
        end procedure;
        procedure check(v, esperado : integer; msg : string) is
        begin
            assert v = esperado report msg & ": " & integer'image(v) & ", esperado " & integer'image(esperado) severity failure;
            report msg & " OK (" & integer'image(v) & ")";
        end procedure;
        variable duty025, duty050 : unsigned(31 downto 0);
    begin
        duty025 := x"40000000";                       -- 0.25 en Q0.32
        duty050 := x"80000000";                       -- 0.50
        wait for 5 * T_AXI; wait until rising_edge(aclk); aresetn <= '1'; wait for 5 * T_AXI;

        -- 1/2. periodo 1000, duty 0.25, enable
        axi_write(4, to_unsigned(1000, 32));
        axi_write(8, duty025);
        axi_write(0, to_unsigned(1, 32));
        espera_periodos(4);
        check(last_period, 1000, "1 periodo");
        check(last_high, 250, "1 ancho G1 (duty 0.25)");
        check(last_sq_high, 500, "2 square 50 %");

        -- 3. cambio de periodo y duty a mitad del periodo: el pulso en curso no cambia
        wait until rising_edge(G1); wait for 100 * T_PWM;       -- dentro del pulso alto (0..250)
        axi_write(4, to_unsigned(600, 32));
        axi_write(8, duty050);
        wait until rising_edge(G1); wait for 20 * T_PWM;         -- cierra el periodo en el que se escribio
        check(last_period, 1000, "3 periodo en curso intacto");
        check(last_high, 250, "3 pulso en curso intacto");
        espera_periodos(3);
        check(last_period, 600, "3 periodo nuevo");
        check(last_high, 300, "3 duty nuevo (0.5 de 600)");
        check(last_sq_high, 300, "3 square nueva");

        -- 4. enable = 0 -> salidas a 0; enable = 1 con periodo 400
        axi_write(0, to_unsigned(0, 32));
        wait for 700 * T_PWM;
        assert G1 = '0' and square = '0' and enable = '0' report "4 salidas no apagadas" severity failure;
        report "4 enable = 0 OK";
        axi_write(4, to_unsigned(400, 32));
        axi_write(0, to_unsigned(1, 32));
        espera_periodos(4);
        check(last_period, 400, "4 arranque con periodo nuevo");
        check(last_high, 200, "4 duty 0.5 de 400");

        report "TB_MZ_AXI_PWM: TODO OK";
        done <= true;
        wait;
    end process;
end sim;
