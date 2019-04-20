---
 -- Copyright (c) 2018 Sean Stasiak. All rights reserved.
 -- Developed by: Sean Stasiak <sstasiak@protonmail.com>
 -- Refer to license terms in license.txt; In the absence of such a file,
 -- contact me at the above email address and I can provide you with one.
---

library ieee;

use ieee.std_logic_1164.all,
    ieee.numeric_std.all;

---
 -- Generic rising edge double flop (SIG)nal (SYNC)hronizer with synchronous reset
---

entity sigsync is
  port( clk_in    : in  std_logic;
        srst_in   : in  std_logic;
        async_in  : in  std_logic;
        sync_out  : out std_logic );
end entity;

architecture dfault of sigsync is
  signal sig : std_logic;
begin
  process(clk_in)
  begin
    if rising_edge(clk_in) then
      if srst_in = '1' then
        sig      <= '0';
        sync_out <= '0';
      else
        sig      <= async_in;
        sync_out <= sig;
      end if;
    end if;
  end process;
end architecture;