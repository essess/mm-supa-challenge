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
 -- (S)ervo (D)river (B)lock which requires a 2KHz enable signal to
 -- cleanly divide the period into 20ms with a resolution of .5ms
 --
 -- this was chosen as a simple way to use a single bit input to
 -- select 0deg or 90deg output.
---

entity sdb is
  generic( TPD : time := 0 ns );
  port( clk_in    : in  std_logic;
        srst_in   : in  std_logic;
        enb_in    : in  std_logic;
        sig_in    : in  std_logic;  --< '0'-> 0deg, '1'-> 90deg
        drive_out : out std_logic );
end entity;

architecture dfault of sdb is
  signal drive : std_logic;
begin

  process(clk_in)
    constant CNT_MAX : positive := 40;   --< # of ticks to result in a 20ms period
                                         --  assuming a 2KHz enb_in 'incrementor'
    constant WIDTH_1MS : natural   := 2; --< 2 ticks at 2KHz == 1ms   == 0deg
    constant WIDTH_1p5MS : natural := 3; --< 3 ticks at 2KHz == 1.5ms == 90deg

    variable cnt : natural range 0 to CNT_MAX;
    variable val : natural range 0 to 3;
  begin
    if rising_edge(clk_in) then
      if srst_in then
        cnt := 0;
        val := WIDTH_1MS;   --< drive to 0deg out of reset
        drive <= '1';
      else
        if enb_in then
          cnt := cnt +1;

          if cnt >= CNT_MAX then
            cnt := 0;
            drive <= '1';     --< start of new period
            if sig_in then    --< 0deg or 90deg for this period?
              val := WIDTH_1p5MS;
            else
              val := WIDTH_1MS;
            end if;
          elsif cnt = val then
            drive <= '0';
          end if;

        end if;
      end if;
    end if;
  end process;

  -- output
  drive_out <= drive after TPD;

end architecture;