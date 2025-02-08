// merge.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include "..\include\MyHeader.h"
#include <locale.h>


#define BUF_SIZE				512
#define MAX_LINE				250
#define MAX_CONFIG_LINE			30


typedef struct
{
	TCHAR inFileName[MAX_PATH];			/* �����ļ��� */
	DWORD inOffset;						/* �����ļ�ƫ�ƣ��� 512 �ֽ�Ϊ��λ */
	TCHAR outFileName[MAX_PATH];		/* ����ļ��� */
	DWORD outOffset;					/* ����ļ�ƫ��, �� 512 �ֽ�Ϊ��λ */
	DWORD nCount;						/* ���� */
	//HANDLE hInFile;						/* �����ļ� HANDLE */
	//HANDLE hOutFile;					/* ����ļ� HANDLE */
} MERGE_CONFIG, *LPMERGE_CONFIG;


MERGE_CONFIG mergeConfig[MAX_CONFIG_LINE];
static DWORD mergeConfigIndex = 0;


static BOOL GetMergeConfig(LPTSTR lpLine);
static void PrintMergeConfigTable();
static VOID ReportError(LPCTSTR userMessage, DWORD exitCode, BOOL printErrorMessage);

int _tmain(int argc, _TCHAR* argv[])
{
	HANDLE hIn, hOut;
	FILE *fp;
	errno_t err;
	TCHAR chLine[MAX_LINE];
	BYTE buf[BUF_SIZE];
	DWORD i, nIn, nOut;
	BOOL bSuccess = TRUE;
	TCHAR msgError[100];

	/* ��ӡ������Ϣ */
	_tprintf(_T("<All rights reserved! DengZhi, Bug: mik@mouseos.com>\n"));

	if (argc > 1)
	{
		ReportError(_T("Usage: merge\n"), 1, FALSE);
	}
	
	if ((err = _tfopen_s(&fp, _T("config.txt"), _T("r"))) != 0)
	{
		ReportError(_T("<Error: open the config.txt> "), 2, TRUE);
	}


	while (_fgetts(chLine, BUF_SIZE, fp))
	{	
	
		if (!GetMergeConfig(chLine))
		{
			ReportError(_T("Error: merge config, please check the config.txt"), 3, FALSE);
		}
		
	}

	for (i = 0; i < mergeConfigIndex; i++)
	{
		hIn = CreateFile(mergeConfig[i].inFileName, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
		if (hIn == INVALID_HANDLE_VALUE)
		{
			_stprintf_s(msgError, 100, _T("<Read Error>: %s,"), mergeConfig[i].inFileName);
			ReportError(msgError, 4, TRUE);
		}
		
		hOut = CreateFile(mergeConfig[i].outFileName, GENERIC_WRITE, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
		if (hOut == INVALID_HANDLE_VALUE)
		{
			_stprintf_s(msgError, 100, _T("<Write Error>: %s,"), mergeConfig[i].outFileName);
			ReportError(msgError, 4, TRUE);
		}

		if (SetFilePointer(hIn, mergeConfig[i].inOffset * 512, 0, FILE_BEGIN) == INVALID_SET_FILE_POINTER)
			ReportError(_T("Error: move the input file pointer for read"), 5, TRUE);

		if (SetFilePointer(hOut, mergeConfig[i].outOffset * 512, 0, FILE_BEGIN) == INVALID_SET_FILE_POINTER)
			ReportError(_T("Error: move the output file pointer for write"), 5, TRUE);

		bSuccess = TRUE;

		__try
		{
			while ((mergeConfig[i].nCount != 0) && ReadFile(hIn, buf, BUF_SIZE, &nIn, NULL) && (nIn > 0) && bSuccess)
			{		
				if (!WriteFile(hOut, buf, nIn, &nOut, NULL))
				{
					//_tprintf(_T("entry #%d:\t%s ---> %s:\tfailure\n"), i, mergeConfig[i].inFileName, mergeConfig[i].outFileName);
					bSuccess = FALSE;
				}

				mergeConfig[i].nCount--;

			}

		}
		__finally
		{
			CloseHandle(hIn);
			CloseHandle(hOut);
		}


		if (bSuccess)
			_tprintf(_T("entry #%d:\t%s ---> %s:\tsuccess\n"), i, mergeConfig[i].inFileName, mergeConfig[i].outFileName);
		else
			_tprintf(_T("entry #%d:\t%s ---> %s:\tfailure\n"), i, mergeConfig[i].inFileName, mergeConfig[i].outFileName);

		CloseHandle(hIn);
		CloseHandle(hOut);
	}


	fclose(fp);

	return 0;
}

static BOOL GetMergeConfig(LPTSTR lpLine)
{
	TCHAR buf[BUF_SIZE];
	DWORD inFileFlag = 0, inOffsetFlag = 0, outFileFlag = 0, outOffsetFlag = 0, countFlag = 0;
	DWORD i = 0;
	
	//_tprintf(lpLine);
	while (*lpLine != _T('\0'))
	{
		//_tprintf(_T("enter while()\n"));

		switch (*lpLine)
		{
		case _T(','):
			//_tprintf(_T("enter case ','"), buf);

			if (i) 
				buf[i] = _T('\0');
			else
				return FALSE;
						
			if (inFileFlag == 0)
			{
				_tcsncpy_s(mergeConfig[mergeConfigIndex].inFileName, MAX_PATH, buf, _TRUNCATE);
				//_tprintf(_T("==%s==\n"), mergeConfig[mergeConfigIndex].inFileName);
				inFileFlag = 1;
			}
			else if (inOffsetFlag == 0)
			{
				mergeConfig[mergeConfigIndex].inOffset = _tstoi(buf);
				inOffsetFlag = 1;
			}
			else if (outFileFlag == 0)
			{
				_tcsncpy_s(mergeConfig[mergeConfigIndex].outFileName, MAX_PATH, buf, _TRUNCATE);
				//_tprintf(_T("==%s==\n"), mergeConfig[mergeConfigIndex].outFileName);
				outFileFlag = 1;
			}
			else if (outOffsetFlag == 0)
			{
				mergeConfig[mergeConfigIndex].outOffset = _tstoi(buf);
				outOffsetFlag = 1;

			}
			i = 0;
			lpLine++;
			break;
		case _T('\n'):
			if (i == 0)
				return TRUE;
			else
			{
				if (outOffsetFlag == 0)
					return FALSE;
	
				if (countFlag == 0)
				{
					mergeConfig[mergeConfigIndex].nCount = _tstoi(buf);
					countFlag = 1;
				} else 
					return FALSE;
			}
			lpLine++;
			break;
		case _T(' '):
		case _T('\t'):
			while ((*lpLine != _T('\0') && ((*lpLine == _T('\t')) || ((*lpLine == _T(' ')))))) lpLine++;
			break;
		case _T('#'):
			if (i) 
				return FALSE;
			else
				return TRUE;					
		default:
			//_tprintf(_T("enter case default\n"));

			buf[i++] = *lpLine;
			lpLine++;
		}
	} /* end of while */

	//_tprintf(_T("leave while()\n"));

	if (countFlag == 0)
	{
		mergeConfig[mergeConfigIndex].nCount = _tstoi(buf);
		countFlag = 1;
	}

	if (inFileFlag == 0 || inOffsetFlag == 0 || outFileFlag == 0 || outOffsetFlag == 0 || countFlag == 0)
	{
		//_tprintf(_T("-->enter test outOffsetFlag\n"));
		return FALSE;
	} 

	mergeConfigIndex++;

	if (mergeConfigIndex > MAX_CONFIG_LINE)
	{
		_tprintf(_T("config.txt line number too much\n"));
		return FALSE;
	}

	return TRUE;
}


static void PrintMergeConfigTable()
{
	DWORD i;

	for (i = 0; i < mergeConfigIndex; i++)
	{
		_tprintf(_T("config line %d: inFileName:%s, inOffset:%d, outFileName:%s, outOffset:%d, nCount:%d\n"),
			i, mergeConfig[i].inFileName, mergeConfig[i].inOffset, mergeConfig[i].outFileName, mergeConfig[i].outOffset, mergeConfig[i].nCount);
	}
}


static VOID ReportError(LPCTSTR userMessage, DWORD exitCode, BOOL printErrorMessage)
{
	DWORD eMsgLen, errNum = GetLastError();
	LPTSTR lpvSysMsg;
	
	_tsetlocale(LC_CTYPE, (LPCWSTR)"");

	//_ftprintf(stderr, _T("%s\n"), userMessage);
	_ftprintf(stderr, _T("%s "), userMessage);

	if (printErrorMessage)
	{
		eMsgLen = FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM,
			NULL, errNum, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), (LPTSTR)&lpvSysMsg, 0, NULL);
		
		if (eMsgLen > 0)
		{
			_ftprintf(stderr, _T("%s\n"), lpvSysMsg);
		}
		else
		{
			_ftprintf(stderr, _T("Last Error Number; %d.\n"), errNum);
		}
		if (lpvSysMsg != NULL)
			LocalFree(lpvSysMsg);			
	}
	
	if (exitCode > 0)
		ExitProcess(exitCode);
}
