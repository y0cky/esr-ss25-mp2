library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AXI_slave_tb is
end AXI_slave_tb;

architecture testbench of AXI_slave_tb is

	-- STANDARD AXI GENERICS AND SIGNALS FOR ONE SLAVE	
	constant C_S00_AXI_DATA_WIDTH : integer := 32;
	constant C_S00_AXI_ADDR_WIDTH : integer := 5;
	
	signal s00_axi_aclk : std_logic;
	signal s00_axi_aresetn : std_logic;
	signal s00_axi_awaddr : std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
	signal s00_axi_awprot : std_logic_vector(2 downto 0) := "000";
	signal s00_axi_awvalid : std_logic;
	signal s00_axi_awready : std_logic;
	signal s00_axi_wdata : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
	signal s00_axi_wstrb : std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
	signal s00_axi_wvalid : std_logic;
	signal s00_axi_wready : std_logic;
	signal s00_axi_bresp : std_logic_vector(1 downto 0);
	signal s00_axi_bvalid : std_logic;
	signal s00_axi_bready : std_logic;
	signal s00_axi_araddr : std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
	signal s00_axi_arprot : std_logic_vector(2 downto 0) := "000";
	signal s00_axi_arvalid : std_logic;
	signal s00_axi_arready : std_logic;
	signal s00_axi_rdata : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
	signal s00_axi_rresp : std_logic_vector(1 downto 0);
	signal s00_axi_rvalid : std_logic;
	signal s00_axi_rready : std_logic;
	
	signal INTERRUPT : std_logic;	

	-- AXI MASTER STATE MACHINE TYPES, SIGNALS
	type t_axi_master_state is (msWait,msWriteRequest,msWriteAddressAccepted,msWriteBothAccepted,msReadRequest,msReadAddressAccepted,msDone);
	signal master_state: t_axi_master_state;
	signal ops_count: integer;
	signal wait_count: integer;
	
	-- AXI OPERATION TYPES, SIGNALS
	type t_read_or_write is (read,write,done);
	
	type t_axi_lite_access is record
		waitcycles : integer;
		address : std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		data    : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		rd_wr   : t_read_or_write;
	end record t_axi_lite_access;
	
	type t_axi_lite_access_array is array(natural range <>) of t_axi_lite_access;
	
	function axiop(waitcycles:integer;rw:t_read_or_write; addr:integer;
					data:std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0):=(others=>'0')
					) return t_axi_lite_access is
		variable buf: t_axi_lite_access;
	begin
		buf.waitcycles := waitcycles;
		buf.rd_wr := rw;
		buf.address := std_logic_vector(to_unsigned(addr,C_S00_AXI_ADDR_WIDTH));
		buf.data := data;
		return buf;
	end function axiop;
	
    constant IE_idx : integer := 4;
    constant SA_idx : integer := 3;
    constant TT_idx : integer := 2;
    constant ST_idx : integer := 1;
    constant SF_idx : integer := 0;
	
	function control_encode(IE:std_logic:='0'; SF:std_logic:='0'; ST:std_logic:='0'; SA:std_logic:='0'; TT:std_logic:='0'
	                       	) return std_logic_vector is
	   variable buf: std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    begin
        buf := (others => '0');
        buf(IE_idx) := IE;
		buf(SA_idx) := SA;
        buf(ST_idx) := ST;
        buf(TT_idx) := TT;
        buf(SF_idx) := SF;
	    return buf;
	end function control_encode;
	
    constant CTRL_ADDR : integer := 0*4;
    constant CLCK_ADDR : integer := 1*4;
    constant WR_S_ADDR : integer := 2*4;
    constant WR_M_ADDR : integer := 3*4;
    constant WR_H_ADDR : integer := 4*4;
	constant RD_S_ADDR : integer := 2*4;
    constant RD_M_ADDR : integer := 3*4;
    constant RD_H_ADDR : integer := 4*4;
    constant WR_SALRM_ADDR : integer := 5*4;
    constant WR_MALRM_ADDR : integer := 6*4;
    constant WR_HALRM_ADDR : integer := 7*4;
	
	
	-- AXI MASTER OPERATIONS; CHANGE AS REQUIRED
	constant SIM_CLOCK_SPEED: std_logic_vector(31 downto 0):=std_logic_vector(to_unsigned(5, 32)); -- "5 Hz"
	
	
	constant AXIOPS : t_axi_lite_access_array := (
					axiop(12, write , CLCK_ADDR, SIM_CLOCK_SPEED), -- after 10 cycles, set system frequency to "5 Hz"
					axiop(02, write , CTRL_ADDR, control_encode(IE=>'0',SF=>'1')), -- IE=0, SF=1 (irq disabled, set clock)
					axiop(02, write , CTRL_ADDR, control_encode(IE=>'0',SF=>'0')), -- IE=0, SF=0 (irq disabled)

					axiop(05, write , WR_H_ADDR, std_logic_vector(to_unsigned(23, 32))), --  write new 'hours' setting
					axiop(02, write , WR_M_ADDR, std_logic_vector(to_unsigned(59, 32))), --  write new 'minutes' setting
					axiop(02, write , WR_S_ADDR, std_logic_vector(to_unsigned(56, 32))), --  write new 'seconds' setting
					axiop(02, write , CTRL_ADDR, control_encode(IE=>'0',ST=>'1')), -- IE=0, ST=1 (irq disabled, set time)
					axiop(02, write , CTRL_ADDR, control_encode(IE=>'0',ST=>'0')), -- IE=0, ST=0 (irq disabled)

					axiop(25, write , CTRL_ADDR, control_encode(IE=>'0',TT=>'1')), -- IE=0, TT=1 (irq disabled, take time) 
					axiop(02, write , CTRL_ADDR, control_encode(IE=>'0',TT=>'0')), -- IE=0, TT=0 (irq disabled)
					axiop(02, read  , RD_H_ADDR),                                     -- read sampled hours				
					axiop(02, read  , RD_M_ADDR),                                     -- read sampled minutes				
					axiop(02, read  , RD_S_ADDR),                                     -- read sampled seconds				

					axiop(05, write , WR_HALRM_ADDR, std_logic_vector(to_unsigned(22, 32))), --  write new 'alarm hours' setting
					axiop(02, write , WR_MALRM_ADDR, std_logic_vector(to_unsigned(04, 32))), --  write new 'alarm minutes' setting
					axiop(02, write , WR_SALRM_ADDR, std_logic_vector(to_unsigned(01, 32))), --  write new 'alarm seconds' setting
					axiop(02, write , CTRL_ADDR, control_encode(IE=>'1',SA=>'1')), -- IE=1, SA=1 (irq enabled, set alarm)
					axiop(02, write , CTRL_ADDR, control_encode(IE=>'1',SA=>'0')), -- IE=1, SA=0 (irq enabled)

					axiop(05, write , WR_H_ADDR, std_logic_vector(to_unsigned(22, 32))), --  write new 'hours' setting
					axiop(02, write , WR_M_ADDR, std_logic_vector(to_unsigned(03, 32))), --  write new 'minutes' setting
					axiop(02, write , WR_S_ADDR, std_logic_vector(to_unsigned(57, 32))), --  write new 'seconds' setting
					axiop(02, write , CTRL_ADDR, control_encode(IE=>'1',ST=>'1')), -- IE=1, ST=1 (irq enabled, set time)
					axiop(02, write , CTRL_ADDR, control_encode(IE=>'1',ST=>'0')), -- IE=1, ST=0 (irq enabled)
					
					axiop(40, write , CTRL_ADDR, control_encode(IE=>'1',TT=>'1')), -- IE=1, TT=1 (irq enabled, take time) 
					axiop(02, write , CTRL_ADDR, control_encode(IE=>'1',TT=>'0')), -- IE=1, TT=0 (irq enabled)
					axiop(02, read  , RD_H_ADDR),                                     -- read sampled hours				
					axiop(02, read  , RD_M_ADDR),                                     -- read sampled minutes				
					axiop(02, read  , RD_S_ADDR),                                     -- read sampled seconds				

					axiop(02, write , CTRL_ADDR, control_encode(IE=>'0')), -- IE=0 (irq disabled/cleared)
					axiop(02, write , CTRL_ADDR, control_encode(IE=>'1')), -- IE=1 (irq enabled)
					
					axiop(00, done  , 00) -- END MARKER			

					);

	
