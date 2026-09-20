library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package ccb_fixed_pkg is
    
    -- ========================================
    -- DEFINICIONES DE TIPOS SIGNED (32 bits)
    -- ========================================
    
    -- Q16.16: 16 bits enteros, 16 bits fraccionarios +-32768.0
    subtype sfixed_16_16 is signed(31 downto 0);
    
    -- Q24.8: 24 bits enteros, 8 bits fraccionarios  +-8388608.0
    subtype sfixed_24_8 is signed(31 downto 0);
    
    -- Q8.24: 8 bits enteros, 24 bits fraccionarios +-128.0
    subtype sfixed_8_24 is signed(31 downto 0);
    
    -- ========================================
    -- DEFINICIONES DE TIPOS UNSIGNED (32 bits)
    -- ========================================
    
    -- Q16.16: 16 bits enteros, 16 bits fraccionarios 0 a 65536.0
    subtype ufixed_16_16 is unsigned(31 downto 0);
    
    -- Q24.8: 24 bits enteros, 8 bits fraccionarios 0 a 16777216.0
    subtype ufixed_24_8 is unsigned(31 downto 0);
    
    -- Q8.24: 8 bits enteros, 24 bits fraccionarios  0 a 256.0
    subtype ufixed_8_24 is unsigned(31 downto 0);
    
    -- ========================================
    -- CONSTANTES PARA ESCALAMIENTO
    -- ========================================
    
    constant SCALE_16_16 : real := 65536.0;    -- 2^16
    constant SCALE_24_8  : real := 256.0;      -- 2^8  
    constant SCALE_8_24  : real := 16777216.0; -- 2^24
    
    -- ========================================
    -- FUNCIONES SIGNED Q16.16
    -- ========================================
    
    function to_sfixed_16_16(val : real) return sfixed_16_16;
    function to_sfixed_16_16(val : std_logic_vector(31 downto 0)) return sfixed_16_16;
    function to_real(val : sfixed_16_16) return real;
    function to_slv(val : sfixed_16_16) return std_logic_vector;
    
    -- ========================================
    -- FUNCIONES SIGNED Q24.8
    -- ========================================
    
    function to_sfixed_24_8(val : real) return sfixed_24_8;
    function to_sfixed_24_8(val : std_logic_vector(31 downto 0)) return sfixed_24_8;
    function to_real_24_8(val : sfixed_24_8) return real;
    function to_slv_24_8(val : sfixed_24_8) return std_logic_vector;
    
    -- ========================================
    -- FUNCIONES SIGNED Q8.24
    -- ========================================
    
    function to_sfixed_8_24(val : real) return sfixed_8_24;
    function to_sfixed_8_24(val : std_logic_vector(31 downto 0)) return sfixed_8_24;
    function to_real_8_24(val : sfixed_8_24) return real;
    function to_slv_8_24(val : sfixed_8_24) return std_logic_vector;
    
    -- ========================================
    -- FUNCIONES UNSIGNED Q16.16
    -- ========================================
    
    function to_ufixed_16_16(val : real) return ufixed_16_16;
    function to_ufixed_16_16(val : std_logic_vector(31 downto 0)) return ufixed_16_16;
    function to_real_u(val : ufixed_16_16) return real;
    function to_slv_u(val : ufixed_16_16) return std_logic_vector;
    
    -- ========================================
    -- FUNCIONES UNSIGNED Q24.8
    -- ========================================
    
    function to_ufixed_24_8(val : real) return ufixed_24_8;
    function to_ufixed_24_8(val : std_logic_vector(31 downto 0)) return ufixed_24_8;
    function to_real_u_24_8(val : ufixed_24_8) return real;
    function to_slv_u_24_8(val : ufixed_24_8) return std_logic_vector;
    
    -- ========================================
    -- FUNCIONES UNSIGNED Q8.24
    -- ========================================
    
    function to_ufixed_8_24(val : real) return ufixed_8_24;
    function to_ufixed_8_24(val : std_logic_vector(31 downto 0)) return ufixed_8_24;
    function to_real_u_8_24(val : ufixed_8_24) return real;
    function to_slv_u_8_24(val : ufixed_8_24) return std_logic_vector;
    
    -- ========================================
    -- FUNCIONES ARITMÉTICAS BÁSICAS
    -- ========================================
    
    function add_sfixed_16_16(a, b : sfixed_16_16) return sfixed_16_16;
    function mult_sfixed_16_16(a, b : sfixed_16_16) return sfixed_16_16;
    
end package ccb_fixed_pkg;

-- ========================================
-- IMPLEMENTACIÓN DEL PAQUETE
-- ========================================

