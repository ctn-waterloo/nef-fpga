library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library IEEE_proposed;
use IEEE_proposed.fixed_pkg.ALL;

entity generic_encoder_1d_tb is
end entity;

architecture sim of generic_encoder_1d_tb is
    signal clk: std_logic;
    constant CLOCK_PERIOD: time := 5 ns;
    
    component generic_encoder_1d
        generic (
            N : integer := 1; -- number of neurons to encode to
            loadfile: string
        );
        Port ( 
            clk : in STD_LOGIC;
            rst: in std_logic;
            X: in sfixed(31 downto 0);
            valid: in std_logic;   
            ready : out STD_LOGIC_VECTOR (N-1 downto 0);
            J : out sfixed (31 downto 0);
            done: out std_logic
        );
     end component;
     
     signal rst: std_logic;
     signal X: sfixed(31 downto 0);
     signal valid: std_logic;
     
     signal ready: std_logic_vector(4 downto 0);
     signal J: sfixed(31 downto 0);
     signal done: std_logic;
    
begin

clkgen: process
begin
    clk <= '0';
    loop
        clk <= '0';
        wait for CLOCK_PERIOD/2;
        clk <= '1';
        wait for CLOCK_PERIOD/2;
    end loop;
end process;

uut: generic_encoder_1d generic map (
    N => 5,
    loadfile => "generic_encoder_1d_tb_5.rom"
) port map (
    clk => clk,
    rst => rst,
    X => X,
    valid => valid,
    ready => ready,
    J => J,
    done => done    
);

tb: process
begin
    rst <= '1';
    X <= to_sfixed(4, 31,0);
    valid <= '0';
    wait for 50 ns;
    rst <= '0';
    wait for CLOCK_PERIOD*3;
    wait until falling_edge(clk);
    valid <= '1';
    wait;
end process;

end architecture sim;