library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity esr_clock_v1_0 is
	generic (
		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 5
	);
	port (
		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic;
		
		-- interrupt signal output - level-type, '1' signals timer is done, needs to be cleared by SW interrupt handler
		irq	: out std_logic
	);
end esr_clock_v1_0;

architecture arch_imp of esr_clock_v1_0 is


	----------------------------------------------------------------------
	-- DEBUG SIGNALS -- DO NOT CHANGE ------------------------------------
	----------------------------------------------------------------------
	type ERROR_TYPE is (seconds_UNDEFINED,minutes_UNDEFINED,hours_UNDEFINED,
	seconds_taken_UNDEFINED,minutes_taken_UNDEFINED,hours_taken_UNDEFINED,
	system_cycle_counter_UNDEFINED,current_system_speed_UNDEFINED,second_pulse_UNDEFINED,
	set_system_frequency_pulse_UNDEFINED,set_time_pulse_UNDEFINED,take_time_pulse_UNDEFINED,
	second_pulse_IS_HIGH_FOR_MORE_THAN_ONE_CYCLE,set_system_frequency_pulse_IS_HIGH_FOR_MORE_THAN_ONE_CYCLE,
	set_time_pulse_IS_HIGH_FOR_MORE_THAN_ONE_CYCLE,take_time_pulse_IS_HIGH_FOR_MORE_THAN_ONE_CYCLE,
	alarm_seconds_UNDEFINED,alarm_minutes_UNDEFINED,alarm_hours_UNDEFINED,
	alarm_seconds_WERE_NOT_SET_CORRECTLY,alarm_minutes_WERE_NOT_SET_CORRECTLY,alarm_hours_WERE_NOT_SET_CORRECTLY,
	alarm_seconds_ILLEGAL_VALUE,alarm_minutes_ILLEGAL_VALUE,alarm_hours_ILLEGAL_VALUE,
	set_alarm_pulse_UNDEFINED, set_alarm_pulse_IS_HIGH_FOR_MORE_THAN_ONE_CYCLE,
	second_pulse_COUNTING_PERIOD_WRONG,seconds_ILLEGAL_VALUE,minutes_ILLEGAL_VALUE,hours_ILLEGAL_VALUE,
	minutes_CHANGED_ASYNCHRONOUSLY_TO_SECONDS,hours_CHANGED_ASYNCHRONOUSLY_TO_SECONDS,
	seconds_WERE_NOT_SET_CORRECTLY,minutes_WERE_NOT_SET_CORRECTLY,hours_WERE_NOT_SET_CORRECTLY,
	seconds_WERE_NOT_TAKEN_CORRECTLY,minutes_WERE_NOT_TAKEN_CORRECTLY,hours_WERE_NOT_TAKEN_CORRECTLY,
	seconds_CHANGING_WITHOUT_SECOND_PULSE_OR_SET_TIME_PULSE,minutes_CHANGING_WITHOUT_SECOND_PULSE_OR_SET_TIME_PULSE,
	hours_CHANGING_WITHOUT_SECOND_PULSE_OR_SET_TIME_PULSE,seconds_NOT_COUNTING_AFTER_SECOND_PULSE,
	minutes_NOT_COUNTING_AFTER_SECONDS_OVERFLOW,hours_NOT_COUNTING_AFTER_MINUTES_OVERFLOW,
	taken_seconds_NOT_READ_BACK_OVER_AXI,taken_minutes_NOT_READ_BACK_OVER_AXI,taken_hours_NOT_READ_BACK_OVER_AXI,
	interrupt_NOT_ASSERTED_DESPITE_FINISHED_TIMER,interrupt_IS_ACTIVE_DESPITE_ie_BEING_ZERO,OK );
	signal ERROR_CODE: ERROR_TYPE := OK; signal DEBUG_ecomb: ERROR_TYPE := OK;
	signal DEBUG_dres,DEBUG_ddres,DEBUG_dsp,DEBUG_dsssp,DEBUG_dstp,DEBUG_dsap,DEBUG_dttp,DEBUG_cycle_changed,DEBUG_die:std_logic;
	signal DEBUG_dseconds,DEBUG_dminutes, DEBUG_dhours, DEBUG_tseconds, DEBUG_tminutes, DEBUG_thours, DEBUG_sardata : unsigned(5 downto 0);
	signal DEBUG_schange,DEBUG_mchange,DEBUG_hchange,DEBUG_allzeroes, DEBUG_allzero_transition : boolean;
	signal DEBUG_cycle_count, DEBUG_cycle_A, DEBUG_cycle_B, DEBUG_cycle_diff, DEBUG_cycle_set, DEBUG_alarm_count: integer;
	
	--------------------------------------------------------------------------
	-- END OF DEBUG SIGNALS --------------------------------------------------
	--------------------------------------------------------------------------


	signal clock : std_logic;
	signal reset : std_logic;

	
	---- WRITE SIGNALS ----
	signal aw_transfer : std_logic;
	signal aw_ready : std_logic;

	signal w_transfer : std_logic;
	signal w_ready : std_logic;
	
	signal b_transfer : std_logic;
	signal b_valid : std_logic;
	
	signal Write_RegAddress : std_logic_vector(2 downto 0);
	signal WriteEnable_Reg0 : std_logic;
	signal WriteEnable_Reg1 : std_logic;
	signal WriteEnable_Reg2 : std_logic;
	signal WriteEnable_Reg3 : std_logic;
	signal WriteEnable_Reg4 : std_logic;
	signal WriteEnable_Reg5 : std_logic;
	signal WriteEnable_Reg6 : std_logic;
	signal WriteEnable_Reg7 : std_logic;

	
	---- REGISTER SIGNALS ----
	signal Register0 : std_logic_vector(31 downto 0);
	signal Register1 : std_logic_vector(31 downto 0);
	signal Register2 : std_logic_vector(31 downto 0);
	signal Register3 : std_logic_vector(31 downto 0);
	signal Register4 : std_logic_vector(31 downto 0);
	signal Register5 : std_logic_vector(31 downto 0);
	signal Register6 : std_logic_vector(31 downto 0);
	signal Register7 : std_logic_vector(31 downto 0);


	---- READ SIGNALS ---- 
	signal ar_transfer : std_logic;
	signal ar_ready : std_logic;

	signal r_transfer : std_logic;
	signal r_valid : std_logic;

	signal Read_RegAddress : std_logic_vector(2 downto 0);

	signal buffer_rdata : std_logic; -- store read multiplexer output, 1 cycle after address store
	signal chosen_rdata : std_logic_vector(31 downto 0);
	
	---- CLOCK-SPECIFIC ----
	
	-- counting register for clock
	signal seconds : unsigned(5 downto 0);
	signal minutes : unsigned(5 downto 0);
	signal hours   : unsigned(5 downto 0);

	-- "snapshot" registers for clock - values to be read back instead of corresponding registers
	signal seconds_taken : std_logic_vector(31 downto 0);
	signal minutes_taken : std_logic_vector(31 downto 0);
	signal hours_taken   : std_logic_vector(31 downto 0);

	-- control bits
	signal SF, ST, TT, SA, IE : std_logic;

	-- pulses made from control bits
	signal set_frequency_pulse : std_logic;
	signal set_time_pulse : std_logic;
	signal take_time_pulse : std_logic;
	signal set_alarm_pulse : std_logic;

	-- extracting a one-per-second pulse from system frequency
	constant DEFAULT_SYSTEM_FREQUENCY : unsigned(31 downto 0) := to_unsigned(10,32); -- count seconds every 10 cycles
	signal system_cycle_counter : unsigned(31 downto 0);
	signal system_frequency : unsigned(31 downto 0); -- clock frequency
	signal second_pulse : std_logic;
	
	
	-- alarm (interrupt) time
	signal alarm_seconds : unsigned(5 downto 0);
	signal alarm_minutes : unsigned(5 downto 0);
	signal alarm_hours   : unsigned(5 downto 0);

	-- internal irq signal; only assign this, not irq output directly
    signal interrupt : std_logic;


    
	-- ADD ANY FURTHER SIGNALS/REGISTERS YOU NEED --
    
    	
	
	
	
