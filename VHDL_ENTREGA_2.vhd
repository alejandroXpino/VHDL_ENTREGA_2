library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.mem_pkg.all;

entity VHDL_ENTREGA_2 is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        selector : in  std_logic_vector(1 downto 0);
        seg_out  : out std_logic_vector(6 downto 0)
    );
end VHDL_ENTREGA_2;

architecture Behavioral of VHDL_ENTREGA_2 is

    -- =========================
    -- COMPONENTES EXTRA (NO PACKAGE)
    -- =========================
    component divisor_frecuencia
        port (
            clk_entrada : in  std_logic;
            selector    : in  std_logic_vector(1 downto 0);
            clk_salida  : out std_logic
        );
    end component;

    component decodificador_7seg
        port (
            bcd_in  : in  std_logic_vector(3 downto 0);
            seg_out : out std_logic_vector(6 downto 0)
        );
    end component;

    -- =========================
    -- FSM
    -- =========================
    type state_t is (READ_ROM, WAIT_ROM, WRITE_RAM, READ_RAM);
    signal state : state_t := READ_ROM;

    -- =========================
    -- SEÑALES
    -- =========================
    signal clk_lento : std_logic;

    signal addr      : addr_t := (others => '0');
    signal rom_data  : word_t;
    signal ram_data  : word_t;

    signal rd_en : std_logic := '0';
    signal wr_en : std_logic := '0';

    -- Display
    signal bcd : std_logic_vector(3 downto 0);

begin

    -- =========================
    -- DIVISOR DE FRECUENCIA
    -- =========================
    DIV1: divisor_frecuencia
        port map (
            clk_entrada => clk,
            selector    => selector,
            clk_salida  => clk_lento
        );

    -- =========================
    -- ROM
    -- =========================
    ROM1: rom_sync
        port map (
            clk      => clk_lento,
            addr     => addr,
            data_out => rom_data
        );

    -- =========================
    -- RAM
    -- =========================
    RAM1: ram_sincrona
        port map (
            clk      => clk_lento,
            rd_en    => rd_en,
            wr_en    => wr_en,
            addr     => addr,
            data_in  => rom_data,
            data_out => ram_data
        );

    -- =========================
    -- FSM
    -- =========================
    process(clk_lento, rst)
    begin
        if rst = '1' then
            addr  <= (others => '0');
            state <= READ_ROM;
            rd_en <= '0';
            wr_en <= '0';

        elsif rising_edge(clk_lento) then

            case state is

                when READ_ROM =>
                    rd_en <= '0';
                    wr_en <= '0';
                    state <= WAIT_ROM;

                when WAIT_ROM =>
                    state <= WRITE_RAM;

                when WRITE_RAM =>
                    wr_en <= '1';
                    rd_en <= '0';
                    state <= READ_RAM;

                when READ_RAM =>
                    wr_en <= '0';
                    rd_en <= '1';

                    if addr = "1111" then
                        addr <= (others => '0');
                    else
                        addr <= std_logic_vector(unsigned(addr) + 1);
                    end if;

                    state <= READ_ROM;

            end case;
        end if;
    end process;

    -- =========================
    -- DISPLAY
    -- =========================
    bcd <= ram_data(3 downto 0);

    DEC1: decodificador_7seg
        port map (
            bcd_in  => bcd,
            seg_out => seg_out
        );

end Behavioral;