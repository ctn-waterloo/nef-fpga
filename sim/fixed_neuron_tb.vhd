----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/28/2013 10:18:12 AM
-- Design Name: 
-- Module Name: fixed_neuron_tb - Behavioral
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

entity fixed_neuron_tb is
end fixed_neuron_tb;

architecture Behavioral of fixed_neuron_tb is
    signal clk: std_logic;
    constant CLOCK_PERIOD: time := 5 ns;
    
    component fixed_neuron
    generic (
        decay: sfixed(31 downto 0) := to_sfixed(3276, 31,0); -- decay = (1<<16)/tau_rc
        tau_ref: unsigned(3 downto 0) := X"2"
    );
    Port ( 
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        
        ready: in std_logic;
        current: in sfixed(31 downto 0);
                
        valid: out std_logic;
        spike: out std_logic
    ); end component;
    
    signal rst: std_logic;
    signal ready: std_logic;
    signal current: sfixed(31 downto 0);
    
    signal valid: std_logic;
    signal spike: std_logic;        
    
begin

    CLKGEN: process
    begin
        clk <= '0';
        loop
            clk <= '0';
            wait for CLOCK_PERIOD/2;
            clk <= '1';
            wait for CLOCK_PERIOD/2;
        end loop;
    end process CLKGEN;
    
    uut: fixed_neuron
    generic map (
        decay => to_sfixed(3276, 31,0),
        tau_ref => X"2"
    ) port map (
        clk => clk,
        rst => rst,
        ready => ready,
        current => current,
        valid => valid,
        spike => spike
    );
    
    tb: process
    begin
        rst <= '1';
        ready <= '0';
        current <= to_sfixed(0, 31,0);
        
        wait for 100 ns;
        rst <= '0';        
        current <= to_sfixed(131072, 31,0);
        
        loop
            wait until falling_edge(clk);
            ready <= '1';
            wait for CLOCK_PERIOD;
            ready <= '0';
            wait until valid = '1';
        end loop;
        
        wait;
        
    end process tb;

end Behavioral;
