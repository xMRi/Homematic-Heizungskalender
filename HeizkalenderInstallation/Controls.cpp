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
#include "helper.h"
#include "Controls.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif

#define FLATLOOK

#ifdef _UNICODE
	#define _TCF_TEXT	CF_UNICODETEXT
#else
	#define _TCF_TEXT	CF_TEXT
#endif

#define NEW_COLORS

inline bool IsShiftKeyDown()	
{
	return (::GetKeyState(VK_SHIFT)	& 0x8000)!=0;
}

inline bool IsCtrlKeyDown()	
{
	return (::GetKeyState(VK_CONTROL) & 0x8000)!=0;
}

inline bool IsMenuKeyDown()	
{
	return (::GetKeyState(VK_MENU) & 0x8000)!=0;
}

//-----------------------------------------------------------------------------

class CEditSpinButtonCtrl : public CSpinButtonCtrl
{
	DECLARE_DYNAMIC(CEditSpinButtonCtrl)
public:
// Construction/Destruction
	CEditSpinButtonCtrl(BOOL fAutoDelete=FALSE);
	~CEditSpinButtonCtrl();

// ClassWizard generated virtual function overrides
protected:
	virtual void PostNcDestroy();

protected:
	BOOL	m_fAutoDelete;

protected:                
	DECLARE_MESSAGE_MAP()
	afx_msg void OnDeltapos(NMHDR* pNMHDR, LRESULT* pResult);
	afx_msg void HScroll(UINT nSBCode, UINT nPos);
	afx_msg void VScroll(UINT nSBCode, UINT nPos);
};


IMPLEMENT_DYNAMIC(CEditSpinButtonCtrl,CSpinButtonCtrl)    

CEditSpinButtonCtrl::CEditSpinButtonCtrl(BOOL fAutoDelete)
	: m_fAutoDelete(fAutoDelete)
{                 
}

CEditSpinButtonCtrl::~CEditSpinButtonCtrl()
{
}

void CEditSpinButtonCtrl::PostNcDestroy() 
{
	// delete it if need to 
	if (m_fAutoDelete)
		delete this;
}

BEGIN_MESSAGE_MAP(CEditSpinButtonCtrl, CSpinButtonCtrl)
	ON_NOTIFY_REFLECT(UDN_DELTAPOS, OnDeltapos)
	ON_WM_HSCROLL_REFLECT()
	ON_WM_VSCROLL_REFLECT()
END_MESSAGE_MAP()

void CEditSpinButtonCtrl::OnDeltapos(NMHDR* pNMHDR, LRESULT* pResult) 
{
	// we received the delta pos message
	NM_UPDOWN* pNMUpDown = (NM_UPDOWN*)pNMHDR;

	// Just send a message to the buddy control
	// Usually the buddy is here the parent so we use it if no buddy is set
	// otherwise we use the buddy control
	CWnd *pBuddy = GetBuddy();
	if (!pBuddy)
		pBuddy = GetParent();
	if (pBuddy) 
	{
		// Get style
		DWORD dwStyle = GetStyle();	
		// check direction
		WORD wScrollMsg= (dwStyle & UDS_HORZ) ? WM_HSCROLL : WM_VSCROLL,
			 wScrollCode = (pNMUpDown->iDelta<0) ? SB_LINEUP : SB_LINEDOWN;
        pBuddy->SendMessage(wScrollMsg, MAKEWPARAM(wScrollCode,pNMUpDown->iPos), (LPARAM)m_hWnd);
	}

	// continue	and allow changes
	*pResult = FALSE;
}

void CEditSpinButtonCtrl::VScroll(UINT , UINT )
{
	// eat message for parent, we do not want the notification
}

void CEditSpinButtonCtrl::HScroll(UINT , UINT )
{
	// eat message for parent, we do not want the notification
}

//-----------------------------------------------------------------------------

IMPLEMENT_DYNAMIC(CEditBase, CEdit)

CEditBase::CEditBase()
	: m_fInCreate(false)		// Avoid call in PreSubclassWindow
	, m_fIsDirty(true)			// Always Dirty (contents and value mismatch)
	, m_pWndCtrl(NULL)			// No Control	
	, m_fEnableEmptyCtrl(false)
	, m_fEnableSelectOnSetFocus(true)
{                            
}

CEditBase::~CEditBase()
{
}

BEGIN_MESSAGE_MAP(CEditBase, CEdit)
	ON_MESSAGE(EM_SETREADONLY,OnSetReadOnly)
	ON_MESSAGE(WM_SETTEXT,OnSetText)
	ON_WM_KILLFOCUS()
	ON_WM_SETFOCUS()
	ON_WM_CHAR()
	ON_WM_SYSKEYDOWN()
	ON_WM_ENABLE()
	ON_WM_HSCROLL()
	ON_WM_VSCROLL()
	ON_WM_DESTROY()
	ON_WM_SHOWWINDOW()
	ON_WM_TIMER()
	ON_WM_SIZE()
	ON_WM_GETDLGCODE()
END_MESSAGE_MAP()

BOOL CEditBase::Create(DWORD dwStyle, const RECT& rect, CWnd* pParentWnd, UINT nID)
{   
	// Set flag for create
	m_fInCreate = true;
	// Create Window
	BOOL fResult = CEdit::Create(dwStyle,rect,pParentWnd,nID);
	// Clear flag
	m_fInCreate = false;

	// If Created, Prepare the Edit initialization and validate
	if (fResult) 
	{
		// Validate the Control
		InitControl();
		ValidateControl();
		// Lockout anything in the Initphase
		FormatControl(formatDoNotNotify);
	}
	return fResult;		
}

