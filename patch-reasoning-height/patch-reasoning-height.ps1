<#
.SYNOPSIS
  Increases the expanded Reasoning block height in the native Kilo Code plugin
  for ALL installed JetBrains IDEs (WebStorm, IntelliJ IDEA, PyCharm, PhpStorm, etc.).
.DESCRIPTION
  Patches ReasoningView.class inside every kilo.jetbrains.frontend.jar found under
  %APPDATA%\JetBrains\<IDE><version>\plugins\kilo.jetbrains\lib\modules\.
    bodyMaxRows:  5  -> 20
    bodyMaxHeight padding: JBUI.scale(16) -> JBUI.scale(120)
  Run while all JetBrains IDEs are closed.

  java.exe is auto-discovered in (in this order):
    - any JetBrains IDE under Program Files / Program Files (x86) / LocalAppData\Programs
    - JetBrains Toolbox (recursive)
    - JetBrains uninstall registry entries
    - %JAVA_HOME% / PATH
  You can override it with -JavaPath.
.PARAMETER NewRows
  Number of reasoning rows in the expanded block (default 20).
.PARAMETER NewPadding
  Padding in pixels (default 120).
.PARAMETER JavaPath
  Explicit path to java.exe. If omitted, auto-discovery is used.
.EXAMPLE
  .\patch-reasoning-height.ps1
  .\patch-reasoning-height.ps1 -NewRows 30 -NewPadding 200
  .\patch-reasoning-height.ps1 -JavaPath "C:\Program Files\JetBrains\WebStorm 2026.2\jbr\bin\java.exe"
#>
param(
    [int]$NewRows = 20,
    [int]$NewPadding = 120,
    [string]$JavaPath
)

$ErrorActionPreference = 'Stop'

$ideProcessNames = @(
    'webstorm64','webstorm',
    'idea64','idea',
    'pycharm64','pycharm',
    'phpstorm64','phpstorm',
    'rubymine64','rubymine',
    'clion64','clion',
    'goland64','goland',
    'datagrip64','datagrip',
    'rider64','rider',
    'dataspell64','dataspell',
    'aqua64','aqua',
    'rustrover64','rustrover',
    'fleet64','fleet'
)

$ideRegex = 'WebStorm|IntelliJ|PyCharm|PhpStorm|RubyMine|CLion|GoLand|DataGrip|Rider|DataSpell|Aqua|RustRover|Fleet'

# --- Find ALL plugin JARs across all JetBrains IDEs ---
function Find-PluginJars {
    $root = Join-Path $env:APPDATA 'JetBrains'
    if (-not (Test-Path $root)) { return @() }

    $jars = Get-ChildItem $root -Directory -ErrorAction SilentlyContinue |
        ForEach-Object {
            Join-Path $_.FullName 'plugins\kilo.jetbrains\lib\modules\kilo.jetbrains.frontend.jar'
        } | Where-Object { Test-Path $_ }

    return @($jars)
}

# --- Get "<IDE><version>" from a JAR path ---
function Get-IdeName {
    param([string]$JarPath)
    $parts = $JarPath -split '\\'
    for ($i = 0; $i -lt $parts.Length - 1; $i++) {
        if ($parts[$i] -eq 'JetBrains') { return $parts[$i + 1] }
    }
    return 'unknown'
}

