# silos
a live granualr instrument for norns
![](assets/silos.png)
—————

Current commands:

  * Assign controls: ``controller id track control_number`` 
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
        * 6 = density
        * 7 = pitch
        * 8 = spread
        * *nb: this list can be viewed in app by pressing ESC*

  * set parameters: 
    * ``parameter track value`` 
      * ``size 2 150`` = set track 2 size to 150ms
    * ``rand track control_number`` 
      * ``rand 1 8`` = set track 1 spread to a random value
    * ``rrand low high track control_number`` 
      * ``rrand 10 150 4 5`` = set track 4 size to a random value between 10 and 150

  * store and recall parameter snapshots
    * ``snap id track``
      * ``snap 10 2`` = save a parameter snapshot for track 2 in slot 10
    * ``recall id track``
      * ``recall 5 3`` = recall track 3 parameter snapshot in slot 5
    * ``id`` = a number 1-16
    * ``snap`` and ``recall`` have the aliases ``s`` and ``r`` for convenience 
      * ``s 1 1`` and ``r 1 1`` are both valid

  * key bindings
    * shift + g = toggle gate
    * shift + r = toggle record
    * shift + n (1-4) = track select
    * shift + tab = randomize track params
    * esc = toggle info display
      * while info display is active, left and right arrow keys navigate info pages
        * page 1 = track parameter values
        * page 2 = encoder/arc assignments
        * page 3 = gridx/y assignments
        
