/***************************************************************************************\
* Ultimate Mortal Kombat 3 (Arcade on MAME & SNES on Bizhawk) AutoSplitter.             *
* By piratesephiroth.                                                                   *
\***************************************************************************************/

state("mame"){}
state("mame64"){}
state("mamearcade"){}

state("emuhawk"){}

startup
{
    refreshRate = 80; // to be on the safe side
    
    settings.Add("ladderSplit",false,"Split at tower");
    settings.Add("onlyShao",false,"Ignore everything, split only at Shao Kahn's defeat");
    settings.Add("diagCantReset",false,"Don't reset timer after leaving the Diagnostics Menu");
}


init    
{
    Action ScanMemoryArcade = () =>
    {
        string sig = "4D 3C 2B 1A 00 00 ?? 00";
        int offset = -0xc662;
        long baseAddress = 0;
        
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
                baseAddress = (long)ptr;
                print("base address found: " + game.ProcessName + ".exe+0x" + baseAddress.ToString("X"));
                vars.scanNeeded = false;
                break;
            }
        }

        long gstate = 0xc12c;
        long p1Char = 0xc146;
        long p2Char = 0xc2bc;
        long p1State = 0xc134;
        long p2State = 0xc2aa;
        long p1rounds = 0xc152;
        long p2rounds = 0xc2c8;
        long ladderSel = 0xc459;
        long ladderPos = 0xc45a;
        //long ladderDiff = 0xc2c2;
        
        vars.postselect = 0xd;
        vars.shaoKhan = 0x19;
        
        vars.watchers = new MemoryWatcherList
        {
            new MemoryWatcher<byte>((IntPtr)(baseAddress + gstate)) { Name = "gameState" },
            new MemoryWatcher<byte>((IntPtr)(baseAddress + p1Char)) { Name = "p1Char" },
            new MemoryWatcher<byte>((IntPtr)(baseAddress + p2Char)) { Name = "p2Char" },
            new MemoryWatcher<byte>((IntPtr)(baseAddress + p1State)) { Name = "p1State" },
            new MemoryWatcher<byte>((IntPtr)(baseAddress + p2State)) { Name = "p2State" },
            new MemoryWatcher<byte>((IntPtr)(baseAddress + p1rounds)) { Name = "p1RoundsWon" },
            new MemoryWatcher<byte>((IntPtr)(baseAddress + p2rounds)) { Name = "p2RoundsWon" },
            new MemoryWatcher<byte>((IntPtr)(baseAddress + ladderSel)) { Name = "ladderSel" },
            new MemoryWatcher<byte>((IntPtr)(baseAddress + ladderPos)) { Name = "ladderPos" }
        };
     };


    Action ScanMemorySNES = () =>
    {
        
        List<MemoryBasicInformation> memoryPages = new List<MemoryBasicInformation>();
        memoryPages.AddRange(game.MemoryPages(true).Where(p => p.Type == MemPageType.MEM_MAPPED && p.State == MemPageState.MEM_COMMIT && (int)p.RegionSize < 0x50000));

        string sig = "1E031F031F032003210321032203230323032403250325032603270327032803";
        int offset = -0x10ac0;
        long baseAddress = 0;
        
        print("Scanning memory...");
        foreach (var page in memoryPages)
        {
            var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);
            var ptr = scanner.Scan(new SigScanTarget(offset, sig));
            if (ptr != IntPtr.Zero)
            { 
                baseAddress = (long)ptr;
                print("base address found: " + game.ProcessName + ".exe+0x" + baseAddress.ToString("X"));
                vars.scanNeeded = false;
                break;
            }
        }

 
        long gameState = 0x36c0;
        long p1State = 0x36c6;;
        long p2State = 0x388a;
        long p1Char = 0x36d0;
        long p2Char = 0x3894;
        long p1RoundsWon = 0x36e0;
        long p2RoundsWon = 0x38a4;
        long ladderSel = 0x3a9c;
        long ladderPos = 0x3a9e;
        //long ladderDiff = 0x3a94;
        long checkValue = 0x10ac0;

        vars.postselect = 0x9;
        vars.shaoKhan = 0x1b;
             
        vars.watchers = new MemoryWatcherList {
            new MemoryWatcher<byte>((IntPtr)(baseAddress + gameState)) { Name = "gameState" },
            new MemoryWatcher<byte>((IntPtr)(baseAddress + p1State)) { Name = "p1State" },
            new MemoryWatcher<byte>((IntPtr)(baseAddress + p2State)) { Name = "p2State" },
            new MemoryWatcher<byte>((IntPtr)(baseAddress + p1Char)) { Name = "p1Char" },
            new MemoryWatcher<byte>((IntPtr)(baseAddress + p2Char)) { Name = "p2Char" },
            new MemoryWatcher<byte>((IntPtr)(baseAddress + p1RoundsWon)) { Name = "p1RoundsWon" },
            new MemoryWatcher<byte>((IntPtr)(baseAddress + p2RoundsWon)) { Name = "p2RoundsWon" },
            new MemoryWatcher<byte>((IntPtr)(baseAddress + ladderSel)) { Name = "ladderSel" },
            new MemoryWatcher<byte>((IntPtr)(baseAddress + ladderPos)) { Name = "ladderPos" },
            new MemoryWatcher<int>((IntPtr)(baseAddress + checkValue)) { Name = "checkValue" }
        };
    
    };
    
    
    if (memory.ProcessName.ToLower().Contains("emuhawk"))
    {
        vars.ScanMemoryAndUpdateAddresses = ScanMemorySNES;
    }
    else
    {
        vars.ScanMemoryAndUpdateAddresses = ScanMemoryArcade;
    }
    
    
    vars.scanNeeded = true;
    vars.matchWon = false;
    vars.disableReset = false;
    
    if (!game.MainWindowTitle.Contains("Ultimate Mortal Kombat 3"))
    {
        vars.scanNeeded = true;
        return false;
    }
}


