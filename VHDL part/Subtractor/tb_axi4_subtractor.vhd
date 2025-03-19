library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_axi4_subtractor is
    -- Testbench does not have ports
end entity tb_axi4_subtractor;

architecture Behavioral of tb_axi4_subtractor is

    -- Component declaration of the axi4_subtractor
    component axi4_subtractor is
        port (
            -- AXI4 Stream Input Interface
            s_axis_a_tdata  : in  std_logic_vector(13 downto 0); -- Operand A
            s_axis_a_tvalid : in  std_logic;                     -- Operand A valid
            s_axis_a_tready : out std_logic;                     -- Operand A ready

            s_axis_b_tdata  : in  std_logic_vector(13 downto 0); -- Operand B
            s_axis_b_tvalid : in  std_logic;                     -- Operand B valid
            s_axis_b_tready : out std_logic;                     -- Operand B ready

            -- AXI4 Stream Output Interface
            m_axis_result_tdata  : out std_logic_vector(13 downto 0); -- Result
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

        -- Instantiate the axi4_subtractor component
        uut: axi4_subtractor
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

            -- Test case 1: Subtract 6 and 2
            s_axis_a_tdata <= "00000000000110"; -- 6
            s_axis_b_tdata <= "00000000000010"; -- 2
            s_axis_a_tvalid <= '1';
            s_axis_b_tvalid <= '1';
            wait until (s_axis_a_tready = '1' and s_axis_b_tready = '1');
            wait for 20 ns;

            -- Test case 2: Subtract 6 and 6
            s_axis_a_tdata <= "00000000000110"; -- 6
            s_axis_b_tdata <= "00000000000110"; -- 6
            wait until (s_axis_a_tready = '1' and s_axis_b_tready = '1');
            wait for 20 ns;

            -- Test case 3: Subtract 7 and 4
            s_axis_a_tdata <= "00000000000111"; -- 7
            s_axis_b_tdata <= "00000000000100"; -- 4
            wait until (s_axis_a_tready = '1' and s_axis_b_tready = '1');
            wait for 20 ns;

            -- Finish simulation
            assert false report "Testbench completed" severity note;
            wait;
        end process;

end architecture Behavioral;