# --- Find java.exe in any JetBrains IDE / JDK ---
function Find-JavaExe {
    $candidates = New-Object System.Collections.Generic.List[string]

    $bases = @($env:ProgramFiles, ${env:ProgramFiles(x86)}, (Join-Path $env:LOCALAPPDATA 'Programs')) |
        Where-Object { $_ -and (Test-Path $_) }
    foreach ($base in $bases) {
        Get-ChildItem $base -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match $ideRegex } |
            ForEach-Object {
                $candidates.Add((Join-Path $_.FullName 'jbr\bin\java.exe'))
                $candidates.Add((Join-Path $_.FullName 'jre\bin\java.exe'))
            }
    }

    foreach ($base in $bases) {
        Get-ChildItem $base -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match $ideRegex } |
            ForEach-Object {
                Get-ChildItem $_.FullName -Recurse -Depth 5 -Filter 'java.exe' -ErrorAction SilentlyContinue |
                    Where-Object { $_.FullName -match '\\(jbr|jre)\\bin\\java\.exe$' } |
                    ForEach-Object { $candidates.Add($_.FullName) }
            }
    }

    $toolbox = Join-Path $env:LOCALAPPDATA 'JetBrains\Toolbox\apps'
    if (Test-Path $toolbox) {
        Get-ChildItem $toolbox -Recurse -Filter 'java.exe' -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match '\\(jbr|jre)\\bin\\java\.exe$' } |
            ForEach-Object { $candidates.Add($_.FullName) }
    }

    foreach ($hive in @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    )) {
        if (-not (Test-Path $hive)) { continue }
        Get-ChildItem $hive -ErrorAction SilentlyContinue | ForEach-Object {
            $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
            if (-not $p) { return }
            $dn = "$($p.DisplayName)"
            $pub = "$($p.Publisher)"
            if ($dn -match $ideRegex -or $pub -match 'JetBrains') {
                if ($p.InstallLocation) {
                    $candidates.Add((Join-Path $p.InstallLocation 'jbr\bin\java.exe'))
                    $candidates.Add((Join-Path $p.InstallLocation 'jre\bin\java.exe'))
                }
                if ($p.DisplayIcon) {
                    $icon = ($p.DisplayIcon -split ',')[0].Trim('"')
                    if ($icon -and (Test-Path $icon)) {
                        $root = Split-Path $icon -Parent
                        $candidates.Add((Join-Path $root 'jbr\bin\java.exe'))
                        $candidates.Add((Join-Path $root 'jre\bin\java.exe'))
                    }
                }
            }
        }
    }

    if ($env:JAVA_HOME) { $candidates.Add((Join-Path $env:JAVA_HOME 'bin\java.exe')) }
    $cmd = Get-Command java.exe -ErrorAction SilentlyContinue
    if ($cmd) { $candidates.Add($cmd.Source) }

    $tried = New-Object System.Collections.Generic.List[string]
    foreach ($c in $candidates) {
        if ([string]::IsNullOrWhiteSpace($c)) { continue }
        $tried.Add($c)
        if (Test-Path $c) {
            $script:JavaCandidatesTried = $tried
            return $c
        }
    }
    $script:JavaCandidatesTried = $tried
    return $null
}

# --- Discover all JARs ---
$jarPaths = Find-PluginJars
if (-not $jarPaths -or $jarPaths.Count -eq 0) {
    throw 'kilo.jetbrains.frontend.jar not found in any JetBrains IDE (%APPDATA%\JetBrains\<IDE><version>\plugins\kilo.jetbrains). Make sure the Kilo Code plugin is installed in at least one IDE.'
}

# --- Resolve java.exe ---
if ($JavaPath) {
    if (-not (Test-Path $JavaPath)) {
        throw "java.exe not found at -JavaPath: $JavaPath"
    }
    $javaExe = $JavaPath
} else {
    $javaExe = Find-JavaExe
}
if (-not $javaExe) {
    Write-Host 'Auto-discovery of java.exe failed. Paths tried:' -ForegroundColor Yellow
    if ($script:JavaCandidatesTried) {
        $script:JavaCandidatesTried | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
    }
    Write-Host ''
    Write-Host 'Specify it explicitly, e.g.:' -ForegroundColor Yellow
    Write-Host '  .\patch-reasoning-height.ps1 -JavaPath "C:\Program Files\JetBrains\WebStorm 2026.2\jbr\bin\java.exe"' -ForegroundColor Yellow
    throw 'java.exe not found.'
}

$workDir   = Join-Path $env:TEMP 'kilo\patch-reasoning'
$entryName = 'ai/kilocode/client/session/views/ReasoningView.class'

Write-Host "Java: $javaExe"  -ForegroundColor Gray
Write-Host "Work: $workDir"  -ForegroundColor Gray
Write-Host "JARs found: $($jarPaths.Count)" -ForegroundColor Gray
$jarPaths | ForEach-Object { Write-Host "  - $_" -ForegroundColor DarkGray }

