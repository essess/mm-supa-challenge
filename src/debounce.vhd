---
 -- Copyright (c) 2019 Sean Stasiak. All rights reserved.
 -- Developed by: Sean Stasiak <sstasiak@protonmail.com>
 -- Refer to license terms in license.txt; In the absence of such a file,
 -- contact me at the above email address and I can provide you with one.
---

library ieee;
use ieee.std_logic_1164.all,
    ieee.numeric_std.all;

---
 -- (DEBOUNCE) an input stream.
 -- sampling occurs when enb_in='1' and rising_edge(clk_in)
 -- n is the number of samples required to be the same value before changing
 -- output state of q
---


entity debounce is
  generic( n   : integer;             --< number of samples
           TPD : time := 0 ns );
  port( clk_in  : in  std_logic;
        srst_in : in  std_logic;
        enb_in  : in  std_logic;      --< 'sample clk'
        d_in    : in  std_logic;
        q_out   : out std_logic );    --< q <= d upon (2^n) samples
end entity;

architecture arch of debounce is

  component siposr is
    generic( n   : integer;           --< width
             TPD : time := 0 ns );
    port( clk_in  : in  std_logic;
          srst_in : in  std_logic;
          enb_in  : in  std_logic;    --< shift enable
          d_in    : in  std_logic;
          q_out   : out std_logic_vector(n-1 downto 0) );
  end component;

  signal sr_q : std_logic_vector(n-1 downto 0);
  signal q, q_next : std_logic;

  constant all_ones  : std_logic_vector(sr_q'range) := (others=>'1');
  constant all_zeros : std_logic_vector(sr_q'range) := (others=>'0');
  signal ones, zeros : std_logic;

begin

  siposr0: siposr
    generic map( n => n )
    port map( clk_in  => clk_in,
              srst_in => srst_in,
              enb_in  => enb_in,
              d_in    => d_in,
              q_out   => sr_q );

  state : process(clk_in)
  begin
    if rising_edge(clk_in) then
      if srst_in then
        q <= d_in;
      else
        q <= q_next;
      end if;
    end if;
  end process;


  -- Due to width being parameterized via n, VHDL does not see all_ones, or all_zeros
  -- as locally static. Determining next state requires a little trickery on our
  -- part below in order to use this with GHDL which is very strict about such things

  -- next
  ones  <= '1' when (sr_q = all_ones)  else '0';
  zeros <= '1' when (sr_q = all_zeros) else '0';

  q_next <= '1' when ((ones='1') and (zeros='0')) else
            '0' when ((ones='0') and (zeros='1')) else
            q;

  -- output
  q_out <= q after TPD;

end architecture;