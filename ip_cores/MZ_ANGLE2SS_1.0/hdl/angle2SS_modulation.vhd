----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Cristobal Cortes
-- 
-- Create Date: 19.06.2025 10:55:29
-- Design Name: 
-- Module Name: angle2SS_modulation - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
-- Bloque de modulacion SHE trifasico con interfaz AXI4-Lite
-- Entrada: K angulos por AXI (K configurable, tipico K=11, maximo K=20)
-- Los angulos deben cumplir 0 < alpha_1 < alpha_2 < ... < alpha_K < pi/2
-- Implementa simetria de media onda automaticamente
-- Genera internamente la referencia de fase (20ms periodo)
-- Usa conteo directo de ciclos de reloj en lugar de angulos en punto flotante
-- 20ms (1 ciclo fundamental) = CLK_FREQ/50 cuentas
-- pi/2 = CLK_FREQ/200 cuentas
-- pi = CLK_FREQ/100 cuentas
-- 2pi = CLK_FREQ/50 cuentas
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity angle2SS_modulation is
    generic (
        ANGLES : positive := 11; -- Numero de Angulos (tipico 11, maximo 20)
        CLK_FREQ : positive := 100_000_000; -- Frecuencia de reloj en Hz (100 MHz)
        FUND_FREQ : positive := 50; 
        C_S_AXI_DATA_WIDTH	: integer	:= 32
    );
    port (
        -- Reloj y reset
        clk          : in  std_logic;
        reset      : in  std_logic;
        
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
        
        -- Salidas de conmutacion trifasicas
        phase_A_state : out std_logic;
        phase_B_state : out std_logic;
        phase_C_state : out std_logic;
        states_valid  : out std_logic; -- Pulso cuando los estados son validos
        
        -- Debug
        phase_counter_a_out : out unsigned(21 downto 0);
        phase_counter_b_out : out unsigned(21 downto 0);
        phase_counter_c_out : out unsigned(21 downto 0)
    );
end angle2SS_modulation;

architecture Behavioral of angle2SS_modulation is        
    -- Constantes para el generador de fase
    constant PERIOD_20MS : integer := CLK_FREQ / FUND_FREQ; -- 20ms = 1/50Hz = 2,000,000 cuentas @100MHz
    constant HALF_PERIOD : integer := CLK_FREQ / (2*FUND_FREQ); -- 10ms =  1,000,000 cuentas
    constant PHASE_120 : integer := CLK_FREQ / (FUND_FREQ * 3); -- 120grados = 666,666 cuentas
    constant PHASE_240 : integer := (CLK_FREQ * 2) / (FUND_FREQ * 3); -- 240grados = 1,333,333 cuentas
    
    -- Tipo para tiempos de conmutacion (en cuentas de reloj)
    subtype switch_time_t is unsigned(31 downto 0);
    type angle_array_t is array (0 to ANGLES-1) of switch_time_t;

    -- Generador de fase interno
    signal phase_counter : unsigned(31 downto 0) := (others => '0');
    signal phase_valid : std_logic := '0';

    -- indice de angulo actual
    signal angle_A_idx : integer range 0 to ANGLES := 0;
    signal angle_B_idx : integer range 0 to ANGLES := 0;
    signal angle_C_idx : integer range 0 to ANGLES := 0;

    -- Estados y variables para ordenamiento de angulos
    type sort_state_t is (IDLE, ODD_SORT, EVEN_SORT, DONE);
    signal sort_state : sort_state_t := IDLE;
    signal sort_pipe : angle_array_t;
    signal sort_step : integer range 0 to ANGLES-1 := 0;
    signal sorted_angles : angle_array_t := (others => (others => '0'));
    signal angles_reg : angle_array_t := (others => (others => '0'));
    signal config_valid : std_logic := '0';
    signal angles_changed : std_logic := '0';
    signal prev_angles_reg : angle_array_t := (others => (others => '0'));       
    

    -- Identificaicon del estado inicial y indice
    procedure get_initial_state_and_idx(
        angles     : in  angle_array_t;
        phase      : in  unsigned(31 downto 0);
        init_state : out std_logic;
        init_idx  : out integer range 0 to ANGLES
    ) is
        variable temp_state : std_logic;
    begin
        temp_state := '1';  -- Valor por defecto para primera mitad
        init_idx := 0;      -- indice por defecto
        
        -- Primera mitad del ciclo (0 a pi)
        if phase < HALF_PERIOD then
            for i in angles'range loop
                if phase >= angles(i) then
                    temp_state := not temp_state;  -- Alternar estado en cada angulo
                    init_idx := i;                 -- Actualizar ultimo indice valido
                end if;
            end loop;
        -- Segunda mitad del ciclo (pi a 2pi)
        else
            temp_state := '0';  -- Valor inicial opuesto
            for i in angles'range loop
                if phase >= (angles(i) + HALF_PERIOD) then
                    temp_state := not temp_state;  -- Alternar estado
                    init_idx := i;                 -- Actualizar ultimo indice
                end if;
            end loop;
        end if;
        init_state := temp_state;
    end procedure;    


