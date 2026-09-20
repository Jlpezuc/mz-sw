----------------------------------------------------------------------------------
-- MZ_AVERAGER_8CH_CHANNEL : promedio de un canal
--
-- Acumula MAX_DATOS muestras (cada flanco de flag_new_data) y entrega la suma
-- desplazada SHIFT_X bits, es decir, el promedio de una potencia de 2 de muestras.
-- El numero deseado (cant_datos) se redondea hacia abajo a la potencia de 2 inferior
-- y se limita a 2**MAX_AVG_LOG2 (parametro del bloque). El acumulador tiene
-- N + MAX_AVG_LOG2 bits, de modo que nunca desborda.
--
-- Con sincronizar_clock_base = '1' el promedio se reinicia en el flanco de subida de
-- clock_base_sync (la interrupcion del ISR): el ISR lee el promedio del periodo anterior.
-- Con enable_ch = '0' el canal deja pasar el dato crudo sin promediar.
-- El valor de cant_datos solo se carga al (re)habilitar el canal.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MZ_AVERAGER_8CH_CHANNEL is
    generic (
        N                      : integer range 1 to 64 := 16;  -- bits del dato
        MAX_AVG_LOG2           : integer range 0 to 20 := 8;   -- maximo de muestras = 2**MAX_AVG_LOG2
        valores_con_signo_ch   : STD_LOGIC := '1';
        sincronizar_clock_base : STD_LOGIC := '1'
    );
    Port ( clk_ch          : in  std_logic;
           resetn_ch       : in  std_logic;
           enable_ch       : in  std_logic;
           cant_datos      : in  std_logic_vector(31 downto 0);  -- muestras a promediar (se redondea a 2**k)
           clock_base_sync : in  std_logic;
           flag_new_data   : in  std_logic;
           dato_in         : in  std_logic_vector(N-1 downto 0);
           dato_avg        : out std_logic_vector(N-1 downto 0);
           avg_done_ch     : out std_logic := '0' );
end MZ_AVERAGER_8CH_CHANNEL;

architecture Behavioral of MZ_AVERAGER_8CH_CHANNEL is
    constant ACC_W            : integer := N + MAX_AVG_LOG2;   -- ancho del acumulador
    constant MAX_DATOS_LIMITE : integer := 2**MAX_AVG_LOG2;
    constant cuentas_calc_avg : integer := 5;

    signal MAX_DATOS     : integer range 1 to MAX_DATOS_LIMITE := 1;
    signal SHIFT_X       : integer range 0 to MAX_AVG_LOG2 := 0;
    signal SUMA_SIG      : signed(ACC_W-1 downto 0)   := (others => '0');
    signal SUMA_UNSIG    : unsigned(ACC_W-1 downto 0) := (others => '0');
    signal CONT_DATOS    : integer range 0 to MAX_DATOS_LIMITE := 0;
    signal CONT_CALC_AVG : integer range 0 to cuentas_calc_avg := 0;
    signal TEMP_AVG_SIG   : signed(ACC_W-1 downto 0)   := (others => '0');
    signal TEMP_AVG_UNSIG : unsigned(ACC_W-1 downto 0) := (others => '0');
    signal FLAG_NEW_DATA_ANT   : std_logic := '0';
    signal CONT_MAX_INICIADO   : integer range 0 to 2 := 0;
    signal CLOCK_BASE_SYNC_ANT : std_logic := '0';
    -- sincronizador de 2 etapas: clock_base_sync (la interrupcion) viene de otro dominio de reloj
    signal CLOCK_BASE_META, CLOCK_BASE_SYNC_R : std_logic := '0';
    attribute ASYNC_REG : string;
    attribute ASYNC_REG of CLOCK_BASE_META : signal is "TRUE";
    attribute ASYNC_REG of CLOCK_BASE_SYNC_R : signal is "TRUE";
    signal AVG_DONE_SIG        : std_logic := '0';
    signal DATO_AVG_SIG        : std_logic_vector(N-1 downto 0) := (others => '0');

    -- mayor k <= MAX_AVG_LOG2 tal que 2**k <= cant (cant >= 1)
    function log2_floor(cant : unsigned(31 downto 0)) return integer is
    begin
        for k in MAX_AVG_LOG2 downto 1 loop
            if cant >= to_unsigned(2**k, 32) then
                return k;
            end if;
        end loop;
        return 0;
    end function;
