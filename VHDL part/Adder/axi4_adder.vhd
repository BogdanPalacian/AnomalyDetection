library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity axi4_adder is
    port (
        -- AXI4 Stream Input Interface
        s_axis_a_tdata  : in  std_logic_vector(15 downto 0); -- Operand A
        s_axis_a_tvalid : in  std_logic;                     -- Operand A valid
        s_axis_a_tready : out std_logic;                     -- Operand A ready

        s_axis_b_tdata  : in  std_logic_vector(15 downto 0); -- Operand B
        s_axis_b_tvalid : in  std_logic;                     -- Operand B valid
        s_axis_b_tready : out std_logic;                     -- Operand B ready

        -- AXI4 Stream Output Interface
        m_axis_result_tdata  : out std_logic_vector(15 downto 0); -- Sum result
        m_axis_result_tvalid : out std_logic;                     -- Result valid
        m_axis_result_tready : in  std_logic;                     -- Result ready

        -- Clock and Reset
        clk   : in std_logic;
        reset : in std_logic
    );
end entity axi4_adder;



architecture Behavioral of axi4_adder is
    -- Define the states
    type state_type is (READ, WRITE);
    signal current_state, next_state : state_type;

    -- Internal signals
    signal operand_a      : std_logic_vector(15 downto 0) := (others => '0');
    signal operand_b      : std_logic_vector(15 downto 0) := (others => '0');
    signal sum_result      : std_logic_vector(15 downto 0) := (others => '0');
    signal result_valid    : std_logic := '0';

begin
    -- State transition process
    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= READ; -- Reset to the initial state
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    -- State logic process
    process(current_state, s_axis_a_tvalid, s_axis_b_tvalid, m_axis_result_tready)
    begin
        -- Default values for next state and outputs
        next_state   <= current_state;
        result_valid <= '0';

        case current_state is
            when READ =>
                if s_axis_a_tvalid = '1' and s_axis_b_tvalid = '1' then
                    operand_a <= s_axis_a_tdata;
                    operand_b <= s_axis_b_tdata;
                    next_state <= WRITE; -- Transition to WRITE state
                end if;

            when WRITE =>
                sum_result <= std_logic_vector(unsigned(operand_a) + unsigned(operand_b));
                result_valid <= '1';

                if m_axis_result_tready = '1' then
                    next_state <= READ; -- Transition back to READ state
                end if;
        end case;
    end process;

    -- Handshaking signals
    s_axis_a_tready <= '1' when current_state = READ else '0';
    s_axis_b_tready <= '1' when current_state = READ else '0';
    m_axis_result_tvalid <= result_valid;

    -- Output result
    m_axis_result_tdata <= sum_result;

end architecture Behavioral;
