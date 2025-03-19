library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity testbench_tlm is
end testbench_tlm;

architecture Tb of testbench_tlm is

    -- Component Declaration
    component TLM is
        Port (
            clk                : in STD_LOGIC;
            reset              : in STD_LOGIC;
            -- AXI4 Stream Input Interface
            s_axis_x_tdata     : in STD_LOGIC_VECTOR(15 downto 0);
            s_axis_x_tready    : out STD_LOGIC;
            s_axis_x_tvalid    : in STD_LOGIC;
            s_axis_xPrev_tdata : in STD_LOGIC_VECTOR(15 downto 0);
            s_axis_xPrev_tready: out STD_LOGIC;
            s_axis_xPrev_tvalid: in STD_LOGIC;
            drift              : in STD_LOGIC_VECTOR(15 downto 0);
            threshold          : in STD_LOGIC_VECTOR(15 downto 0);
            -- AXI4 Stream Output Interface
            m_axis_label_tdata : out STD_LOGIC -- label
        );
    end component;

    -- Clock period constant
    constant T : time := 20 ns;

    -- Signals
    signal aux                : STD_LOGIC := '1';
    signal clk                : STD_LOGIC := '0';
    signal reset              : STD_LOGIC := '0';
    signal s_axis_x_tdata     : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal s_axis_x_tready    : STD_LOGIC := '1';
    signal s_axis_x_tvalid    : STD_LOGIC := '0';
    signal s_axis_xPrev_tdata : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal s_axis_xPrev_tready: STD_LOGIC := '1';
    signal s_axis_xPrev_tvalid: STD_LOGIC := '0';
    signal drift              : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal threshold          : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal m_axis_label_tdata1 : STD_LOGIC := '0';

    signal wr_count : integer := 0;
    signal rd_count : integer := 2;
    signal end_of_reading     : STD_LOGIC := '0';

begin

    -- Clock generation
    clk <= not clk after T / 2;

    -- Reset signal
    reset <= '1', '0' after T;
    
    

    -- Design under test (DUT)
    dut : TLM port map (
        clk                => clk,
        reset              => reset,
        s_axis_x_tdata     => s_axis_x_tdata,
        s_axis_x_tready    => s_axis_x_tready,
        s_axis_x_tvalid    => s_axis_x_tvalid,
        s_axis_xPrev_tdata => s_axis_xPrev_tdata,
        s_axis_xPrev_tready=> s_axis_xPrev_tready,
        s_axis_xPrev_tvalid=> s_axis_xPrev_tvalid,
        drift              => drift,
        threshold          => threshold,
        m_axis_label_tdata => m_axis_label_tdata1
    );

    -- Read stimulus data from input file
    process (clk)
        file stimulus_file : text open read_mode is "LM35DZ_binary.csv";
        variable in_line   : line;
        variable x_data, x_prev_data, drift_data, threshold_data : std_logic_vector(15 downto 0);
    begin
        if rising_edge(clk) then
            if aux = '1' then
                readline(stimulus_file, in_line);
                read(in_line, x_data);
                readline(stimulus_file, in_line);
                read(in_line, x_prev_data);
                
                aux <= '0';
            else
            if reset = '0' and end_of_reading = '0' then
                if not endfile(stimulus_file) then
                    if s_axis_x_tready = '1' and s_axis_xPrev_tready = '1' then
                        s_axis_x_tdata <= x_data;
                        s_axis_x_tvalid <= '1';
                        s_axis_xPrev_tdata <= x_prev_data;
                        s_axis_xPrev_tvalid <= '1';
                        drift <= "0000000000110010";
                        threshold <= "0000000011001000";

                        
                        
                        x_prev_data := x_data;
                        readline(stimulus_file, in_line);
                        read(in_line, x_data);
                        
                        rd_count <= rd_count + 1;
                    else
                        s_axis_x_tvalid <= '0';
                        s_axis_xPrev_tvalid <= '0';
                    end if;
                else
                    file_close(stimulus_file);
                    end_of_reading <= '1';
                end if;
            end if;
            end if;
            
        end if;
    end process;

    -- Write results to output file
    process
        file output_file : text open write_mode is "C:\Users\Bogdan\Desktop\Facultate\SCS\HW6\OUTPUT/output_results1.csv";
        variable out_line : line;
    begin
        wait until rising_edge(clk);

       

        if wr_count < rd_count then
            if s_axis_x_tready = '1' and s_axis_xPrev_tready = '1' then
                write(out_line, m_axis_label_tdata1);
                writeline(output_file, out_line);
                wr_count <= wr_count + 1;
            end if;
        else
            file_close(output_file);
            report "Testbench execution finished.";
            wait;
        end if;
    end process;

end Tb;
