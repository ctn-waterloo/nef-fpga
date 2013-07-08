library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library IEEE_proposed;
use IEEE_proposed.fixed_pkg.ALL;

entity communication_channel_tb is
end entity;

architecture sim of communication_channel_tb is
    signal clk: std_logic;
    constant CLOCK_PERIOD: time := 5 ns;
    
    component communication_channel port (
        clk: in std_logic;
        rst: in std_logic;
        U: in sfixed(31 downto 0);
        valid: in std_logic;
        Y: out sfixed(31 downto 0);
        ready: out std_logic
    ); end component;
    
    signal rst: std_logic;
    signal U: sfixed(31 downto 0);
    signal valid: std_logic;
    signal Y: sfixed(31 downto 0);
    signal ready: std_logic;
    
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
end process;

uut: communication_channel port map (
    clk => clk,
    rst => rst,
    U => U,
    valid => valid,
    Y => Y,
    ready => ready
);

tb: process
begin
    rst <= '1';
    U <= to_sfixed(0, 31,0);
    valid <= '0';
    
    wait for 50 ns;
    rst <= '0';
    wait for CLOCK_PERIOD*3;    
    
    loop
        wait until falling_edge(clk);
        U <= to_sfixed(65536, 31,0);
        valid <= '1';
        wait for CLOCK_PERIOD;
        valid <= '0';
        wait until ready = '1';
        wait for CLOCK_PERIOD;               
    end loop;
    
end process;

end architecture sim;