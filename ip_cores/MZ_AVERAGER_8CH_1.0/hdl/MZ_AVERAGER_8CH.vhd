library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MZ_AVERAGER_8CH is
    generic (
        largo_dato : integer range 1 to 64 := 16 ;    -- bits del dato
        MAX_AVG_LOG2 : integer range 0 to 20 := 8 ;   -- maximo de muestras a promediar = 2**MAX_AVG_LOG2
        valores_con_signo : STD_LOGIC := '1'  ;
        sincronizar_clock_base : STD_LOGIC := '1'  
          -- 1 es signed, 0 es unsigned
    );
    port (
        clk : in std_logic;
        resetn : in std_logic;
        enable_chs : in std_logic_vector(7 downto 0);
        n_datos_to_avg : in std_logic_vector(31 downto 0);  -- muestras a promediar (se redondea a 2**k, max 2**MAX_AVG_LOG2)
        flag_new_datas : in std_logic;
        clock_base_2sync : in std_logic; 
        --
        datos_in_ch7_to_ch0  :  in std_logic_vector(8*largo_dato-1 downto 0);
        --dato_in1  :  in std_logic_vector(largo_dato-1 downto 0);
        --dato_in2  :  in std_logic_vector(largo_dato-1 downto 0);
        --dato_in3  :  in std_logic_vector(largo_dato-1 downto 0);
        --dato_in4  :  in std_logic_vector(largo_dato-1 downto 0);
        --dato_in5  :  in std_logic_vector(largo_dato-1 downto 0);
        --dato_in6  :  in std_logic_vector(largo_dato-1 downto 0);
        --dato_in7  :  in std_logic_vector(largo_dato-1 downto 0);
        datos_out_ch7_to_ch0  :  out std_logic_vector(8*largo_dato-1 downto 0);
        --dato_avg0 : out std_logic_vector(largo_dato-1 downto 0);
        --dato_avg1 : out std_logic_vector(largo_dato-1 downto 0);
        --dato_avg2 : out std_logic_vector(largo_dato-1 downto 0);
        --dato_avg3 : out std_logic_vector(largo_dato-1 downto 0);
        --dato_avg4 : out std_logic_vector(largo_dato-1 downto 0);
        --dato_avg5 : out std_logic_vector(largo_dato-1 downto 0);
        --dato_avg6 : out std_logic_vector(largo_dato-1 downto 0);
        --dato_avg7 : out std_logic_vector(largo_dato-1 downto 0);
        --
        -- avg_done0_out : out std_logic;
        --leer_dato0_rep : out std_logic ;
        --cont_datos0_rep : out std_logic_vector(4 downto 0);
        --cont_calc_avg0_rep : out std_logic_vector(4 downto 0);
        avg_done_all : out std_logic
    );
end MZ_AVERAGER_8CH ;

architecture Behavioral of MZ_AVERAGER_8CH is



--
-- COMPONENTE DE PWM INDIVIDUAL 
--
 
component MZ_AVERAGER_8CH_CHANNEL is
    generic (
        N : integer range 1 to 64 := 16 ;
        MAX_AVG_LOG2 : integer range 0 to 20 := 8 ;
        valores_con_signo_ch : STD_LOGIC := '1'  ;
        sincronizar_clock_base : STD_LOGIC := '1'  
          -- 1 es signed, 0 es unsigned
    );
    Port ( clk_ch : in std_logic;
           resetn_ch : in std_logic;
           enable_ch : in std_logic;
           cant_datos : in std_logic_vector(31 downto 0); 
           clock_base_sync : in std_logic; 
           flag_new_data : in std_logic;
           --
           dato_in  :  in std_logic_vector(N-1 downto 0); 
           dato_avg : out std_logic_vector(N-1 downto 0);
           -- 
           avg_done_ch : out std_logic := '0' );
