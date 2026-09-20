----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04.08.2025 16:58:46
-- Design Name: 
-- Module Name: sogi_1 - Behavioral
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
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.ccb_fixed_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sogi_1 is
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
    nu: in unsigned(15 downto 0);
    k_factor: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    
    med_ready: in std_logic;
    
    h_out: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    phi_out: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    out_valid  : out std_logic
    );
end sogi_1;

architecture Behavioral of sogi_1 is
    -- Constantes 
    -- Constantes para Q16.16
    constant SQRT_2    : sfixed_16_16 := to_sfixed_16_16(1.41421356);
    constant PI        : sfixed_16_16 := to_sfixed_16_16(3.14159265);
    constant w        : sfixed_16_16 := to_sfixed_16_16(314.1592654);
    constant Ts        : sfixed_8_24 := to_sfixed_8_24(0.0000001);
    
    -- Signals
    signal x_a_sf : sfixed_16_16;
    signal x_b_sf : sfixed_16_16;
    signal e_sf : sfixed_16_16;
    signal nu_sf : sfixed_16_16;
    signal k_factor_sf : sfixed_16_16;
    
    signal x_a_sogi2polar : sfixed_16_16;
    signal x_b_sogi2polar : sfixed_16_16;

    -- Procedure para actualizar x_a de un armónico
    procedure update_x_a(
        signal x_a_in     : in  sfixed_16_16; -- valor actual de x_a
        signal x_b_in     : in  sfixed_16_16; -- valor actual de x_b
        signal e          : in  sfixed_16_16; -- error
        constant w          : in  sfixed_16_16; -- frecuencia angular
        constant Ts         : in  sfixed_8_24; -- periodo de muestreo
        signal nu         : in  sfixed_16_16; -- número de armónico
        signal k_factor   : in  sfixed_16_16; -- factor de ganancia
        signal x_a_out    : out sfixed_16_16  -- valor actualizado de x_a
    ) is
        variable k_nu : sfixed_16_16;
        variable dx_a : sfixed_16_16;
    begin
        k_nu := k_factor * SQRT_2 / nu;
        dx_a := w * nu * (k_nu * e - x_b_in);
        x_a_out <= x_a_in + Ts * dx_a;
    end procedure;
    
    -- Procedure para actualizar x_a de un armónico
    procedure update_x_b(
        signal x_a_in     : in  sfixed_16_16; -- valor actual de x_a
        signal x_b_in     : in  sfixed_16_16; -- valor actual de x_b
        signal e          : in  sfixed_16_16; -- error
        constant w          : in  sfixed_16_16; -- frecuencia angular
        constant Ts         : in  sfixed_8_24; -- periodo de muestreo
        signal nu         : in  sfixed_16_16; -- número de armónico
        signal k_factor   : in  sfixed_16_16; -- factor de ganancia
        signal x_b_out    : out sfixed_16_16  -- valor actualizado de x_a
    ) is
        variable k_nu : sfixed_16_16;
        variable g_nu : sfixed_16_16;
        variable dx_b : sfixed_16_16;
    begin
        k_nu := k_factor * SQRT_2 / nu;
        g_nu := k_nu * k_nu * to_sfixed_16_16(-0.25);
        dx_b := w * nu * (g_nu * e + x_a_in);
        x_b_out <= x_b_in + Ts * dx_b;
    end procedure;
    
    -- Procedure para magnitud
    procedure magnitude(
        signal x_a_in     : in  sfixed_16_16; -- valor actual de x_a
        signal x_b_in     : in  sfixed_16_16; -- valor actual de x_b
        signal h_out    : out sfixed_16_16  -- valor actualizado de x_a
    ) is
        -- Función sqrt usando Newton-Raphson
        function sqrt_newton(x : sfixed_16_16) return sfixed_16_16 is
            variable guess, next_guess : sfixed_16_16;
            variable temp : sfixed_16_16;
        begin
            if x <= to_sfixed_16_16(0.0) then
                return to_sfixed_16_16(0.0);
            end if;
            
            guess := x / to_sfixed_16_16(2.0);  -- Inicial guess
            
            -- 4 iteraciones Newton-Raphson: x_n+1 = (x_n + S/x_n) / 2
            for i in 0 to 3 loop
                temp := x / guess;
                next_guess := (guess + temp) / to_sfixed_16_16(2.0);
                guess := next_guess;
            end loop;
            
            return guess;
        end function;
        variable x_a_sq, x_b_sq, sum_sq : sfixed_16_16;
    begin
        -- Magnitud: sqrt(x_a² + x_b²)
        x_a_sq := x_a_in * x_a_in;
        x_b_sq := x_b_in * x_b_in;
        sum_sq := x_a_sq + x_b_sq;
        h_out <= sqrt_newton(sum_sq);
    end procedure;
    
        -- Procedure para magnitud
    procedure phase(
        signal x_a_in     : in  sfixed_16_16; -- valor actual de x_a
        signal x_b_in     : in  sfixed_16_16; -- valor actual de x_b
        signal phase_out    : out sfixed_16_16  -- valor actualizado de x_a
    ) is
      -- Función atan2 simplificada
        function atan2_approx(y, x : sfixed_16_16) return sfixed_16_16 is
            variable ratio : sfixed_16_16;
            variable result : sfixed_16_16;
        begin
            if abs(x) < to_sfixed_16_16(0.001) then  -- x ? 0
                if y > to_sfixed_16_16(0.0) then
                    return to_sfixed_16_16(1.5708);  -- ?/2
                else
                    return to_sfixed_16_16(-1.5708); -- -?/2
                end if;
            end if;
            
            ratio := y / x;
            
            -- Aproximación polinomial: atan(x) ? x - x³/3 + x?/5
            result := ratio - (ratio * ratio * ratio) / to_sfixed_16_16(3.0);
            
            -- Ajustar cuadrantes
            if x < to_sfixed_16_16(0.0) then
                if y >= to_sfixed_16_16(0.0) then
                    result := result + to_sfixed_16_16(3.14159);  -- ?
                else
                    result := result - to_sfixed_16_16(3.14159);  -- -?
                end if;
            end if;
            
            return result;
        end function;
    begin
        -- Fase: atan2(x_b, x_a)
        phase_out <= atan2_approx(x_b_in, x_a_in);
    end procedure;
    

begin
    -- Conversion
    x_a_sf <= to_sfixed_16_16(x_a_in);
    x_b_sf <= to_sfixed_16_16(x_b_in);
    e_sf <= to_sfixed_16_16(e);
    nu_sf <= signed(resize(nu, 32)) sll 16;
    k_factor_sf <= to_sfixed_16_16(k_factor);
    
    -- Actualizar vectores
    update_x_a(x_a_sf, x_b_sf, e_sf, w, Ts, nu_sf, k_factor_sf, x_a_sogi2polar);
    update_x_b(x_a_sf, x_b_sf, e_sf, w, Ts, nu_sf, k_factor_sf, x_b_sogi2polar);
    
    

end Behavioral;
