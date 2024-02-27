import winim
import strutils , strformat
type
  WLAN_INTERFACE_STATE = enum
    wlan_interface_state_not_ready = 0,
    wlan_interface_state_connected = 1,
    wlan_interface_state_ad_hoc_network_formed = 2,
    wlan_interface_state_disconnecting = 3,
    wlan_interface_state_disconnected = 4,
    wlan_interface_state_associating = 5,
    wlan_interface_state_discovering = 6,
    wlan_interface_state_authenticating = 7

  WLAN_INTERFACE_INFO = object
    InterfaceGuid: GUID
    strInterfaceDescription: array[256, WCHAR]
    isState: WLAN_INTERFACE_STATE

  WLAN_INTERFACE_INFO_LIST = object
    dwNumberOfItems: DWORD
    dwIndex: DWORD
    InterfaceInfo: array[10, WLAN_INTERFACE_INFO]
  WLAN_PROFILE_INFO = object
    strProfileName: array[256,WCHAR]
    dwFlags: DWORD
  WLAN_PROFILE_INFO_LIST = object
    dwNumberOfItems: DWORD
    dwIndex: DWORD
    ProfileInfo: array[10,WLAN_PROFILE_INFO]

  PWLAN_INTERFACE_INFO_LIST = ptr WLAN_INTERFACE_INFO_LIST

proc WlanOpenHandle(dwClientVersion: DWORD, pReserved: PVOID, pdwNegotiatedVersion: PDWORD, phClientHandle: PHANDLE): DWORD {.importc, dynlib: "wlanapi", stdcall.}

proc WlanEnumInterfaces(
  hClientHandle: HANDLE, pReserved: PVOID, ppInterfaceList: ptr PWLAN_INTERFACE_INFO_LIST
): DWORD {.importc, dynlib: "wlanapi", stdcall.}

proc WlanGetProfileList(
  hClientHandle: HANDLE, pInterfaceGuid: ptr GUID, pReserved: PVOID,
  ppInterfaceList: ptr ptr WLAN_PROFILE_INFO_LIST
): DWORD {.importc, dynlib: "wlanapi", stdcall.}

proc WlanGetProfile(
    hClientHandle: HANDLE, pInterfaceGuid: ptr GUID, strProfileName : LPCWSTR, pReserved: PVOID , pstrProfileXml : ptr LPWSTR , pdwFlags : ptr DWORD , pdwGrantedAccess : ptr DWORD): DWORD {.importc, dynlib: "wlanapi", stdcall.}

proc getStringFromWide(wca : array[256,WCHAR]): string =
    var final : string = ""
    for byte in wca:
        add(final , chr(byte))
    return final

var WLAN_PROFILE_GET_PLAINTEXT_KEY : DWORD = 0x04.DWORD
var negVersion: DWORD = 0.DWORD
var hClient: HANDLE
var res = WlanOpenHandle(
  1.DWORD, NULL, addr negVersion, addr hClient
)

#echo("WlanOpenHandle Result: ", res)

var interfacesList: ptr WLAN_INTERFACE_INFO_LIST
var res2 = WlanEnumInterfaces(
  hClient, NULL, addr interfacesList
)
#echo("WlanEnumInterfaces Result: ", res2)

for i in 0 .. int(interfacesList.dwNumberOfItems) - 1:
  let interf = interfacesList.InterfaceInfo[i]
  echo(getStringFromWide(interf.strInterfaceDescription))
  let guid = interf.InterfaceGuid
  var profileList : ptr WLAN_PROFILE_INFO_LIST
  var res3 = WlanGetProfileList(
    hClient,
    addr guid,
    NULL,
    addr profileList
  )
  #echo(res3)
  for x in 0..int(profileList.dwNumberOfItems) - 1:
    let profile = profileList.ProfileInfo[x]
    let profile_name = getStringFromWide(profile.strProfileName)
    var xmlData : LPWSTR
    var res5 = WlanGetProfile(
        hClient,
        addr guid,
        newWideCString(profile_name),
        NULL,
        addr xmlData,
        addr WLAN_PROFILE_GET_PLAINTEXT_KEY,
        cast[ptr DWORD](NULL)
    )
    let clean_name = profile_name.replace("\0","")
    let file = open(fmt"{clean_name}.xml" , fmWrite)
    file.write($xmlData)

    