end component MZ_AVERAGER_8CH_CHANNEL ;
--
-- 

    signal DATO_AVG_0_SIG : std_logic_vector(largo_dato-1 downto 0) ;
    signal DATO_AVG_1_SIG : std_logic_vector(largo_dato-1 downto 0) ;
    signal DATO_AVG_2_SIG : std_logic_vector(largo_dato-1 downto 0) ;
    signal DATO_AVG_3_SIG : std_logic_vector(largo_dato-1 downto 0) ;
    signal DATO_AVG_4_SIG : std_logic_vector(largo_dato-1 downto 0) ;
    signal DATO_AVG_5_SIG : std_logic_vector(largo_dato-1 downto 0) ;
    signal DATO_AVG_6_SIG : std_logic_vector(largo_dato-1 downto 0) ;
    signal DATO_AVG_7_SIG : std_logic_vector(largo_dato-1 downto 0) ;

    signal AVG_DONE0 : std_logic := '0' ;
    signal AVG_DONE1 : std_logic := '0' ;
    signal AVG_DONE2 : std_logic := '0' ;
    signal AVG_DONE3 : std_logic := '0' ;
    signal AVG_DONE4 : std_logic := '0' ;
    signal AVG_DONE5 : std_logic := '0' ;
    signal AVG_DONE6 : std_logic := '0' ;
    signal AVG_DONE7 : std_logic := '0' ;


