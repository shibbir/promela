// --------------------------------------------------------------------------------------
// Definition of all message types
// --------------------------------------------------------------------------------------

mtype= {
	speed0,		// set engine thrust to 0%, i.e. shut engine OFF
	speed50,	// set engine thrust to 50%, i.. go ito descend mode
	speed100,	// set engine thrust to 100%, i.e. go into climb mode
	height0,
	height50,
	start
};

chan EngControlChan= [0] of { mtype };		// control channel for engine controller
chan FmsSensorChan=  [0] of { mtype };		// sensor channel for flight mgmt system
chan FmsControlChan= [0] of { mtype };


// --------------------------------------------------------------------------------------
// Engine Control Process - sets the corresponding engine thrust levels received from FMS
// --------------------------------------------------------------------------------------
proctype Engine_Controller( chan ctrl) {
ENG_OFF:
	printf( "Engines OFF\n")
	-> ctrl?speed100
	-> goto ENG_FULL
ENG_FULL:
	printf( "Engines full thrust\n")
	-> ctrl?speed50
	-> goto ENG_HALF
ENG_HALF:
	printf( "Engines half thrust\n")
	-> ctrl?speed0
	-> goto ENG_OFF
}

// --------------------------------------------------------------------------------------
// Flight Management Process - controls the automatic inspection flight on the power pole
// --------------------------------------------------------------------------------------
proctype Flight_Management_System( chan ctrl, sensor, c2) {
FMS_GND:
	printf( "Copter On Ground\n")
	-> c2?start
	-> ctrl!speed100
	-> goto FMS_CLIMB
FMS_CLIMB:
	printf( "Copter Climbing\n")
	-> sensor?height50
	-> ctrl!speed50
	-> goto FMS_SINK
FMS_SINK:
	printf( "Copter Descending\n")
	-> sensor?height0
	-> ctrl!speed0
	-> goto FMS_GND
}

// --------------------------------------------------------------------------------------
// Flight Sensor Simulation - simulates measurement of flight level over ground in [m]
// --------------------------------------------------------------------------------------
proctype Flight_Sensor( chan sensor ) {
	sensor!height50 -> sensor!height0
}

// --------------------------------------------------------------------------------------
// Inspection chopter system
// --------------------------------------------------------------------------------------
init {
	atomic {
		run Flight_Sensor( FmsSensorChan);
		run Flight_Management_System( EngControlChan, FmsSensorChan, FmsControlChan);
		run Engine_Controller( EngControlChan);
	};

	FmsControlChan!start;
}
