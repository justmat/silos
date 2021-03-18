# silos
a live granular instrument for norns
![](assets/silos.png)
—————

Current commands:

  * Assign engine controls: 
  * ``controller id track control_number`` 
    * ``enc 3 1 6`` = set encoder 3 to track 1 density control.
  * Valid controllers are
      * enc
      * arc
      * gridx
      * gridy
  * ``id`` = 1-3 for encoders, 1-4 for arc rings, and 1-2 for gridx/y
  * control numbers are
      * 1 = gain
      * 2 = position
      * 3 = speed
      * 4 = jitter
      * 5 = size
      * 6 = pitch
      * 7 = fdbk
      * 8 = density
      * 9 = dispersal
      * 10 = spread
      * 11 = fx send

  * Assign fx controls:
  * ``controller id fx fx_control_number``
    * ``arc 2 fx 6`` = set arc ring 2 to fx mod_depth
  * Valid controllers are
      * enc
      * arc
      * gridx
      * gridy
  * ``id`` = 1-3 for encoders, 1-4 for arc rings, and 1-2 for gridx/y
  * fx control numbers are
      * 1 = gain
      * 2 = time
      * 3 = size
      * 4 = dampening
      * 5 = diffusion
      * 6 = modulation depth
      * 7 = modulation frequency
      * 8 = lowx
      * 9 = midx
      * 10 = highx

    *nb: control lists can be viewed in app by pressing ESC and using LEFT or RIGHT arrows to navigate*

  * Control macros:
    * each of the norns encoders has an accompanying macro slot.
    * first add controls to the macro slot you want to use.
    * ``macro encoder_id track control_number multiplier``
        * ``macr 3 1 8 .5`` = add track 1 density to macro 3 at half strength
    * then enable the macro 
    * ``enc enc_id macro state``
        * ``enc 3 macro 1`` = enable macro control on encoder 3
    * disable the macro by setting its state to 0 
      * ``enc 3 macro 0``
    * clear the macro with
    * ``macro macro_id clear``
        * ``macro 3 clear`` = clear encoder 3 macro 


  * set parameters: 
    * ``control_name track value`` 
      * ``size 2 150`` = set track 2 size to 150ms
    * ``rand track control_number`` 
      * ``rand 1 8`` = set track 1 spread to a random value
    * ``rrand track control_number low high`` 
      * ``rrand 4 5 10 150`` = set track 4 size to a random value between 10 and 150

  * set multiple parameters:
    * ``gates state1 state2 state3 state4``
      * ``gate 1 1 0 1`` = set gates 1, 2, and 4 to on, gate 3 to off
    * ``records state1 state2 state3 state4``
      * ``records 0 0 0 1`` = set records 1, 2, and 3 off, record 4 on
    * ``gates`` and ``records`` have the aliases ``g`` and ``r`` for convenience
      * ``g 1 1 0 1`` and ``r 0 0 1 0`` are valid
  

  * store and recall parameter snapshots
    * ``snap id track``
      * ``snap 10 2`` = save a parameter snapshot for track 2 in slot 10
    * ``load id track``
      * ``recall 5 3`` = recall track 3 parameter snapshot in slot 5
    * ``id`` = a number 1-16
    * ``snap`` and ``load`` have the aliases ``s`` and ``l`` for convenience 
      * ``s 1 1`` and ``l 1 1`` are valid

  * save and load state
    * ``save_state``
    * ``load_state``

  * save and load pset
    * ``save_pset``
    * ``load_pset``

  *nb: state includes control assignments, macros, snapshots etc... pset is the parameter values*

  * key bindings
    * ctrl + g = toggle gate
    * ctrl + r = toggle record
    * ctrl + (1-4) = track select
    * esc = toggle info display
      * while info display is active, left and right arrow keys navigate info pages
        * page 1 = track parameters
        * page 2 = reverb parameters
        * page 2 = encoder/arc assignments
        * page 3 = gridx/y assignments
        