void CEditBase::PreSubclassWindow()
{
	if (!m_fInCreate)
	{
		/* To avoid a fault on direct creation of the window, the
		 * this code is delayed after the creation. Otherwise
		 * this will cause an integer divide by zero */
		CEdit::PreSubclassWindow();
		// Validate the Control
		InitControl();
		ValidateControl();
		// Lockout anything in the Initphase		
		FormatControl(formatDoNotNotify);        
	}
}

BOOL CEditBase::PreTranslateMessage(MSG* pMsg)
{
	// Multi line edit control need some special handling:
	// 1. Handle Ctrl+Enter for the multiline edit control
	//    This is done with the implementation of a OnGetDlgCode handler.
	// 2. Also we handle Ctrl+A, that is also not handled in multi line edit controls.
	if (pMsg->message==WM_KEYDOWN && (GetStyle() & ES_MULTILINE)!=0)
	{
		switch (pMsg->wParam)
		{
		case VK_RETURN:
			// Deliver Ctrl+Enter to the edit control.
			if (IsCtrlKeyDown())
			{
				// Directly deliver Ctrl+Enter
				::TranslateMessage(pMsg);
				::DispatchMessage(pMsg);
				return TRUE;
			}
			break;
		case 'A':
			// Select everything in the edit control.
			if (IsCtrlKeyDown() && !IsShiftKeyDown() && !IsMenuKeyDown())
			{
				SetSel(0,-1);
				return TRUE;
			}
			break;
		}
	}
	return __super::PreTranslateMessage(pMsg);
}


void CEditBase::ReformatControl()
{
	if (m_hWnd)
		FormatControl(formatDoNotNotify);        
}

bool CEditBase::EnableEmptyCtrl(bool bEnableEmpty)
{
	bool bOldFlag = m_fEnableEmptyCtrl;
	m_fEnableEmptyCtrl = bEnableEmpty;
	return bOldFlag;
}


void CEditBase::SmartSetWindowText(PCTSTR pszNew, bool fLockOut)
{ 
	TCHAR 	szOld[64];
	int 	nNewLen = static_cast<int>(_tcslen(pszNew));

	// Take care about the modified Flag, this is reset by a SetWindowText
	BOOL fModifiedFlag = GetModify();

	// Set Lockout if needed	
	_AFX_THREAD_STATE* pThreadState = NULL;
	HWND hWndOldLockout = NULL;
	if (fLockOut)
	{
		// Need threadstate to block all WM_COMMAND notifications to the parent
		pThreadState = AfxGetThreadState();
		hWndOldLockout = pThreadState->m_hLockoutNotifyWindow;
		ASSERT(hWndOldLockout != m_hWnd);   // must not recurse
		pThreadState->m_hLockoutNotifyWindow = GetParent()->GetSafeHwnd();
	}

	// fast check to see if text really changes (reduces flash in controls)
	if (nNewLen>_countof(szOld) ||
		::GetWindowText(m_hWnd, szOld, _countof(szOld))!=nNewLen ||
		_tcscmp(szOld, pszNew)!=0)
		// need to change the Text
		SetWindowText(pszNew);	

	// Recover saved state
	if (fLockOut)
		pThreadState->m_hLockoutNotifyWindow = hWndOldLockout;

	// Recover Modified state
	SetModify(fModifiedFlag);
}

CWnd *CEditBase::GetAssocControl()
{
	return m_pWndCtrl;
}

void CEditBase::EnableAssocControl()
{
	// Parent Window (edit control) must be enabled by itself
	// and must be visible and must not be readonly.
	BOOL fEnabled = IsWindowEnabled() && (GetStyle() & WS_VISIBLE)!=0 && (GetStyle() & ES_READONLY)==0;
	if (m_pWndCtrl) 
	{
		// Enable disable
		BOOL fWasDisabled = m_pWndCtrl->EnableWindow(fEnabled);	
		// check states (use twice a not, to convert to TRUE/FALSE)
		if (!fWasDisabled!=!!fEnabled) 
			// need to redisplay the window
			m_pWndCtrl->InvalidateRect(NULL);
	}
}

void CEditBase::GetRectForAssocControl(CRect &rectMain, CRect &rectControl)
{
	// Get the height of the parent
	GetWindowRect(rectMain);
	GetParent()->ScreenToClient(rectMain);

	// Use same rect for the control
	rectControl = rectMain;

	// Get the width
	int iWidth = (rectMain.Height()*3)/4;

	// Extend Control from right border
	rectControl.left = rectControl.right-iWidth;

	// Shrink the main window to get a gap between the controls.
	rectMain.right = rectControl.left-GetSystemMetrics(SM_CXEDGE);
}

