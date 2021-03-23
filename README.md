# silos
a live granular instrument for norns
![](assets/silos.png)
—————

### silos granular engine contains 4 tracks, each with its own 8 second buffer. the parameters for controlling the engine are:

* gain = output level for the voice (0 - 1)
* position = position within the buffer (0 - 1)
* speed = playhead speed (-4 - 4) 
* jitter = position modulation (0 - 100)
* size = grain size (0 - 500ms)
* pitch = grain pitch (-4 - 4)
* fdbk = feedback (0 - 1)
* density = frequency of grains (0 - 512hz)
* dispersal = density modulation (0 - 1)
* spread = pan position modulation (0 - 100)
* fx send = send amount (0 - 1)

*nb: speed and pitch both work as rate controls. 2 is twice as fast/1 octave up*

### there is also an fx bus that features a lush modulated reverb followed by a bit crusher. the fx parameters are:

* gain = fx output level (0 - 1)
* time = t60/ the time it takes for the sound to decay by -60db (0 - 60)
* size = size of the space (.5 - 5)
* dampening = damping of high-frequencies as the reverb decays (0 - 1)
* diffusion = shape of early reflections (0 - 1)
* modulation depth = depth of delay-line modulation (0 - 1)
* modulation frequency = delay-line modulation freq (0 - 10)
* lowx = multiplier for the reverberation time within the low band (0 - 1)
* midx = multiplier for the reverberation time within the mid band (0 - 1)
* highx = multiplier for the reverberation time within the high band (0 - 1)
* bit depth = bit crushing (4 - 32)

----------

# quick start

-- TODO


-----------

Current commands:

  * Assign controls:
    * engine:
    * ``controller id track control_number`` 
      * ``enc 3 1 6`` = set encoder 3 to track 1 density control.
    * fx:
    * ``controller id "fx" fx_control_number``
      * ``arc 2 fx 6`` = set arc ring 2 to fx mod_depth
    * valid ``controller``s are:
      * enc
      * arc
      * gridx
      * gridy
    * valid ``id``s are:
      * enc = 1 - 3
      * arc = 1 - 4
      * gridx/gridy = 1 - 2
    * engine ``control_number``s are:
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
    * ``fx_control_number``s are:
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
      * 11 = bit depth

    *nb: control lists can be viewed in app by pressing ESC and using LEFT or RIGHT arrows to navigate, 
    or by holding norns key 1 and pressing key 3. while holding key 1 use encoder 3 to navigate*

  * Control macros:
    * each of the norns encoders has an accompanying macro slot.
    * first add controls to the macro slot you want to use
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

  *nb: multiplier can be negative numbers! this allows one param to increase while others decrease or vice versa*

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
    * ``save_state id``
    * ``load_state id``

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
        
