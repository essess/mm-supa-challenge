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
 -- (P)reamble (D)etector (see preamble.png for sequence)
---

entity pd is
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
end entity;

architecture dfault of pd is

  signal ip, detected : std_logic;

begin
  assert (CLKIN_RATE >= ENB_RATE) severity failure;
  assert (ENB_RATE >= 1E3) severity failure;

  detect : process(clk_in)
    constant HOLD_SECS : integer := 10;
    variable cnt : natural range 0 to (HOLD_SECS*ENB_RATE);

    type state_t is ( IDLE,
                      WAIT_1, WAIT_10, WAIT_101, WAIT_1010, WAIT_10100,
                      WAIT_101000, WAIT_1010000, WAIT_10100001, WAIT_101000010,
                      WAIT_1010000101, WAIT_10100001010, WAIT_101000010100,
                      WAIT_1010000101000, WAIT_10100001010000, WAIT_101000010100000,
                      WAIT_1010000101000000, WAIT_10100001010000001,
                      HOLD );
    variable state : state_t;

  begin
    if rising_edge(clk_in) then
      ip       <= '0';
      detected <= '0';

      if srst_in then
        state := IDLE;
      else

        case state is
          when IDLE =>
            if start_in then
              state := WAIT_1;
            end if;

          when WAIT_1 =>
            ip <= '1';
            if samplenb_in then
              if data_in = '1' then
                state := WAIT_10;
              end if;
            end if;

          when WAIT_10 =>
            ip <= '1';
            if samplenb_in then
              if data_in = '0' then
                state := WAIT_101;
              else
                state := WAIT_1;
              end if;
            end if;

          when WAIT_101 =>
            ip <= '1';
            if samplenb_in then
              if data_in = '1' then
                state := WAIT_1010;
              else
                state := WAIT_1;
              end if;
            end if;

          when WAIT_1010 =>
            ip <= '1';
            if samplenb_in then
              if data_in = '0' then
                state := WAIT_10100;
              else
                state := WAIT_1;
              end if;
            end if;

          when WAIT_10100 =>
            ip <= '1';
            if samplenb_in then
              if data_in = '0' then
                state := WAIT_101000;
              else
                state := WAIT_1010;
              end if;
            end if;

          when WAIT_101000 =>
            ip <= '1';
            if samplenb_in then
              if data_in = '0' then
                state := WAIT_1010000;
              else
                state := WAIT_1;
              end if;
            end if;

          when WAIT_1010000 =>
            ip <= '1';
            if samplenb_in then
              if data_in = '0' then
                state := WAIT_10100001;
              else
                state := WAIT_1;
              end if;
            end if;

          when WAIT_10100001 =>
            ip <= '1';
            if samplenb_in then
              if data_in = '1' then
                state := WAIT_101000010;
              else
                state := WAIT_1;
              end if;
            end if;

          when WAIT_101000010 =>
            ip <= '1';
            if samplenb_in then
              if data_in = '0' then
                state := WAIT_1010000101;
              else
                state := WAIT_1;
              end if;
            end if;

          when WAIT_1010000101 =>
            ip <= '1';
            if samplenb_in then
              if data_in = '1' then
                state := WAIT_10100001010;
              else
                state := WAIT_1;
              end if;
            end if;

          when WAIT_10100001010 =>
            ip <= '1';
            if samplenb_in then
              if data_in = '0' then
                state := WAIT_101000010100;
              else
                state := WAIT_1;
              end if;
            end if;

          when WAIT_101000010100 =>
            ip <= '1';
            if samplenb_in then
              if data_in = '0' then
                state := WAIT_1010000101000;
              else
                state := WAIT_1010;
              end if;
            end if;

          when WAIT_1010000101000 =>
            ip <= '1';
            if samplenb_in then
              if data_in = '0' then
                state := WAIT_10100001010000;
              else
                state := WAIT_1;
              end if;
            end if;

          when WAIT_10100001010000 =>
            ip <= '1';
            if samplenb_in then
              if data_in = '0' then
                state := WAIT_101000010100000;
              else
                state := WAIT_1;
              end if;
            end if;

          when WAIT_101000010100000 =>
            ip <= '1';
            if samplenb_in then
              if data_in = '0' then
                state := WAIT_1010000101000000;
              else
                state := WAIT_101000010;
              end if;
            end if;

          when WAIT_1010000101000000 =>
            ip <= '1';
            if samplenb_in then
              if data_in = '0' then
                state := WAIT_10100001010000001;
              else
                state := WAIT_1;
              end if;
            end if;

          when WAIT_10100001010000001 =>
            ip <= '1';
            if samplenb_in then
              cnt := 0;
              if data_in = '1' then
                state := HOLD;
              else
                state := WAIT_1;
              end if;
            end if;

          when HOLD =>
            ip       <= '1';
            detected <= '1';
            if samplenb_in then
              cnt := cnt +1;
              if cnt = (HOLD_SECS*ENB_RATE) then
                state := IDLE; --< may result in ip/detected glitch but keeps pattern
              end if;          --  recognition synchronized correctly with samplenb_in
            end if;

          when others =>      --< GHDL complains
            state := IDLE;

        end case;
      end if;
    end if;
  end process;

  -- output
  ip_out       <= ip after TPD;
  detected_out <= detected after TPD;

end architecture;