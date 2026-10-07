// Heizkalender-Installer
// Copyright (C) 2026 Martin Richter (xMRi-Software) - heizkalender@m-ri.de
//
// Dieses Programm ist freie Software: Sie können es unter den Bedingungen
// der GNU General Public License, wie von der Free Software Foundation
// veröffentlicht, weitergeben und/oder modifizieren, entweder gemäß
// Version 3 der Lizenz oder (nach Ihrer Wahl) jeder späteren Version.
//
// Dieses Programm wird in der Hoffnung verteilt, dass es nützlich ist,
// jedoch OHNE JEDE GEWÄHRLEISTUNG; sogar ohne die implizite Gewährleistung
// der MARKTFÄHIGKEIT oder EIGNUNG FÜR EINEN BESTIMMTEN ZWECK.
// Weitere Details finden Sie in der GNU General Public License.
//
// Sie sollten eine Kopie der GNU General Public License zusammen mit
// diesem Programm erhalten haben. Falls nicht, siehe
// <https://www.gnu.org/licenses/>.
// 
// SPDX-License-Identifier: GPL-3.0-or-later

#include "pch.h"
#include "HeizkalenderInstallation.h"
#include "afxdialogex.h"
#include "AboutDlg.h"
#include "FileVersionInfo.h"

// CAboutDlg dialog

IMPLEMENT_DYNAMIC(CAboutDlg, CDialogEx)

CAboutDlg::CAboutDlg(CWnd* pParent /*=nullptr*/)
	: CDialogEx(IDD_ABOUTBOX, pParent)
{

}

CAboutDlg::~CAboutDlg()
{
}

void CAboutDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialogEx::DoDataExchange(pDX);
}


BEGIN_MESSAGE_MAP(CAboutDlg, CDialogEx)
END_MESSAGE_MAP()

// CAboutDlg message handlers

BOOL CAboutDlg::OnInitDialog()
{
	CDialogEx::OnInitDialog();

	// Set the text to be bold
	LOGFONT logfont;
	GetFont()->GetObject(sizeof(LOGFONT),&logfont);
	logfont.lfWeight = FW_BOLD;
	if (m_fontBold.CreateFontIndirect(&logfont))
	{
		// Set bold font
		static const UINT uiBoldCtrls[] = 
		{
			IDC_ST_VERSION, IDC_ST_COPYRIGHT, 0
		};
		for (int i=0; uiBoldCtrls[i]; ++i)
		{
			CWnd *pWnd = GetDlgItem(uiBoldCtrls[i]);
			if (pWnd)
				pWnd->SetFont(&m_fontBold);
		}
	}

	// Programmversion und Copyright laden und anzeigen
	CFileVersionInfo fvi;
	fvi.GetFileVersionInfo();
	
	CString strVersion, strMask;
	GetDlgItemText(IDC_ST_VERSION,strMask);
	strVersion.FormatMessage(strMask,theApp.m_strAppVersion.GetString(), theApp.m_strScriptVersion.GetString());
	SetDlgItemText(IDC_ST_VERSION,strVersion);
	SetDlgItemText(IDC_ST_COPYRIGHT,fvi.GetLegalCopyright());

	return TRUE;  
}

