----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/27/2013 10:43:53 AM
-- Design Name: 
-- Module Name: fixed_neuron - Behavioral
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

library IEEE_proposed;
use IEEE_proposed.fixed_pkg.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fixed_neuron is
    generic (
        decay: sfixed(31 downto 0) := to_sfixed(3276, 31,0); -- decay = (1<<16)/tau_rc
        tau_ref: unsigned(3 downto 0) := X"2";
        Jbias: sfixed(31 downto 0) := to_sfixed(0, 31,0)
    );
    Port ( 
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        
        ready: in std_logic;
        current: in sfixed(31 downto 0);
                
        valid: out std_logic;
        spike: out std_logic
    );
end fixed_neuron;

architecture Behavioral of fixed_neuron is
    type state_type is (state_idle, state_dv, state_voltage, state_spike);
    
    type ci_type is record    
        state: state_type;
        voltage: sfixed(31 downto 0);
        refractory: unsigned(3 downto 0);
        current_diff: sfixed(31 downto 0); -- (current - voltage)
        dv: sfixed(31 downto 0); -- (current - voltage)*decay >> 16
        
        valid: std_logic;
        spike: std_logic;
    end record;
    
    constant reg_reset: ci_type := (
        state => state_idle,
        voltage => to_sfixed(0, 31,0),
        refractory => X"0",
        current_diff => (others=>'0'),
        dv => (others=>'0'),
        
        valid => '0',
        spike => '0'
    );
    
    signal reg: ci_type := reg_reset;
    
    signal ci_next: ci_type;
    
    constant voltage_threshold: sfixed(31 downto 0) := X"00010000"; -- 1<<16
begin

    COMB: process(clk, rst, ready, current, reg)
        variable ci: ci_type;
    begin
        ci := reg;
        
        if(rst = '1') then
            ci := reg_reset;
        else
            case reg.state is
                when state_idle =>
                    if(ready = '1') then
                        ci.valid := '0';
                        -- calculate current_diff = current - voltage
                        ci.current_diff := resize(current - reg.voltage + Jbias, ci.current_diff);
                        ci.state := state_dv;
                    end if;
                when state_dv =>
                    -- calculate dv = (current_diff * decay) >> 16
                    ci.dv := resize((reg.current_diff * decay) sra 16, ci.dv); -- FIXME possibly make decay a power of 2, eliminate the multiply
                    ci.state := state_voltage;
                when state_voltage =>
                    -- accumulate voltage if not in refractory period, and decrement refractory otherwise
                    if(reg.refractory = X"0") then
                        ci.voltage := resize(reg.voltage + reg.dv, ci.voltage); 
                    else
                        ci.refractory := reg.refractory - X"1";
                    end if;
                    ci.state := state_spike;
                when state_spike =>
                    if(reg.voltage > voltage_threshold) then
                        ci.spike := '1';
                        ci.refractory := tau_ref;
                        ci.voltage := resize(reg.voltage - voltage_threshold, ci.voltage);
                    else
                        ci.spike := '0';
                    end if;
                    ci.valid := '1';
                    ci.state := state_idle;
            end case;
        end if;
        
        ci_next <= ci;
    end process COMB;
    
    SEQ: process(clk, ci_next)
    begin
        if(rising_edge(clk)) then
            reg <= ci_next;
        end if;
    end process SEQ;

    valid <= reg.valid;
    spike <= reg.spike;

end Behavioral;
