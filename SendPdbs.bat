@rem Run SendPdbs.exe via this .bat file because, when msys bash attempts to
@rem run it directly, SendPdbs.exe complains about absence of switches that
@rem are clearly present on its command line.

"%SendPdbs%" /a "%viewer_channel%" /v "%version%" /b "%BUGSPLAT_DB%" /f "%files%"