bool CEditBase::CreateSpinBtnCtrl(bool bInplace)
{
	// Create a Spin Ctrl if necessary
	ASSERT(m_pWndCtrl==0);

	// Set everything for Inplace
	CRect rect;
	rect.SetRectEmpty();
	CWnd *pParent = this;
	
	if (bInplace)
	{
		// UDS_ALIGNRIGHT does not work if the up/down control is placed
		// inside our control
		int iWidth = ::GetSystemMetrics(SM_CXVSCROLL);
		SetMargins(0,iWidth);
		
		// Get the rectangle for the button
		GetWindowRect(rect);
		ScreenToClient(rect);
		rect.left = rect.right-iWidth;

		// FIX: Vista
		// If the control has the focus, the button on the right side gets overwritten
		// Hovering with the mouse make it reappear. 
		// To fix this we set the state WS_CLIPCHILDREN here.
		ModifyStyle(0,WS_CLIPCHILDREN);
	}
	else
	{
		// Get the height of the parent
		CRect rectMain;
		GetRectForAssocControl(rectMain, rect);

		// Shrink Main Window and set the button directly behind the control in the Z-Order
		SetWindowPos(NULL,rectMain.left,rectMain.right,rectMain.Width(),rectMain.Height(),SWP_NOMOVE|SWP_NOZORDER|SWP_NOACTIVATE);

		// reset Parent and style
		pParent = GetParent();
	}

	// Create the Button
	CEditSpinButtonCtrl *pButton = new CEditSpinButtonCtrl(TRUE);
	if (pButton->Create(WS_CHILD|UDS_WRAP|UDS_ARROWKEYS|(GetStyle() & WS_VISIBLE),rect,pParent,static_cast<UINT>(-1)))
	{	
		// Set Buddy if we set the buddy to this and, the edit control is the 
		// parent of the Updown Control it will cause a crash in W2K on destroying
		// the control. So we take care about the parent. We set the buddy only if we are 
		// the associated one and have the same parent and do not contain the Updown 
		// control as a child window.
		if (pParent!=this)
		{
			// Change the Z-Order too
			pButton->SetWindowPos(this,0,0,0,0,SWP_NOMOVE|SWP_NOSIZE|SWP_NOACTIVATE);
			pButton->SetBuddy(this);
		}
//		else
//			// Change the style to clip this new child
//			ModifyStyle(0,WS_CLIPCHILDREN);
		m_pWndCtrl = pButton;
		// Need to reflect enable and disable state
		EnableAssocControl();
	}
	return m_pWndCtrl!=NULL;
}

void CEditBase::DestroyAssocControl()
{
	ASSERT_VALID(m_pWndCtrl);
	m_pWndCtrl->DestroyWindow();
	m_pWndCtrl = NULL;
}

void CEditBase::OnSize(UINT nType, int cx, int cy)
{
	CEdit::OnSize(nType, cx, cy);

	// Maybe need to resize assoc control
	if (m_pWndCtrl && m_pWndCtrl->GetParent()==this)
	{
		// It is set to the right of the edit control by default. The
		// width will never change. The hight will change
		CRect rect;
		m_pWndCtrl->GetWindowRect(rect);
		m_pWndCtrl->MoveWindow(cx-rect.Width(),0,rect.Width(),cy);

		// Set margin for edit control to protect children
		SetMargins(0,rect.Width());
	}
}

bool CEditBase::IsDirty()
{
	return m_fIsDirty || GetFocus()==this;
}


bool CEditBase::EnableSelectOnSetFocus(bool fOn)
{
	bool bOldState = m_fEnableSelectOnSetFocus;
	m_fEnableSelectOnSetFocus = fOn;
	return bOldState;
}

void CEditBase::PrepareEditText()
{
}                            

void CEditBase::InitControl()
{
}                               

void CEditBase::FormatControl(eFormatControl eFlag)
{
	m_fIsDirty = FALSE;
	if (eFlag==formatAndNotify)            
		SetModify();
}

void CEditBase::PostNcDestroy()
{
	m_pWndCtrl = NULL;
}

void CEditBase::OnDestroy() 
{
	// Delete an associated Control first if there is any
	// W2K seamns to crash if not doing it. Normaly this should work
	if (m_pWndCtrl)
		m_pWndCtrl->DestroyWindow();
	m_pWndCtrl = NULL;		

	// Ok default ausführen
	CEdit::OnDestroy();
}

void CEditBase::OnShowWindow(BOOL bShow, UINT nStatus)
{
	// First do the default.
	CEdit::OnShowWindow(bShow,nStatus);

	// Show Hide the associated Control too
	if (m_pWndCtrl->GetSafeHwnd())
	{
		// Show the associated control and enable or disable it.
		m_pWndCtrl->ShowWindow(bShow ? SW_SHOW : SW_HIDE);
		EnableAssocControl();
	}
}

void CEditBase::OnEnable(BOOL bEnable)
{                            
	// do the default
	CEdit::OnEnable(bEnable);
	// Enable or disable associated microscroll
	EnableAssocControl();
}

LPARAM CEditBase::OnSetReadOnly(WPARAM wParam, LPARAM lParam)
{
	// Do the default
	LRESULT lResult = Default();	
	// Get the current Enable Status
	EnableAssocControl();	                     
	return lResult;	
}


LPARAM CEditBase::OnSetText(WPARAM wParam, LPARAM lParam)
{
	// There is an external SetText
	m_fIsDirty = TRUE;
	//	Standard Execution
	return DefWindowProc(WM_SETTEXT,wParam,lParam);	
}

void CEditBase::OnKillFocus(CWnd* pNewWnd)
{
	// Reformat the Edit Control
	if ((GetStyle() & ES_READONLY)==0) 
	{
		// Validate the Field
		BOOL bValid = ValidateControl();

		// Check if the control is empty, if so we
		// check for the m_fEnableEmptyCtrl, is set
		// we leave it empty
		int iLen = GetWindowTextLength();
		bool bLeaveEmpty = (bValid && iLen==0 && m_fEnableEmptyCtrl);

		/* Reformat the Control, and notify if there are changes
		* otherwise, just ignore any changes made by formater, 
		* assume, that the input has notified the parent */
		FormatControl(!bValid ? formatAfterKillFocus : formatDoNotNotify);       

		// but now set it back to empty, do not notify
		if (bLeaveEmpty)
			SmartSetWindowText(_T(""),true);
	}
	// now perform the KillFocus	
	CEdit::OnKillFocus(pNewWnd);
}

