spacehigh
=========

Space Invaders high score hack. Adds a high score list to the 1978 Space Invaders roms.

CONTAINS NO ORIGINAL GAME ROMS

USE AT YOUR OWN RISK, HAVEN'T BEEN THOROUGHLY TESTED

## Files
* spacehigh.asm - Source code
* patch.c       - Program to patch the file invaders.f with the contents of the intel hex file spacehigh.ihx.
                  Works only with a rom set of 4 2Kbyte roms.

The high score list has been successfully tested on real Midway L-shaped hardware strapped for 9316 EPROMs. The f chip was replaced with a ST M2732A (with the rom doubled as described in http://www.brentradio.com/images/SpaceInvaders/midway_8080_tech.txt).

The time and effort put into this was greatly reduced by using
the dissassembly comments by Chris Cantrell at
http://computerarcheology.com

More comments in spacehigh.asm
