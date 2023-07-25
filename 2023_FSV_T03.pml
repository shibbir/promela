// --------------------------------------------------------------------------------------
// Definition of flight plan commands, flight plan, fcs positions, and message types
// --------------------------------------------------------------------------------------

// Flight Plan (FP) commands for Inspection Copter which are stored in the flight plan
#define CMD_UP		0			// Fly upwards, i.e. climb
#define CMD_DOWN	1			// Fly downwards, i.e. sink
#define CMD_FWD		2			// Fly forwrad
#define CMD_BWD		3			// Fly backward

#define FP_LEN		4
int flight_plan[ FP_LEN]		// the flight plan, i.e. list of commands


// Flight Control System (FCS) variables for Inspection Copter current position
int fcs_x_position = 0;			// copter x position (absolute)
int fcs_y_position = 0;			// copter y position (absolute)

// Message definitions for Inspection Copter
mtype = {
	fcsCmdMsg,				// new command sent from FMS to FCS
	fcsAckMsg, 				// acknowledge message from FCS to FMS
	FmsStartMsg,			// start message to begin inspection
	FmsCompleteMsg };		// completion message after inspection

// Channel declarations for Inspection Copter
chan FcsCtrlChan = [0] of { mtype, int };  	// control channel from FMS to FCS
chan FcsAcknChan = [0] of { mtype };		// acknowledge channel from FCS to FMS
chan FmsCtrlChan = [0] of { mtype };		// control channel to FMS


// --------------------------------------------------------------------------------------
// Flight Management System process - simulates the management of the flight acc. to plan
// --------------------------------------------------------------------------------------
proctype Flight_Management_System(chan ctrl, ackn, c2) {
	int i;

	FMS_START:
		c2?FmsStartMsg
		-> printf("Inspection mission starting\n")
		-> goto FMS_FLIGHT
	FMS_FLIGHT:
		for( i: 0 .. FP_LEN-1) {
			ctrl!fcsCmdMsg(flight_plan[i]) -> ackn?fcsAckMsg;
		} -> goto FMS_TERM
	FMS_TERM:
		printf("Inspection mission completed\n") -> c2!FmsCompleteMsg;
}

// --------------------------------------------------------------------------------------
// Flight Control System process - simulates the control of the quadro copter (position)
// --------------------------------------------------------------------------------------
proctype Flight_Control_System(chan ctrl, ackn) {

	int cmd;

	FCS_HOVER:
		ctrl?fcsCmdMsg(cmd) ->
	   	if
		:: (cmd == CMD_UP)   -> goto FCS_UP
		:: (cmd == CMD_DOWN) -> goto FCS_DOWN
		:: (cmd == CMD_FWD)  -> goto FCS_FWD
		:: (cmd == CMD_BWD)  -> goto FCS_BWD
		fi
	FCS_UP:
		fcs_y_position = fcs_y_position + 1
		-> printf("UP to (%d,%d)\n", fcs_x_position, fcs_y_position)
		-> ackn!fcsAckMsg
		-> goto FCS_HOVER
	FCS_DOWN:
		fcs_y_position = fcs_y_position - 1
		-> printf("DOWN to (%d,%d)\n", fcs_x_position, fcs_y_position)
		-> ackn!fcsAckMsg
		-> goto FCS_HOVER
	FCS_FWD:
		fcs_x_position = fcs_x_position + 1
		-> printf("FWD to (%d,%d)\n", fcs_x_position, fcs_y_position)
		-> ackn!fcsAckMsg
		-> goto FCS_HOVER
	FCS_BWD:
		fcs_x_position = fcs_x_position - 1
		-> printf("BWD to (%d,%d)\n", fcs_x_position, fcs_y_position)
		-> ackn!fcsAckMsg
		-> goto FCS_HOVER
}

// --------------------------------------------------------------------------------------
// Inspection chopter system
// --------------------------------------------------------------------------------------
init {
	// initialise flight plan
	flight_plan[0] = CMD_UP;	// 1st command
	flight_plan[1] = CMD_FWD;	// 2nd command
	flight_plan[2] = CMD_BWD;	// 3rd command
	flight_plan[3] = CMD_DOWN;	// 4th command

	// instantiate and run processes
	atomic {
		run Flight_Management_System(FcsCtrlChan, FcsAcknChan, FmsCtrlChan);
		run Flight_Control_System(FcsCtrlChan, FcsAcknChan)
	};

	FmsCtrlChan!FmsStartMsg -> FmsCtrlChan?FmsCompleteMsg
}