void CEditBase::OnSetFocus(CWnd* pOldWnd)
{                 
	// Reformat the Edit Control 
	if ((GetStyle() & ES_READONLY)==0)
	{
		// Only if it is not empty and an empty control is allowed
		if (!m_fEnableEmptyCtrl || GetWindowTextLength()!=0)
			PrepareEditText();	
	}
	CEdit::OnSetFocus(pOldWnd);
}

void CEditBase::OnChar(UINT nChar, UINT nRepCnt, UINT nFlags)
{                
	// Use the new given parameters and pass it to edit
	DefWindowProc(WM_CHAR,nChar,MAKELPARAM(nRepCnt,nFlags));	
}


void CEditBase::OnSysKeyDown(UINT nChar, UINT nRepCnt, UINT nFlags)
{	
	// Dropdown Button availabel? check ALT-DOWN/UP Taste	
	if (m_pWndCtrl->GetSafeHwnd() && (nChar==VK_DOWN || nChar==VK_UP))
	{
		// Is the control a button
		TCHAR szClassname[16];
		::GetClassName(m_pWndCtrl->GetSafeHwnd(),szClassname,_countof(szClassname));
		if (_tcsicmp(szClassname,WC_BUTTON)==0)
			// Send Messsage that Button is pressed
			SendMessage(WM_COMMAND,MAKEWPARAM(m_pWndCtrl->GetDlgCtrlID(),BN_CLICKED),(LPARAM)m_pWndCtrl->m_hWnd);			
	}
	// Use the new given parameters and pass it to edit
	DefWindowProc(WM_SYSKEYDOWN,nChar,MAKELPARAM(nRepCnt,nFlags));
}

UINT CEditBase::OnGetDlgCode()
{
	// Multi line edit controls usually return DLGC_WANTALLCHARS but this causes
	// problems in a CPropertySheet. So we clean this flag here if it is multi line
	// and we let PreTranslateMessage handle Ctrl+Enter. Otherwise, Enter and Escape are
	// not handled correct when focus in in the multi line edit control and the control
	// resides in a propertsheet
	UINT dlgCode = __super::OnGetDlgCode();
	if (GetStyle() & ES_MULTILINE)
		dlgCode &= ~DLGC_WANTALLKEYS;
	if (!m_fEnableSelectOnSetFocus)
		// Usually this is set, if not the activation in a dialog does not selects the control contents
		dlgCode &= ~DLGC_HASSETSEL;
	return dlgCode;
}

void CEditBase::SetCueBanner(PCTSTR pszText)
{
	SendMessage(EM_SETCUEBANNER,FALSE,reinterpret_cast<LPARAM>(pszText));
}


//-----------------------------------------------------------------------------

IMPLEMENT_DYNCREATE(CEditInt, CEditBase)

CEditInt::CEditInt(int iMin, int iMax)
	: m_fEmptyOnZero(false)
{                  
	ASSERT(iMin<=iMax);
	m_iMin   = iMin;
	m_iMax	 = iMax;
	m_iValue = iMin;
	m_iStep  = 1;
}

CEditInt::~CEditInt()
{
}

const int CEditInt::m_cMaxInputLength = 11;		// -2147483647 

BEGIN_MESSAGE_MAP(CEditInt, CEditBase)
	ON_WM_CHAR()
	ON_WM_VSCROLL()
	ON_WM_HSCROLL()
END_MESSAGE_MAP()

BOOL CEditInt::SubclassDlgItem(UINT nID, CWnd* pParent, int iMin, int iMax)
{                             
	// Preset the Values
	m_iMin = iMin;
	m_iMax = iMax;
	return CEditBase::SubclassDlgItem(nID, pParent);	
}

void CEditInt::SetValue(int iValue)
{
	// Save the value in the internal Storage
	m_iValue = max(m_iMin,iValue);
	m_iValue = min(m_iMax,m_iValue);
	// Control ausgeben
	FormatControl(formatDoNotNotify);
}


int CEditInt::SetStepValue(int iValue)
{
	int iOld = m_iStep;
	m_iStep = iValue;
	return iOld;
}

int CEditInt::GetValue()
{
	// Need to reformat ?
	if (IsDirty())
		// Get internal Value (never reformat)
		ValidateControl();
	// Return internal Value
	return m_iValue;			
}


void CEditInt::SetMinMax(int iMin, int iMax)
{
	m_iMin = iMin;
	m_iMax = iMax;      
	ASSERT(m_iMin<=m_iMax);
}

void CEditInt::GetMinMax(int &iMin, int &iMax)
{
	iMin = m_iMin;
	iMax = m_iMax;
}

bool CEditInt::EnableEmptyOnZero(bool fEmptyOnZero)
{
	bool fOldEmptyOnZero = m_fEmptyOnZero;
	m_fEmptyOnZero = fEmptyOnZero;
	ReformatControl();	
	return fOldEmptyOnZero;
}

void CEditInt::InitControl()
{
	LimitText(m_cMaxInputLength);
}                               

