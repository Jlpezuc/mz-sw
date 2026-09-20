----------------------------------------------------------------------------------
-- MZ_CLOCK_DIV : divisor de reloj configurable por AXI4-Lite
--
--   clk_out = clk / DIVIDER,  para cualquier DIVIDER >= 1
--
-- Registros (32 bit):
--   0x00  DIVIDER  (RW)  factor de division, >= 1 (0 se trata como 1). Se carga al habilitar.
--   0x04  CONTROL  (RW)  bit 0: ENABLE. Secuencia: ENABLE = 0, escribir DIVIDER, ENABLE = 1.
--   0x08  STATUS   (RO)  bit 0: RUNNING (contador en marcha), bit 1: resetn (p. ej. 'locked').
--
-- Dominios de reloj: el esclavo AXI va con s00_axi_aclk; el contador con 'clk' (el reloj
-- que se divide, p. ej. la salida de un Clocking Wizard). 'resetn' es el reset (activo
-- bajo) del contador: conectar 'locked' del Clocking Wizard.
--
-- * DIVIDER = 1 : clk_out = clk (paso directo), flag_out = '1'.
-- * DIVIDER par : 50 % de ciclo de trabajo; impar: alto (N+1)/2, bajo (N-1)/2 ciclos.
-- * flag_out : pulso de un ciclo de clk en cada flanco de subida de clk_out.
-- clk_out es una senal logica (no un reloj de BUFG): para interrupciones, triggers y enables.
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MZ_CLOCK_DIV is
    generic (
        C_S00_AXI_DATA_WIDTH : integer := 32;
        C_S00_AXI_ADDR_WIDTH : integer := 4
    );
    port (
        -- reloj a dividir y su reset
        clk      : in  std_logic;
        resetn   : in  std_logic;
        clk_out  : out std_logic;
        flag_out : out std_logic;
        -- AXI4-Lite
        s00_axi_aclk    : in  std_logic;
        s00_axi_aresetn : in  std_logic;
        s00_axi_awaddr  : in  std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
        s00_axi_awprot  : in  std_logic_vector(2 downto 0);
        s00_axi_awvalid : in  std_logic;
        s00_axi_awready : out std_logic;
        s00_axi_wdata   : in  std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
        s00_axi_wstrb   : in  std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
        s00_axi_wvalid  : in  std_logic;
        s00_axi_wready  : out std_logic;
        s00_axi_bresp   : out std_logic_vector(1 downto 0);
        s00_axi_bvalid  : out std_logic;
        s00_axi_bready  : in  std_logic;
        s00_axi_araddr  : in  std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
        s00_axi_arprot  : in  std_logic_vector(2 downto 0);
        s00_axi_arvalid : in  std_logic;
        s00_axi_arready : out std_logic;
        s00_axi_rdata   : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
        s00_axi_rresp   : out std_logic_vector(1 downto 0);
        s00_axi_rvalid  : out std_logic;
        s00_axi_rready  : in  std_logic
    );
end MZ_CLOCK_DIV;

architecture arch_imp of MZ_CLOCK_DIV is
    component MZ_CLOCK_DIV_S00_AXI is
        generic (
            C_S_AXI_DATA_WIDTH : integer := 32;
            C_S_AXI_ADDR_WIDTH : integer := 4
        );
        port (
            reg_0_axi_out : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            reg_1_axi_out : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            reg_2_axi_in  : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            S_AXI_ACLK    : in std_logic;
            S_AXI_ARESETN : in std_logic;
            S_AXI_AWADDR  : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
            S_AXI_AWPROT  : in std_logic_vector(2 downto 0);
            S_AXI_AWVALID : in std_logic;
            S_AXI_AWREADY : out std_logic;
            S_AXI_WDATA   : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            S_AXI_WSTRB   : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
            S_AXI_WVALID  : in std_logic;
            S_AXI_WREADY  : out std_logic;
            S_AXI_BRESP   : out std_logic_vector(1 downto 0);
            S_AXI_BVALID  : out std_logic;
            S_AXI_BREADY  : in std_logic;
            S_AXI_ARADDR  : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
            S_AXI_ARPROT  : in std_logic_vector(2 downto 0);
            S_AXI_ARVALID : in std_logic;
            S_AXI_ARREADY : out std_logic;
            S_AXI_RDATA   : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            S_AXI_RRESP   : out std_logic_vector(1 downto 0);
            S_AXI_RVALID  : out std_logic;
            S_AXI_RREADY  : in std_logic
        );
    end component;

    component MZ_CLOCK_DIV_CORE is
        port (
            clk      : in  std_logic;
            resetn   : in  std_logic;
            enable   : in  std_logic;
            divider  : in  std_logic_vector(31 downto 0);
            running  : out std_logic;
            clk_out  : out std_logic;
            flag_out : out std_logic
        );
    end component;

    signal reg_divider : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal reg_control : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal reg_status  : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    signal running     : std_logic;
    signal run_meta, run_sync : std_logic := '0';   -- running -> dominio AXI
    attribute ASYNC_REG : string;
    attribute ASYNC_REG of run_meta : signal is "TRUE";
    attribute ASYNC_REG of run_sync : signal is "TRUE";
begin
    axi_inst : MZ_CLOCK_DIV_S00_AXI
        generic map (C_S_AXI_DATA_WIDTH => C_S00_AXI_DATA_WIDTH, C_S_AXI_ADDR_WIDTH => C_S00_AXI_ADDR_WIDTH)
        port map (
            reg_0_axi_out => reg_divider,
            reg_1_axi_out => reg_control,
            reg_2_axi_in  => reg_status,
            S_AXI_ACLK => s00_axi_aclk, S_AXI_ARESETN => s00_axi_aresetn,
            S_AXI_AWADDR => s00_axi_awaddr, S_AXI_AWPROT => s00_axi_awprot, S_AXI_AWVALID => s00_axi_awvalid, S_AXI_AWREADY => s00_axi_awready,
            S_AXI_WDATA => s00_axi_wdata, S_AXI_WSTRB => s00_axi_wstrb, S_AXI_WVALID => s00_axi_wvalid, S_AXI_WREADY => s00_axi_wready,
            S_AXI_BRESP => s00_axi_bresp, S_AXI_BVALID => s00_axi_bvalid, S_AXI_BREADY => s00_axi_bready,
            S_AXI_ARADDR => s00_axi_araddr, S_AXI_ARPROT => s00_axi_arprot, S_AXI_ARVALID => s00_axi_arvalid, S_AXI_ARREADY => s00_axi_arready,
            S_AXI_RDATA => s00_axi_rdata, S_AXI_RRESP => s00_axi_rresp, S_AXI_RVALID => s00_axi_rvalid, S_AXI_RREADY => s00_axi_rready
        );

    core_inst : MZ_CLOCK_DIV_CORE
        port map (
            clk => clk, resetn => resetn,
            enable => reg_control(0), divider => reg_divider,
            running => running, clk_out => clk_out, flag_out => flag_out
        );

    -- estado hacia el dominio AXI
    process (s00_axi_aclk)
    begin
        if rising_edge(s00_axi_aclk) then
            run_meta <= running;
            run_sync <= run_meta;
        end if;
    end process;
    reg_status(0) <= run_sync;
    reg_status(1) <= resetn;
end arch_imp;
