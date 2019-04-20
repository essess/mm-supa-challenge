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
 -- (M)ystery (M)achine toplevel
 --
 -- ASSUMPTIONS:
 --   1. all inputs synchronous to clk_in
 --   2. button and data_line inputs are debounced/glitch free
---

entity mm is
  generic( CLKIN_RATE : integer );
  port( clk_in    : in  std_logic;
        srst_in   : in  std_logic;
        data_line : in  std_logic;
        button    : in  std_logic;
        led       : out std_logic;
        servo     : out std_logic );
end entity;

architecture dfault of mm is

  component div is
    generic( CLKIN_RATE : positive;
             ENB_RATE   : positive;   --< desired output rate
             TPD        : time := 0 ns );
    port( clk_in  : in  std_logic;
          srst_in : in  std_logic;
          enb_out : out std_logic );
  end component;

  component sdb is
    generic( TPD : time := 0 ns );
    port( clk_in    : in  std_logic;
          srst_in   : in  std_logic;
          enb_in    : in  std_logic;
          sig_in    : in  std_logic;  --< '0'-> 0deg, '1'-> 90deg
          drive_out : out std_logic );
  end component;

  component pd is
    generic( CLKIN_RATE : positive;       --< clk_in rate
             ENB_RATE   : positive;       --< samplenb_in rate
             TPD        : time := 0 ns );
    port( clk_in       : in  std_logic;
          srst_in      : in  std_logic;
          samplenb_in  : in  std_logic;   --< data stream sample clk/enb
          data_in      : in  std_logic;   --< preamble data stream
          start_in     : in  std_logic;   --< begin detection of sequence
          detected_out : out std_logic;   --< sequence detected flag
          ip_out       : out std_logic ); --< sequence detection in-progress flag
  end component;

  signal samplenb_2K, samplenb_2M, detected : std_logic;

begin
  ---
   -- downhill from here, just connect the blocks
  ---

  div_2k : div
    generic map( CLKIN_RATE => CLKIN_RATE,
                 ENB_RATE   => 2E3 )
    port map( clk_in  => clk_in,
              srst_in => srst_in,
              enb_out => samplenb_2K );

  div_2m : div
    generic map( CLKIN_RATE => CLKIN_RATE,
                 ENB_RATE   => 2E6 )
    port map( clk_in  => clk_in,
              srst_in => srst_in,
              enb_out => samplenb_2M );

  servo_driver : sdb
    port map( clk_in    => clk_in,
              srst_in   => srst_in,
              enb_in    => samplenb_2K,
              sig_in    => detected,
              drive_out => servo );

  preamble_detector : pd
    generic map( CLKIN_RATE => CLKIN_RATE,
                 ENB_RATE   => 2E6 )
    port map( clk_in       => clk_in,
              srst_in      => srst_in,
              samplenb_in  => samplenb_2M,
              data_in      => data_line,
              start_in     => button,
              detected_out => detected,
              ip_out       => led );

end architecture;