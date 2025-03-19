library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_axi4_threshold_processor is
end entity tb_axi4_threshold_processor;

architecture behavior of tb_axi4_threshold_processor is
    -- Component declaration for the axi4_threshold_processor
    component axi4_threshold_processor
        port (
            s_axis_threshold_tdata : in  std_logic_vector(13 downto 0);
            s_axis_threshold_tvalid : in  std_logic;
            s_axis_threshold_tready : out std_logic;

            s_axis_gp_tdata : in  std_logic_vector(13 downto 0);
            s_axis_gp_tvalid : in  std_logic;
            s_axis_gp_tready : out std_logic;

            s_axis_gm_tdata : in  std_logic_vector(13 downto 0);
            s_axis_gm_tvalid : in  std_logic;
            s_axis_gm_tready : out std_logic;

            m_axis_gp_prev_tdata : out std_logic_vector(13 downto 0);
            m_axis_gp_prev_tvalid : out std_logic;
            m_axis_gp_prev_tready : in  std_logic;

            m_axis_gm_prev_tdata : out std_logic_vector(13 downto 0);
            m_axis_gm_prev_tvalid : out std_logic;
            m_axis_gm_prev_tready : in  std_logic;

            label_out : out std_logic;

            clk : in std_logic;
            reset : in std_logic
        );
    end component;

    -- Signals to drive the component inputs
    signal s_axis_threshold_tdata : std_logic_vector(13 downto 0);
    signal s_axis_threshold_tvalid : std_logic;
    signal s_axis_threshold_tready : std_logic;

    signal s_axis_gp_tdata : std_logic_vector(13 downto 0);
    signal s_axis_gp_tvalid : std_logic;
    signal s_axis_gp_tready : std_logic;

    signal s_axis_gm_tdata : std_logic_vector(13 downto 0);
    signal s_axis_gm_tvalid : std_logic;
    signal s_axis_gm_tready : std_logic;

    signal m_axis_gp_prev_tdata : std_logic_vector(13 downto 0);
    signal m_axis_gp_prev_tvalid : std_logic;
    signal m_axis_gp_prev_tready : std_logic;

    signal m_axis_gm_prev_tdata : std_logic_vector(13 downto 0);
    signal m_axis_gm_prev_tvalid : std_logic;
    signal m_axis_gm_prev_tready : std_logic;

    signal label_out : std_logic;

    -- Clock and Reset signals
    signal clk : std_logic := '0';
    signal reset : std_logic := '0';

 

begin

   -- Clock generation process
    process
    begin
        clk <= not clk after 10 ns; -- Clock period 20 ns
        wait for 10 ns;
    end process;
    -- Instantiate the threshold processor
    uut: axi4_threshold_processor
        port map (
            s_axis_threshold_tdata => s_axis_threshold_tdata,
            s_axis_threshold_tvalid => s_axis_threshold_tvalid,
            s_axis_threshold_tready => s_axis_threshold_tready,
            s_axis_gp_tdata => s_axis_gp_tdata,
            s_axis_gp_tvalid => s_axis_gp_tvalid,
            s_axis_gp_tready => s_axis_gp_tready,
            s_axis_gm_tdata => s_axis_gm_tdata,
            s_axis_gm_tvalid => s_axis_gm_tvalid,
            s_axis_gm_tready => s_axis_gm_tready,
            m_axis_gp_prev_tdata => m_axis_gp_prev_tdata,
            m_axis_gp_prev_tvalid => m_axis_gp_prev_tvalid,
            m_axis_gp_prev_tready => m_axis_gp_prev_tready,
            m_axis_gm_prev_tdata => m_axis_gm_prev_tdata,
            m_axis_gm_prev_tvalid => m_axis_gm_prev_tvalid,
            m_axis_gm_prev_tready => m_axis_gm_prev_tready,
            label_out => label_out,
            clk => clk,
            reset => reset
        );

    -- Testbench process
    process
    begin
        -- Reset the DUT
        reset <= '1';
        wait for 20 ns;
        reset <= '0';
        wait for 20 ns;

        -- Test 1: gp and gm above threshold
        -- Setting the threshold to 2
        s_axis_threshold_tdata <= "00000000000010";  -- Threshold = 2
        s_axis_threshold_tvalid <= '1';
        

        -- Setting gp and gm above the threshold
        s_axis_gp_tdata <= "00000000000101";  -- gp = 5 (above threshold)
        s_axis_gp_tvalid <= '1';
        s_axis_gm_tdata <= "00000000000110";  -- gm = 6 (above threshold)
        s_axis_gm_tvalid <= '1';
        m_axis_gm_prev_tready <='1';
        m_axis_gp_prev_tready <= '1';
        wait for 10 ns;
        s_axis_gp_tvalid <= '0';
        s_axis_gm_tvalid <= '0';
        s_axis_threshold_tvalid <= '0';

        -- Wait and check the label_out value (should be 1)
        wait for 30 ns;
        assert label_out = '1' report "Test 1 failed" severity error;

        -- Test 2: gp and gm below threshold
        -- Setting the threshold to 2
        s_axis_threshold_tdata <= "00000000000010";  -- Threshold = 2
        s_axis_threshold_tvalid <= '1';
        

        -- Setting gp and gm below the threshold
        s_axis_gp_tdata <= "00000000000001";  -- gp = 1 (below threshold)
        s_axis_gp_tvalid <= '1';
        s_axis_gm_tdata <= "00000000000000";  -- gm = 0 (below threshold)
        s_axis_gm_tvalid <= '1';
        m_axis_gm_prev_tready <='1';
        m_axis_gp_prev_tready <= '1';
        wait for 10 ns;
        s_axis_gp_tvalid <= '0';
        s_axis_gm_tvalid <= '0';
        s_axis_threshold_tvalid <= '0';

        -- Wait and check the label_out value (should be 0)
        wait for 30 ns;
        assert label_out = '0' report "Test 2 failed" severity error;

        -- End of tests
        wait;
    end process;
end architecture behavior;
