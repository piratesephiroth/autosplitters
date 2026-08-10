/***************************************************************************************\
* Street Fighter II (MAME) AutoSplitter.                                                *
* By piratesephiroth.                                                                   *
*                                                                                       *
* Supports:                                                                             *
*    Street Fighter II: The World Warrior and its bootlegs                              *
*    Street Fighter II: Champion Editon and its bootlegs                                *
*    Street Fighter II: Hyper Fighting                                                  *
*    Super Street Fighter II                                                            *
*    Super Street Fighter II Turbo                                                      *
\***************************************************************************************/

state("mame"){}
state("mame64"){}
state("mamearcade"){}


startup
{
    refreshRate = 80; // to be on the safe side
    settings.Add("onlyDictator",false,"Ignore everything, split only at Dictator's defeat");
}


init
{
    // the game's RAM is byteswapped on MAME's process 
    Func<int,int> FixAddress = (address) =>
    {
        if (address % 2 == 1)
        {
            return address - 1;
        }
         
        return address + 1;;
    };
    
    Action ScanMemoryAndUpdateAddresses = () =>
    {
        int offset = 0;
        string sig = "";
        
        int p1RoundsWon = 0x864e;
        int isCharacterSelected = 0x89d0;
        int background = 0x89bf;
        int bonusStagesCleared = 0x89ee;
        int wins = 0x89ed;
        int gameState0 = 0x8000;
        int gameState1 = 0x8004;
        
        
        if (game.MainWindowTitle.Contains("[sf2]")
        ||  game.MainWindowTitle.Contains("[sf2b]")
        ||  game.MainWindowTitle.Contains("[sf2b2]")
        ||  game.MainWindowTitle.Contains("[sf2ea]")
        ||  game.MainWindowTitle.Contains("[sf2eb]")
        ||  game.MainWindowTitle.Contains("[sf2ebbl]")
        ||  game.MainWindowTitle.Contains("[sf2ebbl2]")
        ||  game.MainWindowTitle.Contains("[sf2ebbl3]")
        ||  game.MainWindowTitle.Contains("[sf2ed]")
        ||  game.MainWindowTitle.Contains("[sf2ee]")
        ||  game.MainWindowTitle.Contains("[sf2ef]")
        ||  game.MainWindowTitle.Contains("[sf2em]")
        ||  game.MainWindowTitle.Contains("[sf2en]")
        ||  game.MainWindowTitle.Contains("[sf2j]")
        ||  game.MainWindowTitle.Contains("[sf2j17]")
        ||  game.MainWindowTitle.Contains("[sf2ja]")
        ||  game.MainWindowTitle.Contains("[sf2jc]")
        ||  game.MainWindowTitle.Contains("[sf2jf]")
        ||  game.MainWindowTitle.Contains("[sf2jh]")
        ||  game.MainWindowTitle.Contains("[sf2jl]")
        ||  game.MainWindowTitle.Contains("[sf2qp1]")
        ||  game.MainWindowTitle.Contains("[sf2qp2]")
        ||  game.MainWindowTitle.Contains("[sf2re]")
        ||  game.MainWindowTitle.Contains("[sf2rk]")
        ||  game.MainWindowTitle.Contains("[sf2rules]")
        ||  game.MainWindowTitle.Contains("[sf2stt]")
        ||  game.MainWindowTitle.Contains("[sf2thndr]")
        ||  game.MainWindowTitle.Contains("[sf2thndr2]")
        ||  game.MainWindowTitle.Contains("[sf2ua]")
        ||  game.MainWindowTitle.Contains("[sf2ub]")
        ||  game.MainWindowTitle.Contains("[sf2uc]")
        ||  game.MainWindowTitle.Contains("[sf2ud]")
        ||  game.MainWindowTitle.Contains("[sf2ue]")
        ||  game.MainWindowTitle.Contains("[sf2uf]")
        ||  game.MainWindowTitle.Contains("[sf2ug]")
        ||  game.MainWindowTitle.Contains("[sf2uh]")
        ||  game.MainWindowTitle.Contains("[sf2ui]")
        ||  game.MainWindowTitle.Contains("[sf2uk]")
        ||  game.MainWindowTitle.Contains("[sf2um]"))
        {
            sig = "00 00 00 00 00 00 E2 0C FF 00 50 02 FF 00 90 02" +
                  "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00";

            p1RoundsWon = 0x8656;
            isCharacterSelected = 0x89dc;
            background = 0x89cb;
            bonusStagesCleared = 0x89fa;
            wins = 0x89f9;
            print("  => detected Street Fighter II - The World Warrior");
        }
        
        
        if (game.MainWindowTitle.Contains("[sf2ce]")
        ||  game.MainWindowTitle.Contains("[sf2acc]")
        ||  game.MainWindowTitle.Contains("[sf2acca]")
        ||  game.MainWindowTitle.Contains("[sf2accp2]")
        ||  game.MainWindowTitle.Contains("[sf2amf]")
        ||  game.MainWindowTitle.Contains("[sf2amf2]")
        ||  game.MainWindowTitle.Contains("[sf2amf3]")
        ||  game.MainWindowTitle.Contains("[sf2bhh]")
        ||  game.MainWindowTitle.Contains("[sf2ceb]")
        ||  game.MainWindowTitle.Contains("[sf2ceb2]")
        ||  game.MainWindowTitle.Contains("[sf2ceb3]")
        ||  game.MainWindowTitle.Contains("[sf2ceb4]")
        ||  game.MainWindowTitle.Contains("[sf2ceb5]")
        ||  game.MainWindowTitle.Contains("[sf2ceblp]")
        ||  game.MainWindowTitle.Contains("[sf2cebltw]")
        ||  game.MainWindowTitle.Contains("[sf2ceds6]")
        ||  game.MainWindowTitle.Contains("[sf2ceea]")
        ||  game.MainWindowTitle.Contains("[sf2ceec]")
        ||  game.MainWindowTitle.Contains("[sf2ceja]")
        ||  game.MainWindowTitle.Contains("[sf2cejb]")
        ||  game.MainWindowTitle.Contains("[sf2cejc]")
        ||  game.MainWindowTitle.Contains("[sf2cems6a]")
        ||  game.MainWindowTitle.Contains("[sf2cems6b]")
        ||  game.MainWindowTitle.Contains("[sf2cems6c]")
        ||  game.MainWindowTitle.Contains("[sf2cet]")
        ||  game.MainWindowTitle.Contains("[sf2ceua]")
        ||  game.MainWindowTitle.Contains("[sf2ceub]")
        ||  game.MainWindowTitle.Contains("[sf2ceuc]")
        ||  game.MainWindowTitle.Contains("[sf2ceupl]")
        ||  game.MainWindowTitle.Contains("[sf2dkot2]")
        ||  game.MainWindowTitle.Contains("[sf2dongb]")
        ||  game.MainWindowTitle.Contains("[sf2koryu]")
        ||  game.MainWindowTitle.Contains("[sf2background]")
        ||  game.MainWindowTitle.Contains("[sf2m1]")
        ||  game.MainWindowTitle.Contains("[sf2m10]")
        ||  game.MainWindowTitle.Contains("[sf2m2]")
        ||  game.MainWindowTitle.Contains("[sf2m3]")
        ||  game.MainWindowTitle.Contains("[sf2m4]")
        ||  game.MainWindowTitle.Contains("[sf2m5]")
        ||  game.MainWindowTitle.Contains("[sf2m6]")
        ||  game.MainWindowTitle.Contains("[sf2m7]")
        ||  game.MainWindowTitle.Contains("[sf2m8]")
        ||  game.MainWindowTitle.Contains("[sf2m9]")
        ||  game.MainWindowTitle.Contains("[sf2mdt]")
        ||  game.MainWindowTitle.Contains("[sf2mdta]")
        ||  game.MainWindowTitle.Contains("[sf2mdtb]")
        ||  game.MainWindowTitle.Contains("[sf2rb]")
        ||  game.MainWindowTitle.Contains("[sf2rb2]")
        ||  game.MainWindowTitle.Contains("[sf2rb3]")
        ||  game.MainWindowTitle.Contains("[sf2red]")
        ||  game.MainWindowTitle.Contains("[sf2reda]")
        ||  game.MainWindowTitle.Contains("[sf2redp2]")
        ||  game.MainWindowTitle.Contains("[sf2v004]")
        ||  game.MainWindowTitle.Contains("[sf2yyc]")
        ||  game.MainWindowTitle.Contains("[sf2mkot]")) // wtf hack of WW
        {
            sig = "00 00 00 00 00 00 F6 08 FF 00 50 02 FF 00 90 02" +
                  "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00";
                  
            p1RoundsWon = 0x864e;
            background = 0x89bf;
            print("  => detected Street Fighter II - Champion Edition");
        }
        
        
        if (game.MainWindowTitle.Contains("[sf2hf]")
        ||  game.MainWindowTitle.Contains("[sf2hfu]")
        ||  game.MainWindowTitle.Contains("[sf2hfj]") )
        {
            sig = "00 00 00 00 0B 00 90 97 FF 00 10 05 FF 00 50 05" +
                  "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00";
            offset = -0x2c0;
            print("  => detected Street Fighter II - Hyper Fighting");
        }
        
        
        
        if (game.MainWindowTitle.Contains("[ssf2]")
        ||  game.MainWindowTitle.Contains("[ssf2a]")
        ||  game.MainWindowTitle.Contains("[ssf2ar1]")
        ||  game.MainWindowTitle.Contains("[ssf2h]")
        ||  game.MainWindowTitle.Contains("[ssf2j]")
        ||  game.MainWindowTitle.Contains("[ssf2jr1]")
        ||  game.MainWindowTitle.Contains("[ssf2jr2]")
        ||  game.MainWindowTitle.Contains("[ssf2r1]")
        ||  game.MainWindowTitle.Contains("[ssf2u]")
        ||  game.MainWindowTitle.Contains("[ssf2ud]")
        ||  game.MainWindowTitle.Contains("[ssf2us2]") )
        {
            sig = "00 00 00 00 00 00 90 09 FF 00 50 02 FF 00 90 02" +
                  "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00";
            
            p1RoundsWon = 0x875e;
            isCharacterSelected = 0x8be0;
            background = 0x8bcf;
            wins = 0x8bd1;
            bonusStagesCleared = 0x8c02;
            
            print("  => detected Super Street Fighter II: The New Challengers");
        }
        
        
        if (game.MainWindowTitle.Contains("[ssf2t]")
        ||  game.MainWindowTitle.Contains("[ssf2ta]")
        ||  game.MainWindowTitle.Contains("[ssf2tad]")
        ||  game.MainWindowTitle.Contains("[ssf2th]")
        ||  game.MainWindowTitle.Contains("[ssf2tu]")
        ||  game.MainWindowTitle.Contains("[ssf2tur1]")
        ||  game.MainWindowTitle.Contains("[ssf2xj]")
        ||  game.MainWindowTitle.Contains("[ssf2xjr1]")
        ||  game.MainWindowTitle.Contains("[ssf2xjr1d]")
        ||  game.MainWindowTitle.Contains("[ssf2xjr1r]") )
        {
            sig = "00 00 00 00 00 00 D6 09 FF 00 50 02 FF 00 90 02" +
                  "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00";
            
            p1RoundsWon = 0x87de;
            isCharacterSelected = 0x8c60;
            background = 0x8c4f;
            wins = 0x8c51;
            bonusStagesCleared = 0;          
            
            print("  => detected Super Street Fighter II - Turbo");
        
        }
        
        
        
        long membase = 0;
        print("Scanning memory...");
        foreach (var page in game.MemoryPages(true))
        {
            var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);
            var ptr = scanner.Scan(new SigScanTarget(offset, sig));
            if (ptr != IntPtr.Zero)
            { 
                membase = (long)ptr;
                print("  => membase found: " + game.ProcessName + ".exe+0x" + membase.ToString("X"));
                
                vars.scanNeeded = false;
                break;
            }
        }
        
        if (membase == 0) {
            throw new Exception("  => Couldn't find membase in MAME!");
        }
        
        vars.watchers = new MemoryWatcherList
        {
            new MemoryWatcher<byte>((IntPtr)(membase + FixAddress(p1RoundsWon) )) { Name = "p1RoundsWon" },
            new MemoryWatcher<byte>((IntPtr)(membase + FixAddress(isCharacterSelected) )) { Name = "isCharacterSelected" },
            new MemoryWatcher<byte>((IntPtr)(membase + FixAddress(background) )) { Name = "background" },
            new MemoryWatcher<byte>((IntPtr)(membase + FixAddress(bonusStagesCleared) )) { Name = "bonusStagesCleared" },
            new MemoryWatcher<byte>((IntPtr)(membase + FixAddress(wins) )) { Name = "wins" },
            new MemoryWatcher<ushort>((IntPtr)(membase + gameState0 )) { Name = "gameState0" },
            new MemoryWatcher<ushort>((IntPtr)(membase + gameState1 )) { Name = "gameState1" },
        };
     };
     
     vars.ScanMemoryAndUpdateAddresses = ScanMemoryAndUpdateAddresses;
     vars.scanNeeded = true;

}


