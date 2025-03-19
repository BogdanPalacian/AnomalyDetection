library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity axi4_threshold_processor is
    port (
        -- AXI4 Stream Input Interface
        s_axis_threshold_tdata : in  std_logic_vector(15 downto 0); -- Threshold
        s_axis_threshold_tvalid : in  std_logic;                    -- Threshold valid
        s_axis_threshold_tready : out std_logic;                    -- Threshold ready

        s_axis_gp_tdata : in  std_logic_vector(15 downto 0);        -- g+(t)
        s_axis_gp_tvalid : in  std_logic;                           -- g+(t) valid
        s_axis_gp_tready : out std_logic;                           -- g+(t) ready

        s_axis_gm_tdata : in  std_logic_vector(15 downto 0);        -- g-(t)
        s_axis_gm_tvalid : in  std_logic;                           -- g-(t) valid
        s_axis_gm_tready : out std_logic;                           -- g-(t) ready

        -- AXI4 Stream Output Interface
        m_axis_gp_prev_tdata : out std_logic_vector(15 downto 0);   -- g+(t-1)
        m_axis_gp_prev_tvalid : out std_logic;                      -- g+(t-1) valid
        m_axis_gp_prev_tready : in  std_logic;                      -- g+(t-1) ready

        m_axis_gm_prev_tdata : out std_logic_vector(15 downto 0);   -- g-(t-1)
        m_axis_gm_prev_tvalid : out std_logic;                      -- g-(t-1) valid
        m_axis_gm_prev_tready : in  std_logic;                      -- g-(t-1) ready

        label_out : out std_logic;                                      -- Label output

        -- Clock and Reset
        clk : in std_logic;
        reset : in std_logic
    );
end entity axi4_threshold_processor;

architecture Behavioral of axi4_threshold_processor is
    -- Define the states
    type state_type is (INIT, READ, WRITE);
    signal next_state : state_type;
    signal current_state : state_type := INIT;

    -- Internal signals
    signal threshold  : std_logic_vector(15 downto 0) := (others => '0');
    signal gp_current : std_logic_vector(15 downto 0) := (others => '0');
    signal gm_current : std_logic_vector(15 downto 0) := (others => '0');

    signal gp_prev    : std_logic_vector(15 downto 0) := (others => '0');
    signal gm_prev    : std_logic_vector(15 downto 0) := (others => '0');
    signal label_reg  : std_logic := '0';

    signal valid_gp_prev, valid_gm_prev : std_logic := '0';

begin
    -- State transition process
    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= INIT;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    -- State logic process
    process(current_state, s_axis_threshold_tvalid, s_axis_gp_tvalid, s_axis_gm_tvalid,
            m_axis_gp_prev_tready, m_axis_gm_prev_tready)
    begin
        -- Default values
        next_state <= current_state;
        valid_gp_prev <= '0';
        valid_gm_prev <= '0';
        label_reg <= '0';

        case current_state is
            when INIT =>
                gp_prev <= (others => '0');
                gm_prev <= (others => '0');
                valid_gp_prev <= '1';
                valid_gm_prev <= '1';

                next_state <= READ;

            when READ =>
                if s_axis_threshold_tvalid = '1' and s_axis_gp_tvalid = '1' and s_axis_gm_tvalid = '1' then
                    threshold <= s_axis_threshold_tdata;
                    gp_current <= s_axis_gp_tdata;
                    gm_current <= s_axis_gm_tdata;
                    next_state <= WRITE;
                end if;

            when WRITE =>
                if signed(gp_current) > signed(threshold) or signed(gm_current) > signed(threshold) then
                    gp_prev <= (others => '0');
                    gm_prev <= (others => '0');
                    label_reg <= '1';
                    valid_gp_prev <= '1';
                    valid_gm_prev <= '1';
                else
                    gp_prev <= gp_current;
                    gm_prev <= gm_current;
                    label_reg <= '0';
                    valid_gp_prev <= '1';
                    valid_gm_prev <= '1';
                end if;

               

                if m_axis_gp_prev_tready = '1' and m_axis_gm_prev_tready = '1' then
                    next_state <= READ;
                end if;

        end case;
    end process;

    -- Handshaking signals
    s_axis_threshold_tready <= '1' when current_state = READ else '0';
    s_axis_gp_tready        <= '1' when current_state = READ else '0';
    s_axis_gm_tready        <= '1' when current_state = READ else '0';

    m_axis_gp_prev_tvalid <= valid_gp_prev;
    m_axis_gm_prev_tvalid <= valid_gm_prev;

    -- Output assignments
    m_axis_gp_prev_tdata <= gp_prev;
    m_axis_gm_prev_tdata <= gm_prev;
    label_out <= label_reg;

end architecture Behavioral;
