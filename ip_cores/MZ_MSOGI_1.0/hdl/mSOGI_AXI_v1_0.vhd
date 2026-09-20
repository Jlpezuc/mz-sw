library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mSOGI_AXI_v1_0 is
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
		med_ready_in :   in std_logic;    
		
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
end mSOGI_AXI_v1_0;

architecture arch_imp of mSOGI_AXI_v1_0 is

	-- component declaration
	component mSOGI_AXI_v1_0_S00_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 6
		);
		port (
		
		-- Users to add ports here
		AXI_x_a_reg0  : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		AXI_x_b_reg1  : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		AXI_x_a_reg2  : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		AXI_x_b_reg3  : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		AXI_x_a_reg4  : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		AXI_x_b_reg5  : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		AXI_x_a_reg6  : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		AXI_x_b_reg7  : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		AXI_x_a_reg8  : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		AXI_x_b_reg9  : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		
		AXI_e_reg10  : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		AXI_kf1_reg11  : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		AXI_kf2_reg12  : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		AXI_kf3_reg13  : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		AXI_kf4_reg14  : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		AXI_kf5_reg15  : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);

		-- User ports ends
		
		
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
	end component mSOGI_AXI_v1_0_S00_AXI;
	
	-- mSogi
    component sogi_1 is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32
		);
        -- Puertos
        port (  
        clk: in std_logic;
        reset: in std_logic;
              
        x_a_in: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        x_b_in: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        e: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        --nu: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        k_factor: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        
        med_ready: in std_logic;
        
        h_out: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        phi_out: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        out_valid  : out std_logic
        );
    end component sogi_1;
    
    -- User Internal mapping signal
    signal axi2sogi1_reg0  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal axi2sogi1_reg1  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0); 
    signal axi2sogi2_reg2  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0); 
    signal axi2sogi2_reg3  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0); 
    signal axi2sogi3_reg4  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0); 
    signal axi2sogi3_reg5  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal axi2sogi4_reg6  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0); 
    signal axi2sogi4_reg7  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal axi2sogi5_reg8  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);    
    signal axi2sogi5_reg9  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0); 
    signal axi2sogi_e_reg10  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal axi2sogi_kf1_reg11  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0); 
    signal axi2sogi_kf2_reg12  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0); 
    signal axi2sogi_kf3_reg13  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0); 
    signal axi2sogi_kf4_reg14  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal axi2sogi_kf5_reg15  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);  
    
    signal sogi1_filt_h  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal sogi1_filt_phi  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal sogi2_filt_h  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal sogi2_filt_phi  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0); 
    signal sogi3_filt_h  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal sogi3_filt_phi  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);   
    signal sogi4_filt_h  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal sogi4_filt_phi  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0); 
    signal sogi5_filt_h  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal sogi5_filt_phi  :   std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    
    signal s1_out_valid  : std_logic;
    signal s2_out_valid  : std_logic;
    signal s3_out_valid  : std_logic;
    signal s4_out_valid  : std_logic;
    signal s5_out_valid  : std_logic;
    
           
begin

-- Instantiation of Axi Bus Interface S00_AXI
mSOGI_AXI_v1_0_S00_AXI_inst : mSOGI_AXI_v1_0_S00_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
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
		S_AXI_RREADY	=> s00_axi_rready,
		
	    -- User port map
	    AXI_x_a_reg0 => axi2sogi1_reg0,
	    AXI_x_b_reg1 => axi2sogi1_reg1,
	    AXI_x_a_reg2 => axi2sogi2_reg2,
	    AXI_x_b_reg3 => axi2sogi2_reg3,
	    AXI_x_a_reg4 => axi2sogi3_reg4,
	    AXI_x_b_reg5 => axi2sogi3_reg5,
	    AXI_x_a_reg6 => axi2sogi4_reg6,
	    AXI_x_b_reg7 => axi2sogi4_reg7,
	    AXI_x_a_reg8 => axi2sogi5_reg8,
	    AXI_x_b_reg9 => axi2sogi5_reg9,
	    AXI_e_reg10 => axi2sogi_e_reg10,
	    AXI_kf1_reg11  =>  axi2sogi_kf1_reg11,
	    AXI_kf2_reg12  =>  axi2sogi_kf2_reg12,
	    AXI_kf3_reg13  =>  axi2sogi_kf3_reg13,
	    AXI_kf4_reg14  =>  axi2sogi_kf4_reg14,
	    AXI_kf5_reg15  =>  axi2sogi_kf5_reg15
	    
	    -- End user port map
	);

	-- Add user logic here
sogi_1_inst: sogi_1
    generic map (
    C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH
    )
    -- Puertos
    port map (
    clk      => s00_axi_aclk,
    reset    => s00_axi_aresetn,
    
    x_a_in      =>  axi2sogi1_reg0,
    x_b_in      =>  axi2sogi1_reg1,
    e           =>  axi2sogi_e_reg10,
    k_factor    =>  axi2sogi_kf1_reg11,
    med_ready   =>  med_ready_in,
    
    h_out     =>  sogi1_filt_h,
    phi_out     =>  sogi1_filt_phi,
    out_valid     =>  s1_out_valid
    );
	-- User logic ends

end arch_imp;
