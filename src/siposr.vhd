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
 -- variable width (S)erial (I)n (P)arallel (O)ut (S)hift (R)egister
 -- serial in, parallel out
 --
 -- upon reset, q_out takes on the value of d_in upon rising edge of clk_in
 --   allows for easy use as a pulse stretcher
---

entity siposr is
  generic( n   : integer;           --< width
           TPD : time := 0 ns );
  port( clk_in  : in  std_logic;
        srst_in : in  std_logic;
        enb_in  : in  std_logic;    --< shift enable
        d_in    : in  std_logic;
        q_out   : out std_logic_vector(n-1 downto 0) );
end entity;

architecture dfault of siposr is

  signal q : std_logic_vector(q_out'range);

begin
  assert (n >= 2) report "minimum width (n) is 2" severity failure;

  shift : process(clk_in)
  begin
    if rising_edge(clk_in) then
      if srst_in = '1' then
        if d_in = '1' then
          q <= (others=>'1');
        else
          q <= (others=>'0');
        end if;
      elsif enb_in = '1' then
        q(n-1 downto 1) <= q(n-2 downto 0);
        q(0) <= d_in;
      end if;
    end if;
  end process;

  -- output
  q_out <= q after TPD;

end architecture;