bool CEditInt::IsValid()
{             
	TCHAR szText[m_cMaxInputLength+1];	
	// Get the value from the control     
	GetWindowText(szText,_countof(szText));
	// Convert the Number	
	PTSTR pEnd;
	int iValue = _tcstol(szText,&pEnd,10);
	int iValueOrg = iValue;		
	// Minima and maxima
	iValue = max(m_iMin,iValue);
	iValue = min(m_iMax,iValue);
	// Return result if Control is realy Valid (no min/max error etc.)		
	return *pEnd=='\0' && iValue==iValueOrg;
}


bool CEditInt::ValidateControl()
{             
	TCHAR szText[m_cMaxInputLength+1];	
	// Get the value from the control     
	GetWindowText(szText,_countof(szText));
	// Convert the Number	
	PTSTR pEnd;
	int iValue = _tcstol(szText,&pEnd,10);
	int iValueOrg = iValue;		
	// Minima and maxima
	iValue = max(m_iMin,iValue);
	iValue = min(m_iMax,iValue);
	m_iValue = (int)iValue;
	// Return result if Control is realy Valid (no min/max error etc.)		
	return *pEnd=='\0' && iValue==iValueOrg;
}


void CEditInt::FormatControl(eFormatControl eFlag)
{	                        
	// reformat the text
	TCHAR szText[m_cMaxInputLength+1];
	// Konvertiere in Ascii-Text	
	if (m_iValue==0 && 
		((m_hWnd==::GetFocus() && GetWindowTextLength()==0) || m_fEmptyOnZero))
		szText[0] = '\0';
	else		
		_itot_s(m_iValue,szText,10);	

	// save settext              
	if (eFlag!=formatAndNotify)            
		SmartSetWindowText(szText,eFlag==formatDoNotNotify);
	else
		SetWindowText(szText);	
	// Do the Default
	CEditBase::FormatControl(eFlag);
}

void CEditInt::OnChar(UINT nChar, UINT nRepCnt, UINT nFlags)
{
	// Allow control chars, numbers and the minus sign if allowed
	if (nChar<0x20 ||
		(_istdigit((TCHAR)nChar)) ||
		(m_iMin<0 && nChar=='-'))
		// Ok this character is correct	
		CEditBase::OnChar(nChar, nRepCnt, nFlags);	
	else
		// Beep wegen Fehler
		MessageBeep((UINT)-1);		
}

void CEditInt::OnVScroll(UINT nSBCode, UINT nPos, CScrollBar* pScrollBar)
{                       
	// Exit if no Step Value
	if (!m_iStep)
		return;
	// Get old value
	int		iOldValue = m_iValue;
	BOOL	fValid;	

	// Set Focus if need to, avoid flickering
	if (GetFocus()!=this) 
	{
		// the contents might be invalid
		if (IsDirty())
			ValidateControl();	
		SetFocus();	   
		// After this the contents is always valid
		fValid = TRUE;
	} 
	else 		
		// The control has the focus, but might be invalid
		// Validate Control, without changing the Controls Text
		fValid = ValidateControl();

	// Scrolling from associated CEditSpinButtonCtrl ?
	switch (nSBCode) 
	{
	case SB_LINEUP:
		m_iValue = ((m_iValue/m_iStep)+1)*m_iStep;
		if (m_iValue>m_iMax)
			m_iValue = m_iMax;
		break;
	case SB_LINEDOWN:
		m_iValue = ((m_iValue+(m_iStep-1)*((m_iValue>=0) ? 1 : -1))/m_iStep-1)*m_iStep;
		if (m_iValue<m_iMin)
			m_iValue = m_iMin;
		break;
	}
	// Need to reformat (redisplay) ?
	if (!fValid || m_iValue!=iOldValue) 
	{
		// Display new contents
		FormatControl(formatAndNotify);           
		// Select the complete Contents
		SetSel(0,-1);
	}		
}


void CEditInt::OnHScroll(UINT nSBCode, UINT nPos, CScrollBar* pScrollBar)
{
	OnVScroll(nSBCode, nPos, pScrollBar);
}                                                                            

void AFXAPI DDX_EditInt(CDataExchange* pDX, int nIDC, int &iValue)
{
	// Get pointer to control
	HWND hWndCtrl = pDX->PrepareEditCtrl(nIDC); 	
	CEditInt *pWnd = (CEditInt *)CWnd::FromHandle(hWndCtrl);
	// Must be CEditDate	
	ASSERT(pWnd->IsKindOf(RUNTIME_CLASS(CEditInt)));
	// get the Information from the defined Window 	
	if (pDX->m_bSaveAndValidate) 
		// Get the Value
		iValue = pWnd->GetValue();
	else 
		pWnd->SetValue(iValue);		
}

void AFXAPI DDX_EditInt(CDataExchange* pDX, int nIDC, long &lValue)
{
	int iValue = lValue;
	DDX_EditInt(pDX, nIDC, iValue);
	lValue = iValue;
}

//-----------------------------------------------------------------------------

IMPLEMENT_DYNCREATE(CEditDouble, CEditBase)

CEditDouble::CEditDouble(int iPrecission)
	: m_fStep(1)
	, m_fValue(0)
{               
	// Nachkommastellen merken   
	SetPrecision(iPrecission);
}

CEditDouble::~CEditDouble()
{
}

const int CEditDouble::m_cMaxInputLength = MAX_NUMERIC_LENGTH;

BEGIN_MESSAGE_MAP(CEditDouble, CEditBase)
	ON_WM_CHAR()
	ON_WM_VSCROLL()
	ON_WM_HSCROLL()
END_MESSAGE_MAP()

