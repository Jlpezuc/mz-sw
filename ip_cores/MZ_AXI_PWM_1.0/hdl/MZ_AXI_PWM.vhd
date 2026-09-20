library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity MZ_AXI_PWM is
	generic (
		-- Users to add parameters here

		CONTROL_REG_DEFAULT     : integer := 0;
		MAX_VALUE_REG_DEFAULT   : integer := 10000;
		COMP_REG_DEFAULT        : integer := 2500;

		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 4
	);
	port (
		-- Users to add ports here

		-- Inversor 1 (referencia, 0 grados)
		G1 : out std_logic;
		G2 : out std_logic;

		-- Inversor 2 (desfasado 90 grados)
		G3 : out std_logic;
		G4 : out std_logic;

		enable : out std_logic;

		pwm_clk : in std_logic;

		square : out std_logic;

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
end MZ_AXI_PWM;

architecture arch_imp of MZ_AXI_PWM is

    signal control_reg: std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal max_value_reg: unsigned(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal comp_reg: unsigned(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal free_reg: std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);

    -- Cruce de dominios AXI (s00_axi_aclk) -> pwm_clk. Los relojes son distintos (p. ej. 100 y 200 MHz,
    -- ambos del mismo MMCM), asi que los registros AXI no se usan directamente en la logica del contador:
    --  1. se copian cada ciclo a registros del dominio pwm_clk (*_axi_q): el cruce queda como FF -> FF
    --     directo, corto y analizable por Vivado (relojes relacionados);
    --  2. los valores en uso (*_q) se cargan desde esas copias al INICIO de cada periodo (contador = 0)
    --     o mientras el PWM esta parado: un cambio de periodo o de duty desde el software nunca corta
    --     el pulso en curso y todos los valores derivados cambian a la vez.
    -- El producto duty x periodo va en un pipeline de 2 etapas (32 x 32 bits) para cerrar timing.
    signal control_axi_q  : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    signal max_value_axi_q: unsigned(C_S00_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    signal comp_axi_q     : unsigned(C_S00_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    signal mult_stage1    : unsigned(2*C_S00_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    signal mult_stage2    : unsigned(2*C_S00_AXI_DATA_WIDTH-1 downto 0) := (others => '0');

    signal enable_buff: std_logic := '0';
    signal reset_buff: std_logic := '0';
    signal max_value_q : unsigned(C_S00_AXI_DATA_WIDTH-1 downto 0) := (others => '0');

    -- Contador real
    signal counter0_value: unsigned(C_S00_AXI_DATA_WIDTH-1 downto 0);

    -- Contadores "falsos" (versiones desfasadas del contador real)
    signal counter1_value: unsigned(C_S00_AXI_DATA_WIDTH-1 downto 0);  -- 180 grados
    signal counter2_value: unsigned(C_S00_AXI_DATA_WIDTH-1 downto 0);  --  90 grados
    signal counter3_value: unsigned(C_S00_AXI_DATA_WIDTH-1 downto 0);  -- 270 grados

    -- Offsets de fase
    signal half_value         : unsigned(C_S00_AXI_DATA_WIDTH-1 downto 0);  -- max/2
    signal quarter_value      : unsigned(C_S00_AXI_DATA_WIDTH-1 downto 0);  -- max/4
    signal three_quarter_value: unsigned(C_S00_AXI_DATA_WIDTH-1 downto 0);  -- 3*max/4

    -- Complementos (max - offset), para evitar restar dos veces en la logica
    signal comp_half         : unsigned(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal comp_quarter      : unsigned(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal comp_three_quarter: unsigned(C_S00_AXI_DATA_WIDTH-1 downto 0);

    signal comp_value : unsigned(C_S00_AXI_DATA_WIDTH-1 downto 0) := (others => '0');

    constant SHIFT_BITS : positive := positive(ceil(log2(real(C_S00_AXI_DATA_WIDTH))));

	-- component declaration
	component MZ_AXI_PWM_S00_AXI is
		generic (

		CONTROL_REG_DEFAULT     : integer := 3;
		MAX_VALUE_REG_DEFAULT   : integer := 10000;
		COMP_REG_DEFAULT        : integer := 2500;

		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 4
		);
		port (

		S_AXI_REG0 : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        S_AXI_REG1 : out unsigned(C_S_AXI_DATA_WIDTH-1 downto 0);
        S_AXI_REG2 : out unsigned(C_S_AXI_DATA_WIDTH-1 downto 0);
        S_AXI_REG3 : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);

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
	end component MZ_AXI_PWM_S00_AXI;

begin

-- Instantiation of Axi Bus Interface S00_AXI
AXI_PWM_slave_lite_v1_0_S00_AXI_inst : MZ_AXI_PWM_S00_AXI
	generic map (

	    CONTROL_REG_DEFAULT => CONTROL_REG_DEFAULT,
	    MAX_VALUE_REG_DEFAULT => MAX_VALUE_REG_DEFAULT,
	    COMP_REG_DEFAULT => COMP_REG_DEFAULT,

		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
	    S_AXI_REG0	=> control_reg,
		S_AXI_REG1	=> max_value_reg,
		S_AXI_REG2	=> comp_reg,
		S_AXI_REG3	=> free_reg,

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

	enable <= enable_buff;

    -- 1. copia de los registros AXI al dominio pwm_clk (cruce FF -> FF) y pipeline del producto
    process(pwm_clk)
    begin
        if rising_edge(pwm_clk) then
            control_axi_q   <= control_reg;
            max_value_axi_q <= max_value_reg;
            comp_axi_q      <= comp_reg;
            mult_stage1     <= comp_axi_q * max_value_axi_q;   -- duty (Q0.32) x periodo
            mult_stage2     <= mult_stage1;
        end if;
    end process;

    -- 2. valores en uso: se cargan al inicio del periodo o con el PWM parado (enable = 0 / reset)
    process(pwm_clk)
    begin
        if rising_edge(pwm_clk) then
            enable_buff <= control_axi_q(0);
            reset_buff  <= control_axi_q(1);
            if counter0_value = 0 or enable_buff = '0' or reset_buff = '1' then
                max_value_q         <= max_value_axi_q;
                comp_value          <= mult_stage2(2*C_S00_AXI_DATA_WIDTH-1 downto C_S00_AXI_DATA_WIDTH);
                half_value          <= shift_right(max_value_axi_q, 1);                                   -- max/2  -> 180 grados
                quarter_value       <= shift_right(max_value_axi_q, 2);                                   -- max/4  ->  90 grados
                three_quarter_value <= shift_right(max_value_axi_q, 1) + shift_right(max_value_axi_q, 2); -- 3max/4 -> 270 grados
                comp_half           <= max_value_axi_q - shift_right(max_value_axi_q, 1);
                comp_quarter        <= max_value_axi_q - shift_right(max_value_axi_q, 2);
                comp_three_quarter  <= max_value_axi_q - (shift_right(max_value_axi_q, 1) + shift_right(max_value_axi_q, 2));
            end if;
        end if;
    end process;

    -- Contador principal (unico contador real); periodo = max_value_q ciclos
    process(pwm_clk)
    begin
        if rising_edge(pwm_clk) then
            if S00_AXI_ARESETN = '0' or reset_buff = '1' then
                counter0_value <= (others => '0');
            else
                if counter0_value >= max_value_q - 1 then
                    counter0_value <= (others => '0');
                else
                    counter0_value <= counter0_value + 1;
                end if;
            end if;
        end if;
    end process;

    -- Contadores "falsos": suma modulo max_value_q del contador real.
    -- Si counter0 + offset < max  -> suma directa
    -- Si no                       -> counter0 - (max - offset)   (equivale a la suma menos max)

    -- 180 grados (pierna 2 del inversor 1)
    counter1_value <= counter0_value + half_value
                      when counter0_value < comp_half else
                      counter0_value - comp_half;

    -- 90 grados (pierna 1 del inversor 2)
    counter2_value <= counter0_value + quarter_value
                      when counter0_value < comp_quarter else
                      counter0_value - comp_quarter;

    -- 270 grados (pierna 2 del inversor 2 = 90 + 180)
    counter3_value <= counter0_value + three_quarter_value
                      when counter0_value < comp_three_quarter else
                      counter0_value - comp_three_quarter;

    -- Inversor 1
    G1 <= '1' when enable_buff = '1' and counter0_value < comp_value else '0';
    G2 <= '1' when enable_buff = '1' and counter1_value < comp_value else '0';

    -- Inversor 2 (desfasado 90 grados respecto al inversor 1)
    G3 <= '1' when enable_buff = '1' and counter2_value < comp_value else '0';
    G4 <= '1' when enable_buff = '1' and counter3_value < comp_value else '0';

    square <= '1' when enable_buff = '1' and counter0_value < half_value else '0';

	-- User logic ends

end arch_imp;