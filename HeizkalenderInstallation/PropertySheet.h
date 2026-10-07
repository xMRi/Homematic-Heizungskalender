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


#pragma once

#include "Controls.h"

//-----------------------------------------------------------------------------

class CPageBase : public CMFCPropertyPage
{
public:
	using CMFCPropertyPage::CMFCPropertyPage;
	virtual BOOL OnQueryCancel() override;
	virtual BOOL OnApply() override;
	virtual BOOL OnSetActive() override;
protected:
	bool m_bSeiteBesucht{};
};

//-----------------------------------------------------------------------------

class CPageConnect : public CPageBase
{
public:
	CPageConnect();

// Dialog Data
#ifdef AFX_DESIGN_TIME
	enum { IDD = IDD_PAGE_CONNECT };
#endif
	CComboBox	m_cbScript1Mode;
	CEditText	m_edHost, m_edUserName, m_edPassword, m_edPrefix, 
				m_edCTChurchName, m_edCTLoginToken, 
				m_ediCalUrl, m_edGoogleApiKey, m_edGoogleKalId, m_edRaumListe,
				m_edCDOrgaId, m_edCDApiToken;
	CFont	m_fontBold;

private:
	bool m_bBlockFirstOnKillActive{ true };

protected:
	DECLARE_MESSAGE_MAP()
	virtual BOOL OnKillActive();
	virtual BOOL OnInitDialog();
	virtual void DoDataExchange(CDataExchange* pDX);
	afx_msg void OnBnClickedBtConnect();
	afx_msg void OnBnClickedAbout();
	afx_msg void OnCbnSelchangeCbMode();
	afx_msg void OnBnClickedBtReadres();

};

//-----------------------------------------------------------------------------

class CPageSettings : public CPageBase
{
public:
	CPageSettings();

	// Dialog Data
#ifdef AFX_DESIGN_TIME
	enum { IDD = IDD_PAGE_SETTINGS };
#endif
	CEditDouble	m_edGrungTemp;
	CEditDouble	m_edATempGrenze;
	CEditInt	m_edKurve[8];

	DECLARE_MESSAGE_MAP()
	virtual void DoDataExchange(CDataExchange* pDX);
	virtual BOOL OnInitDialog();
};

//-----------------------------------------------------------------------------

class CPagePrograms : public CPageBase
{
public:
	CPagePrograms();

	// Dialog Data
#ifdef AFX_DESIGN_TIME
	enum { IDD = IDD_PAGE_PROGRAMS };
#endif
	CListCtrl m_lcData;
	CButton m_btWinMerge;

	static int const COL_NAME = 0;
	static int const COL_DATE_INSTALLED = 1;
	static int const COL_DATE_UPDATE = 2;
	static int const COL_INFO = 3;

	void EnableControls();

	DECLARE_MESSAGE_MAP()
	virtual void DoDataExchange(CDataExchange* pDX);
	virtual BOOL OnInitDialog();
	afx_msg void OnLvnItemchangedLcData(NMHDR* pNMHDR, LRESULT* pResult);
	afx_msg void OnBnClickedBtWinmerge();
	afx_msg void OnNMDblclkLcData(NMHDR* pNMHDR, LRESULT* pResult);
};

//-----------------------------------------------------------------------------

class CPageRooms : public CPageBase
{
public:
	CPageRooms();

	// Dialog Data
#ifdef AFX_DESIGN_TIME
	enum { IDD = IDD_PAGE_ROOMS };
#endif
	CListCtrl m_lcData;
	CButton m_btNew;
	CButton m_btModify;
	CButton m_btDelete;

	static int const COL_NAME = 0;
	static int const COL_SH = 1;
	static int const COL_TEMP = 2;
	static int const COL_EIN = 3;
	static int const COL_AUS = 4;
	static int const COL_HEIZGR = 5;
	static int const COL_INFO = 6;

	void EnableControls();

	DECLARE_MESSAGE_MAP()
	virtual BOOL OnSetActive() override;
	virtual void DoDataExchange(CDataExchange* pDX);
	virtual BOOL OnInitDialog();
	afx_msg void OnNMDblclkLcRooms(NMHDR* pNMHDR, LRESULT* pResult);
	afx_msg void OnBnClickedBtNew();
	afx_msg void OnBnClickedBtModify();
	afx_msg void OnBnClickedBtDelete();
	afx_msg void OnLvnItemchangedLcData(NMHDR* pNMHDR, LRESULT* pResult);
	afx_msg void OnKeydownLcData(NMHDR* pNMHDR, LRESULT* pResult);
};

//-----------------------------------------------------------------------------

class CPageResources : public CPageBase
{
public:
	CPageResources();

	// Dialog Data
#ifdef AFX_DESIGN_TIME
	enum { IDD = IDD_PAGE_RESOURCES };
#endif
	CListCtrl m_lcData;
	CButton m_btModify;
	CMapRaumListe m_mapRaeume;

	static int const COL_ID = 0;
	static int const COL_NAME = 1;
	static int const COL_ROOMS = 2;

	void EnableControls();

	DECLARE_MESSAGE_MAP()
	virtual BOOL OnSetActive() override;
	virtual void DoDataExchange(CDataExchange* pDX);
	virtual BOOL OnInitDialog();
	afx_msg void OnNMDblclkLcRooms(NMHDR* pNMHDR, LRESULT* pResult);
	afx_msg void OnBnClickedBtModify();
	afx_msg void OnLvnItemchangedLcRooms(NMHDR* pNMHDR, LRESULT* pResult);
	afx_msg void OnBnClickedBtDelete();
	afx_msg void OnKeydownLcData(NMHDR* pNMHDR, LRESULT* pResult);
	afx_msg void OnItemclickLcData(NMHDR* pNMHDR, LRESULT* pResult);
};

//-----------------------------------------------------------------------------

class CPageSysvar : public CPageBase
{
public:
	CPageSysvar();

	// Dialog Data
#ifdef AFX_DESIGN_TIME
	enum { IDD = IDD_PAGE_SYSVARS };
#endif
	CListCtrl m_lcData;
	CButton m_btInfo;

	static int const COL_NAME = 0;
	static int const COL_CONTENT = 1;
	static int const COL_INFO = 2;

	void EnableControls();

	DECLARE_MESSAGE_MAP()
	virtual void DoDataExchange(CDataExchange* pDX);
	virtual BOOL OnInitDialog();
	afx_msg void OnBnClickedBtInfo();
	afx_msg void OnLvnItemchangedLcData(NMHDR* pNMHDR, LRESULT* pResult);
	afx_msg void OnNMDblclkLcData(NMHDR* pNMHDR, LRESULT* pResult);
};

//-----------------------------------------------------------------------------

class CInstallationsWizard : public CMFCPropertySheet
{
	DECLARE_DYNAMIC(CInstallationsWizard)
	friend class CPageBase;
public:
	CInstallationsWizard();
	virtual ~CInstallationsWizard();

protected:
	DECLARE_MESSAGE_MAP()
	virtual BOOL OnInitDialog();

private:
	CPageConnect	m_pageConnect;
	CPageSettings	m_pageSettings;
	CPageSysvar		m_pageSysVar;
	CPagePrograms	m_pagePrograms;
	CPageRooms		m_pageRooms;
	CPageResources	m_pageResources;
};

//-----------------------------------------------------------------------------
