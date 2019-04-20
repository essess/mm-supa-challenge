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
 -- (DIV)ider to provide enable signals at a lower freq than clk_in
 -- while remaining fully synchronous
---

entity div is
  generic( CLKIN_RATE : positive;
           ENB_RATE   : positive;   --< desired output rate
           TPD        : time := 0 ns );
  port( clk_in  : in  std_logic;
        srst_in : in  std_logic;
        enb_out : out std_logic );
end entity;

architecture dfault of div is
  signal enb : std_logic;
begin

  assert (CLKIN_RATE >= ENB_RATE) severity failure;

  process(clk_in)
    constant CNT_MAX : positive := (CLKIN_RATE / ENB_RATE);
    variable cnt : natural range 0 to CNT_MAX;
  begin
    if rising_edge(clk_in) then
      enb <= '0';
      if srst_in then
        cnt := 0;
      else
        cnt := cnt +1;
        if cnt = CNT_MAX then
          enb <= '1';
          cnt := 0;
        end if;
      end if;
    end if;
  end process;

  -- output
  enb_out <= enb after TPD;

end architecture;