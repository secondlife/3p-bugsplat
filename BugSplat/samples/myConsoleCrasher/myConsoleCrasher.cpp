//
//        This sample project illustrates how to capture crashes (unhandled exceptions) in native Windows applications using BugSplat.
//
//        The shared sample database 'Fred' is used in this example.
//        You may view crashes for the Fred account by logging in at https://www.bugsplat.com:
//        Account (Email Address): Fred 
//                       Password: Flintstone
//
//        In order to assure that crashes sent to the BugSplat website yield exception stack traces with file/line # information, 
//        just rebuild this project.  A Visual Studio post build event is configured to send the resulting .exe and .pdb files
//        to BugSplat via the SendPdbs utility.  If you wish to use your own account and database, you will need to modify the post build
//        event accordingly.  If you do not care about file/line # info or for any reason you do not want  to send these files, 
//        simply disable the post build event.
//
//        More information is available online at https://www.bugsplat.com


#pragma optimize( "", off) // prevent optimizer from interfering with our crash-producing code

#include "stdafx.h"
#include <windows.h>
#include "BugSplat.h"

void StackOverflow(void *p);
bool ExceptionCallback(UINT nCode, LPVOID lpVal1, LPVOID lpVal2);

MiniDmpSender *mpSender;

int wmain(int argc, wchar_t **argv)
{

    if (IsDebuggerPresent())
    {
        wprintf(L"Run this application without the debugger attached to enable BugSplat exception handling.\n");
        DebugBreak();
        exit(0);
    }

    // BugSplat initialization.  Post crash reports to the "Fred" database for application "myConsoleCrasher" version "1.0"
    mpSender = new MiniDmpSender(L"Fred", L"myConsoleCrasher", L"1.0", NULL, MDSF_USEGUARDMEMORY | MDSF_LOGFILE);

    // Set optional default values for user, email, and user description of the crash.
    mpSender->setDefaultUserName(_T("Fred"));
    mpSender->setDefaultUserEmail(_T("fred@bedrock.com"));
	mpSender->setDefaultUserDescription(_T("This is the default user crash description."));

    // Process command line args that we need prior to crashing
    for (int i = 1; i < argc; i++) {

        if (!_wcsicmp(argv[i], L"/AttachFiles")) {
            mpSender->setCallback(ExceptionCallback); // files are attached in the callback after the exception occurs
        }
    }

    // Force a crash, in a variety of ways
    for (int i = 1; i < argc; i++) {

        if (!_wcsicmp(argv[i], L"/Crash")) {
            // Don't let the BugSplat dialog appear
            mpSender->setFlags(MDSF_NONINTERACTIVE | mpSender->getFlags());
        }

        if (!_wcsicmp(argv[i], L"/MemoryException") || !_wcsicmp(argv[i], L"/Crash")) {
            // Dereferencing a null pointer results in a memory exception
            *(volatile int *)0 = 0;
        }

        else if (!_wcsicmp(argv[i], L"/StackOverflow")) {
            // Calling a recursive function with no exit results in a stack overflow
            StackOverflow(NULL);
        }

        else if (!_wcsicmp(argv[i], L"/DivByZero")) {
            // No surprises here
            volatile int x, y, z;
            x = 1;
            y = 0;
            z = x / y;
        }

		else if (!_wcsicmp(argv[i], L"/OutOfMemory")) {
			while (true)  // Loop until memory exhausted
			{
				char* a = new char[1024*1024];
				a[0] = 'X';
			}
		}

        else if (!_wcsicmp(argv[i], L"/Abort")) {
            abort(); // Must build in release configuration to catch this one
        }

    }

    // Default if no crash resulted from command line args
    *(volatile int *)0 = 0;

    return 0;
}

void StackOverflow(void *p)
{
    volatile char q[10000];
    while (true) {
        StackOverflow((void *)q);
    }
}

// BugSplat exception callback
bool ExceptionCallback(UINT nCode, LPVOID lpVal1, LPVOID lpVal2)
{

    switch (nCode)
    {
        case MDSCB_EXCEPTIONCODE:
        {
            EXCEPTION_RECORD *p = (EXCEPTION_RECORD *)lpVal1;
            DWORD code = p ? p->ExceptionCode : 0;

            // Create some files in the %temp% directory and attach them
            wchar_t cmdString[2 * MAX_PATH];
            wchar_t filePath[MAX_PATH];
            wchar_t tempPath[MAX_PATH];
            GetTempPathW(MAX_PATH, tempPath);

            wsprintf(filePath, L"%sfile1.txt", tempPath);
            wsprintf(cmdString, L"echo Exception Code = 0x%08x > %s", code, filePath);
            _wsystem(cmdString);
            mpSender->sendAdditionalFile(filePath);

            wsprintf(filePath, L"%sfile2.txt", tempPath);

			wchar_t buf[_MAX_PATH];
			mpSender->getMinidumpPath(buf, _MAX_PATH);

            wsprintf(cmdString, L"echo Crash reporting is so clutch!  minidump path = %s > %s", buf, filePath);
            _wsystem(cmdString);
            mpSender->sendAdditionalFile(filePath);
        }
        break;
    }

    return false;
}
