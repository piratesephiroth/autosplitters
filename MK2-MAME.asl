/***************************************************************************************\
* Mortal Kombat II (MAME) AutoSplitter.                                                 *
* Supported versions: Arcade  and SNES (Bizhawk)                                                                   *
\***************************************************************************************/

state("mame"){}
state("mame64"){}
state("emuhawk"){}

startup
{
    refreshRate = 80; // to be on the safe side
    settings.Add("onlyShao",false,"Ignore everything, split only at Shao Kahn's defeat");
}

init
{
    Action ScanMemoryArcade = () =>
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
        else if (game.MainWindowTitle.Contains("[mk2r2"))
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
     
    
    Action ScanMemorySNES = () =>
    {
        List<MemoryBasicInformation> memoryPages = new List<MemoryBasicInformation>();
        memoryPages.AddRange(game.MemoryPages(true).Where(p => p.Type == MemPageType.MEM_MAPPED && p.State == MemPageState.MEM_COMMIT && (int)p.RegionSize < 0x50000));

        string sig = "00000100020003000400050000000000";
        int offset = -0x3090;
        long baseAddress = 0;
        
        print("Scanning memory...");
        foreach (var page in memoryPages)
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

        long gstate = 0x2ee4;
        long unknown = 0x040b;
        long p1State = 0x2eee;
        long p2State = 0x309c;
        long p1rounds = 0x2f04;
        long p2rounds = 0x30b2;
        long ladderPos = 0x3284;
        long checkValue = offset * -1;
        
        vars.watchers = new MemoryWatcherList
        {
            new MemoryWatcher<byte>((IntPtr)(vars.membase + gstate)) { Name = "gameState" },
            new MemoryWatcher<byte>((IntPtr)(vars.membase + unknown)) { Name = "unknown" },
            new MemoryWatcher<byte>((IntPtr)(vars.membase + p1State)) { Name = "p1State" },
            new MemoryWatcher<byte>((IntPtr)(vars.membase + p2State)) { Name = "p2State" },
            new MemoryWatcher<byte>((IntPtr)(vars.membase + p1rounds)) { Name = "p1RoundsWon" },
            new MemoryWatcher<byte>((IntPtr)(vars.membase + p2rounds)) { Name = "p2RoundsWon" },
            new MemoryWatcher<byte>((IntPtr)(vars.membase + ladderPos)) { Name = "ladderPos" },
            new MemoryWatcher<int>((IntPtr)(vars.membase + checkValue)) { Name = "checkValue" },
        };
    
    };


    Func<bool> IsCharacterJustSelected = () =>
    {
         if (vars.watchers["p1State"].Current == 3 ^ vars.watchers["p2State"].Current == 3)
         {
            if (memory.ProcessName.ToLower().Contains("emuhawk")
            && vars.watchers["unknown"].Old < 5
            && vars.watchers["unknown"].Current >= 5)
            {
                return true;
            }
            
            if (vars.watchers["unknown"].Old == 0x28 && vars.watchers["unknown"].Current == 0x29)
            {
                return true;
            }
         }

        
        return false;
    };
         
    
    if (memory.ProcessName.ToLower().Contains("emuhawk"))
    {
        vars.ScanMemoryAndUpdateAddresses = ScanMemorySNES;
    }
    else
    {
        vars.ScanMemoryAndUpdateAddresses = ScanMemoryArcade;
    }
    vars.IsCharacterJustSelected = IsCharacterJustSelected;
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
    // look for game name in window title
    game.Refresh();
    if (!game.MainWindowTitle.Contains("Mortal Kombat II"))
    {
        // if bizhawk, also check value in ram
        if (memory.ProcessName.ToLower().Contains("emuhawk"))
        {
            if (vars.watchers["checkValue"].Current != 0x00010000)
            {
                 vars.scanNeeded = true;
                return false;
            }
        }
        else
        {
            vars.scanNeeded = true;
            return false;
        }

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
    return vars.IsCharacterJustSelected();
}

reset
{
    // reset timer if game is:
    // booting up;
    // in attract mode;
    // game over;
    // main menu (SNES)
    if ( (vars.watchers["gameState"].Current == 18 && vars.watchers["gameState"].Old != 18) 
      || vars.watchers["gameState"].Current <= 1
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
    if (vars.watchers["ladderPos"].Current > vars.watchers["ladderPos"].Old
    && !settings["onlyShao"])
    {
        print("TOWER SPLIT");
        return true;
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
        if (vars.watchers["ladderPos"].Current == 14)
        {
            vars.matchWon = false;
            print("SHAO KAHN'S RULE IS OVER");
            return true;
        }
        vars.matchWon = false;
    }
}