begin
    process(clk_ch, resetn_ch)
        variable LEER_DATO : std_logic := '0';
        variable SYNC_WAIT : std_logic := '0';   -- el reinicio espera siempre al primer flanco de clock_base_sync
        variable CANT_U    : unsigned(31 downto 0);
        variable K         : integer range 0 to MAX_AVG_LOG2;
    begin
        if (resetn_ch = '0') then
            SUMA_SIG   <= (others => '0');
            SUMA_UNSIG <= (others => '0');
            TEMP_AVG_SIG   <= (others => '0');
            TEMP_AVG_UNSIG <= (others => '0');
            CONT_DATOS <= 0;
            CONT_CALC_AVG <= 0;
            FLAG_NEW_DATA_ANT <= '0';
            SYNC_WAIT := '0';
            CLOCK_BASE_SYNC_ANT <= '0';
            CLOCK_BASE_META <= '0';
            CLOCK_BASE_SYNC_R <= '0';
            AVG_DONE_SIG <= '0';
            CONT_MAX_INICIADO <= 0;
            MAX_DATOS <= 1;
            SHIFT_X <= 0;
        elsif rising_edge(clk_ch) then
            CLOCK_BASE_META <= clock_base_sync;
            CLOCK_BASE_SYNC_R <= CLOCK_BASE_META;
            -- carga del numero de muestras (solo al iniciar / rehabilitar)
            if (CONT_MAX_INICIADO < 2) then
                CANT_U := unsigned(cant_datos);
                if (CANT_U /= 0) then
                    CONT_MAX_INICIADO <= CONT_MAX_INICIADO + 1;
                    K := log2_floor(CANT_U);
                    SHIFT_X   <= K;
                    MAX_DATOS <= 2**K;
                end if;
            end if;

            if (flag_new_data = '1' and FLAG_NEW_DATA_ANT = '0') then -- flanco de subida = dato nuevo
                LEER_DATO := '1';
            else
                LEER_DATO := '0';
            end if;

            if (enable_ch = '1') then ----------------------------------------------------------
                if (CONT_DATOS < MAX_DATOS) then                    -- acumular hasta MAX_DATOS
                    if (LEER_DATO = '1') then
                        CONT_DATOS <= CONT_DATOS + 1;
                        if (valores_con_signo_ch = '1') then
                            SUMA_SIG <= SUMA_SIG + resize(signed(dato_in), ACC_W);
                        else
                            SUMA_UNSIG <= SUMA_UNSIG + resize(unsigned(dato_in), ACC_W);
                        end if;
                    end if;
                end if;
                if (CONT_DATOS >= MAX_DATOS and CONT_CALC_AVG < cuentas_calc_avg) then  -- calcular promedio
                    CONT_CALC_AVG <= CONT_CALC_AVG + 1;
                    if (valores_con_signo_ch = '1') then
                        TEMP_AVG_SIG <= shift_right(SUMA_SIG, SHIFT_X);
                        DATO_AVG_SIG <= std_logic_vector(resize(TEMP_AVG_SIG, N));
                    else
                        TEMP_AVG_UNSIG <= shift_right(SUMA_UNSIG, SHIFT_X);
                        DATO_AVG_SIG <= std_logic_vector(resize(TEMP_AVG_UNSIG, N));
                    end if;
                    if (CONT_CALC_AVG = cuentas_calc_avg-1) then
                        AVG_DONE_SIG <= '1';
                    end if;
                end if;
                if (CONT_DATOS >= MAX_DATOS and CONT_CALC_AVG >= cuentas_calc_avg) then   -- reinicio
                    if (sincronizar_clock_base = '1') then
                        if (CLOCK_BASE_SYNC_R = '1' and CLOCK_BASE_SYNC_ANT = '0') then
                            SYNC_WAIT := '1';
                        end if;
                        if (SYNC_WAIT = '1' and LEER_DATO = '1') then
                            SYNC_WAIT := '0';
                            CONT_DATOS <= 1;
                            CONT_CALC_AVG <= 0;
                            AVG_DONE_SIG <= '0';
                            if (valores_con_signo_ch = '1') then
                                SUMA_SIG <= resize(signed(dato_in), ACC_W);
                            else
                                SUMA_UNSIG <= resize(unsigned(dato_in), ACC_W);
                            end if;
                        end if;
                    elsif (LEER_DATO = '1') then
                        CONT_DATOS <= 1;
                        CONT_CALC_AVG <= 0;
                        AVG_DONE_SIG <= '0';
                        if (valores_con_signo_ch = '1') then
                            SUMA_SIG <= resize(signed(dato_in), ACC_W);
                        else
                            SUMA_UNSIG <= resize(unsigned(dato_in), ACC_W);
                        end if;
                    end if;
                end if;
            else -- enable_ch = '0': paso directo, se prepara la recarga de cant_datos --------------
                if (sincronizar_clock_base = '1') then
                    if (CLOCK_BASE_SYNC_R = '1' and CLOCK_BASE_SYNC_ANT = '0') then
                        SYNC_WAIT := '1';
                    end if;
                    if (SYNC_WAIT = '1') then
                        if (flag_new_data = '0' and FLAG_NEW_DATA_ANT = '1' and AVG_DONE_SIG = '1') then
                            AVG_DONE_SIG <= '0';
                            CONT_MAX_INICIADO <= 0;
                            CONT_DATOS <= 0;
                            CONT_CALC_AVG <= 0;
                            SUMA_SIG   <= (others => '0');
                            SUMA_UNSIG <= (others => '0');
                        end if;
                        if (flag_new_data = '1' and FLAG_NEW_DATA_ANT = '0' and AVG_DONE_SIG = '0') then
                            AVG_DONE_SIG <= '1';
                            SYNC_WAIT := '0';
                        end if;
                    end if;
                else
                    AVG_DONE_SIG <= flag_new_data;
                    if (LEER_DATO = '1') then
                        CONT_MAX_INICIADO <= 0;
                        CONT_DATOS <= 1;
                        CONT_CALC_AVG <= 0;
                        SUMA_SIG   <= (others => '0');
                        SUMA_UNSIG <= (others => '0');
                    end if;
                end if;
            end if; -------------------------------------------------------------------------------
            CLOCK_BASE_SYNC_ANT <= CLOCK_BASE_SYNC_R;
            FLAG_NEW_DATA_ANT   <= flag_new_data;
        end if;
    end process;

    dato_avg    <= dato_in when enable_ch = '0' else DATO_AVG_SIG;
    avg_done_ch <= AVG_DONE_SIG;
end Behavioral;