begin 
    -- Generador de fase interno (20ms periodo)
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '0' then
                phase_counter <= (others => '0');
                phase_valid <= '0';
            else
                phase_valid <= '0';
                
                if phase_counter = PERIOD_20MS-1 then
                    phase_counter <= (others => '0');
                    phase_valid <= '1';
                else
                    phase_counter <= phase_counter + 1;
                end if;
            end if;
            phase_counter_a_out <= phase_counter(21 downto 0);
        end if;
    end process;
    
    process(clk)
    begin
        if rising_edge(clk) then
            angles_reg(0) <= unsigned(angle0_reg);
            angles_reg(1) <= unsigned(angle1_reg);
            angles_reg(2) <= unsigned(angle2_reg);
            angles_reg(3) <= unsigned(angle3_reg);
            angles_reg(4) <= unsigned(angle4_reg);
            angles_reg(5) <= unsigned(angle5_reg);
            angles_reg(6) <= unsigned(angle6_reg);
            angles_reg(7) <= unsigned(angle7_reg);
            angles_reg(8) <= unsigned(angle8_reg);
            angles_reg(9) <= unsigned(angle9_reg);
            angles_reg(10) <= unsigned(angle10_reg);
        end if;
    end process;

    -- Deteccion de cambios en angles_reg (comparación ciclo a ciclo)
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '0' then
                angles_changed <= '0';
                prev_angles_reg <= (others => (others => '0'));
            else
                if new_angles_reg(0) = '1' then
                    -- Activar angles_changed solo si hay cambios reales
                    if angles_reg /= prev_angles_reg then
                        angles_changed <= '1';
                        prev_angles_reg <= angles_reg;  -- Actualizar copia
                    elsif sort_state = DONE then
                        angles_changed <= '0';  -- Reset después de ordenar
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Proceso de ordenamiento 
    process(clk, reset)
        variable temp : switch_time_t;
    begin
        if reset = '0' then
            sort_state <= IDLE;
            sort_step <= 0;
            sorted_angles <= (others => (others => '0'));
            config_valid <= '0';
        elsif rising_edge(clk) then
            
            case sort_state is
                when IDLE =>
                    if angles_changed = '1' then
                        config_valid <= '0';
                        sort_pipe <= angles_reg;  -- Cargar ángulos no ordenados
                        sort_step <= 0;
                        sort_state <= ODD_SORT;
                    end if;
                
                -- Fase IMPAR: Comparar elementos (1-2, 3-4, ...)
                when ODD_SORT =>
                    for i in 0 to (ANGLES/2)-1 loop
                        if (2*i + 1 < ANGLES) and (sort_pipe(2*i) > sort_pipe(2*i + 1)) then
                            temp := sort_pipe(2*i);
                            sort_pipe(2*i) <= sort_pipe(2*i + 1);
                            sort_pipe(2*i + 1) <= temp;
                        end if;
                    end loop;
                    sort_state <= EVEN_SORT;
                
                -- Fase PAR: Comparar elementos (2-3, 4-5, ...)
                when EVEN_SORT =>
                    for i in 1 to (ANGLES/2)-1 loop
                        if (2*i < ANGLES) and (sort_pipe(2*i - 1) > sort_pipe(2*i)) then
                            temp := sort_pipe(2*i - 1);
                            sort_pipe(2*i - 1) <= sort_pipe(2*i);
                            sort_pipe(2*i) <= temp;
                        end if;
                    end loop;
                    
                    -- Control de terminación (se requieren ANGLES pasos)
                    if sort_step = ANGLES - 1 then
                        sorted_angles <= sort_pipe;
                        config_valid <= '1';  -- angulos ordenados listos
                        sort_state <= DONE;
                    else
                        sort_step <= sort_step + 1;
                        sort_state <= ODD_SORT;
                    end if;
                
                when DONE =>
                    sort_state <= IDLE;
            end case;
        end if;
    end process;    

    -- Proceso principal de control
    process(clk, reset)
        variable phase_B_counter : unsigned(31 downto 0);
        variable phase_C_counter : unsigned(31 downto 0);
        variable phase_A_int : std_logic := '0';
        variable phase_B_int : std_logic := '0';
        variable phase_C_int : std_logic := '0';
        variable v_angle_A_idx : integer range 0 to ANGLES;
        variable v_angle_B_idx : integer range 0 to ANGLES;
        variable v_angle_C_idx : integer range 0 to ANGLES;
    begin
        if reset = '0' then
            phase_A_int := '0';
            phase_B_int := '0';
            phase_C_int := '0';
            angle_A_idx <= 0;
            angle_B_idx <= 0;
            angle_C_idx <= 0;
            states_valid <= '0';
            
        elsif rising_edge(clk) then
            states_valid <= '0'; -- Por defecto no valido

            -- Cuando la configuracion es valida, ordenar angulos
            if config_valid = '1' then
                -- Calcular fases desplazadas
                -- Fase B (desplazamiento constante de 120°)
                phase_B_counter := phase_counter + PHASE_120;
                if phase_B_counter >= PERIOD_20MS then
                    phase_B_counter := phase_B_counter - PERIOD_20MS;
                end if;
                
                -- Fase C (desplazamiento constante de 240°)
                phase_C_counter := phase_counter + PHASE_240;
                if phase_C_counter >= PERIOD_20MS then
                    phase_C_counter := phase_C_counter - PERIOD_20MS;
                end if;
                phase_counter_b_out <= phase_B_counter(21 downto 0);
                phase_counter_c_out <= phase_C_counter(21 downto 0);

                -- Inicializacion de estados
                if phase_counter = 0 then 
                    phase_A_int := '1';
                    angle_A_idx <= 0;
                    --get_initial_state_and_idx(sorted_angles, phase_B_counter, phase_B_int, v_angle_B_idx);
                    --get_initial_state_and_idx(sorted_angles, phase_C_counter, phase_C_int, v_angle_C_idx);
                    --angle_B_idx <= v_angle_B_idx;
                    --angle_C_idx <= v_angle_C_idx;
                elsif phase_counter = HALF_PERIOD then
                    phase_A_int := '0';
                    angle_A_idx <= 0;
                end if;
                
                if phase_B_counter = 0 then
                    phase_B_int := '1';  -- Estado correcto en 0 ms
                    angle_B_idx <= 0;
                elsif phase_B_counter = HALF_PERIOD then
                    phase_B_int := '0';  -- Estado correcto en 10 ms
                    angle_B_idx <= 0;
                end if;  
                
                if phase_C_counter = 0 then
                    phase_C_int := '1';  -- Estado correcto en 0 ms
                    angle_C_idx <= 0;
                elsif phase_C_counter = HALF_PERIOD then
                    phase_C_int := '0';  -- Estado correcto en 10 ms
                    angle_C_idx <= 0;
                end if;                
                
                if phase_counter <= HALF_PERIOD then
                    if angle_A_idx < ANGLES then
                        if (phase_counter >= sorted_angles(angle_A_idx)) then
                            phase_A_int := not phase_A_int;
                            angle_A_idx <= angle_A_idx + 1;
                        end if;
                    end if;
                else
                    if angle_A_idx < ANGLES then
                        if phase_counter >= sorted_angles(angle_A_idx) + HALF_PERIOD then
                            phase_A_int := not phase_A_int;
                            angle_A_idx <= angle_A_idx + 1;
                        end if;
                    end if;                    
                end if;

                if phase_B_counter <= HALF_PERIOD  then
                    if angle_B_idx < ANGLES then
                        if phase_B_counter >= sorted_angles(angle_B_idx) then
                            phase_B_int := not phase_B_int;
                            angle_B_idx <= angle_B_idx + 1;
                        end if;
                    end if;
                else
                    if angle_B_idx < ANGLES then
                        if phase_B_counter >= sorted_angles(angle_B_idx) + HALF_PERIOD then
                            phase_B_int := not phase_B_int;
                            angle_B_idx <= angle_B_idx + 1;
                        end if;
                    end if;
                end if;

                if phase_C_counter <= HALF_PERIOD  then
                    if angle_C_idx < ANGLES then
                        if phase_C_counter >= sorted_angles(angle_C_idx) then
                            phase_C_int := not phase_C_int;
                            angle_C_idx <= angle_C_idx + 1;
                        end if;
                    end if;
                else
                    if angle_C_idx < ANGLES then
                        if phase_C_counter >= sorted_angles(angle_C_idx) + HALF_PERIOD then
                            phase_C_int := not phase_C_int;
                            angle_C_idx <= angle_C_idx + 1;
                        end if;
                    end if;
                end if;
                states_valid <= '1';
            end if;
            -- Asignacion de salidas
            phase_A_state <= phase_A_int;
            phase_B_state <= phase_B_int;
            phase_C_state <= phase_C_int;               
        end if;
     
    end process;
end Behavioral;