package body ccb_fixed_pkg is
    
    -- ========================================
    -- IMPLEMENTACIÓN SIGNED Q16.16
    -- ========================================
    
    function to_sfixed_16_16(val : real) return sfixed_16_16 is
    begin
        return to_signed(integer(val * SCALE_16_16), 32);
    end function;
    
    function to_sfixed_16_16(val : std_logic_vector(31 downto 0)) return sfixed_16_16 is
    begin
        return signed(val);
    end function;
    
    function to_real(val : sfixed_16_16) return real is
    begin
        return real(to_integer(val)) / SCALE_16_16;
    end function;
    
    function to_slv(val : sfixed_16_16) return std_logic_vector is
    begin
        return std_logic_vector(val);
    end function;
    
    -- ========================================
    -- IMPLEMENTACIÓN SIGNED Q24.8
    -- ========================================
    
    function to_sfixed_24_8(val : real) return sfixed_24_8 is
    begin
        return to_signed(integer(val * SCALE_24_8), 32);
    end function;
    
    function to_sfixed_24_8(val : std_logic_vector(31 downto 0)) return sfixed_24_8 is
    begin
        return signed(val);
    end function;
    
    function to_real_24_8(val : sfixed_24_8) return real is
    begin
        return real(to_integer(val)) / SCALE_24_8;
    end function;
    
    function to_slv_24_8(val : sfixed_24_8) return std_logic_vector is
    begin
        return std_logic_vector(val);
    end function;
    
    -- ========================================
    -- IMPLEMENTACIÓN SIGNED Q8.24
    -- ========================================
    
    function to_sfixed_8_24(val : real) return sfixed_8_24 is
    begin
        return to_signed(integer(val * SCALE_8_24), 32);
    end function;
    
    function to_sfixed_8_24(val : std_logic_vector(31 downto 0)) return sfixed_8_24 is
    begin
        return signed(val);
    end function;
    
    function to_real_8_24(val : sfixed_8_24) return real is
    begin
        return real(to_integer(val)) / SCALE_8_24;
    end function;
    
    function to_slv_8_24(val : sfixed_8_24) return std_logic_vector is
    begin
        return std_logic_vector(val);
    end function;
    
    -- ========================================
    -- IMPLEMENTACIÓN UNSIGNED Q16.16
    -- ========================================
    
    function to_ufixed_16_16(val : real) return ufixed_16_16 is
    begin
        return to_unsigned(integer(val * SCALE_16_16), 32);
    end function;
    
    function to_ufixed_16_16(val : std_logic_vector(31 downto 0)) return ufixed_16_16 is
    begin
        return unsigned(val);
    end function;
    
    function to_real_u(val : ufixed_16_16) return real is
    begin
        return real(to_integer(val)) / SCALE_16_16;
    end function;
    
    function to_slv_u(val : ufixed_16_16) return std_logic_vector is
    begin
        return std_logic_vector(val);
    end function;
    
    -- ========================================
    -- IMPLEMENTACIÓN UNSIGNED Q24.8
    -- ========================================
    
    function to_ufixed_24_8(val : real) return ufixed_24_8 is
    begin
        return to_unsigned(integer(val * SCALE_24_8), 32);
    end function;
    
    function to_ufixed_24_8(val : std_logic_vector(31 downto 0)) return ufixed_24_8 is
    begin
        return unsigned(val);
    end function;
    
    function to_real_u_24_8(val : ufixed_24_8) return real is
    begin
        return real(to_integer(val)) / SCALE_24_8;
    end function;
    
    function to_slv_u_24_8(val : ufixed_24_8) return std_logic_vector is
    begin
        return std_logic_vector(val);
    end function;
    
    -- ========================================
    -- IMPLEMENTACIÓN UNSIGNED Q8.24
    -- ========================================
    
    function to_ufixed_8_24(val : real) return ufixed_8_24 is
    begin
        return to_unsigned(integer(val * SCALE_8_24), 32);
    end function;
    
    function to_ufixed_8_24(val : std_logic_vector(31 downto 0)) return ufixed_8_24 is
    begin
        return unsigned(val);
    end function;
    
    function to_real_u_8_24(val : ufixed_8_24) return real is
    begin
        return real(to_integer(val)) / SCALE_8_24;
    end function;
    
    function to_slv_u_8_24(val : ufixed_8_24) return std_logic_vector is
    begin
        return std_logic_vector(val);
    end function;
    
    -- ========================================
    -- IMPLEMENTACIÓN FUNCIONES ARITMÉTICAS
    -- ========================================
    
    function add_sfixed_16_16(a, b : sfixed_16_16) return sfixed_16_16 is
    begin
        return a + b;  -- Suma directa
    end function;
    
    function mult_sfixed_16_16(a, b : sfixed_16_16) return sfixed_16_16 is
        variable temp : signed(63 downto 0);
    begin
        temp := a * b;
        -- Ajustar por doble escala (dividir por 2^16)
        return temp(47 downto 16);
    end function;
    
end package body ccb_fixed_pkg;