BOOL CEditDouble::SubclassDlgItem(UINT nID, CWnd* pParent, int iPrecision)
{                             
	// Preset the Values
	SetPrecision(iPrecision);
	return CEditBase::SubclassDlgItem(nID,pParent);	
}

void CEditDouble::SetValue(double fValue)
{
	// Save the value in the internal Storage
	m_fValue = max(m_fMin,fValue);
	m_fValue = min(m_fMax,m_fValue);
	// Control ausgeben
	FormatControl(formatDoNotNotify);
}

double CEditDouble::SetStepValue(double fValue)
{
	double fOld=m_fStep;
	m_fStep = fValue;
	return fOld;
}

double CEditDouble::GetValue()
{
	// Need to reformat ?
	if (IsDirty())
		// Get internal Value (never reformat)
		ValidateControl();
	// Return internal Value
	return m_fValue;			
}


int CEditDouble::SetPrecision(int iPrecision)
{
	int iOldPrec = m_iPrecision;
	m_iPrecision   = iPrecision;          
	if (m_iPrecision==-1)
		m_iPrecision = 2;
	SetMinMaxDefault();
	ReformatControl();	
	return iOldPrec;
}

void CEditDouble::SetMinMaxDefault()
{
	// Must be room for a sign, for the digits and a decimal point
	ASSERT(1+MAX_SIGFLOAT_DIGITS+1<=m_cMaxInputLength);
	// Maximale Zahl bei 0 Nachkomma stellen
	m_fMax=1;
	for (int i=0; i<MAX_SIGFLOAT_DIGITS; ++i)
		m_fMax *= 10;
	// Wert korrigieren um 999.99 Wert zu erhalten, sowie negativ Startwert
	m_fMin = -m_fMax;
	--m_fMax;
	++m_fMin;
	if (m_iPrecision>=0) 
	{
		for (int i=0; i<m_iPrecision; ++i)
		{
			m_fMax /= 10;
			m_fMin /= 10;
		}
	}
	// merke dir die maximal und minmal Zahl, aber Runde bitte
	m_fMin = RoundDouble(m_fMin,m_iPrecision);
	m_fMax = RoundDouble(m_fMax,m_iPrecision);
}

void CEditDouble::SetMinMax(double fMin, double fMax)
{
	m_fMin = RoundDouble(fMin,m_iPrecision);
	m_fMax = RoundDouble(fMax,m_iPrecision);    
	ASSERT(m_fMin<=m_fMax);
}

void CEditDouble::GetMinMax(double &fMin, double &fMax)
{
	fMin = m_fMin;
	fMax = m_fMax;
}

void CEditDouble::InitControl()
{
	LimitText(m_cMaxInputLength);
}                               

bool CEditDouble::IsValid()
{             
	TCHAR szText[m_cMaxInputLength+1];	
	// Get the value from the control     
	GetWindowText(szText,_countof(szText));
	// Convert the Number	
	double fValue = StringToDouble(szText);
	double fValueOrg = fValue;		
	// Minima and maxima
	fValue = max(m_fMin,fValue);
	fValue = min(m_fMax,fValue);
	// Return result if Control is realy Valid (no min/max error etc.)		
	return fValue==fValueOrg;
}


bool CEditDouble::ValidateControl()
{             
	TCHAR szText[m_cMaxInputLength+1];	
	// Get the value from the control     
	GetWindowText(szText,_countof(szText));
	// Convert the Number	
	m_fValue = StringToDouble(szText);
	double fValueOrg = m_fValue;		
	// Minima and maxima
	m_fValue = max(m_fMin,m_fValue);
	m_fValue = min(m_fMax,m_fValue);	
	// Return result if Control is realy Valid (no min/max error etc.)		
	return m_fValue==fValueOrg;
}


void CEditDouble::PrepareEditText()
{
	TCHAR szText[m_cMaxInputLength+1];	
	// Get the value from the control     
	GetWindowText(szText,_countof(szText));
	CString strText = DoubleToString(StringToDouble(szText),-1);
	// Reformat but do not notify	
	SmartSetWindowText(szText,TRUE);
	SetSel(0,-1);
}

void CEditDouble::FormatControl(eFormatControl eFlag)
{	                        
	// reformat the text
	CString strText;
	// Konvertiere in Ascii-Text	
	if (m_fValue==0 && m_hWnd==::GetFocus() && GetWindowTextLength()==0)
		;
	else		
		strText = DoubleToString(m_fValue,m_iPrecision);	

	// save settext              
	if (eFlag!=formatAndNotify)            
		SmartSetWindowText(strText,eFlag==formatDoNotNotify);
	else
		SetWindowText(strText);	
	// Do the Default
	CEditBase::FormatControl(eFlag);
}

void CEditDouble::OnChar(UINT nChar, UINT nRepCnt, UINT nFlags)
{
	// Allow control chars, numbers and the minus sign if allowed
	if (nChar<0x20 || 
		(_istdigit((TCHAR)nChar)) ||
		(m_fMin<0 && nChar==_T('-')))
		// Ok this character is correct	
		CEditBase::OnChar(nChar, nRepCnt, nFlags);	
	else if (m_iPrecision!=0 && _istpunct((TCHAR)nChar))
	{		
		// Punctations
		TCHAR szText[m_cMaxInputLength+1];	
		GetWindowText(szText,_countof(szText));
		// count the punctations
		int i, j;
		for (i=0,j=0; szText[i]; ++i)
		{
			if (szText[i]!=_T('-') && _istpunct(szText[i]))
				++j;
		}
		/// Ignore if already 1 delimiters
		if (j>=1)
			return;		
		// Convert to decimal Point
		CEditBase::OnChar(_T('.'), nRepCnt, nFlags);
	} 
	else
		// Beep wegen Fehler
		MessageBeep((UINT)-1);		
}


