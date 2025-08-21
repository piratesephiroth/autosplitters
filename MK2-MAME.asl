/***************************************************************************************\
* Mortal Kombat II (MAME) AutoSplitter.                                                 *
* By piratesephiroth.                                                                   *
\***************************************************************************************/

state("mame"){}
state("mame64"){}

startup
{
    refreshRate = 80; // to be on the safe side
    settings.Add("ladderSplit",false,"Split at tower");
    settings.Add("onlyShao",false,"Ignore everything, split only at Shao Kahn's defeat");
}

init
{
    Action ScanMemoryAndUpdateAddresses = () =>
    {
        long gstate = 0xc03a;
        long unknown = 0xb76a;
        long p1State = 0xc03e;
        long p2State = 0xc1b8;
        long p1rounds = 0xc062;
        long p2rounds = 0xc1dc;
        long ladderPos = 0xc366;
        
        string sig = "4D 3C 2B 1A 00 00 ?? 00";
        int offset = -0x16386; // for v3.x
        
        if (game.MainWindowTitle.Contains("[mk2r11]"))
        {
            offset = -0x1638c;
            ladderPos += 2;
        }
        else if (game.MainWindowTitle.Contains("[mk2r14]"))
        {
            offset = -0x16374;
        }
        else if (game.MainWindowTitle.Contains("[mk2r2]"))
        {
            offset = -0x16380;
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
            new MemoryWatcher<byte>((IntPtr)(vars.membase + unknown)) { Name = "unknown" },
            new MemoryWatcher<byte>((IntPtr)(vars.membase + p1State)) { Name = "p1State" },
            new MemoryWatcher<byte>((IntPtr)(vars.membase + p2State)) { Name = "p2State" },
            new MemoryWatcher<byte>((IntPtr)(vars.membase + p1rounds)) { Name = "p1RoundsWon" },
            new MemoryWatcher<byte>((IntPtr)(vars.membase + p2rounds)) { Name = "p2RoundsWon" },
            new MemoryWatcher<byte>((IntPtr)(vars.membase + ladderPos)) { Name = "ladderPos" },
        };
     };
    
    vars.ScanMemoryAndUpdateAddresses = ScanMemoryAndUpdateAddresses;
    vars.scanNeeded = true;
    vars.matchWon = false;
    
    game.Refresh();
    if (!game.MainWindowTitle.Contains("Mortal Kombat II"))
    {
        throw new Exception("Couldn't find process!");
    }
}

update
{
    // rom was unloaded? find the membase again
    game.Refresh();
    if (!game.MainWindowTitle.Contains("Mortal Kombat II"))
    {
        vars.scanNeeded = true;
        return false;
    }
    
    if (vars.scanNeeded )
    {
        vars.ScanMemoryAndUpdateAddresses();
    }
    
    vars.watchers.UpdateAll(game);
}

start
{
    // start timer only at the "Select your Fighter" screen
    if (vars.watchers["gameState"].Current != 4)
    {
        return false;
    }
    
    // start timer after selecting the character
    // when the portrait flashes
    if ( (vars.watchers["p1State"].Current == 3 ^ vars.watchers["p2State"].Current == 3) 
         && vars.watchers["unknown"].Old == 0x29
         && vars.watchers["unknown"].Current == 0x28)
    {
        print("START TIMER");
        return true;
    }
    
    return false;
}

reset
{
    // reset timer if game is:
    // booting up;
    // in attract mode;
    // game over;
    if ( vars.watchers["gameState"].Current <= 1
      || (vars.watchers["gameState"].Current == 11
      && (vars.watchers["p1RoundsWon"].Current + vars.watchers["p2RoundsWon"].Current == 0)) )
    {
        print("RESET TIMER");
        return true;
    }
    
    // reset timer when start is pressed after Shao Kahn's defeat
    // (Game Over -> Select Your Fighter)
    if (vars.watchers["gameState"].Current == 4 && vars.watchers["gameState"].Old == 11)
    {
        timer.CurrentPhase = TimerPhase.Running;
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
