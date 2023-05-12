// --------------------------------------------------------------------------------------
// Definition of waypoint type, flight plan array, fcs positions, and message types
// --------------------------------------------------------------------------------------
typedef way_point {
	int distance;	// x position
	int height	    // y position
};

#define FP_LEN 	4

way_point flight_plan[FP_LEN];		// the flight plan, i.e. set of waypoints

int fcs_x_position = 0;				// copter x position (absolute)
int fcs_y_position = 0;				// copter y position (absolute)

mtype = { 						    // message definitions for channels
	fcsCmdMsg,
	fcsAckMsg,
	FmsStartMsg,
	FmsCompleteMsg
};

chan FcsCtrlChan = [0] of { mtype, int, int };  // control channel from FMS to FCS
chan FcsAcknChan = [0] of { mtype };		    // acknowledge channel from FS to FMS
chan FmsCtrlChan = [0] of { mtype };		    // start channel to FMS


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
		for(i: 0 .. FP_LEN-1) {
			ctrl!fcsCmdMsg(flight_plan[i].distance, flight_plan[i].height)
			-> ackn?fcsAckMsg;
		} -> goto FMS_TERM
	FMS_TERM:
		printf("Inspection mission completed\n") -> c2!FmsCompleteMsg;
}

// --------------------------------------------------------------------------------------
// Flight Control System process - simulates the control of the quadro copter (position)
// --------------------------------------------------------------------------------------
proctype Flight_Control_System(chan ctrl, ackn) {
	int i, x, y;

	for( i: 0 .. FP_LEN-1) {
		ctrl?fcsCmdMsg(x, y)
		-> fcs_x_position= fcs_x_position + x
		-> fcs_y_position= fcs_y_position + y
		-> printf("FCS position = (%d,%d)\n", fcs_x_position, fcs_y_position)
		-> ackn!fcsAckMsg;
	}
}

// --------------------------------------------------------------------------------------
// Inspection chopter system
// --------------------------------------------------------------------------------------
init {
	// initialise flight plan
	flight_plan[0].distance = 0;	// 1st waypoint
	flight_plan[0].height = 1;

	flight_plan[1].distance = 1;	// 2nd waypoint
	flight_plan[1].height = 0;

	flight_plan[2].distance = -1;	// 3rd waypoint
	flight_plan[2].height = 0;

	flight_plan[3].distance = 0;	// 4th waypoint
	flight_plan[3].height = -1;

	// instantiate and run processes
	atomic {
		run Flight_Management_System(FcsCtrlChan, FcsAcknChan, FmsCtrlChan);
		run Flight_Control_System(FcsCtrlChan, FcsAcknChan)
	};

	FmsCtrlChan!FmsStartMsg -> FmsCtrlChan?FmsCompleteMsg
}
