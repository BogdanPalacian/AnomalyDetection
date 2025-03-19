library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TLM is
  Port ( 
    clk : IN STD_LOGIC;
    reset: IN std_logic;
    
    --AXI4 Stream Input Interface
    --x
    s_axis_x_tdata : IN std_logic_vector (15 downto 0);
    s_axis_x_tready : out std_logic ;
    s_axis_x_tvalid : in std_logic ;
    
    --x_prev
    s_axis_xPrev_tdata : IN std_logic_vector (15 downto 0);
    s_axis_xPrev_tready : out std_logic ;
    s_axis_xPrev_tvalid : in std_logic ;
    
    
    drift,threshold : in std_logic_vector ( 15 downto 0);
    
    --AXI4 Stream Output Interface
    m_axis_label_tdata : out std_logic  --label
    
  );
end TLM;

architecture Behavioral of TLM is

--Components
COMPONENT fifo_axi4
  PORT (
    s_axis_aresetn : IN STD_LOGIC;
    s_axis_aclk : IN STD_LOGIC;
    s_axis_tvalid : IN STD_LOGIC;
    s_axis_tready : OUT STD_LOGIC;
    s_axis_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    m_axis_tvalid : OUT STD_LOGIC;
    m_axis_tready : IN STD_LOGIC;
    m_axis_tdata : OUT STD_LOGIC_VECTOR(15 DOWNTO 0) 
  );
END COMPONENT;

COMPONENT broadcaster
  PORT (
    aclk : IN STD_LOGIC;
    aresetn : IN STD_LOGIC;
    s_axis_tvalid : IN STD_LOGIC;
    s_axis_tready : OUT STD_LOGIC;
    s_axis_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    m_axis_tvalid : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axis_tready : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axis_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) 
  );
END COMPONENT;

component axi4_adder is
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
end component axi4_adder;

component axi4_threshold_processor is
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
end component axi4_threshold_processor;

component axi4_subtractor is
    port (
        -- AXI4 Stream Input Interface
        s_axis_a_tdata  : in  std_logic_vector(15 downto 0); -- Operand A
        s_axis_a_tvalid : in  std_logic;                     -- Operand A valid
        s_axis_a_tready : out std_logic;                     -- Operand A ready

        s_axis_b_tdata  : in  std_logic_vector(15 downto 0); -- Operand B
        s_axis_b_tvalid : in  std_logic;                     -- Operand B valid
        s_axis_b_tready : out std_logic;                     -- Operand B ready

        -- AXI4 Stream Output Interface
        m_axis_result_tdata  : out std_logic_vector(15 downto 0); -- Result
        m_axis_result_tvalid : out std_logic;                     -- Result valid
        m_axis_result_tready : in  std_logic;                     -- Result ready

        -- Clock and Reset
        clk   : in std_logic;
        reset : in std_logic
    );
end component axi4_subtractor;

component axi4_max_finder is
    port (
        -- AXI4 Stream Input Interface
        s_axis_a_tdata  : in  std_logic_vector(15 downto 0); -- Input A
        s_axis_a_tvalid : in  std_logic;                     -- Input A valid
        s_axis_a_tready : out std_logic;                     -- Input A ready

        s_axis_b_tdata  : in  std_logic_vector(15 downto 0); -- Input B
        s_axis_b_tvalid : in  std_logic;                     -- Input B valid
        s_axis_b_tready : out std_logic;                     -- Input B ready

        -- AXI4 Stream Output Interface
        m_axis_result_tdata  : out std_logic_vector(15 downto 0); -- Maximum result
        m_axis_result_tvalid : out std_logic;                     -- Result valid
        m_axis_result_tready : in  std_logic;                     -- Result ready

        -- Clock and Reset
        clk   : in std_logic;
        reset : in std_logic
    );
end component axi4_max_finder;
signal aux,aux1,aux2,aux3,aux4: std_logic; --used for drift zero threshold
signal s_zero :std_logic_vector (15 downto 0) := (others => '0'); --used for max comparator
--Signals
--x fifo
signal x, xo : std_logic_vector (15 downto 0);
signal vx, rx : std_logic;
signal vxo, rxo: std_logic;

