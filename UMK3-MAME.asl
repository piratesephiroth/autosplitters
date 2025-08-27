/***************************************************************************************\
* Ultimate Mortal Kombat 3 (MAME) AutoSplitter.                                         *
* By piratesephiroth.                                                                   *
\***************************************************************************************/

state("mame"){}
state("mame64"){}

startup
{
    refreshRate = 80; // to be on the safe side
    settings.Add("ladderSplit",false,"Split at tower");
    settings.Add("onlyShao",false,"Ignore everything, split only at Shao Kahn's defeat");
    settings.Add("diagCantReset",false,"Don't reset timer after leaving the Diagnostics Menu");

}

init
{
    Action ScanMemoryAndUpdateAddresses = () =>
    {
        string sig = "4D 3C 2B 1A 00 00 ?? 00";
        int offset = -0xc662;
        long gstate = 0xc12c;
        long p1State = 0xc134;
        long p2State = 0xc2aa;
        long p1rounds = 0xc152;
        long p2rounds = 0xc2c8;
        long ladderPos = 0xc45a;
        long ladderSel = 0xc459;
        
        if (game.MainWindowTitle.Contains("[umk3r10]"))
        {
            offset += 2;
            print("detected r1.0");
        }
        
        print("Scanning memory...");
        foreach (var page in game.MemoryPages(true))
        {
            var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);
            var ptr = scanner.Scan(new SigScanTarget(offset, sig));
            if (ptr != IntPtr.Zero)
            { 
                vars.membase = (long)ptr;
                print("membase found: " + game.ProcessName + ".exe+0x" + vars.membase.ToString("X"));
                vars.scanNeeded = false;
                break;
            }
        }
        
        vars.watchers = new MemoryWatcherList
        {
            new MemoryWatcher<byte>((IntPtr)(vars.membase + gstate)) { Name = "gameState" },
            new MemoryWatcher<byte>((IntPtr)(vars.membase + p1State)) { Name = "p1State" },
            new MemoryWatcher<byte>((IntPtr)(vars.membase + p2State)) { Name = "p2State" },
            new MemoryWatcher<byte>((IntPtr)(vars.membase + p1rounds)) { Name = "p1RoundsWon" },
            new MemoryWatcher<byte>((IntPtr)(vars.membase + p2rounds)) { Name = "p2RoundsWon" },
            new MemoryWatcher<byte>((IntPtr)(vars.membase + ladderPos)) { Name = "ladderPos" },
            new MemoryWatcher<byte>((IntPtr)(vars.membase + ladderSel)) { Name = "ladderSel" },
        };
     };
    
    vars.ScanMemoryAndUpdateAddresses = ScanMemoryAndUpdateAddresses;
    vars.scanNeeded = true;
    vars.matchWon = false;
    vars.ignoreReset = false;
    
    game.Refresh();
    if (!game.MainWindowTitle.Contains("Ultimate Mortal Kombat 3"))
    {
        throw new Exception("Couldn't find process!");
    }
}

update
{
    // rom was unloaded? find the membase again
    game.Refresh();
    if (!game.MainWindowTitle.Contains("Ultimate Mortal Kombat 3"))
    {
        vars.scanNeeded = true;
        return false;
    }
    
    if (vars.scanNeeded )
    {
        vars.ScanMemoryAndUpdateAddresses();
    }
    
    vars.watchers.UpdateAll(game);
    
    if (settings["diagCantReset"])
    {
        // disable timer reset after leaving Diag menu
        if (!vars.ignoreReset && vars.watchers["gameState"].Current == 8)
        {
            print("DIAG, RESET DISABLED");
            vars.ignoreReset = true;
        }
        
        // re-enable reset at Mode of Play screen
        if (vars.ignoreReset && vars.watchers["gameState"].Current == 20)
        {
            print("RESET RE-ENABLED");
            vars.ignoreReset = false;
        }
    }
}

start
{
    //print("game state: " + vars.watchers["gameState"].Current.ToString("X"));
    // start timer only at the "Select your Destiny" screen
    if (vars.watchers["gameState"].Current != 13)
    {
        return false;
    }
    // start timer after selecting the tower
    if (vars.watchers["ladderSel"].Current == 255)
    {
        print("START TIMER");
        return true;
    }
}

reset
{
    // reset timer if game is:
    // booting up;
    // in attract mode;
    // game over;
    
    if (vars.ignoreReset)
    {
        return false;
    }
    
    if (vars.watchers["gameState"].Current == 0 && vars.watchers["gameState"].Old != 0)
    {
        print("RESET TIMER");
        return true;
    }
}

split
{
    // tower
    if (settings["ladderSplit"] && !settings["onlyShao"])
    {
        if (vars.watchers["ladderPos"].Current > vars.watchers["ladderPos"].Old)
        {
            print("TOWER SPLIT");
            return true;
        }
    }
    
    // won the match
    if (vars.watchers["p1State"].Current == 1 || vars.watchers["p1State"].Old == 1)
    {
        if (vars.watchers["p1RoundsWon"].Current == 2 && (vars.watchers["p1RoundsWon"].Current != vars.watchers["p1RoundsWon"].Old)) {
            vars.matchWon = true;
            print ("P1 WON");
        }
    }
    if (vars.watchers["p2State"].Current == 1 || vars.watchers["p2State"].Old == 1)
    {
        if (vars.watchers["p2RoundsWon"].Current == 2 && (vars.watchers["p2RoundsWon"].Current != vars.watchers["p2RoundsWon"].Old))
        {
            vars.matchWon = true;
            print ("P2 WON");
        }
    }
    
    // find out if it was a regular character or Shao Khan
    if (vars.matchWon)
    {
        if (vars.watchers["gameState"].Current == 5 && !settings["onlyShao"] && !settings["ladderSplit"])
        {
            vars.matchWon = false;
            print("VICTORY SPLIT");
            return true;
        }
        if (vars.watchers["gameState"].Current== 11)
        {
            vars.matchWon = false;
            print("SHAO KAHN'S RULE IS OVER");
            return true;
        }
    }
}