# --- Verify no JetBrains IDE is running ---
$running = Get-Process -Name $ideProcessNames -ErrorAction SilentlyContinue
if ($running) {
    $names = ($running | Select-Object -ExpandProperty Name -Unique) -join ', '
    throw "JetBrains IDE is running ($names). Close it before patching."
}

# --- Prepare work dir and shared helpers ---
if (Test-Path $workDir) { Remove-Item $workDir -Recurse -Force }
New-Item -ItemType Directory -Path $workDir -Force | Out-Null

$extractJava = "$workDir\ExtractClass.java"
@'
import java.io.*;
import java.nio.file.*;
import java.util.zip.*;
public class ExtractClass {
    public static void main(String[] args) throws Exception {
        String jarPath = args[0], entryName = args[1], outPath = args[2];
        try (ZipInputStream zin = new ZipInputStream(new FileInputStream(jarPath))) {
            ZipEntry e;
            while ((e = zin.getNextEntry()) != null) {
                if (e.getName().equals(entryName)) {
                    Files.copy(zin, Paths.get(outPath), StandardCopyOption.REPLACE_EXISTING);
                    System.out.println("Extracted: " + entryName);
                    return;
                }
            }
        }
        throw new FileNotFoundException("Entry not found: " + entryName);
    }
}
'@ | Set-Content $extractJava -Encoding ASCII

$patchJava = "$workDir\PatchReasoning.java"
@'
import java.io.*;
import java.nio.file.*;
public class PatchReasoning {
    static byte[] d;
    static int pos;
    static int[] cpTags;
    static String[] cpStrs;

    static int u1(){int v=d[pos]&0xFF;pos++;return v;}
    static int u2(){int v=((d[pos]&0xFF)<<8)|(d[pos+1]&0xFF);pos+=2;return v;}
    static int u4(){int v=((d[pos]&0xFF)<<24)|((d[pos+1]&0xFF)<<16)|((d[pos+2]&0xFF)<<8)|(d[pos+3]&0xFF);pos+=4;return v;}
    static int u2a(int o){return ((d[o]&0xFF)<<8)|(d[o+1]&0xFF);}
    static int u4a(int o){return ((d[o]&0xFF)<<24)|((d[o+1]&0xFF)<<16)|((d[o+2]&0xFF)<<8)|(d[o+3]&0xFF);}
    static void w2(int o,int v){d[o]=(byte)(v>>8);d[o+1]=(byte)v;}
    static void w4(int o,int v){d[o]=(byte)(v>>24);d[o+1]=(byte)(v>>16);d[o+2]=(byte)(v>>8);d[o+3]=(byte)v;}

