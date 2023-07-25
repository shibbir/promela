bit doorIsOpen[3];

chan doorChan = [0] of { byte, bit };

proctype Door(byte level) {
    do
    /* receive and validate door open message from lift */
    :: doorChan?eval(level), 1;

        /* open door at level */
        doorIsOpen[level-1] = 1;
        assert(doorIsOpen[level-1] && !doorIsOpen[level%3] && !doorIsOpen[(level+1)%3]);

        /* close door at level */
        doorIsOpen[level-1] = 0;

        /* send confirmation message to lift */
        doorChan!level, 0;
    od
}

proctype Lift() {
    byte floor = 1;

    do
    :: (floor != 3) -> floor++
    :: (floor != 1) -> floor--
    :: doorChan!floor, 1;
        doorChan?eval(floor), 0
    od
}

init {
    atomic {
        run Door(1);
        run Door(2);
        run Door(3);
        run Lift();
    };
}