--xPrev fifo
signal xPrev, xPrevo : std_logic_vector (15 downto 0);
signal vxPrev, rxPrev : std_logic;
signal vxPrevo, rxPrevo: std_logic;

--subtractor 1
signal s : std_logic_vector (15 downto 0);
signal vs,rs : std_logic ;

--subtractor 1 fifo
signal so : std_logic_vector (15 downto 0);
signal vso,rso : std_logic ;

--broadcaster
signal bro : std_logic_vector (31 downto 0);
signal vbro,rbro : std_logic_vector (1 downto 0) ;

--adder 1(top)
signal a : std_logic_vector (15 downto 0);
signal va,ra : std_logic ;

--fifo adder 1(top)
signal ao : std_logic_vector (15 downto 0);
signal vao,rao : std_logic ;

--sub 1(bot)
signal b : std_logic_vector (15 downto 0);
signal vb,rb : std_logic ;

--fifo sub 1(bot)
signal bo : std_logic_vector (15 downto 0);
signal vbo,rbo : std_logic ;

--sub 2(top)
signal c : std_logic_vector (15 downto 0);
signal vc,rc : std_logic ;

--fifo sub 2(top)
signal co : std_logic_vector (15 downto 0);
signal vco,rco : std_logic ;

--sub 2(bot)
signal d : std_logic_vector (15 downto 0);
signal vd,rd : std_logic ;

--fifo sub 2(bot)
signal do : std_logic_vector (15 downto 0);
signal vdo,rdo : std_logic ;


-- max top
signal e : std_logic_vector (15 downto 0);
signal ve,re : std_logic;

-- fifo max top
signal eo : std_logic_vector (15 downto 0);
signal veo,reo : std_logic;

-- max bot
signal f : std_logic_vector (15 downto 0);
signal vf,rf : std_logic;

-- fifo max bot
signal fo : std_logic_vector (15 downto 0);
signal vfo,rfo : std_logic;

--threshold comp
signal g,h : std_logic_vector ( 15 downto 0);
signal vg,rg,vh,rh : std_logic;

-- fifo g top
signal go : std_logic_vector (15 downto 0);
signal vgo,rgo : std_logic;

-- fifo g bot
signal ho : std_logic_vector (15 downto 0);
signal vho,rho : std_logic;


signal nreset : std_logic;

signal output : std_logic ;

begin
nreset <= not reset;

--setup signals
--input
x <= s_axis_x_tdata;
vx <=    s_axis_x_tvalid ;
xPrev<=    s_axis_xPrev_tdata ;   
vxPrev <=    s_axis_xPrev_tvalid;
    
    --AXI4 Stream Output Interface
  --  m_axis_label_tdata : out std_logic ;
   -- m_axis_label_tready : out std_logic;
  --  m_axis_label_tvalid : in std_logic

--x fifo
x_fifo : fifo_axi4
  PORT MAP (
    s_axis_aresetn => nreset,
    s_axis_aclk => clk,
    s_axis_tvalid => vx,
    s_axis_tready => s_axis_x_tready,
    s_axis_tdata => x,
    m_axis_tvalid => vxo,
    m_axis_tready => rxo,
    m_axis_tdata => xo
  );

--xPrev fifo
xPrev_fifo : fifo_axi4
  PORT MAP (
    s_axis_aresetn => nreset,
    s_axis_aclk => clk,
    s_axis_tvalid => vxPrev,
    s_axis_tready => s_axis_xPrev_tready,
    s_axis_tdata => xPrev,
    m_axis_tvalid => vxPrevo,
    m_axis_tready => rxPrevo,
    m_axis_tdata => xPrevo
  );
  
 --subtractor 1
