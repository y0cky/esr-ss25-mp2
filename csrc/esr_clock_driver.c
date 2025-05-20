#include "esr_clock_driver.h"


void ESRclock_Initialize(ESRclock *Instance, uint32_t BaseAddress, uint32_t system_clock_frequency)
{
	// Set pointer to IP registers
	Instance->Register = (uint32_t*)BaseAddress;  // access as: Register[NUMBER/#DEFTOKEN]

	/* ADD OPERATIONS TO SET SYSTEM CLOCK FREQUENCY */
	Instance->Register[
}


void ESRclock_SetTime(ESRclock *Instance, const esr_time_t *time)
{
	/* ADD OPERATIONS TO SET TIME */

}


void ESRclock_GetTime(ESRclock *Instance, esr_time_t *time)
{
	/* ADD OPERATIONS TO GET TIME */

}


void ESRclock_EnableAlarmInterrupt(ESRclock *Instance)
{
	/* ADD OPERATION TO ENABLE ALARM INTERRUPT */

}


void ESRclock_DisableAlarmInterrupt(ESRclock *Instance)
{
	/* ADD OPERATION TO DISABLE ALARM INTERRUPT */

}


void ESRclock_ClearAlarmInterrupt(ESRclock *Instance)
{
	/* ADD OPERATIONS TO CLEAR, THEN RE-ENABLE ALARM INTERRUPT */

}


void ESRclock_SetAlarm(ESRclock *Instance, const esr_time_t *time)
{
	/* ADD OPERATIONS TO SET ALARM TIME */




	ESRclock_EnableAlarmInterrupt(Instance);
}
