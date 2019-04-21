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

  signal ip       : std_logic;    --< in progress
  signal detected : std_logic;    --< sequence detected

begin
  assert (CLKIN_RATE >= ENB_RATE) severity failure;
  assert (ENB_RATE >= 1E3) severity failure;

  detect : process(clk_in)
    constant HOLD_SECS : integer := 10;
    variable cnt : natural range 0 to (HOLD_SECS*ENB_RATE);

    type state_t is ( IDLE,
                      a, b, c, d, e, f, g, h, i,
                      j, k, l, m, n, o, p, q,
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
              state := a;
            end if;

          when a =>
            ip <= '1';
            if samplenb_in then
              if data_in = '1' then
                state := b;
              end if;
            end if;

          when b =>
            ip <= '1';
            if samplenb_in then
              if data_in = '0' then
                state := c;
              end if;
            end if;

          when c =>
            ip <= '1';
            if samplenb_in then
              if data_in = '1' then
                state := d;
              else
                state := a;
              end if;
            end if;

          when d =>
            ip <= '1';
            if samplenb_in then
              if data_in = '0' then
                state := e;
              else
                state := b;
              end if;
            end if;

          when e =>
            ip <= '1';
            if samplenb_in then
              if data_in = '0' then
                state := f;
              else
                state := d;
              end if;
            end if;

          when f =>
            ip <= '1';
            if samplenb_in then
              if data_in = '0' then
                state := g;
              else
                state := b;
              end if;
            end if;

          when g =>
            ip <= '1';
            if samplenb_in then
              if data_in = '0' then
                state := h;
              else
                state := b;
              end if;
            end if;

          when h =>
            ip <= '1';
            if samplenb_in then
              if data_in = '1' then
                state := i;
              else
                state := a;
              end if;
            end if;

          when i =>
            ip <= '1';
            if samplenb_in then
              if data_in = '0' then
                state := j;
              else
                state := b;
              end if;
            end if;

          when j =>
            ip <= '1';
            if samplenb_in then
              if data_in = '1' then
                state := k;
              else
                state := a;
              end if;
            end if;

          when k =>
            ip <= '1';
            if samplenb_in then
              if data_in = '0' then
                state := l;
              else
                state := b;
              end if;
            end if;

          when l =>
            ip <= '1';
            if samplenb_in then
              if data_in = '0' then
                state := m;
              else
                state := d;
              end if;
            end if;

          when m =>
            ip <= '1';
            if samplenb_in then
              if data_in = '0' then
                state := n;
              else
                state := b;
              end if;
            end if;

          when n =>
            ip <= '1';
            if samplenb_in then
              if data_in = '0' then
                state := o;
              else
                state := b;
              end if;
            end if;

          when o =>
            ip <= '1';
            if samplenb_in then
              if data_in = '0' then
                state := p;
              else
                state := i;
              end if;
            end if;

          when p =>
            ip <= '1';
            if samplenb_in then
              if data_in = '0' then
                state := q;
              else
                state := b;
              end if;
            end if;

          when q =>
            ip <= '1';
            if samplenb_in then
              cnt := 0;
              if data_in = '1' then
                state := HOLD;
              else
                state := a;
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
