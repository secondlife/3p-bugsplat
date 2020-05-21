@rem This .bat file is because wmic is sensitive to exactly how you invoke it
@rem -- seems to work better from command line than from cygwin bash.
@wmic datafile where name="%1" get Version /value
