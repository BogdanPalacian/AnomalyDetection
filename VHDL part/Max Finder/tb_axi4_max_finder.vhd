library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_axi4_max_finder is
    -- Testbench does not have ports
end entity tb_axi4_max_finder;

architecture Behavioral of tb_axi4_max_finder is

    -- Component declaration of the axi4_max_finder
    component axi4_max_finder is
        port (
            -- AXI4 Stream Input Interface
            s_axis_a_tdata  : in  std_logic_vector(13 downto 0); -- Input A
            s_axis_a_tvalid : in  std_logic;                     -- Input A valid
            s_axis_a_tready : out std_logic;                     -- Input A ready

            s_axis_b_tdata  : in  std_logic_vector(13 downto 0); -- Input B
            s_axis_b_tvalid : in  std_logic;                     -- Input B valid
            s_axis_b_tready : out std_logic;                     -- Input B ready

            -- AXI4 Stream Output Interface
            m_axis_result_tdata  : out std_logic_vector(13 downto 0); -- Maximum result
            m_axis_result_tvalid : out std_logic;                     -- Result valid
            m_axis_result_tready : in  std_logic;                     -- Result ready

            -- Clock and Reset
            clk   : in std_logic;
            reset : in std_logic
        );
    end component;

    -- Testbench signals
    signal s_axis_a_tdata   : std_logic_vector(13 downto 0) := (others => '0');
    signal s_axis_a_tvalid  : std_logic := '0';
    signal s_axis_a_tready  : std_logic;
    signal s_axis_b_tdata   : std_logic_vector(13 downto 0) := (others => '0');
    signal s_axis_b_tvalid  : std_logic := '0';
    signal s_axis_b_tready  : std_logic;
    signal m_axis_result_tdata : std_logic_vector(13 downto 0);
    signal m_axis_result_tvalid : std_logic;
    signal m_axis_result_tready : std_logic := '1'; -- Assume the result is always ready
    signal clk               : std_logic := '0';
    signal reset             : std_logic := '0';

    -- Clock generation
    constant clk_period : time := 10 ns;

    begin

        -- Instantiate the axi4_max_finder component
        uut: axi4_max_finder
            port map (
                s_axis_a_tdata   => s_axis_a_tdata,
                s_axis_a_tvalid  => s_axis_a_tvalid,
                s_axis_a_tready  => s_axis_a_tready,
                s_axis_b_tdata   => s_axis_b_tdata,
                s_axis_b_tvalid  => s_axis_b_tvalid,
                s_axis_b_tready  => s_axis_b_tready,
                m_axis_result_tdata => m_axis_result_tdata,
                m_axis_result_tvalid => m_axis_result_tvalid,
                m_axis_result_tready => m_axis_result_tready,
                clk               => clk,
                reset             => reset
            );

        -- Clock process
        clk_process: process
        begin
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end process;

        -- Stimulus process
        stim_proc: process
        begin
            -- Apply reset
            reset <= '1';
            wait for 20 ns;
            reset <= '0';
            wait for 10 ns;

            -- Test case 1: First operand is the maximum
            s_axis_a_tdata <= "00011111010000"; -- 1000
            s_axis_b_tdata <= "00001111100100"; -- 500
            s_axis_a_tvalid <= '1';
            s_axis_b_tvalid <= '1';
            wait until (s_axis_a_tready = '1' and s_axis_b_tready = '1');
            wait for 20 ns; -- Allow for processing

            -- Test case 2: Second operand is the maximum
            s_axis_a_tdata <= "00001111100100"; -- 500
            s_axis_b_tdata <= "00011111010001"; -- 1001
            wait until (s_axis_a_tready = '1' and s_axis_b_tready = '1');
            wait for 20 ns; -- Allow for processing

            -- Test case 3: Both operands are equal
            s_axis_a_tdata <= "00011111010010"; -- 1002
            s_axis_b_tdata <= "00011111010010"; -- 1002
            wait until (s_axis_a_tready = '1' and s_axis_b_tready = '1');
            wait for 20 ns; -- Allow for processing

            -- Finish simulation
            assert false report "Testbench completed" severity note;
            wait;
        end process;

end architecture Behavioral;