void CEditDouble::OnVScroll(UINT nSBCode, UINT nPos, CScrollBar* pScrollBar)
{                
	// If no stepping exit
	if (!m_fStep)
		return;
	// Save old value    
	double  fOldValue = m_fValue;
	BOOL	fValid;	

	// Set Focus if need to, avoid flickering
	if (GetFocus()!=this) 
	{
		// the contents might be invalid
		if (IsDirty())
			ValidateControl();	
		SetFocus();	   
		// After this the contents is always valid
		fValid = TRUE;
	} 
	else 		
		// The control has the focus, but might be invalid
		// Validate Control, without changing the Controls Text
		fValid = ValidateControl();

	// Scrolling from associated CEditSpinButtonCtrl ?
	switch (nSBCode) 
	{
	case SB_LINEUP:			                        
		m_fValue = RoundDouble(((int)(m_fValue/m_fStep)+1)*m_fStep,m_iPrecision);
		if (m_fValue>m_fMax)
			m_fValue = m_fMax;
		else
			break;
	case SB_LINEDOWN:
		m_fValue = RoundDouble((((int)(m_fValue*2/m_fStep)+1)/2-1)*m_fStep,m_iPrecision);
		if (m_fValue<m_fMin)
			m_fValue = m_fMin;
		break;
	}
	// Need to reformat (redisplay) ?
	if (!fValid || m_fValue!=fOldValue)
	{
		// Display new contents
		FormatControl(formatAndNotify);           
		// Select the complete Contents
		SetSel(0,-1);
	}		
}

void CEditDouble::OnHScroll(UINT nSBCode, UINT nPos, CScrollBar* pScrollBar)
{
	OnVScroll(nSBCode, nPos, pScrollBar);
}                                                                            

void AFXAPI DDX_EditDouble(CDataExchange* pDX, int nIDC, double &dValue)
{
	// Get pointer to control
	HWND hWndCtrl = pDX->PrepareEditCtrl(nIDC); 	
	CEditDouble *pWnd = (CEditDouble *)CWnd::FromHandle(hWndCtrl);
	// Must be CEditDate	
	ASSERT(pWnd->IsKindOf(RUNTIME_CLASS(CEditDouble)));
	// get the Information from the defined Window 	
	if (pDX->m_bSaveAndValidate) 
		// Get the Value
		dValue = pWnd->GetValue();
	else 
		pWnd->SetValue(dValue);		
}

//-----------------------------------------------------------------------------

CEditText::CEditText(int iLimitTextLength, UINT uiStyle)
{                          
	m_cInputLength 	= iLimitTextLength;
	m_iEditType		= uiStyle;
}

CEditText::~CEditText()
{
}

IMPLEMENT_DYNCREATE(CEditText, CEditBase)


BEGIN_MESSAGE_MAP(CEditText, CEditBase)
	ON_MESSAGE(EM_LIMITTEXT,OnLimitText)	
	ON_MESSAGE(WM_PASTE,OnPaste)
	ON_WM_CHAR()
END_MESSAGE_MAP()


BOOL CEditText::SubclassDlgItem(UINT nID, CWnd* pParent, int iLimitTextLength, UINT uiStyle)
{                   
	// Preset the Values
	m_cInputLength 	= iLimitTextLength;
	m_iEditType		= uiStyle;
	return CEditBase::SubclassDlgItem(nID,pParent);
}

LPARAM CEditText::OnLimitText(WPARAM wParam, LPARAM lParam)
{                       
	m_cInputLength = static_cast<int>(wParam);		
	return Default();
}                      

void CEditText::OnChar(UINT nChar, UINT nRepCnt, UINT nFlags)
{   
	// Allow all control chars and call the filter function
	// We need to cast it to _TUCHAR because if the character is >127 it is sign
	// extended. Under W2K there might be that problem that the change of nChar from 0xE4
	// to 0xFFFFFFE4 produces some ghost characters. We can not see this under XP.
	if (nChar<0x20 ||
		(nChar=static_cast<_TUCHAR>(Filter(static_cast<TCHAR>(nChar)))))
		// Ok this character is correct	
		CEditBase::OnChar(nChar, nRepCnt, nFlags);	
	else
		// Beep wegen Fehler
		MessageBeep((UINT)-1);
}

LPARAM CEditText::OnPaste(WPARAM /*wParam*/, LPARAM /*lParam*/)
{
	// Need an explicit check if we are read only! It seams that Ctrl+V and Shift+Ins
	// have different handling. Ctrl+V doesn't cause WM_PASTE to be send to the
	// control. But Shift+Ins does.
	if ((GetStyle() & ES_READONLY)!=0)	
		return 0;

	// Check if we have a Text format available
	if (!::IsClipboardFormatAvailable(_TCF_TEXT))
		return 0;

	// Get the data from the clipboard
    if (!OpenClipboard()) 
        return 0; 
   
    HGLOBAL hglb = ::GetClipboardData(_TCF_TEXT); 
    if (hglb!=NULL) 
    { 
        CString str(static_cast<LPCTSTR>(::GlobalLock(hglb))); 
		// Check for single line edit control
		if ((GetStyle() & ES_MULTILINE)==0)
		{
			// Find terminating line feed for single edit controls.
			int iLen = str.FindOneOf(_T("\r\n"));
			if (iLen!=-1)
				str.GetBufferSetLength(iLen);
		}

        // Call the ReplaceSel function to insert the text and repaint the window.
		// but just with the filtered text.
		ReplaceSel(Filter(str),TRUE);
        ::GlobalUnlock(hglb); 
    } 
    ::CloseClipboard(); 

	// Done
	return 0;
}

