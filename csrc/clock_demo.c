#include <stdio.h>
#include <stdint.h>
#include "xuartlite_l.h"
#include "xparameters.h"
#include "xil_exception.h"
#include "esr_clock_driver.h"


ESRclock MyClock;
esr_time_t time_taken;
esr_time_t time_to_set;
esr_time_t alarm_time;


void Alarm_InterruptHandler(void* data);

int check_uart_for_new_time(esr_time_t *time);


int main(void)
{
	unsigned int last_sampled_seconds = 99; // next sample _will_ be different

	xil_printf("Clock test application started...\r\n");

	ESRclock_Initialize(&MyClock, /* ADD BASE_ADDRESS */, /* ADD AXI BUS FREQUENCY */);
	xil_printf("Clock driver and system frequency initialized...\r\n");

	time_to_set.hours   = 23;
	time_to_set.minutes = 59;
	time_to_set.seconds = 50;

	ESRclock_SetTime(&MyClock, &time_to_set);
	xil_printf("Clock set to initial test value...\r\n\r\n");


	// Set Alarm
	alarm_time.hours   = 11;
	alarm_time.minutes = 22;
	alarm_time.seconds = 33;
	ESRclock_SetAlarm(&MyClock, &alarm_time);


	// Register our Interrupt Service Routine and enable interrupts
	Xil_ExceptionInit();
	Xil_ExceptionRegisterHandler( XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler) Alarm_InterruptHandler, NULL);
	Xil_ExceptionEnable();


	 // clock polling loop - terribly inefficient
	while(1)
	{
		ESRclock_GetTime(&MyClock, &time_taken);

		if (time_taken.seconds != last_sampled_seconds) // there is a new time to display
		{
			Xil_ExceptionDisable(); // protect printing from timeout interruption
			xil_printf("The time is  %02d:%02d:%02d\r\n", time_taken.hours, time_taken.minutes, time_taken.seconds);
			Xil_ExceptionEnable();
		}
		last_sampled_seconds = time_taken.seconds;

		// check for valid set time command
		int success = check_uart_for_new_time(&time_to_set);
		if (success == 1)
		{
			xil_printf("\r\nNew time has been set:\r\n");
			ESRclock_SetTime(&MyClock, &time_to_set);
		}
		if (success == 0)
			xil_printf("\r\n-- Illegal time set command --\r\n\r\n");

	}

	return 0;
}



void Alarm_InterruptHandler(void* data)
{
	xil_printf("\r\nWAKE UP!\r\n\r\n");
	ESRclock_ClearAlarmInterrupt(&MyClock); // clear and re-enable

	return;
}



int check_uart_for_new_time(esr_time_t *time)
{
	static int string_count = 0;
	static char command_string[9];
	char received;

	// check and read from UART
	if (XUartLite_IsReceiveEmpty(XPAR_AXI_UARTLITE_0_BASEADDR))
		return -1;

	received = XUartLite_RecvByte(XPAR_AXI_UARTLITE_0_BASEADDR);

	// dispose of EOL characters, set to first command character, return quietly 
	if ((received=='\r') || (received=='\n'))
	{
		string_count = 0;
		return -1;
	}

	// add received character to command string
	command_string[string_count++] = received;

	// return quietly if less than 9 command characters received
	if (string_count < 9)
		return -1;

	// syntax check
	string_count = 0;

	if ((command_string[0] < '0') || (command_string[0] > '2')) return 0;
	if ((command_string[1] < '0') || (command_string[1] > '3')) return 0;
	
	if  (command_string[2] != 'h') return 0;

	if ((command_string[3] < '0') || (command_string[3] > '5')) return 0;
	if ((command_string[4] < '0') || (command_string[4] > '9')) return 0;
	
	if  (command_string[5] != 'm') return 0;

	if ((command_string[6] < '0') || (command_string[6] > '5')) return 0;
	if ((command_string[7] < '0') || (command_string[7] > '9')) return 0;
	
	if  (command_string[8] != 's') return 0;

	// calculate times
	time->hours   = ((command_string[0] - 0x30) * 10 + (command_string[1] - 0x30));
	time->minutes = ((command_string[3] - 0x30) * 10 + (command_string[4] - 0x30));
	time->seconds = ((command_string[6] - 0x30) * 10 + (command_string[7] - 0x30));

	return 1;
}