begin
	
	clock <= s00_axi_aclk;
	reset <= not s00_axi_aresetn;


	---- WRITE ACCESS (control flow) ----
	s00_axi_awready <= aw_ready;
	s00_axi_wready  <= w_ready;
	s00_axi_bvalid  <= b_valid;
	s00_axi_bresp   <= "00"; -- always OK
	
	aw_transfer <= s00_axi_awvalid and aw_ready;
	w_transfer  <= s00_axi_wvalid  and w_ready;
	b_transfer  <= s00_axi_bready  and b_valid;

	aw_ready <= '1';  -- can always accept write address

	process(clock)
	begin
		if (rising_edge(clock)) then
			if (reset='1') then
				Write_RegAddress <= (others => '0');
			elsif (aw_transfer='1') then
				Write_RegAddress <= s00_axi_awaddr(4 downto 2); -- 8 registers; lower two bits are for byte-addressing and not used for 32-bit registers;
			end if;
		end if;
	end process;
	
	process(clock)
	begin
		if (rising_edge(clock)) then
			if (reset='1') then
				w_ready <= '0';
			elsif (aw_transfer='1') then -- can accept data one cycle after address transfer
				w_ready <= '1';
			elsif (w_transfer='1') then
				w_ready <= '0';
			end if;
		end if;
	end process;

	process(clock)
	begin
		if (rising_edge(clock)) then
			if (reset='1') then
				b_valid <= '0';
			elsif (w_transfer='1') then -- can acknowledge right after write transfer
				b_valid <= '1';
			elsif (b_transfer='1') then
				b_valid <= '0';
			end if;
		end if;
	end process;

	-- Write De-multiplexer
	WriteEnable_Reg0 <= '1' when (w_transfer='1' and Write_RegAddress="000") else '0';
	WriteEnable_Reg1 <= '1' when (w_transfer='1' and Write_RegAddress="001") else '0';
	WriteEnable_Reg2 <= '1' when (w_transfer='1' and Write_RegAddress="010") else '0';
	WriteEnable_Reg3 <= '1' when (w_transfer='1' and Write_RegAddress="011") else '0';
	WriteEnable_Reg4 <= '1' when (w_transfer='1' and Write_RegAddress="100") else '0';
	WriteEnable_Reg5 <= '1' when (w_transfer='1' and Write_RegAddress="101") else '0';
	WriteEnable_Reg6 <= '1' when (w_transfer='1' and Write_RegAddress="110") else '0';
	WriteEnable_Reg7 <= '1' when (w_transfer='1' and Write_RegAddress="111") else '0';



	---- REGISTERS (data flow) ----
	
	-- Register 0
	process(clock)
	begin
		if (rising_edge(clock)) then
			if (reset='1') then
				Register0 <= (others => '0');
			elsif (WriteEnable_Reg0='1') then
				Register0 <= s00_axi_wdata(31 downto 0);
			end if;
		end if;
	end process;
	
	-- Register 1
	process(clock)
	begin
		if (rising_edge(clock)) then
			if (reset='1') then
				Register1 <= (others => '0');
			elsif (WriteEnable_Reg1='1') then
				Register1 <= s00_axi_wdata(31 downto 0);
			end if;
		end if;
	end process;

	-- Register 2
	process(clock)
	begin
		if (rising_edge(clock)) then
			if (reset='1') then
				Register2 <= (others => '0');
			elsif (WriteEnable_Reg2='1') then
				Register2 <= s00_axi_wdata(31 downto 0);
			end if;
		end if;
	end process;

	-- Register 3
	process(clock)
	begin
		if (rising_edge(clock)) then
			if (reset='1') then
				Register3 <= (others => '0');
			elsif (WriteEnable_Reg3='1') then
				Register3 <= s00_axi_wdata(31 downto 0);
			end if;
		end if;
	end process;

	-- Register 4
	process(clock)
	begin
		if (rising_edge(clock)) then
			if (reset='1') then
				Register4 <= (others => '0');
			elsif (WriteEnable_Reg4='1') then
				Register4 <= s00_axi_wdata(31 downto 0);
			end if;
		end if;
	end process;
	
	-- Register 5
	process(clock)
	begin
		if (rising_edge(clock)) then
			if (reset='1') then
				Register5 <= (others => '0');
			elsif (WriteEnable_Reg5='1') then
				Register5 <= s00_axi_wdata(31 downto 0);
			end if;
		end if;
	end process;

	-- Register 6
	process(clock)
	begin
		if (rising_edge(clock)) then
			if (reset='1') then
				Register6 <= (others => '0');
			elsif (WriteEnable_Reg6='1') then
				Register6 <= s00_axi_wdata(31 downto 0);
			end if;
		end if;
	end process;

	-- Register 7
	process(clock)
	begin
		if (rising_edge(clock)) then
			if (reset='1') then
				Register7 <= (others => '0');
			elsif (WriteEnable_Reg7='1') then
				Register7 <= s00_axi_wdata(31 downto 0);
			end if;
		end if;
	end process;


	---- READ ACCESS (control flow) ----
	s00_axi_arready <= ar_ready;
	s00_axi_rvalid  <= r_valid;
	s00_axi_rresp   <= "00"; -- always OK
	
	ar_transfer <= s00_axi_arvalid and ar_ready;
	r_transfer  <= s00_axi_rready  and r_valid;
	
	ar_ready <= '1';  -- can always accept read address
	
	process(clock)
	begin
		if (rising_edge(clock)) then
			if (reset='1') then
				Read_RegAddress <= (others => '0');
			elsif (ar_transfer='1') then
				Read_RegAddress <= s00_axi_araddr(4 downto 2); -- 8 registers; lower two bits are for byte-addressing and not used for 32-bit registers;
			end if;
		end if;
	end process;
	
	process(clock)
	begin
		if (rising_edge(clock)) then
			if (reset='1') then
				r_valid <= '0';
				buffer_rdata <= '0';
			elsif (ar_transfer='1') then -- address stored after clock edge
				r_valid <= '0';
				buffer_rdata <= '1';
			elsif (buffer_rdata='1') then -- chosen register stored in buffer, offer on bus
				r_valid <= '1';
				buffer_rdata <= '0';
			elsif (r_transfer='1') then
				r_valid <= '0';
				buffer_rdata <= '0';
			end if;
		end if;
	end process;

		
	-- Read Multiplexer - picks which register value to return
	with Read_RegAddress select
		chosen_rdata <= 	Register0 when "000",
							Register1 when "001",
							Register2 when "010",
							Register3 when "011",
							Register4 when "100",
							Register5 when "101",
							Register6 when "110",
							Register7 when others; -- "111"
	
	  --              ^^^^ THIS IS PROBABLY THE ONLY  ^^^^ 
	  --              VHDL STATEMENT ABOVE YOU NEED TO CHANGE
	

	-- Store multiplexer output (addressed register) for AXI return - generates one buffer register
	process(clock)
	begin
		if (rising_edge(clock)) then
			if (reset='1') then
				s00_axi_rdata(31 downto 0) <= (others => '0');
			elsif (buffer_rdata='1') then
				s00_axi_rdata(31 downto 0) <= chosen_rdata;
			end if;
		end if;
	end process;						



	--------------------------
	-- ESR clock operation
	--------------------------
	
	-- ADD CLOCK-SPECIFIC IP HERE ---

	-- assign control bits from control register

		


	-- Make 1-cycle-long pulse signals from control bits

	

	
	-- Set a new system speed (clock frequency) and reset cycle counter with "SET_FREQUENCY" pulse
	-- Count cycles and make once-a-second pulse


	
	-- Write main h:m:s counting process
	-- include "SET_TIME" mechanism (with higher priority than counting)

	

	-- Take snapshots of counter values on "TAKE_TIME" pulse



	-- Set alarm h:m:s  on "SET_ALARM" pulse


	
	-- Generate/assign signal "interrupt"
	-- Set the interrupt on the next second_pulse after clock has reached alarm time
	-- NOT on the ongoing state of alarm time

    irq <= interrupt; -- KEEP THIS, do not change output signal 'irq' directly

	
	
	

	