    public static void main(String[] args) throws Exception {
        int newRows = Integer.parseInt(args[2]);
        int newPad  = Integer.parseInt(args[3]);
        d = Files.readAllBytes(Paths.get(args[0]));
        pos = 8;
        int ps = u2();
        cpTags = new int[ps]; cpStrs = new String[ps];
        for (int i=1;i<ps;i++){
            int t=u1(); cpTags[i]=t;
            switch(t){
                case 1:int l=u2();cpStrs[i]=new String(d,pos,l,"UTF-8");pos+=l;break;
                case 3:case 4:pos+=4;break;
                case 5:case 6:pos+=8;i++;break;
                case 7:case 8:case 16:case 19:case 20:pos+=2;break;
                case 9:case 10:case 11:case 12:case 17:case 18:pos+=4;break;
                case 15:pos+=3;break;
            }
        }
        u2();u2();u2(); int ic=u2(); for(int i=0;i<ic;i++)u2();
        int fc=u2(); for(int i=0;i<fc;i++){u2();u2();u2();int ac=u2();for(int j=0;j<ac;j++){u2();int al=u4();pos+=al;}}

        int mc=u2();
        int rowsCodeStart=-1,rowsCodeLen=-1,rowsAttrDataStart=-1;
        int heightCodeStart=-1,heightCodeLen=-1;

        for(int i=0;i<mc;i++){
            u2(); int ni=u2(); int di=u2();
            int ac=u2(); String mn=cpStrs[ni];
            for(int j=0;j<ac;j++){
                int ani=u2(); int al=u4(); String an=cpStrs[ani];
                if(an.equals("Code")){
                    int ads=pos; u2();u2(); int cl=u4(); int cs=pos;
                    if(mn.contains("bodyMaxRows")){rowsCodeStart=cs;rowsCodeLen=cl;rowsAttrDataStart=ads;
                        System.out.println("  bodyMaxRows: codeStart="+cs+" codeLen="+cl);
                    }
                    if(mn.contains("bodyMaxHeight")){heightCodeStart=cs;heightCodeLen=cl;
                        System.out.println("  bodyMaxHeight: codeStart="+cs+" codeLen="+cl);
                    }
                    pos=cs+cl; int etl=u2();
                    for(int k=0;k<etl;k++){u2();u2();u2();u2();}
                    int iac=u2(); for(int k=0;k<iac;k++){u2();int al2=u4();pos+=al2;}
                } else { pos+=al; }
            }
        }

        if(rowsCodeStart<0||heightCodeStart<0){System.out.println("  ERROR: methods not found");return;}
        boolean heightAfterRows = heightCodeStart > rowsCodeStart;

        if((d[rowsCodeStart]&0xFF)==0x08){
            int insertPos=rowsCodeStart+1;
            byte[] nd=new byte[d.length+1];
            System.arraycopy(d,0,nd,0,insertPos);
            nd[insertPos]=(byte)newRows;
            System.arraycopy(d,insertPos,nd,insertPos+1,d.length-insertPos);
            d=nd;
            d[rowsCodeStart]=0x10;
            w4(rowsCodeStart-4,rowsCodeLen+1);
            int newCodeEnd=rowsCodeStart+rowsCodeLen+1;
            int etl=u2a(newCodeEnd);
            int innerStart=newCodeEnd+2+etl*8;
            int iac=u2a(innerStart);
            int cur=innerStart+2;
            for(int k=0;k<iac;k++){
                int aNI=u2a(cur); int aLen=u4a(cur+2);
                if(cpStrs[aNI].equals("LineNumberTable")){
                    int entries=u2a(cur+6);
                    for(int m=0;m<entries;m++){
                        int sp=u2a(cur+8+m*4);
                        w2(cur+8+m*4, sp+(sp>=1?1:0));
                    }
                }
                cur+=6+aLen;
            }
            w4(rowsAttrDataStart-4, cur-rowsAttrDataStart);
            if(heightAfterRows) heightCodeStart+=1;
            System.out.println("  bodyMaxRows patched: iconst_5 -> bipush "+newRows);
        } else if((d[rowsCodeStart]&0xFF)==0x10){
            d[rowsCodeStart+1]=(byte)newRows;
            System.out.println("  bodyMaxRows updated: bipush "+newRows);
        } else {
            System.out.println("  WARN: unexpected opcode 0x"+Integer.toHexString(d[rowsCodeStart]&0xFF)+" in bodyMaxRows");
        }

        boolean foundPad=false;
        for(int k=0;k<heightCodeLen-1;k++){
            if((d[heightCodeStart+k]&0xFF)==0x10 && ((d[heightCodeStart+k+1]&0xFF)==16 || (d[heightCodeStart+k+1]&0xFF)==120)){
                d[heightCodeStart+k+1]=(byte)newPad;
                System.out.println("  bodyMaxHeight patched: bipush "+newPad+" at offset "+k);
                foundPad=true; break;
            }
        }
        if(!foundPad) System.out.println("  WARN: bipush 16/120 not found in bodyMaxHeight");

        Files.write(Paths.get(args[1]),d);
        System.out.println("  Done: "+args[1]+" ("+d.length+" bytes)");
    }
}
'@ | Set-Content $patchJava -Encoding ASCII

