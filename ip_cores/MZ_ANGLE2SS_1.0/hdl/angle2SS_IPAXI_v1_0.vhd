library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity angle2SS_IPAXI_v1_0 is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 6
	);
	port (
		-- Users to add ports here
		
        -- Salidas de conmutacion trifasicas
        phase_A_ss : out std_logic;
        phase_B_ss : out std_logic;
        phase_C_ss: out std_logic;
        states_valid_out  : out std_logic; 
        
        -- Debug signal
        debug_signal1a: out unsigned(21 downto 0);
        debug_signal1b: out unsigned(21 downto 0);
        debug_signal1c: out unsigned(21 downto 0);
        
        debug_signal2: out std_logic;
        debug_signal3: out  std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0); 

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
end angle2SS_IPAXI_v1_0;

architecture arch_imp of angle2SS_IPAXI_v1_0 is

	-- component declaration
	component angle2SS_IPAXI_v1_0_S00_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 6
		);
		port (
		-- User data out port
		AXI_angle0_reg    : out  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		AXI_angle1_reg    : out  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		AXI_angle2_reg    : out  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		AXI_angle3_reg    : out  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		AXI_angle4_reg    : out  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		AXI_angle5_reg    : out  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		AXI_angle6_reg    : out  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		AXI_angle7_reg    : out  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		AXI_angle8_reg    : out  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		AXI_angle9_reg    : out  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		AXI_angle10_reg    : out  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		AXI_newangles_reg    : out  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- end User data out
		
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
	end component angle2SS_IPAXI_v1_0_S00_AXI;
    
    component angle2SS_modulation is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32
		);
        -- Puertos
        port (  
        clk: in std_logic;
        reset: in std_logic;
              
        angle0_reg: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        angle1_reg: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        angle2_reg: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        angle3_reg: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        angle4_reg: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        angle5_reg: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        angle6_reg: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        angle7_reg: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        angle8_reg: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        angle9_reg: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        angle10_reg: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        
        new_angles_reg: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        
        phase_A_state : out std_logic;
        phase_B_state : out std_logic;
        phase_C_state : out std_logic;
        states_valid  : out std_logic;
        
        --Debug
        phase_counter_a_out : out unsigned(21 downto 0);  
        phase_counter_b_out : out unsigned(21 downto 0);  
        phase_counter_c_out : out unsigned(21 downto 0)   
        );
    end component angle2SS_modulation;
    
    -- User Internal mapping signal
    signal axi2module_reg0  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal axi2module_reg1  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal axi2module_reg2  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal axi2module_reg3  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal axi2module_reg4  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal axi2module_reg5  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal axi2module_reg6  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal axi2module_reg7  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal axi2module_reg8  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal axi2module_reg9  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal axi2module_reg10  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal axi2module_reg11  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    
    signal counterA_out_int :  unsigned(21 downto 0);
    signal counterB_out_int :  unsigned(21 downto 0);
    signal counterC_out_int :  unsigned(21 downto 0);
    
begin

-- Instantiation of Axi Bus Interface S00_AXI
angle2SS_IPAXI_v1_0_S00_AXI_inst : angle2SS_IPAXI_v1_0_S00_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH
		--C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
	    -- User port map
	    AXI_angle0_reg => axi2module_reg0,
	    AXI_angle1_reg => axi2module_reg1,
	    AXI_angle2_reg => axi2module_reg2,
	    AXI_angle3_reg => axi2module_reg3,
	    AXI_angle4_reg => axi2module_reg4,
	    AXI_angle5_reg => axi2module_reg5,
	    AXI_angle6_reg => axi2module_reg6,
	    AXI_angle7_reg => axi2module_reg7,
	    AXI_angle8_reg => axi2module_reg8,
	    AXI_angle9_reg => axi2module_reg9,
	    AXI_angle10_reg => axi2module_reg10,
	    AXI_newangles_reg => axi2module_reg11,
	    
	    -- End user port map
	       
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
	
	-- INSTANCIA IP CORE SIN AXI
	angle2SS_modulation_ins : angle2SS_modulation
	port map(
	   clk      => s00_axi_aclk,
	   reset    => s00_axi_aresetn,
	   
	   phase_A_state   => phase_A_ss,
	   phase_B_state   => phase_B_ss,
	   phase_C_state   => phase_C_ss,
	   states_valid     => states_valid_out,
	   
	   angle0_reg  => axi2module_reg0,
	   angle1_reg  => axi2module_reg1,
	   angle2_reg  => axi2module_reg2,
	   angle3_reg  => axi2module_reg3,
	   angle4_reg  => axi2module_reg4,
	   angle5_reg  => axi2module_reg5,
	   angle6_reg  => axi2module_reg6,
	   angle7_reg  => axi2module_reg7,
	   angle8_reg  => axi2module_reg8,
	   angle9_reg  => axi2module_reg9,
	   angle10_reg  => axi2module_reg10,
	   new_angles_reg  => axi2module_reg11,
	   
	   phase_counter_a_out   =>  counterA_out_int,
	   phase_counter_b_out   =>  counterB_out_int,
	   phase_counter_c_out   =>  counterC_out_int
	); 
	-- User logic ends
	
    debug_signal1a   <= counterA_out_int;
    debug_signal1b   <= counterB_out_int;
    debug_signal1c   <= counterC_out_int;
    
    debug_signal2   <= axi2module_reg11(0);
    debug_signal3   <= axi2module_reg1;
    

end arch_imp;