sub1 : axi4_subtractor
    PORT MAP(
    s_axis_a_tdata => xPrevo,
    s_axis_a_tvalid => vxPrevo,
    s_axis_a_tready => rxPrevo,
    s_axis_b_tdata => xo,
    s_axis_b_tvalid => vxo,
    s_axis_b_tready => rxo,
    m_axis_result_tdata => s,
    m_axis_result_tvalid => vs,
    m_axis_result_tready => rs,
    clk => clk,
    reset => reset
    );
    
 --subtractor 1 fifo
 sub1_fifo : fifo_axi4
  PORT MAP (
    s_axis_aresetn => nreset,
    s_axis_aclk => clk,
    s_axis_tvalid => vs,
    s_axis_tready => rs,
    s_axis_tdata => s,
    m_axis_tvalid => vso,
    m_axis_tready => rso,
    m_axis_tdata => so
  );
  
  
  --broadcaster
  broadcast : broadcaster
  PORT MAP (
    aclk => clk,
    aresetn => nreset,
    s_axis_tvalid => vso,
    s_axis_tready => rso,
    s_axis_tdata => so,
    m_axis_tvalid => vbro,
    m_axis_tready => rbro,
    m_axis_tdata => bro
  );
  
  
  --adder 1 (top part)
  add1 : axi4_adder
    PORT MAP(
    s_axis_a_tdata => bro(31 downto 16),
    s_axis_a_tvalid => vbro(1),
    s_axis_a_tready => rbro(1),
    s_axis_b_tdata => go, --change with last fifo from top done
    s_axis_b_tvalid => vgo,--change with last fifo from top
    s_axis_b_tready => rgo,--change with last fifo from top
    m_axis_result_tdata => a,
    m_axis_result_tvalid => va,
    m_axis_result_tready => ra,
    clk => clk,
    reset => reset
    ); 
  
  --fifo adder 1 (top part)
   add1_fifo : fifo_axi4
  PORT MAP (
    s_axis_aresetn => nreset,
    s_axis_aclk => clk,
    s_axis_tvalid => va,
    s_axis_tready => ra,
    s_axis_tdata => a,
    m_axis_tvalid => vao,
    m_axis_tready => rao,
    m_axis_tdata => ao
  );
  
  
  --sub 1 (bot part)
  subb1 : axi4_adder
    PORT MAP(
    s_axis_a_tdata => bro(15 downto 0),
    s_axis_a_tvalid => vbro(0),
    s_axis_a_tready => rbro(0),
    s_axis_b_tdata => ho, --change with last fifo from bot done
    s_axis_b_tvalid => vho,--change with last fifo from bot
    s_axis_b_tready => rho,--change with last fifo from bot
    m_axis_result_tdata => b,
    m_axis_result_tvalid => vb,
    m_axis_result_tready => rb,
    clk => clk,
    reset => reset
    ); 
  
  --fifo adder 1 (bot part)
   subb1_fifo : fifo_axi4
  PORT MAP (
    s_axis_aresetn => nreset,
    s_axis_aclk => clk,
    s_axis_tvalid => vb,
    s_axis_tready => rb,
    s_axis_tdata => b,
    m_axis_tvalid => vbo,
    m_axis_tready => rbo,
    m_axis_tdata => bo
  );
  
  
  
  
  --sub 2 (top part)
  subt2 : axi4_subtractor
    PORT MAP(
    s_axis_a_tdata => ao,
    s_axis_a_tvalid => vao,
    s_axis_a_tready => rao,
    s_axis_b_tdata => drift, 
    s_axis_b_tvalid => '1',
    s_axis_b_tready => aux,
    m_axis_result_tdata => c,
    m_axis_result_tvalid => vc,
    m_axis_result_tready => rc,
    clk => clk,
    reset => reset
    ); 
  
  --fifo sub 2 (top part)
   subt2_fifo : fifo_axi4
  PORT MAP (
    s_axis_aresetn => nreset,
    s_axis_aclk => clk,
    s_axis_tvalid => vc,
    s_axis_tready => rc,
    s_axis_tdata => c,
    m_axis_tvalid => vco,
    m_axis_tready => rco,
    m_axis_tdata => co
  );
  
  --sub 2 (bot part)
  subb2 : axi4_subtractor
    PORT MAP(
    s_axis_a_tdata => bo,
    s_axis_a_tvalid => vbo,
    s_axis_a_tready => rbo,
    s_axis_b_tdata => drift, 
    s_axis_b_tvalid => '1',
    s_axis_b_tready => aux1,
    m_axis_result_tdata => d,
    m_axis_result_tvalid => vd,
    m_axis_result_tready => rd,
    clk => clk,
    reset => reset
    ); 
  
  --fifo sub 2 (top part)
   subb2_fifo : fifo_axi4
  PORT MAP (
    s_axis_aresetn => nreset,
    s_axis_aclk => clk,
    s_axis_tvalid => vd,
    s_axis_tready => rd,
    s_axis_tdata => d,
    m_axis_tvalid => vdo,
    m_axis_tready => rdo,
    m_axis_tdata => do
  );
  
  --max (top part)
  max_top : axi4_max_finder
  PORT MAP(
    s_axis_a_tdata => co,
    s_axis_a_tvalid => vco,
    s_axis_a_tready => rco,
    s_axis_b_tdata => s_zero,
    s_axis_b_tvalid => '1',
    s_axis_b_tready => aux4,
    m_axis_result_tdata => e,
    m_axis_result_tvalid => ve,
    m_axis_result_tready => re,
    clk => clk,
    reset => reset
    );
    
  --fifo max (top part)
    maxt_fifo : fifo_axi4
  PORT MAP (
    s_axis_aresetn => nreset,
    s_axis_aclk => clk,
    s_axis_tvalid => ve,
    s_axis_tready => re,
    s_axis_tdata => e,
    m_axis_tvalid => veo,
    m_axis_tready => reo,
    m_axis_tdata => eo
  );
  
    --max (bot part)
  max_bot : axi4_max_finder
  PORT MAP(
    s_axis_a_tdata => do,
    s_axis_a_tvalid => vdo,
    s_axis_a_tready => rdo,
    s_axis_b_tdata => s_zero,
    s_axis_b_tvalid => '1',
    s_axis_b_tready => aux3,
    m_axis_result_tdata => f,
    m_axis_result_tvalid => vf,
    m_axis_result_tready => rf,
    clk => clk,
    reset => reset
    );
    
  --fifo max (bot part)
    maxb_fifo : fifo_axi4
  PORT MAP (
    s_axis_aresetn => nreset,
    s_axis_aclk => clk,
    s_axis_tvalid => vf,
    s_axis_tready => rf,
    s_axis_tdata => f,
    m_axis_tvalid => vfo,
    m_axis_tready => rfo,
    m_axis_tdata => fo
  );
  
  comp: axi4_threshold_processor
  PORT MAP (
    s_axis_threshold_tdata => threshold,
    s_axis_threshold_tvalid => '1',
    s_axis_threshold_tready => aux2,
    s_axis_gp_tdata => eo,
    s_axis_gp_tvalid => veo,
    s_axis_gp_tready => reo,
    s_axis_gm_tdata => fo,
    s_axis_gm_tvalid => vfo,
    s_axis_gm_tready => rfo,
    m_axis_gp_prev_tdata => g,
    m_axis_gp_prev_tvalid => vg,
    m_axis_gp_prev_tready => rg,
    m_axis_gm_prev_tdata => h,
    m_axis_gm_prev_tvalid => vh,
    m_axis_gm_prev_tready => rh,
    label_out => output,
    clk => clk,
    reset => reset
  );
  
  --fifo g (top part)
    gtop_fifo : fifo_axi4
  PORT MAP (
    s_axis_aresetn => nreset,
    s_axis_aclk => clk,
    s_axis_tvalid => vg,
    s_axis_tready => rg,
    s_axis_tdata => g,
    m_axis_tvalid => vgo,
    m_axis_tready => rgo,
    m_axis_tdata => go
  );
  
  --fifo g (bot part)
    gbot_fifo : fifo_axi4
  PORT MAP (
    s_axis_aresetn => nreset,
    s_axis_aclk => clk,
    s_axis_tvalid => vh,
    s_axis_tready => rh,
    s_axis_tdata => h,
    m_axis_tvalid => vho,
    m_axis_tready => rho,
    m_axis_tdata => ho
  );
  
  m_axis_label_tdata <= output;
  
  
  
end Behavioral;
