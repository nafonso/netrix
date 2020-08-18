Netrix is a clone of Tetris, released as a Mac OS X Dashboard Widget, that I had originally done around 2007 as a way for me to learn multiplayer APIs that had just been added to Unity. Recently I got my hands on the Jai Programming Language and decided to redo that project as it wasn't that complicated, I already had the assets, and could focus purely on implementing it.

Currently it doesn't have multiplayer support nor leaderboards like the original, and not sure when / if that will happen given lack of time.

It is meant as a learning resource for those interested in Jai, and as such full source is provided, although you'll have to wait for Jai to be released in order to build it yourself.

Hope you find it useful,
Nuno Afonso
https://twitter.com/nafonsopt



## How To Build ##
    jai build.jai

Build parameters are passed after --, e.g.:

    jai build.jai -- run

Currently the build parameters available are:
    run - will run the game after building successfully
    codeonly - will recompile code, will _not_ copy assets / libraries

Arguments starting with - will be forwarded to the game, example:

    jai build.jai -- run -game

Currently the game parameters available are:
    -game: launches the game directly in single player
    -options: launches the game with the options menu open (for debugging purposes, just left it in)
    -fps: launches the game with the FPS counter visible



## Main Entry Point ##

The main entry point to the game is in src/main.jai