update
{
    // rom was unloaded? find the membase again
    game.Refresh();
    if (!game.MainWindowTitle.Contains("Street Fighter II"))
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
    // don't start when character is selected during the demo
    if (vars.watchers["gameState0"].Current == 10)
    {
        return false;
    }
    
    if (vars.watchers["isCharacterSelected"].Current == 1
    &&  vars.watchers["isCharacterSelected"].Old == 0)
    {
        print("  => character selected");
        return true;
    }
}


reset
{
    if (vars.watchers["gameState0"].Current == 0 && vars.watchers["gameState1"].Current == 0)
    {
        print("  => reset");
        return true;
    }
}


split
{
    if (vars.watchers["p1RoundsWon"].Current == 2
     && vars.watchers["p1RoundsWon"].Old == 1
     && vars.watchers["background"].Current == 8)
    {
        print("  => Dictator defeated!");
        return true;
    }
    
    if (settings["onlyDictator"])
    {
        return false;
    }
    
    if (vars.watchers["bonusStagesCleared"].Current > vars.watchers["bonusStagesCleared"].Old)
    {
        print("  => bonus stage completed!");
        return true;
    }
    
    if (vars.watchers["wins"].Current > vars.watchers["wins"].Old)
    {
        print("  => match won!");
        return true;
    }
}
