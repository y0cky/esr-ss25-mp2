#ifndef ESR_CLOCK_DRIVER_H
#define ESR_CLOCK_DRIVER_H

#include <stdint.h>


// driver instance
typedef struct
{
	volatile uint32_t *Register;
} ESRclock;

// Register indices (for array indexing)
#define CONTROL_REGISTER       0
#define SYS_FREQUENCY_REGISTER 1

#define SECONDS_REGISTER       2
#define MINUTES_REGISTER       3
#define HOURS_REGISTER         4

#define ALARM_SECONDS_REGISTER 5
#define ALARM_MINUTES_REGISTER 6
#define ALARM_HOURS_REGISTER   7

	// Control register bit masks
	#define bmSET_FREQUENCY       0x00000001
	#define bmSET_TIME            0x00000002
	#define bmTAKE_TIME           0x00000004
	#define bmSET_ALARM           0x00000008
	#define bmINTERRUPT_ENABLE    0x00000010

	// Alternative: Bit indices (for left-shift)
	#define ixSET_FREQUENCY       0
	#define ixSET_TIME            1
	#define ixTAKE_TIME           2
	#define ixSET_ALARM           3
	#define ixINTERRUPT_ENABLE    4


// time structure type
typedef struct
{
	uint32_t hours;
	uint32_t minutes;
	uint32_t seconds;
} esr_time_t;


// function prototypes
void ESRclock_Initialize(ESRclock *Instance, uint32_t BaseAddress, uint32_t clock_speed);

void ESRclock_SetTime(ESRclock *Instance, const esr_time_t *time);

void ESRclock_GetTime(ESRclock *Instance, esr_time_t *time);

void ESRclock_EnableAlarmInterrupt(ESRclock *Instance);
void ESRclock_DisableAlarmInterrupt(ESRclock *Instance);
void ESRclock_ClearAlarmInterrupt(ESRclock *Instance);

void ESRclock_SetAlarm(ESRclock *Instance, const esr_time_t *time);

#endif // ESR_CLOCK_DRIVER_H