update
{
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
    
    if (memory.ProcessName.ToLower().Contains("emuhawk"))
    {
        if (vars.watchers["checkValue"].Current != 0x31f031e)
        {
            vars.scanNeeded = true;
        }
    }

}


start
{
    // only at the "Select your Destiny" screen
    if (vars.watchers["gameState"].Current != vars.postselect)
    {
        return false;
    }
    // right after selecting the tower
    if (vars.watchers["ladderSel"].Current != 0)
    {
        print("START TIMER");
        return true;
    }
}


reset
{
    // reset timer if game is booting up
    if (vars.watchers["gameState"].Current == 0 && vars.watchers["gameState"].Old != 0)
    {
        if (vars.disableReset)
        {
            vars.disableReset = false;
            print("RESET ENABLED AGAIN");
            return false;
        }
        
        print("RESET TIMER");
        return true;
    }
}


split
{
    // tower, when ladder position goes up
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
        if (vars.watchers["p1RoundsWon"].Current == 2 && vars.watchers["p1RoundsWon"].Old == 1)
        {
            vars.matchWon = true;
            print ("P1 WON");
        }
    }
    if (vars.watchers["p2State"].Current == 1 || vars.watchers["p2State"].Old == 1)
    {
        if (vars.watchers["p2RoundsWon"].Current == 2 && vars.watchers["p2RoundsWon"].Old == 1)
        {
            vars.matchWon = true;
            print ("P2 WON");
        }
    }
    
    // find out if it was a regular character or Shao Khan
    if (vars.matchWon)
    {
        if (vars.watchers["gameState"].Current == 5)
        {
            vars.matchWon = false;
            if (!settings["onlyShao"] && !settings["ladderSplit"])
            {
                print("VICTORY SPLIT");
                return true;
            }
        }
        if (vars.watchers["p1Char"].Current == vars.shaoKhan || vars.watchers["p2Char"].Current == vars.shaoKhan)
        {
            vars.matchWon = false;
            print("SHAO KAHN'S RULE IS OVER");
            return true;
        }
    }
}
