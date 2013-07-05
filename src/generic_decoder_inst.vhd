----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/02/2013 11:06:32 AM
-- Design Name: 
-- Module Name: generic_decoder_inst - Behavioral
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

library std;
use std.textio.all;

library IEEE_proposed;
use IEEE_proposed.fixed_pkg.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity generic_decoder_inst is
    generic (
        N : integer := 1; -- number of neurons to decode
        LOGN: integer := 1;
        loadfile: string
    );
    Port ( 
        clk : in STD_LOGIC;
        rst: in std_logic;
        valid: in std_logic;   
        spikes : in STD_LOGIC_VECTOR (N-1 downto 0);
        decoded_value : out sfixed (15 downto 0);
        ready: out std_logic
    );
end generic_decoder_inst;

architecture Behavioral of generic_decoder_inst is
    type state_type is (state_idle, state_load0, state_accumulate, state_wait);
    
    signal counter_high: unsigned(LOGN-1 downto 0) := to_unsigned(N-1, LOGN); -- why this cannot be "constant" I will never know.

    type ROM_type is array(0 to N-1) of std_logic_vector(15 downto 0);
    impure function InitFromFile (FileName: in string) return ROM_type is
         FILE ROMFile : text is in FileName;
         variable ROMFileLine : line;
         variable ROM: ROM_type;
         variable tmp: bit_vector(15 downto 0);
    begin
         for I in ROM_type'range loop
             readline(ROMFile, ROMFileLine);
             read(ROMFileLine, tmp);
             ROM(I) := to_stdlogicvector(tmp);
         end loop;
         return ROM;
    end function; 
    signal ROM: ROM_type := InitFromFile(loadfile);
    signal ROM_data: std_logic_vector(15 downto 0);

    type ci_type is record
        state: state_type;
        counter: unsigned(LOGN-1 downto 0);
        next_accumulated: unsigned(LOGN-1 downto 0);
        accumulator: sfixed(23 downto 0);
        ready: std_logic;
    end record;

    constant reg_reset: ci_type := (
        state => state_idle,
        counter => (others=>'0'),
        next_accumulated => (others=>'0'),
        accumulator => to_sfixed(0, 23,0),
        ready => '0'
    );

    signal reg: ci_type := reg_reset;
    signal ci_next: ci_type;
begin

COMB: process(reg, rst, valid, spikes, ROM_data)
    variable ci: ci_type;
begin
    ci := reg;
    if(rst = '1') then
        ci := reg_reset;
    else
        case reg.state is
            when state_idle =>
                if(valid = '1') then
                    -- reset outputs
                    ci.counter := (others=>'0'); -- set up read for decoder #0 
                    ci.accumulator := to_sfixed(0, 23,0);
                    ci.next_accumulated := (others=>'0');
                    ci.ready := '0';
                    ci.state := state_load0;
                end if;
            when state_load0 =>
                -- stall to get data from decoder #0, set up read for decoder #1
                ci.counter := reg.counter + "1";
                ci.state := state_accumulate;
            when state_accumulate =>
                -- accumulate if the neuron spiked this timestep
                if(spikes(to_integer(reg.next_accumulated)) = '1') then
                    ci.accumulator := resize(reg.accumulator + to_sfixed(ROM_data, 15, 0), ci.accumulator);
                end if;
                -- set up read for next decoder
                ci.counter := reg.counter + "1";
                -- if we just accumulated the last neuron, we're done accumulating
                if(reg.next_accumulated = counter_high) then
                    ci.ready := '1';
                    ci.state := state_wait;
                else
                    ci.next_accumulated := reg.next_accumulated + "1";
                end if;
            when state_wait =>
                -- wait for valid to go low before doing anything else
                if(valid = '0') then
                    ci.state := state_idle;
                end if;                         
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

decoded_value <= resize(reg.accumulator, 15,0);
ready <= reg.ready;

ROM_seq: process(clk, reg)
    variable addr: integer;
begin
    addr := to_integer(unsigned(reg.counter));
    if(rising_edge(clk)) then
        if(addr < N) then
            ROM_data <= ROM(addr);
        else
            ROM_data <= (others=>'0');
        end if; 
    end if;
end process ROM_seq;

end Behavioral;
