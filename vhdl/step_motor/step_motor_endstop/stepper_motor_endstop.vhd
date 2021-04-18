----------------------------------------------------------------------------------
-- Engineer: Carlos Sanchez
-- Create Date: 14.03.2021 
-- Module Name: stepper_motor - Behavioral
-- Project Name: TFM
-- Description: 
--        Control del motor paso a paso con un final de carrera normalmente cerrado.
--        El bot�n izquierdo mueve el motor y el sw0 cambia el sentido.
--==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;-- para poder utilizar signed y unsigned;

--==============================================================================
entity stepper_motor is
 Port ( 
       clk: in std_logic;
       rst: in std_logic; -- sw 15
    motor1: in std_logic;
      sw_1: in std_logic; -- sw 1: ON - sentido horario; OFF - sentido antihorario
   
   endstop: in std_logic;
    
       int: out std_logic_vector(3 downto 0); -- salidas para el motor
       led: out std_logic;
       led1: out std_logic;
       led2: out std_logic
 );
end stepper_motor;

--==============================================================================
architecture Behavioral of stepper_motor is
    -- Se�ales para obtener la se�ar de 100Hz
    signal cuenta: natural range 0 to 2**20-1;
    constant fin_cuenta: natural := 1000000; --1000000
    signal step: std_logic;  
    
    --Defino maquina de estados
    -----------ESTADOS --------------------------
    type estado_motor is ( AB, BC, CD, DA);
    --Se�ales de los procesos
    signal estado_actual, estado_siguiente: estado_motor;
    
    constant sw_on : std_logic := '1'; -- se�ales activas a nivel alto
    constant sw_off : std_logic := '0';
    
    --enable btn:
    signal reg_m1: std_logic;
    signal reg_m2: std_logic;
    signal pulso_m1: std_logic;
    signal s_m1: std_logic;
    signal enable_m1: std_logic;
    
    
--==============================================================================

begin

Detector_pulso: process(rst, clk)
    begin
        if rst='1' then
             reg_m1 <='0';
             reg_m2 <='0';
        elsif clk' event and clk='1' then
            reg_m1 <= motor1;
            reg_m2 <= reg_m1;
        end if;
    end process;
    pulso_m1 <='1' when (reg_m1 = '1' and reg_m2 ='0') else '0';  
  
bies_T : process(rst, clk)
    begin
        if rst='1' then
            s_m1 <='0';
        elsif clk' event and clk='1' then
            if pulso_m1= '1' then
                s_m1 <= not s_m1;
            end if;
        end if;
    end process; 
    enable_m1 <= s_m1;
  
  
 P_contador_100Hz: process(clk,rst)
    begin 
        if rst = '1' then
            cuenta <= 0;
        elsif clk'event and clk = '1' then
            if cuenta = fin_cuenta-1 then
               cuenta <= 0;
            else 
               cuenta <= cuenta + 1;
            end if;
        end if;
 end process;
   
 step <= '1' when (cuenta = fin_cuenta-1) else '0'; 
 led <= '1' when enable_m1 = '1' else '0';
 led1 <= '1' when sw_1 = '1' else '0';    
 led2 <= '1' when rst = '1' else '0'; 
 
P_cambio_estado: Process (estado_actual, enable_m1, sw_1, step, endstop)
begin
    case estado_actual is 
   -------------------s1-------------
        when AB => 
            if step = '1' and enable_m1 = '1' and endstop = '0' then 
                
                if sw_1 = '1' then  
                   estado_siguiente <= BC;        
                elsif sw_1 = '0' then
                   estado_siguiente <= DA;
                end if;   
                
            else -- step = '0'
                estado_siguiente <= AB;
            end if;
             
   --------------------s2-------------             
           when BC => 
            if step = '1' and enable_m1 = '1' and endstop = '0' then 
                if sw_1 = '1' then         
                   estado_siguiente <= CD;        
                elsif sw_1 = '0' then   
                   estado_siguiente <= AB;
                end if;
            else
                estado_siguiente <= BC;
            end if;
    --------------------s3-------------             
          when CD => 
            if step = '1' and enable_m1 = '1' and endstop = '0' then 
                if sw_1 = '1' then         
                   estado_siguiente <= DA;        
                elsif sw_1 = '0' then     
                   estado_siguiente <= BC;
                end if;
            else
                estado_siguiente <= CD;
            end if;   
    --------------------s4-------------             
          when DA => 
            if step = '1' and enable_m1 = '1' and endstop = '0' then 
                if sw_1 = '1' then        
                   estado_siguiente <= AB;        
                elsif sw_1 = '0' then      
                   estado_siguiente <= CD;
                end if;
            else 
                estado_siguiente <= DA;
            end if;  
    end case;
end process;

----------PROCESO--------------
---Biestable D: proceso secuencia que actualiza el estado cada cilco de reloj y lo guarda en un biesteble.
p_secuencia: Process (rst, clk)
begin
  if rst='1' then
    estado_actual <= AB;
  elsif clk'event and clk= '1' then
    estado_actual <= estado_siguiente;
  end if;
end process;

--------PROCESO COMINACIONAL DE SALIDAS.--------
--proporciaona las salidas 
P_comb_salidas: Process (estado_actual)
begin
    int   <= (others=>'0');
       case estado_actual is
         --------------s001------------
         when AB => 
           int   <= ("1100");
         --------------s010------------             
         when BC => 
           int   <= ("0110");
         --------------s011------------             
         when CD =>
           int   <= ("0011");
         --------------s11-------------             
         when DA=> 
           int   <= ("1001");
        end case;
end process;

end Behavioral;
