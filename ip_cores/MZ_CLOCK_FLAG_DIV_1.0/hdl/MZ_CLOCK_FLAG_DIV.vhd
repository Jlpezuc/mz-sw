library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MZ_CLOCK_FLAG_DIV is
	generic (
		-- Users to add parameters here
        sincronizar_clock_base : STD_LOGIC := '1'  ;
		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 4
	);
	port (
		-- Users to add ports here

		--
		clk : in std_logic;                 -- reloj a dividir (dominio propio, p. ej. la salida del Clocking Wizard)
		clock_base_2sync : in std_logic;    -- sincronismo de arranque (se sincroniza internamente a 'clk')
		clk_output : out  STD_LOGIC ;
		flag_output : out  STD_LOGIC ;
		--

		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic
	);
end MZ_CLOCK_FLAG_DIV;

architecture arch_imp of MZ_CLOCK_FLAG_DIV is

	-- component declaration
	component MZ_CLOCK_FLAG_DIV_S00_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 4
		);
		port (
		--
		reg_0_axi_out  : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		reg_1_axi_out  : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		--
		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic
		);
	end component MZ_CLOCK_FLAG_DIV_S00_AXI;

	component MZ_CLOCK_FLAG_DIV_CORE is
	generic (
        sincronizar_clock_base : STD_LOGIC := '1'
          -- 1 es signed, 0 es unsigned
    );
    Port ( clk_in : in  STD_LOGIC ;
           reset : in  STD_LOGIC ;
           clock_base_sync : in std_logic;
           frec_divider : in  std_logic_vector(31 downto 0) ;
           clk_out : out  STD_LOGIC ;
           flag_out : out  STD_LOGIC );
    end component MZ_CLOCK_FLAG_DIV_CORE;


	-- RESET DE CLOCK (dominio AXI) y su version sincronizada al dominio 'clk'
	signal RESET_CLOCK_SIG :  STD_LOGIC := '1' ;
	signal RESET_META, RESET_SYNC : STD_LOGIC := '1' ;
	attribute ASYNC_REG : string;
	attribute ASYNC_REG of RESET_META : signal is "TRUE";
	attribute ASYNC_REG of RESET_SYNC : signal is "TRUE";


	-- SEÑALES PARA MOVER DATA
	signal REG_0_SIG_FREC_DIV  :  std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
	signal REG_1_SIG_EN_RST_PROCE  :  std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
	-- REG_1_SIG_EN_RST_PROCE(1) = ENABLE DE PROCE
	-- REG_1_SIG_EN_RST_PROCE(0) = RESET DE PROCE


begin

-- Instantiation of Axi Bus Interface S00_AXI
clock_flag_div_axi_mz_v1_0_S00_AXI_inst : MZ_CLOCK_FLAG_DIV_S00_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
	    --
	    reg_0_axi_out => REG_0_SIG_FREC_DIV ,
	    reg_1_axi_out => REG_1_SIG_EN_RST_PROCE ,
	    --
		S_AXI_ACLK	=> s00_axi_aclk,
		S_AXI_ARESETN	=> s00_axi_aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,
		S_AXI_AWPROT	=> s00_axi_awprot,
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA	=> s00_axi_wdata,
		S_AXI_WSTRB	=> s00_axi_wstrb,
		S_AXI_WVALID	=> s00_axi_wvalid,
		S_AXI_WREADY	=> s00_axi_wready,
		S_AXI_BRESP	=> s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA	=> s00_axi_rdata,
		S_AXI_RRESP	=> s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready
	);

	-- Add user logic here

	-- RESET CLOCK :  reset axi || not enable proce || reset proce  (dominio AXI)
	RESET_CLOCK_SIG <= (not s00_axi_aresetn) or (not REG_1_SIG_EN_RST_PROCE(1)) or (REG_1_SIG_EN_RST_PROCE(0)) ;
	-- sincronizador de 2 etapas hacia el dominio 'clk' (frec_divider es estatico mientras hay reset)
	process (clk)
	begin
	    if rising_edge(clk) then
	        RESET_META <= RESET_CLOCK_SIG ;
	        RESET_SYNC <= RESET_META ;
	    end if ;
	end process ;

	-- INSTANCIA IPCORE SIN AXI
	custom_clock_flag_divider_inst : MZ_CLOCK_FLAG_DIV_CORE
	generic map (
       sincronizar_clock_base => sincronizar_clock_base
    )
	port map (
	   --
	   clk_in => clk ,
	   reset  => RESET_SYNC ,
	   --
	   clock_base_sync => clock_base_2sync ,
	   frec_divider    => REG_0_SIG_FREC_DIV  ,
	   --
	   clk_out  => clk_output ,
	   flag_out  => flag_output
	   --
	);



	-- User logic ends

end arch_imp;