----------------------------------------------------------------------------------
-- DEBUG BLOCK - DO NOT CHANGE BELOW ---------------------------------------------	
----------------------------------------------------------------------------------
-- synthesis translate_off
process(clock) begin if (falling_edge(clock)) then if (reset='1') then ERROR_CODE <= OK;
elsif (ERROR_CODE = OK) then ERROR_CODE <= DEBUG_ecomb; end if; end if; end process; DEBUG_ecomb <= OK
when DEBUG_ddres='1' else seconds_UNDEFINED when ((std_logic_vector(seconds)="UUUUUU") or (std_logic_vector(seconds)="XXXXXX")) else    
minutes_UNDEFINED when ((std_logic_vector(minutes)="UUUUUU") or (std_logic_vector(minutes)="XXXXXX")) else
hours_UNDEFINED when ((std_logic_vector(hours)="UUUUUU") or (std_logic_vector(hours)="XXXXXX")) else
seconds_taken_UNDEFINED when ((std_logic_vector(seconds_taken)="UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU") or (std_logic_vector(seconds_taken)="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")) else    
minutes_taken_UNDEFINED when ((std_logic_vector(minutes_taken)="UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU") or (std_logic_vector(minutes_taken)="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")) else
hours_taken_UNDEFINED when ((std_logic_vector(hours_taken)="UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU") or (std_logic_vector(hours_taken)="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")) else
system_cycle_counter_UNDEFINED when ((std_logic_vector(system_cycle_counter)="UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU") or (std_logic_vector(system_cycle_counter)="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")) else
current_system_speed_UNDEFINED when ((std_logic_vector(system_frequency)="UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU") or (std_logic_vector(system_frequency)="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")) else
set_system_frequency_pulse_UNDEFINED when ((set_frequency_pulse='U') or (set_frequency_pulse='X')) else
set_system_frequency_pulse_IS_HIGH_FOR_MORE_THAN_ONE_CYCLE when ((set_frequency_pulse='1') and (DEBUG_dsssp='1')) else
second_pulse_UNDEFINED when ((second_pulse='U') or (second_pulse='X')) else second_pulse_IS_HIGH_FOR_MORE_THAN_ONE_CYCLE when ((second_pulse='1') and (DEBUG_dsp='1')) else
set_time_pulse_UNDEFINED when ((set_time_pulse='U') or (set_time_pulse='X')) else set_time_pulse_IS_HIGH_FOR_MORE_THAN_ONE_CYCLE when ((set_time_pulse='1') and (DEBUG_dstp='1')) else
take_time_pulse_UNDEFINED when ((take_time_pulse='U') or (take_time_pulse='X')) else take_time_pulse_IS_HIGH_FOR_MORE_THAN_ONE_CYCLE when ((take_time_pulse='1') and (DEBUG_dttp='1')) else
second_pulse_COUNTING_PERIOD_WRONG when ((DEBUG_cycle_A/=0) and (DEBUG_cycle_B/=0) and (DEBUG_cycle_diff/=DEBUG_cycle_set)) else
seconds_ILLEGAL_VALUE when (seconds<0 or seconds>59) else minutes_ILLEGAL_VALUE when (minutes<0 or minutes>59) else
hours_ILLEGAL_VALUE when (hours<0 or hours>23) else minutes_CHANGED_ASYNCHRONOUSLY_TO_SECONDS when (DEBUG_mchange and not DEBUG_schange) else
hours_CHANGED_ASYNCHRONOUSLY_TO_SECONDS when (DEBUG_hchange and not DEBUG_schange) else
seconds_WERE_NOT_SET_CORRECTLY when ( (DEBUG_dstp='1') and (seconds/=unsigned(Register2(5 downto 0))) ) else
minutes_WERE_NOT_SET_CORRECTLY when ( (DEBUG_dstp='1') and (minutes/=unsigned(Register3(5 downto 0))) ) else
hours_WERE_NOT_SET_CORRECTLY when ( (DEBUG_dstp='1') and (hours/=unsigned(Register4(4 downto 0))) ) else
seconds_WERE_NOT_TAKEN_CORRECTLY when ( (DEBUG_dttp='1') and (unsigned(seconds_taken(5 downto 0))/=DEBUG_dseconds) ) else
minutes_WERE_NOT_TAKEN_CORRECTLY when ( (DEBUG_dttp='1') and (unsigned(minutes_taken(5 downto 0))/=DEBUG_dminutes) ) else
hours_WERE_NOT_TAKEN_CORRECTLY when ( (DEBUG_dttp='1') and (unsigned(hours_taken(5 downto 0))/=DEBUG_dhours) ) else
seconds_CHANGING_WITHOUT_SECOND_PULSE_OR_SET_TIME_PULSE when ( (DEBUG_schange) and (DEBUG_dsp='0') and (DEBUG_dstp='0') ) else
minutes_CHANGING_WITHOUT_SECOND_PULSE_OR_SET_TIME_PULSE when ( (DEBUG_mchange) and (DEBUG_dsp='0') and (DEBUG_dstp='0') ) else
hours_CHANGING_WITHOUT_SECOND_PULSE_OR_SET_TIME_PULSE when ( (DEBUG_hchange) and (DEBUG_dsp='0') and (DEBUG_dstp='0') ) else
seconds_NOT_COUNTING_AFTER_SECOND_PULSE when ( (DEBUG_dsp='1') and (not DEBUG_schange) and (not DEBUG_allzeroes) ) else
minutes_NOT_COUNTING_AFTER_SECONDS_OVERFLOW when ( (DEBUG_dsp='1') and (seconds=0) and (not DEBUG_mchange) ) else
hours_NOT_COUNTING_AFTER_MINUTES_OVERFLOW when ( (DEBUG_dsp='1') and (seconds=0) and (minutes=0) and (not DEBUG_hchange) ) else
alarm_seconds_UNDEFINED when ((std_logic_vector(alarm_seconds)="UUUUUU") or (std_logic_vector(alarm_seconds)="XXXXXX")) else
alarm_minutes_UNDEFINED when ((std_logic_vector(alarm_minutes)="UUUUUU") or (std_logic_vector(alarm_minutes)="XXXXXX")) else
alarm_hours_UNDEFINED when ((std_logic_vector(alarm_hours)="UUUUUU") or (std_logic_vector(alarm_hours)="XXXXXX")) else
alarm_seconds_WERE_NOT_SET_CORRECTLY when ( (DEBUG_dsap='1') and (alarm_seconds/=unsigned(Register5(5 downto 0))) ) else
alarm_minutes_WERE_NOT_SET_CORRECTLY when ( (DEBUG_dsap='1') and (alarm_minutes/=unsigned(Register6(5 downto 0))) ) else
alarm_hours_WERE_NOT_SET_CORRECTLY when ( (DEBUG_dsap='1') and (alarm_hours/=unsigned(Register7(5 downto 0))) ) else
alarm_seconds_ILLEGAL_VALUE when (alarm_seconds<0 or alarm_seconds>59) else alarm_minutes_ILLEGAL_VALUE when (alarm_minutes<0 or alarm_minutes>59) else
alarm_hours_ILLEGAL_VALUE when (alarm_hours<0 or alarm_hours>23) else set_alarm_pulse_UNDEFINED when ((set_alarm_pulse='U') or (set_alarm_pulse='X')) else
set_alarm_pulse_IS_HIGH_FOR_MORE_THAN_ONE_CYCLE when ((set_alarm_pulse='1') and (DEBUG_dsap='1')) else
taken_seconds_NOT_READ_BACK_OVER_AXI when ((r_transfer&Read_RegAddress)="1010" and (DEBUG_tseconds/=DEBUG_sardata)) else
taken_minutes_NOT_READ_BACK_OVER_AXI when ((r_transfer&Read_RegAddress)="1011" and (DEBUG_tminutes/=DEBUG_sardata)) else
taken_hours_NOT_READ_BACK_OVER_AXI when ((r_transfer&Read_RegAddress)="1100" and (DEBUG_thours/=DEBUG_sardata)) else
interrupt_NOT_ASSERTED_DESPITE_FINISHED_TIMER when (DEBUG_alarm_count>5 and interrupt='0') else
interrupt_IS_ACTIVE_DESPITE_ie_BEING_ZERO when (interrupt='1' and DEBUG_die ='0') else
OK; DEBUG_allzeroes <= (seconds=0) and (minutes=0) and (hours=0);
process(clock) begin if (rising_edge(clock)) then if (reset='1') then DEBUG_dres <= '1'; DEBUG_ddres <= '1'; DEBUG_dsp <= '0';
DEBUG_dsssp <= '0'; DEBUG_dstp <= '0'; DEBUG_dttp <= '0'; DEBUG_die <= '0'; DEBUG_dseconds <= seconds; DEBUG_dminutes <= minutes;
DEBUG_dhours <= hours; else DEBUG_dres <= reset; DEBUG_ddres <= DEBUG_dres; DEBUG_dsp <= second_pulse; DEBUG_dsssp <= set_frequency_pulse;
DEBUG_dsap <= set_alarm_pulse; DEBUG_dstp <= set_time_pulse; DEBUG_dttp <= take_time_pulse; DEBUG_dseconds <= seconds; DEBUG_dminutes <= minutes; DEBUG_dhours <= hours;
DEBUG_die <= Register0(4); end if; end if; end process; DEBUG_schange <= (seconds/=DEBUG_dseconds);
DEBUG_mchange <= (minutes/=DEBUG_dminutes); DEBUG_hchange <= (hours/=DEBUG_dhours);
process(clock) begin if (falling_edge(clock)) then if (reset='1') then DEBUG_cycle_changed <= '0';
DEBUG_cycle_set <= 0; elsif (set_frequency_pulse='1') then DEBUG_cycle_changed <= '1';
DEBUG_cycle_set <= to_integer(unsigned(Register1)); end if; if (reset='1' or set_frequency_pulse='1') then
DEBUG_cycle_count <= 0; DEBUG_cycle_A <= 0; DEBUG_cycle_B <= 0; elsif (DEBUG_cycle_changed='1') then DEBUG_cycle_count <= DEBUG_cycle_count + 1;
if (second_pulse='1') then DEBUG_cycle_A <= DEBUG_cycle_B; DEBUG_cycle_B <= DEBUG_cycle_count; end if; end if; end if; end process;
DEBUG_cycle_diff <= DEBUG_cycle_B - DEBUG_cycle_A;
process(clock) begin if (falling_edge(clock)) then if (reset='1' or Register0(4)='0') then DEBUG_alarm_count <= 0; DEBUG_allzero_transition <= false;
elsif (DEBUG_allzeroes and DEBUG_dseconds=1) then DEBUG_allzero_transition <= true; elsif (DEBUG_allzero_transition) then DEBUG_alarm_count <= DEBUG_alarm_count + 1;
end if;	end if; end process; process(clock) begin if (rising_edge(clock)) then if (take_time_pulse='1') then DEBUG_tseconds <= seconds;  DEBUG_tminutes <= minutes;           
DEBUG_thours <= hours; end if; if (buffer_rdata='1') then DEBUG_sardata <= unsigned(chosen_rdata(5 downto 0)); end if; end if; end process;
-- synthesis translate_on

end arch_imp;
