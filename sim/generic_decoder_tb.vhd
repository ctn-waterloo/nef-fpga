library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library IEEE_proposed;
use IEEE_proposed.fixed_pkg.ALL;

entity generic_decoder_tb is
end entity;

architecture sim of generic_decoder_tb is

    signal clk: std_logic;
    constant CLOCK_PERIOD: time := 5 ns;

    component generic_decoder
    generic (
        N : integer; -- number of neurons to decode
        loadfile: string
    );
    Port ( 
        clk : in STD_LOGIC;
        rst: in std_logic;
        valid: in std_logic;   
        spikes : in STD_LOGIC_VECTOR (N-1 downto 0);
        decoded_value : out sfixed (15 downto 0);
        ready: out std_logic
    ); end component;
    
    signal rst: std_logic;
    signal valid: std_logic;
    signal spikes: std_logic_vector(4 downto 0);
    signal decoded_value: sfixed(15 downto 0);
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

uut: generic_decoder generic map (
    N => 5,
    loadfile => "generic_decoder_tb_5.rom"
) port map (
    clk => clk,
    rst => rst,
    valid => valid,
    spikes => spikes,
    decoded_value => decoded_value,
    ready => ready
);
    
    tb: process
    begin
        rst <= '1';
        valid <= '0';
        spikes <= (others=>'0');
        wait for 50 ns;
        rst <= '0';
        wait for 3*CLOCK_PERIOD;
        wait until falling_edge(clk);
        spikes <= (others=>'1');
        valid <= '1';
        wait for CLOCK_PERIOD;
        
        wait;
    end process tb;

end architecture;