TCHAR CEditText::Filter(TCHAR c)
{   	
#ifdef _UNICODE
	// Unicode Space berücksichtigen
	if (IsUnicodeSpace(c))
		c = _T(' ');
#endif 

	// If this character is explicitly not allowed we stop here.
	// If it is allowed it must match the other styles too!
	if (!m_strAllowedChars.IsEmpty() && m_strAllowedChars.Find(c)==-1)
		// Character is not in the list.
		return _T('\0');
	// Check if disallowed char
	if (m_strDisallowedChars.Find(c)!=-1)
		// Character is in the list and not allowed.
		return _T('\0');

	// Check for special control chars. 
	if (_tcschr(_T("\x7f\n\r\t\b\f\a"),c)!=NULL)
		return _T('\0');

	// Need Uppercase ?
	if (IsCharAlpha(c) && (m_iEditType & fTypeUpperCase)!=0)
		c = static_cast<TCHAR>(reinterpret_cast<DWORD_PTR>(CharUpper(reinterpret_cast<LPTSTR>((TCHAR)c))));

	// check all others
	if (_istascii(c) && _istspace(c))     
		return (m_iEditType & fTypeSpaces) ? c : _T('\0');	
	
	if (IsCharAlpha(c)) 
		return (m_iEditType & fTypeAlpha) ? c : _T('\0');	
	
	if (c>=_T('0') && c<=_T('9'))
		return (m_iEditType & fTypeNumeric) ? c : _T('\0');	
	
	if (c==_T('_')) 
		return (m_iEditType & fTypeUnderscore) ? c : _T('\0');
	
	if (_istpunct(c))
		return (m_iEditType & fTypePunct) ? c : _T('\0');	
	
	if (_tcschr(_T("§°€²³"),c))
		// Eurozeichen etc.
		return (m_iEditType & fTypeSpecial) ? c : _T('\0');
	
	if ((m_iEditType & fTypeAll)==fTypeAll)
	{
#ifdef _UNICODE
		// We don't allow unicode characters from the "Private Use Area"
		if (HIBYTE(c) >= 0xE0 && HIBYTE(c) <= 0xF8)
			// this is the standard replacement char.
			// https://en.wikipedia.org/wiki/Specials_(Unicode_block)
			c = 0xFFFD;
#endif
		return c;
	}
	
	// failed
	return 0;
}

CString CEditText::Filter(PCTSTR pszStr)
{
	// Erzeuge maximalen String                             
	int l = static_cast<int>(_tcslen(pszStr));
	if (m_cInputLength && l>m_cInputLength)
		l = m_cInputLength;

	// Länge begrenzen	
	CString sString;
	PTSTR 	pBuff = sString.GetBuffer(l);
	TCHAR 	c;

	// Remove Spaces 
	while (l-- && pszStr) 
	{
		// Nimm das nächste Zeichen
		if ((c = Filter(*pszStr))!=0) 
			*pBuff++ = c;
		++pszStr;
	}
	*pBuff = _T('\0');	
	sString.ReleaseBuffer();

	// und exit
	return sString;	
}
void CEditText::SetValue(PCTSTR pszStr)
{
	// Control ausgeben
	SmartSetWindowText(Filter(pszStr),TRUE);
	FormatControl(formatDoNotNotify);
}


CString CEditText::GetValue()
{
	CString	sValue;
	// Need to reformat ?
	if (IsDirty())
		// Get internal Value (never reformat)
		ValidateControl();
	// Hole den Fenster Text
	GetWindowText(sValue);
	return sValue;
}

void CEditText::SetAllowedCharList(PCTSTR pszAllowedChars)
{
	m_strAllowedChars = pszAllowedChars;
}

const CString &CEditText::GetAllowedCharList()
{
	return m_strAllowedChars;
}

void CEditText::SetDisallowedCharList(PCTSTR pszDisallowedChars)
{
	m_strDisallowedChars = pszDisallowedChars;
}

const CString &CEditText::GetDisallowedCharList()
{
	return m_strDisallowedChars;
}

void CEditText::InitControl()
{   
	if (m_cInputLength)
		LimitText(m_cInputLength);
}                               


bool CEditText::IsValid()
{   
	// Lade den text
	CString sOrg;
	GetWindowText(sOrg);
	// Filter durchführen und kontrollieren	
	return sOrg==Filter(sOrg);
}


bool CEditText::ValidateControl()
{       
	// Lade den text
	CString sOrg;
	GetWindowText(sOrg);
	// Check if we need to apply any filter, usually this is not
	// needed, because the WM_CHAR handler does most of the job
	CString sFilter = Filter(sOrg);
	/* Copy new text back to control. Note that for long text contents
	* SmartSetWindowText always copyies the data, this causes the insert position
	* to get lost */
	if (sFilter!=sOrg)
	{
		// Strange, strange, the filter found some mismatching chars! How that?
		// So try to keep the previous position.
		DWORD dwPos = GetSel();
		SmartSetWindowText(sFilter, true);   
		SetSel(dwPos);
	}
	// Any changes
	return sOrg==sFilter;
}
