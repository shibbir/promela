// --------------------------------------------------------------------------------------
// Definition of waypoint type, flight plan array, fcs positions, and message types
// --------------------------------------------------------------------------------------
typedef way_point {
	int distance;	// x position
	int height	    // y position
};

way_point flight_plan[4];

int fcs_x_position = 0;
int fcs_y_position = 0;

mtype = { fcsCmdMsg, fcsAckMsg };

chan FcsCtrlChan = [0] of { mtype, int, int }; 	// control channel from FMS to FCS
chan FcsAcknChan = [0] of { mtype };		    // acknowledge chnaggel from FS to FMS

// --------------------------------------------------------------------------------------
// Flight Plan Loader process - simulates the loading of the flight plan from an XML file
// --------------------------------------------------------------------------------------
proctype Flight_Plan_Loader() {
	flight_plan[0].distance = 0;
	flight_plan[0].height = 1;

	flight_plan[1].distance = 1;
	flight_plan[1].height = 0;

	flight_plan[2].distance = -1;
	flight_plan[2].height = 0;

	flight_plan[3].distance = 0;
	flight_plan[3].height = -1;
}

// --------------------------------------------------------------------------------------
// Flight Management System process - simulates the management of the flight acc. to plan
// --------------------------------------------------------------------------------------
proctype Flight_Management_System(chan ctrl, ackn) {
	int i;

	printf("Flight plan loaded - mission starting\n");

	for(i: 0 .. 3) {
		ctrl!fcsCmdMsg(flight_plan[i].distance, flight_plan[i].height)
		-> ackn?fcsAckMsg;
	}

	printf("Flight plan processed - mission completed\n");
}

// --------------------------------------------------------------------------------------
// Flight Control System process - simulates the control of the quadro copter (position)
// --------------------------------------------------------------------------------------
proctype Flight_Control_System(chan ctrl, ackn) {

	int i, x, y;

	for(i: 0 .. 3) {
		ctrl?fcsCmdMsg(x, y)
		-> fcs_x_position = fcs_x_position + x
		-> fcs_y_position = fcs_y_position + y
		-> printf("FCS position = (%d,%d)\n", fcs_x_position, fcs_y_position)
		-> ackn!fcsAckMsg;
	}
}

// --------------------------------------------------------------------------------------
// Inspection chopter system
// --------------------------------------------------------------------------------------
init {
	atomic {
		run Flight_Plan_Loader();
		run Flight_Management_System(FcsCtrlChan, FcsAcknChan);
		run Flight_Control_System(FcsCtrlChan, FcsAcknChan)
	}
}

// --------------------------------------------------------------------------------------
// never claim - performs a safety check on the flight plan, e.g. detects obj collisions
// --------------------------------------------------------------------------------------
never {
    S0:
        if
        :: (fcs_x_position > 1) -> goto S1
        :: else -> goto S0
        fi;
    S1:
        skip
}