begin
	
	-- ADD PERIPHERAL INSTANCE HERE
	dut: entity work.esr_clock_v1_0
		generic map(
			C_S00_AXI_DATA_WIDTH => C_S00_AXI_DATA_WIDTH,
			C_S00_AXI_ADDR_WIDTH => C_S00_AXI_ADDR_WIDTH
		)
		port map(
			s00_axi_aclk    => s00_axi_aclk,
			s00_axi_aresetn => s00_axi_aresetn,
			s00_axi_awaddr  => s00_axi_awaddr,
			s00_axi_awprot  => s00_axi_awprot,
			s00_axi_awvalid => s00_axi_awvalid,
			s00_axi_awready => s00_axi_awready,
			s00_axi_wdata   => s00_axi_wdata,
			s00_axi_wstrb   => s00_axi_wstrb,
			s00_axi_wvalid  => s00_axi_wvalid,
			s00_axi_wready  => s00_axi_wready,
			s00_axi_bresp   => s00_axi_bresp,
			s00_axi_bvalid  => s00_axi_bvalid,
			s00_axi_bready  => s00_axi_bready,
			s00_axi_araddr  => s00_axi_araddr,
			s00_axi_arprot  => s00_axi_arprot,
			s00_axi_arvalid => s00_axi_arvalid,
			s00_axi_arready => s00_axi_arready,
			s00_axi_rdata   => s00_axi_rdata,
			s00_axi_rresp   => s00_axi_rresp,
			s00_axi_rvalid  => s00_axi_rvalid,
			s00_axi_rready  => s00_axi_rready,
			
			irq => INTERRUPT
		);
	
	
	
	
	-- STANDARD BUS SIGNALS
	clkproc: process
	begin
		s00_axi_aclk <= '1';
		wait for 5 ns;
		s00_axi_aclk <= '0';
		wait for 5 ns;
	end process;
	
	rstproc: process
	begin
		s00_axi_aresetn <= '0';
		wait for 22 ns;
		s00_axi_aresetn <= '1';
		wait;
	end process;
	
	-- AXI MASTER OPERATIONS STATE MACHINE
	axiops_fsm:process(s00_axi_aclk)
	begin
		if rising_edge(s00_axi_aclk) then
			if (s00_axi_aresetn='0') then
				master_state <= msWait;
				ops_count    <= 0;
				wait_count    <= 0;
			else
				case master_state is 
					when msWait =>
						if (wait_count < AXIOPS(ops_count).waitcycles) then
							wait_count <= wait_count + 1;
						else
							wait_count <= 0;
							if (AXIOPS(ops_count).rd_wr=done) 		then master_state <= msDone;
							elsif (AXIOPS(ops_count).rd_wr=write) 	then master_state <= msWriteRequest;
																	else master_state <= msReadRequest; end if;
						end if;
					when msWriteRequest =>
						if (s00_axi_awready='1' and s00_axi_wready='1')	then master_state <= msWriteBothAccepted;
						elsif (s00_axi_awready='1')						then master_state <= msWriteAddressAccepted; end if;
					when msWriteAddressAccepted =>
						if (s00_axi_wready='1')	then master_state <= msWriteBothAccepted; end if;
					when msWriteBothAccepted =>
						if (s00_axi_bvalid='1')	then
							--if (ops_count = NUM_AXIOPS) then
							--	master_state <= msDone;
							--else
								ops_count <= ops_count + 1;
								master_state <= msWait;
							--end if;
						end if;
					when msReadRequest =>
						if (s00_axi_arready='1') then master_state <= msReadAddressAccepted; end if;
					when msReadAddressAccepted =>
						if (s00_axi_rvalid='1')	then
							--if (ops_count = NUM_AXIOPS) then
							--	master_state <= msDone;
							--else
								ops_count <= ops_count + 1;
								master_state <= msWait;
							--end if; 
						end if;
					when msDone =>
						null;
				end case;
			end if;
		end if;
	end process;
	
	-- STATE DEPENDENT BUS SIGNALS
	s00_axi_awaddr  <= AXIOPS(ops_count).address when (master_state=msWriteRequest) else ((others=>'X'));
	s00_axi_awvalid <= '1'                       when (master_state=msWriteRequest) else '0';
	s00_axi_wdata   <= AXIOPS(ops_count).data    when (master_state=msWriteRequest or master_state=msWriteAddressAccepted) else (others => 'X');
	s00_axi_wvalid  <= '1'                       when (master_state=msWriteRequest or master_state=msWriteAddressAccepted) else '0';
	s00_axi_wstrb   <= (others => '1')           when (master_state=msWriteRequest or master_state=msWriteAddressAccepted) else (others => '0');
	s00_axi_bready  <= '1'                       when (master_state=msWriteBothAccepted) else '0';
	
	s00_axi_araddr  <= AXIOPS(ops_count).address when (master_state=msReadRequest) else ((others=>'X'));
	s00_axi_arvalid <= '1'                       when (master_state=msReadRequest) else '0';
	s00_axi_rready  <= '1'                       when (master_state=msReadAddressAccepted) else '0';


end testbench;