begin
    
    -- Inicio de process  
    -- Fin de process
    
    
    -- INSTANTIATION O MAPEO DE SEÑALES 
    --
    --
    channel_0 : MZ_AVERAGER_8CH_CHANNEL 
    generic map (
        N => largo_dato,
        MAX_AVG_LOG2 => MAX_AVG_LOG2,
        valores_con_signo_ch => valores_con_signo, 
        sincronizar_clock_base => sincronizar_clock_base
    )
    port map (
        clk_ch => clk ,
        resetn_ch => resetn ,
        enable_ch => enable_chs(0) ,
        cant_datos => n_datos_to_avg ,
        clock_base_sync => clock_base_2sync , 
        flag_new_data => flag_new_datas ,
        dato_in => datos_in_ch7_to_ch0(15 downto 0) ,
        dato_avg => datos_out_ch7_to_ch0(15 downto 0) ,
        avg_done_ch => AVG_DONE0
    ); 
    --
    
    --
    channel_1 : MZ_AVERAGER_8CH_CHANNEL 
    generic map (
        N => largo_dato,
        MAX_AVG_LOG2 => MAX_AVG_LOG2,
        valores_con_signo_ch => valores_con_signo, 
        sincronizar_clock_base => sincronizar_clock_base
    )
    port map (
        clk_ch => clk ,
        resetn_ch => resetn ,
        enable_ch => enable_chs(1) ,
        cant_datos => n_datos_to_avg ,
        clock_base_sync => clock_base_2sync , 
        flag_new_data => flag_new_datas ,
        dato_in => datos_in_ch7_to_ch0(31 downto 16) ,
        dato_avg => datos_out_ch7_to_ch0(31 downto 16) ,
        avg_done_ch => AVG_DONE1
    ); 
    --
    
    --
    channel_2 : MZ_AVERAGER_8CH_CHANNEL 
    generic map (
        N => largo_dato,
        MAX_AVG_LOG2 => MAX_AVG_LOG2,
        valores_con_signo_ch => valores_con_signo, 
        sincronizar_clock_base => sincronizar_clock_base
    )
    port map (
        clk_ch => clk ,
        resetn_ch => resetn ,
        enable_ch => enable_chs(2) ,
        cant_datos => n_datos_to_avg ,
        clock_base_sync => clock_base_2sync , 
        flag_new_data => flag_new_datas ,
        dato_in => datos_in_ch7_to_ch0(47 downto 32) ,
        dato_avg => datos_out_ch7_to_ch0(47 downto 32) ,
        avg_done_ch => AVG_DONE2
    ); 
    --
    
    --
    channel_3 : MZ_AVERAGER_8CH_CHANNEL 
    generic map (
        N => largo_dato,
        MAX_AVG_LOG2 => MAX_AVG_LOG2,
        valores_con_signo_ch => valores_con_signo, 
        sincronizar_clock_base => sincronizar_clock_base
    )
    port map (
        clk_ch => clk ,
        resetn_ch => resetn ,
        enable_ch => enable_chs(3) ,
        cant_datos => n_datos_to_avg ,
        clock_base_sync => clock_base_2sync , 
        flag_new_data => flag_new_datas ,
        dato_in => datos_in_ch7_to_ch0(63 downto 48) ,
        dato_avg => datos_out_ch7_to_ch0(63 downto 48) ,
        avg_done_ch => AVG_DONE3
    ); 
    --
    
    --
    channel_4 : MZ_AVERAGER_8CH_CHANNEL 
    generic map (
        N => largo_dato,
        MAX_AVG_LOG2 => MAX_AVG_LOG2,
        valores_con_signo_ch => valores_con_signo, 
        sincronizar_clock_base => sincronizar_clock_base
    )
    port map (
        clk_ch => clk ,
        resetn_ch => resetn ,
        enable_ch => enable_chs(4) ,
        cant_datos => n_datos_to_avg ,
        clock_base_sync => clock_base_2sync , 
        flag_new_data => flag_new_datas ,
        dato_in => datos_in_ch7_to_ch0(79 downto 64) ,
        dato_avg => datos_out_ch7_to_ch0(79 downto 64) ,
        avg_done_ch => AVG_DONE4
    ); 
    --
    
    --
    channel_5 : MZ_AVERAGER_8CH_CHANNEL 
    generic map (
        N => largo_dato,
        MAX_AVG_LOG2 => MAX_AVG_LOG2,
        valores_con_signo_ch => valores_con_signo, 
        sincronizar_clock_base => sincronizar_clock_base
    )
    port map (
        clk_ch => clk ,
        resetn_ch => resetn ,
        enable_ch => enable_chs(5) ,
        cant_datos => n_datos_to_avg ,
        clock_base_sync => clock_base_2sync , 
        flag_new_data => flag_new_datas ,
        dato_in => datos_in_ch7_to_ch0(95 downto 80) ,
        dato_avg => datos_out_ch7_to_ch0(95 downto 80) ,
        avg_done_ch => AVG_DONE5
    ); 
    --
    
    --
    channel_6 : MZ_AVERAGER_8CH_CHANNEL 
    generic map (
        N => largo_dato,
        MAX_AVG_LOG2 => MAX_AVG_LOG2,
        valores_con_signo_ch => valores_con_signo, 
        sincronizar_clock_base => sincronizar_clock_base
    )
    port map (
        clk_ch => clk ,
        resetn_ch => resetn ,
        enable_ch => enable_chs(6) ,
        cant_datos => n_datos_to_avg ,
        clock_base_sync => clock_base_2sync , 
        flag_new_data => flag_new_datas ,
        dato_in => datos_in_ch7_to_ch0(111 downto 96) ,
        dato_avg => datos_out_ch7_to_ch0(111 downto 96) ,
        avg_done_ch => AVG_DONE6
    ); 
    --
    
    --
    channel_7 : MZ_AVERAGER_8CH_CHANNEL 
    generic map (
        N => largo_dato,
        MAX_AVG_LOG2 => MAX_AVG_LOG2,
        valores_con_signo_ch => valores_con_signo, 
        sincronizar_clock_base => sincronizar_clock_base
    )
    port map (
        clk_ch => clk ,
        resetn_ch => resetn ,
        enable_ch => enable_chs(7) ,
        cant_datos => n_datos_to_avg ,
        clock_base_sync => clock_base_2sync , 
        flag_new_data => flag_new_datas ,
        dato_in => datos_in_ch7_to_ch0(127 downto 112) ,
        dato_avg => datos_out_ch7_to_ch0(127 downto 112) ,
        avg_done_ch => AVG_DONE7
    ); 
    --
    
    -- FIN INSTANCIAMIENTO DE AVERAGE INDIVIDUALES 
    -- 
    
    
    -- INICIO LOGICA BEHAVIORAL  
    --datos_out_ch7_to_ch0 <= DATO_AVG_7_SIG & DATO_AVG_6_SIG & DATO_AVG_5_SIG & DATO_AVG_4_SIG & DATO_AVG_3_SIG & DATO_AVG_2_SIG & DATO_AVG_1_SIG & DATO_AVG_0_SIG ;
    avg_done_all <= (AVG_DONE0) and (AVG_DONE1) and (AVG_DONE2) and (AVG_DONE3) and (AVG_DONE4) and (AVG_DONE5) and (AVG_DONE6) and (AVG_DONE7) ;   
    --avg_done_all <= (AVG_DONE0 or (not enable_chs(0))) and (AVG_DONE1 or (not enable_chs(1))) and (AVG_DONE2 or (not enable_chs(2))) and (AVG_DONE3 or (not enable_chs(3))) and (AVG_DONE4 or (not enable_chs(4))) and (AVG_DONE5 or (not enable_chs(5))) and (AVG_DONE6 or (not enable_chs(6))) and (AVG_DONE7 or (not enable_chs(7))) ;                     
    
    -- FIN LOGICA
    
end Behavioral;