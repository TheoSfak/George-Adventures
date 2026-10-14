# Helpers for looking at (and clicking in) the EXPORTED game window without touching the rest of the desktop.
# Dot-source it from the project folder:   . tools/exe_window.ps1
#   $proc = Start-Process <exe> -ArgumentList "--resolution","1280x720" -PassThru
#   $hwnd = Wait-Window $proc 40            # the window handle (wait up to 40 s)
#   Save-Window $hwnd "shot.png"            # PrintWindow: ONLY this window, never the desktop
#   Click-Window $hwnd 1003 389             # click at IMAGE coordinates of the saved picture (posted with PostMessage)
# Used for the real update tests (old release exe -> click "Enselmerosi" -> new exe), see HANDOVER.md section 2.
# Kill only processes whose Path is inside the test folder, never Theodore's editor or game.
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing @"
using System;
using System.Runtime.InteropServices;
public class W {
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint flags);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint msg, IntPtr w, IntPtr l);
    public struct RECT { public int L, T, R, B; }
    public struct POINT { public int X, Y; }
}
"@

# Saves ONLY this window (PrintWindow), never the desktop.
function Save-Window($hwnd, $path) {
    $r = New-Object W+RECT
    [void][W]::GetWindowRect($hwnd, [ref]$r)
    $w = $r.R - $r.L; $h = $r.B - $r.T
    $bmp = New-Object System.Drawing.Bitmap $w, $h
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $hdc = $g.GetHdc()
    [void][W]::PrintWindow($hwnd, $hdc, 2)
    $g.ReleaseHdc($hdc)
    $g.Dispose()
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    return "$w x $h"
}

# Offset of the client area inside the captured window image.
function Client-Offset($hwnd) {
    $r = New-Object W+RECT
    [void][W]::GetWindowRect($hwnd, [ref]$r)
    $p = New-Object W+POINT
    [void][W]::ClientToScreen($hwnd, [ref]$p)
    return @(($p.X - $r.L), ($p.Y - $r.T))
}

# A click at image coordinates (as seen in the saved picture), posted to the window.
function Click-Window($hwnd, $imgX, $imgY) {
    $off = Client-Offset $hwnd
    $x = $imgX - $off[0]; $y = $imgY - $off[1]
    $l = [IntPtr](($y -shl 16) -bor ($x -band 0xFFFF))
    [void][W]::PostMessage($hwnd, 0x200, [IntPtr]0, $l)
    Start-Sleep -Milliseconds 150
    [void][W]::PostMessage($hwnd, 0x201, [IntPtr]1, $l)
    Start-Sleep -Milliseconds 120
    [void][W]::PostMessage($hwnd, 0x202, [IntPtr]0, $l)
}

function Wait-Window($proc, $seconds) {
    for ($i = 0; $i -lt ($seconds * 2); $i++) {
        $proc.Refresh()
        if ($proc.MainWindowHandle -ne [IntPtr]::Zero) { return $proc.MainWindowHandle }
        Start-Sleep -Milliseconds 500
    }
    return [IntPtr]::Zero
}
