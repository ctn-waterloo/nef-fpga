----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/28/2013 03:02:41 PM
-- Design Name: 
-- Module Name: generic_encoder_1d - Behavioral
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

entity generic_encoder_1d is
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
end generic_encoder_1d;

architecture Behavioral of generic_encoder_1d is
    -- clogb2 function - ceiling of log base 2
    function clogb2 (size : integer) return integer is
        variable base : integer := 1;
        variable inp : integer := 0;
    begin
        inp := size - 1;
        while (inp > 1) loop
            inp := inp/2 ;
            base := base + 1;
        end loop;
        return base;
    end function;
    
    constant counter_width: integer := clogb2(N);
    
    component generic_encoder_1d_inst
    generic (
        N : integer := 1; -- number of neurons to decode
        LOGN: integer := 1;
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
    
begin

    inst: generic_encoder_1d_inst generic map (
        N => N,
        LOGN => counter_width,
        loadfile => loadfile
    ) port map (
        clk => clk,
        rst => rst,
        X => X,
        valid => valid,
        ready => ready,
        J => J,
        done => done
    );

end Behavioral;
