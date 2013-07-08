library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library std;
use std.textio.all;

library IEEE_proposed;
use IEEE_proposed.fixed_pkg.ALL;

entity communication_channel is port (
    clk: in std_logic;
    rst: in std_logic;
    U: in sfixed(31 downto 0);
    valid: in std_logic;
    Y: out sfixed(31 downto 0);
    ready: out std_logic
    );
end entity;

architecture behav of communication_channel is
    component generic_encoder_1d generic (
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
    ); end component;
    
    component fixed_neuron generic (
        decay: integer := 4;
        tau_ref: unsigned(3 downto 0) := X"2";
        Jbias: sfixed(15 downto 0) := to_sfixed(0, 15,0)
    );
    Port ( 
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        
        ready: in std_logic;
        current: in sfixed(31 downto 0);
                
        valid: out std_logic;
        spike: out std_logic
    ); end component;
    
    component generic_decoder generic (
        N : integer := 1; -- number of neurons to decode
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
    
    
    type ROM_type is array(0 to 19) of std_logic_vector(15 downto 0);
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
    constant A_Jbias_ROM: ROM_type := InitFromFile("communication_channel_A_Jbias.rom");
    
    signal a_encoded: sfixed(31 downto 0);
    signal a_encoded_ready: std_logic_vector(19 downto 0);
    signal a_encoded_shifted: sfixed(31 downto 0);
    signal a_done: std_logic;

    signal a_spike_valid: std_logic_vector(19 downto 0);
    signal a_spike: std_logic_vector(19 downto 0);
    
    signal a_decoded: sfixed(15 downto 0);
    signal a_decoded_ready: std_logic;

begin

    A_encoder: generic_encoder_1d generic map (
        N => 20,
        loadfile => "communication_channel_A_encoder.rom"
    ) port map (
        clk => clk,
        rst => rst,
        X => U,
        valid => valid,
        ready => a_encoded_ready,
        J => a_encoded,
        done => a_done
    );
    a_encoded_shifted <= a_encoded sra 10; -- dot product >> (ENCODER_BITS + VALUE_BITS - NEURON_BITS)
    
NEURON: for I in 0 to 19 generate
    A_neuron: fixed_neuron generic map (
        decay => 4,
        tau_ref => X"2",
        Jbias => to_sfixed(A_Jbias_ROM(I), 15,0)
    ) port map (
        clk => clk,
        rst => rst,
        ready => a_encoded_ready(I),
        current => a_encoded_shifted,
        valid => a_spike_valid(I),
        spike => a_spike(I)
    );
end generate;

    A_decoder: generic_decoder generic map (
        N => 20,
        loadfile => "communication_channel_A_decoder.rom"
    ) port map (
        clk => clk,
        rst => rst,
        valid => a_done, -- cheating
        spikes => a_spike,
        decoded_value => a_decoded,
        ready => a_decoded_ready
    );
    
    ready <= a_decoded_ready; -- temporarily

end architecture behav;