$updateJava = "$workDir\UpdateJar.java"
@'
import java.io.*;
import java.nio.file.*;
import java.util.zip.*;
public class UpdateJar {
    public static void main(String[] args) throws Exception {
        String jarPath=args[0], entryName=args[1], replacementFile=args[2];
        String tmpPath=jarPath+".tmp";
        byte[] newContent=Files.readAllBytes(Paths.get(replacementFile));
        try(ZipInputStream zin=new ZipInputStream(new FileInputStream(jarPath));
            ZipOutputStream zout=new ZipOutputStream(new FileOutputStream(tmpPath))){
            ZipEntry e;
            while((e=zin.getNextEntry())!=null){
                if(e.getName().equals(entryName)){
                    ZipEntry ne=new ZipEntry(entryName);
                    ne.setTime(System.currentTimeMillis());
                    zout.putNextEntry(ne); zout.write(newContent); zout.closeEntry();
                    System.out.println("  Replaced: "+entryName+" ("+newContent.length+" bytes)");
                } else {
                    zout.putNextEntry(new ZipEntry(e.getName()));
                    byte[] buf=new byte[8192]; int len;
                    while((len=zin.read(buf))>0) zout.write(buf,0,len);
                    zout.closeEntry();
                }
            }
        }
        Files.delete(Paths.get(jarPath));
        Files.move(Paths.get(tmpPath), Paths.get(jarPath));
        System.out.println("  JAR updated: "+jarPath);
    }
}
'@ | Set-Content $updateJava -Encoding ASCII

# --- Patch every discovered JAR ---
$results = New-Object System.Collections.Generic.List[object]

foreach ($jarPath in $jarPaths) {
    $ideName    = Get-IdeName $jarPath
    $backupPath = "$jarPath.bak"

    Write-Host ""
    Write-Host "=== $ideName ===" -ForegroundColor Cyan
    Write-Host "  JAR: $jarPath" -ForegroundColor Gray

    if (-not (Test-Path $backupPath)) {
        Copy-Item $jarPath $backupPath -Force
        Write-Host "  Backup created: $backupPath" -ForegroundColor Green
    } else {
        Write-Host "  Backup already exists: $backupPath" -ForegroundColor Yellow
    }

    $safeName     = ($ideName -replace '[^\w]','_')
    $srcClass     = "$workDir\$safeName.orig.class"
    $patchedClass = "$workDir\$safeName.patched.class"

    & $javaExe $extractJava $jarPath $entryName $srcClass 2>&1 | ForEach-Object { Write-Host "  $_" }
    if (-not (Test-Path $srcClass)) {
        Write-Host "  ERROR: failed to extract ReasoningView.class - skipping" -ForegroundColor Red
        $results.Add([pscustomobject]@{ IDE = $ideName; JAR = $jarPath; Status = 'extract failed' })
        continue
    }

    & $javaExe $patchJava $srcClass $patchedClass $NewRows $NewPadding 2>&1 | ForEach-Object { Write-Host "  $_" }
    if (-not (Test-Path $patchedClass)) {
        Write-Host "  ERROR: patch failed - skipping" -ForegroundColor Red
        $results.Add([pscustomobject]@{ IDE = $ideName; JAR = $jarPath; Status = 'patch failed' })
        continue
    }

    & $javaExe $updateJava $jarPath $entryName $patchedClass 2>&1 | ForEach-Object { Write-Host "  $_" }

    $results.Add([pscustomobject]@{ IDE = $ideName; JAR = $jarPath; Status = 'OK' })
}

# --- Cleanup ---
Remove-Item $workDir -Recurse -Force -ErrorAction SilentlyContinue

# --- Summary ---
Write-Host ""
Write-Host "=== Patch applied ===" -ForegroundColor Green
Write-Host "  bodyMaxRows:  -> $NewRows rows" -ForegroundColor Cyan
Write-Host "  padding:      -> $NewPadding px" -ForegroundColor Cyan
Write-Host ""
foreach ($r in $results) {
    $color = if ($r.Status -eq 'OK') { 'Green' } else { 'Red' }
    Write-Host ("  [{0,-14}] {1}" -f $r.Status, $r.IDE) -ForegroundColor $color
    Write-Host ("                   {0}" -f $r.JAR) -ForegroundColor DarkGray
    if ($r.Status -eq 'OK') {
        Write-Host ("                   backup: {0}.bak" -f $r.JAR) -ForegroundColor DarkGray
    }
}
Write-Host ""
Write-Host "Start the IDE(s) to verify." -ForegroundColor Yellow