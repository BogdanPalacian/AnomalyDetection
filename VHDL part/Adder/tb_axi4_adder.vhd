library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_axi4_adder is
    -- Testbench does not have ports
end entity tb_axi4_adder;

architecture Behavioral of tb_axi4_adder is

    -- Component declaration of the axi4_adder
    component axi4_adder is
        port (
            -- AXI4 Stream Input Interface
            s_axis_a_tdata  : in  std_logic_vector(13 downto 0); -- Operand A
            s_axis_a_tvalid : in  std_logic;                     -- Operand A valid
            s_axis_a_tready : out std_logic;                     -- Operand A ready

            s_axis_b_tdata  : in  std_logic_vector(13 downto 0); -- Operand B
            s_axis_b_tvalid : in  std_logic;                     -- Operand B valid
            s_axis_b_tready : out std_logic;                     -- Operand B ready

            -- AXI4 Stream Output Interface
            m_axis_result_tdata  : out std_logic_vector(13 downto 0); -- Sum result
            m_axis_result_tvalid : out std_logic;                     -- Result valid
            m_axis_result_tready : in  std_logic;                     -- Result ready

            -- Clock and Reset
            clk   : in std_logic;
            reset : in std_logic
        );
    end component;

    -- Signals for connecting to the axi4_adder component
    signal s_axis_a_tdata  : std_logic_vector(13 downto 0) := (others => '0');
    signal s_axis_a_tvalid : std_logic := '0';
    signal s_axis_a_tready : std_logic := '0';

    signal s_axis_b_tdata  : std_logic_vector(13 downto 0) := (others => '0');
    signal s_axis_b_tvalid : std_logic := '0';
    signal s_axis_b_tready : std_logic := '0';

    signal m_axis_result_tdata  : std_logic_vector(13 downto 0);
    signal m_axis_result_tvalid : std_logic;
    signal m_axis_result_tready : std_logic := '1';

    signal clk_in   : std_logic := '0';
    signal reset : std_logic := '0';

 
    
    begin

    -- Instantiate the axi4_adder component
    uut: axi4_adder port map (
            s_axis_a_tdata  => s_axis_a_tdata,
            s_axis_a_tvalid => s_axis_a_tvalid,
            s_axis_a_tready => s_axis_a_tready,

            s_axis_b_tdata  => s_axis_b_tdata,
            s_axis_b_tvalid => s_axis_b_tvalid,
            s_axis_b_tready => s_axis_b_tready,

            m_axis_result_tdata  => m_axis_result_tdata,
            m_axis_result_tvalid => m_axis_result_tvalid,
            m_axis_result_tready => m_axis_result_tready,

            clk   => clk_in,
            reset => reset
        );
    
       -- Clock process for the testbench
    process 
    begin
        -- Clock generation: Toggle every 10 ns (50 MHz)
        clk_in <= not clk_in;
        wait for 10 ns;
    end process;


    -- Stimulus process
    process
    begin
        -- Apply reset
        reset <= '1';
        wait for 20 ns;
        reset <= '0';

        -- First operation: A = 10, B = 20
        s_axis_a_tdata <= "00000000001010";  -- Operand A = 10
        s_axis_b_tdata <= "00000000010100";  -- Operand B = 20
        s_axis_a_tvalid <= '1';
        s_axis_b_tvalid <= '1';
        wait for 20 ns;

        -- Second operation: A = 15, B = 5
        s_axis_a_tdata <= "00000000011111";  -- Operand A = 15
        s_axis_b_tdata <= "00000000000101";  -- Operand B = 5
        wait for 20 ns;

        -- Third operation: A = 50, B = 25
        s_axis_a_tdata <= "00000000110010";  -- Operand A = 50
        s_axis_b_tdata <= "00000000011001";  -- Operand B = 25
        wait for 20 ns;

        -- Finish the testbench
        assert m_axis_result_tvalid = '1' report "Result not valid" severity error;
        assert m_axis_result_tdata = "00000000011110" report "Sum not correct" severity error;  -- Expected result for first case is 30

        wait;
    end process;

end architecture Behavioral;
