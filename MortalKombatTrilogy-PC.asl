/***************************************************************************************\
* Mortal Kombat Trilogy (PC) (GOG & DOSBox) AutoSplitter.                               *
* By piratesephiroth.                                                                   *
\***************************************************************************************/


state("MKTRILW") {
}


state("DOSBox") {
}


startup {
    refreshRate = 80; // to be on the safe side
    
    settings.Add("endOfMatchSplit",false,"Split after end of match");
    settings.Add("onlyShao",false,"Detect only Shao Khan's defeat");
}


init {
    long membase = 0;
    
    long gstateOffset = 0;
    long unknownOffset = 0;
    long p1joinOffset = 0;
    long p2joinOffset = 0;
    long p1charOffset = 0;
    long p2charOffset = 0;
    long p1roundsOffset = 0;
    long p2roundsOffset = 0;
    long twSelectOffset = 0;
    long twPosOffset = 0;
    
    // short pause, waiting for the game to load
    Thread.Sleep(2000);
    
    if (game.ProcessName == "dosbox") {
        game.Suspend();
        foreach (var page in game.MemoryPages(true)) {
            var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);
            var ptr = scanner.Scan(new SigScanTarget(0, "60 10 00 F0 F4 00 70 00 F4 00 70 00 F4 00 70 00"));
            if (ptr != IntPtr.Zero) {
                membase = (long)ptr;
                print("membase: dosbox.exe+0x" + membase.ToString("X"));
                break;
            }
        }
        game.Resume();
        
        if (membase == 0) {
            throw new Exception("Couldn't find dosbox membase!");
        }
        
        gstateOffset = 0x3539b0;
        unknownOffset = 0x336A0C;
        p1joinOffset = 0x3539b8;
        p2joinOffset = 0x353B30;
        p1charOffset = 0x3539cc;
        p2charOffset = 0x353b44;
        p1roundsOffset = 0x3539D8;
        p2roundsOffset = 0x353B50;
        twSelectOffset = 0x353ce0;
        twPosOffset = 0x353Ce4;
    }
    
    
    if (game.ProcessName == "MKTRILW") {
        var module = modules.First();
        var baseAddr = module.BaseAddress;
        gstateOffset = (long)baseAddr + 0x15422c;
        unknownOffset = (long)baseAddr + 0x137cdc;
        p1joinOffset = (long)baseAddr + 0x154234;
        p2joinOffset = (long)baseAddr + 0x1543ac;
        p1charOffset = (long)baseAddr + 0x154248;
        p2charOffset = (long)baseAddr + 0x1543c0;
        p1roundsOffset = (long)baseAddr + 0x154254;
        p2roundsOffset = (long)baseAddr + 0x1543cc;
        twSelectOffset = (long)baseAddr + 0x15455c;
        twPosOffset = (long)baseAddr + 0x154560;
        
        print("membase: " + game.ProcessName + " + 0x" + baseAddr.ToString("X"));
    }

    
    vars.watchers = new MemoryWatcherList {
        new MemoryWatcher<byte>((IntPtr)(membase + gstateOffset)) { Name = "gameState" },
        new MemoryWatcher<byte>((IntPtr)(membase + unknownOffset)) { Name = "unknown" },
        new MemoryWatcher<byte>((IntPtr)(membase + p1joinOffset)) { Name = "p1Joined" },
        new MemoryWatcher<byte>((IntPtr)(membase + p2joinOffset)) { Name = "p2Joined" },
        new MemoryWatcher<byte>((IntPtr)(membase + p1charOffset)) { Name = "p1Char" },
        new MemoryWatcher<byte>((IntPtr)(membase + p2charOffset)) { Name = "p2Char" },
        new MemoryWatcher<byte>((IntPtr)(membase + p1roundsOffset)) { Name = "p1RoundsWon" },
        new MemoryWatcher<byte>((IntPtr)(membase + p2roundsOffset)) { Name = "p2RoundsWon" },
        new MemoryWatcher<byte>((IntPtr)(membase + twSelectOffset)) { Name = "towerSelect" },
        new MemoryWatcher<byte>((IntPtr)(membase + twPosOffset)) { Name = "towerPos" }
    };
    
    vars.matchWon = false;
}


update {
    vars.watchers.UpdateAll(game);
}


start {
    //  if 0 or 2 players, do nothing
    if ((vars.watchers["p1Joined"].Current ^ vars.watchers["p2Joined"].Current) != 1){
        return false;
    }
    
    if (vars.watchers["gameState"].Current == 4 &&
        vars.watchers["unknown"].Current == 22 &&
        vars.watchers["towerSelect"].Current != 0) {
            return true;
        }
}


split {
    // end of match
    if (settings["endOfMatchSplit"] && !settings["onlyShao"])    {
        if (vars.watchers["towerPos"].Current > vars.watchers["towerPos"].Old)        {
            print("TOWER SPLIT");
            return true;
        }
    }

    if (vars.watchers["p1Joined"].Current == 1){
        if (vars.watchers["p1RoundsWon"].Current == 2 && (vars.watchers["p1RoundsWon"].Current != vars.watchers["p1RoundsWon"].Old)){
            vars.matchWon = true;
        }
    }
    if (vars.watchers["p2Joined"].Current == 1){
        if (vars.watchers["p2RoundsWon"].Current == 2 && (vars.watchers["p2RoundsWon"].Current != vars.watchers["p2RoundsWon"].Old)){
            vars.matchWon = true;
        }
    }
    
    if (vars.matchWon) {
        if (vars.watchers["gameState"].Current == 5 && !settings["onlyShao"] && !settings["endOfMatchSplit"]) {
            print("WON THE MATCH!");
            vars.matchWon = false;
            return true;
        }
        if (vars.watchers["gameState"].Current== 11) {
            print("ALL DONE!");
            vars.matchWon = false;
            return true;
        }
    }
    
}


// reset timer if game is in attract mode
reset {
    if (vars.watchers["p1Joined"].Current + vars.watchers["p2Joined"].Current == 0){
        print("RESET");
        return true;
    }
}