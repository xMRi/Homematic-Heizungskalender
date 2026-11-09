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
#include "Helper.h"
#include <list>
#include <map>
#include <set>

//-----------------------------------------------------------------------------

template<class TData> 
class TDataList : public std::list<TData>
{
public:
	using TBaseClass = list<TData>; 
	using TBaseClass::TBaseClass;
	// Achtung Test ist case sensitive
	TData* Find(CString const& strName)
	{
		for (auto& e : *this)
		{
			if (!e.m_bDeleted && e.m_strName==strName)
				return &e;
		}
		return nullptr;
	}
};

class CDataEntry
{
public:
	CDataEntry(){}
	bool m_bNew{false},
		 m_bModified{false},
		 m_bDeleted{false};
};

//-----------------------------------------------------------------------------

enum class DataType { 
	// Von Homematic Doku
	vtUnknown = 0,
	vtboolean = 2,
	vtInteger = 4,		// In fact it is a real
	// vtReal = 3,
	vtString = 20,
	// vtTime = 5,
};

class CDataSystemVariable : public CDataEntry
{
public:
	CDataSystemVariable()
	{
	}
	CDataSystemVariable(CString const& strLine);
	CDataSystemVariable(int id,CString const& strName,CString const& strContent,CString const& strDescription,
						DataType dt,bool bProtocoll,bool bVisible);

	int		m_id{};
	CString m_strName;
	CString m_strContent;
	CString m_strContentOld;
	CString m_strDescription;
	DataType m_dataType{ DataType::vtUnknown };
	bool m_bModifiedName{false},
		 m_bProtocoll{false}, 
		 m_bVisible{false};		

	// Funktionen
	void ClearContent()
	{
		SetContent(CString{});
	}

	void SetContent(CString const& str);

	CString GetDataAsLine();
	void InitNeuerRaum(CString const &strName);
};

//-----------------------------------------------------------------------------

struct SRaumDaten
{
	CString m_strName;
	CString m_strMode;
	double m_dblTemp{};
	double m_dblTempG{};
	int m_iVBegin{};
	int m_iVEnde{};
	int m_iVMininum{};
	double m_dblFaktor{};
	CString m_strDevTyp;
	CString m_strAktor;

	SRaumDaten()
	{ }
	SRaumDaten(const CString& strName, const CString& str)
	{
		LoadFromString(strName,str);
	}
	void LoadFromString(CString const &strName, CString const &str);
	void GetAsString(CString &strName, CString &str);
};

//-----------------------------------------------------------------------------

class CListSystemVariables : public TDataList<CDataSystemVariable>
{
public:
	// using TDataList<CDataSystemVariable>::TDataList<CDataSystemVariable>;
	void LoadFromString(CStringA const &strOut);
};

//-----------------------------------------------------------------------------

class CDataProgram : public CDataEntry
{
public:
	CDataProgram(CString const& strLine);
	CDataProgram(
		int id,
		CString const& strName,
		CString const& strDescription
	) : m_id{ id }
		, m_strName{ strName }
		, m_strProgBeschreibung{ strDescription }
	{
	}

	int		m_id{};
	CString m_strName;				// Name des Programmes in der CCU
	CString m_strProgBeschreibung;	// Beschreibung im Programmkopf der CCU
	COleDateTime	m_date{ 0.0 };	// Stanbddatum
	bool	 m_bActive{};			// Flag ob das Programm aktiv ist

	CString m_strSkriptBeschreibung; // Zeile 1
	CStringA m_strSkript;			// Das Skript selbst bzw. neues Skript das gespeichert werden soll
									// Wird hier durch UpdatePrograms ersetzt. 
	CStringA m_strSkriptAlt;		// Kopie des alten Skripts bevor UpdatePrograms läuft. (Benötigt um Änderungen zu erkennen)
	CDataProgram* m_pAppProg{};		// Referenz auf das Applikationsprogramm (m_lstAppPrograms),
									// dass für ein Update benutzt wird. Sonst nullptr
	CString GetDataAsLine();
};

//-----------------------------------------------------------------------------

enum class ChannelType
{
	ictUnknown =0,
	ictHSS = 17, 
	ictWeatherStation = 22,
	ictHSSBinaryActuator = 3, 
	ictBinaryActuator = 26,
};

enum class Operation
{
	OPERATION_READ = 1,
	OPERATION_WRITE = 2,
	OPERATION_EVENT = 4,
};

class CDataDevice : public CDataEntry
{
public:
	CDataDevice(CString const& strLine);

	CString		m_strName;			// Benutzer Channel Name!
	CString		m_strDevName;
	CString		m_strDevType;
	CString		m_strDataPoint;
	ChannelType	m_channelType{ChannelType::ictUnknown};
	int			m_operations{ 0 };

	bool ChannelTypeHeizung() const		{ return m_channelType==ChannelType::ictHSS || m_channelType==ChannelType::ictWeatherStation; }
	bool ChannelTypeWeatherStation() const		{ return m_channelType==ChannelType::ictWeatherStation; }
	bool ChannelTypeSchalten() const	{ return !ChannelTypeHeizung(); }
	
	CString GetDataPointName() const
	{
		int iPos = m_strDataPoint.ReverseFind(_T('.'));
		if (iPos>=0)
			return m_strDataPoint.Mid(iPos+1);
		else
			return m_strDataPoint;
	}
	bool IsActualTemperature() const
	{
		auto const dpName = GetDataPointName();
		return dpName==_T("ACTUAL_TEMPERATURE") || dpName==_T("TEMPERATURE");
	}
	bool IsState() const
	{
		return GetDataPointName()==_T("STATE");
	}
	bool IsSetPointTemperature() const
	{
		auto const dpName = GetDataPointName();
		return dpName==_T("SET_POINT_TEMPERATURE") || dpName==_T("SET_TEMPERATURE") || dpName==_T("SETPOINT");
	}
	bool CanWrite() const
	{
		return m_operations & static_cast<int>(Operation::OPERATION_WRITE);
	}
	bool CanRead() const
	{
		return m_operations & static_cast<int>(Operation::OPERATION_READ);
	}
	CString GetDataAsLine();
};

//-----------------------------------------------------------------------------

class CListPrograms : public TDataList<CDataProgram>
{
public:
	// using TDataList<CDataProgram>::TDataList<CDataProgram>;
	void LoadFromString(CStringA const &strOut);
};

//-----------------------------------------------------------------------------

class CListDevices : public TDataList<CDataDevice>
{
public:
	// using TDataList<CDataProgram>::TDataList<CDataProgram>;
	void LoadFromString(CStringA const &strOut);
};


//-----------------------------------------------------------------------------

// Map von Ressource auf Raumliste. Die numerischen Ressourcen sollen
// logisch sortiert werden, d,h, 10 kommt nach 2.
struct SRaumDesc
{
	CString m_strResourceName;
	std::list<CString> m_lstRaeume;
};
using CMapRaumListe = std::map<CString,SRaumDesc,COMPARE_LOGICAL>;
