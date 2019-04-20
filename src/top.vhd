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
 -- (TOP) level implementation of mm-supa-challenge
---

entity top is
  generic( constant CLKIN_RATE : integer := 100448E3 );
  port( clk12M_in : in  std_logic;
        start_in  : in  std_logic;    --< ball B3
        data_in   : in  std_logic;    --< ball C1
        servo_out : out std_logic;    --< ball B1
        led_out   : out std_logic_vector(0 to 7) );
end entity;

architecture dfault of top is

  component pll is
      port ( CLKI  : in  std_logic;
             CLKOP : out std_logic;
             LOCK  : out std_logic );
  end component;

  component div is
    generic( CLKIN_RATE : positive;
             ENB_RATE   : positive;   --< desired output rate
             TPD        : time := 0 ns );
    port( clk_in  : in  std_logic;
          srst_in : in  std_logic;
          enb_out : out std_logic );
  end component;

  component sigsync is
    port( clk_in    : in  std_logic;
          srst_in   : in  std_logic;
          async_in  : in  std_logic;
          sync_out  : out std_logic );
  end component;

  component debounce is
    generic( n   : integer;             --< number of samples
             TPD : time := 0 ns );
    port( clk_in  : in  std_logic;
          srst_in : in  std_logic;
          enb_in  : in  std_logic;      --< 'sample clk'
          d_in    : in  std_logic;
          q_out   : out std_logic );    --< q <= d upon (2^n) samples
  end component;

  component mm is
    generic( CLKIN_RATE : integer );
    port( clk_in    : in  std_logic;
          srst_in   : in  std_logic;
          data_line : in  std_logic;
          button    : in  std_logic;
          led       : out std_logic;
          servo     : out std_logic );
  end component;

  signal sstart_in, sdata_in : std_logic; --< inputs sync'd to clk100M
  signal start    , data     : std_logic; --< debounced/deglitched and fully sync'd inputs to mm

  signal clk100M, enb1K, lock, srst, led, servo : std_logic;

begin
  led_out(1 to 7) <= (1 to 7=>'1');

  pll0 : pll
    port map( CLKI  => clk12M_in,
              CLKOP => clk100M,   --< 100_448_000Hz is the closest I could manage
              LOCK  => lock );

  -- generate sample clk for start button debounce
  div0 : div
    generic map( CLKIN_RATE => CLKIN_RATE,
                 ENB_RATE   => 1E3 )
    port map( clk_in  => clk100M,
              srst_in => srst,
              enb_out => enb1K );


  -- condition start button
  sync0 : sigsync
    port map( clk_in  => clk100M,
              srst_in => srst,
              async_in => not(start_in),
              sync_out => sstart_in );

  debounce0 : debounce
    generic map( n => 10 ) --< 10ms @ 1K
    port map( clk_in  => clk100M,
              srst_in => srst,
              enb_in  => enb1K,
              d_in    => sstart_in,
              q_out   => start );

  -- condition data line input
  sync1 : sigsync
    port map( clk_in   => clk100M,
              srst_in  => srst,
              async_in => data_in,
              sync_out => sdata_in );

  debounce1 : debounce
    generic map( n => 15 ) --< .15us @ 100M  (30% of bit time)
    port map( clk_in  => clk100M,
              srst_in => srst,
              enb_in  => '1',
              d_in    => sdata_in,
              q_out   => data );

  ---
   -- stretch lock signal and use for global reset
   -- can't depend on inferred GSR because all resets
   -- are synchronous -> need to gen my own
  ---
  srst <= /* stretch <= */ not(lock);  --< TODO


  mm0 : mm
    generic map( CLKIN_RATE => CLKIN_RATE )
    port map( clk_in    => clk100M,
              srst_in   => srst,
              data_line => data,
              button    => start,
              led       => led,
              servo     => servo );
  led_out(0) <= not(led);
  servo_out <= not(servo);  --< invert for low-side driver

end architecture;