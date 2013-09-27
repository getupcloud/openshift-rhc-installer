; Script generated by the HM NIS Edit Script Wizard.
SetCompressor /SOLID lzma

; HM NIS Edit Wizard helper defines
!define PRODUCT_NAME "OpenShift-RHC"
!define PRODUCT_VERSION "1.0.1-1"
!define PRODUCT_PUBLISHER "OpenShift Origin"
!define PRODUCT_WEB_SITE "http://github.com/openshift/rhc/"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\${PRODUCT_NAME}"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"
!define GIT_INSTALLER "Git-1.8.1.2-preview20130201.exe"
!define RUBY_INSTALLER "rubyinstaller-1.9.3-p429.exe"

; MUI 1.67 compatible ------
!include "MUI.nsh"
!include LogicLib.nsh
!include nsDialogs.nsh

!addincludedir .\include
!include EnvVarUpdate.nsh

; MUI Settings
!define MUI_ABORTWARNING
!define MUI_ICON "openshift.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"

; Language Selection Dialog Settings
!define MUI_LANGDLL_REGISTRY_ROOT "${PRODUCT_UNINST_ROOT_KEY}"
!define MUI_LANGDLL_REGISTRY_KEY "${PRODUCT_UNINST_KEY}"
!define MUI_LANGDLL_REGISTRY_VALUENAME "NSIS:Language"

; Welcome page
!insertmacro MUI_PAGE_WELCOME
; License page
!insertmacro MUI_PAGE_LICENSE "LICENSE"
; Directory page
!insertmacro MUI_PAGE_DIRECTORY

Page custom proxyPage proxyPageLeave
Page custom libraServerPage libraServerPageLeave

; Instfiles page
!insertmacro MUI_PAGE_INSTFILES
  ; Finish page
  !define MUI_FINISHPAGE_RUN
  !define MUI_FINISHPAGE_RUN_TEXT "Run Initial RHC Setup (recomended)"
  !define MUI_FINISHPAGE_RUN_FUNCTION "RHC_Setup"
!insertmacro MUI_PAGE_FINISH

Var fullname
Var rhlogin
#Var password
Var libraServerURL

Function RHC_Setup
  ExecWait '"$PROGRAMFILES\git\bin\git.exe" config --global user.name "$fullname"'
  ExecWait '"$PROGRAMFILES\git\bin\git.exe" config --global user.email "$rhlogin"'
  ExecWait '"$PROGRAMFILES\git\bin\git.exe" config --global push.default simple"'

  # First wee need to find out if it is safe to exec() passing password as a parameter
  # since it may be logged by nsis somewhere.
  #ExecWait '"$PROGRAMFILES\git\bin\sh" -c "rhc setup --create-token --server \"$libraServerURL\" --rhlogin \"$rhlogin\" --password \"$password\""'
  ExecWait '"$PROGRAMFILES\git\bin\sh" -c "rhc setup --create-token --server \"$libraServerURL\" --rhlogin \"$rhlogin\""'

  MessageBox MB_OK 'Installation has finished. Now, run "Git Bash" and execute "rhc --help" to start the game ;)'
FunctionEnd

; Uninstaller pages
!insertmacro MUI_UNPAGE_INSTFILES

; Language files
!insertmacro MUI_LANGUAGE "English"

; include for some of the windows messages defines
!include "winmessages.nsh"
; HKLM (all users) vs HKCU (current user) defines
!define env_hklm 'HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"'
!define env_hkcu 'HKCU "Environment"'

; MUI end ------

Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "Install.exe"
XPStyle on

InstallDir "$PROGRAMFILES\${PRODUCT_NAME}"
InstallDirRegKey HKLM "${PRODUCT_DIR_REGKEY}" ""
ShowInstDetails show
ShowUnInstDetails show

Var HTTP_PROXY
Var proxyDialog
Var proxyLabel
Var proxyTextBox
Var proxyCheckbox

; dialog create function
Function proxyPage
  
  ; === libra_server (type: Dialog) ===
  nsDialogs::Create 1018
  Pop $proxyDialog
  ${If} $proxyDialog == error
    Abort
  ${EndIf}
  !insertmacro MUI_HEADER_TEXT "Configure HTTP Proxy (for gem install)" ""
  
  ; === Label ===
  ${NSD_CreateLabel} 8u 5u 200u 9u "Are you behind a HTTP Proxy server?"
  ${NSD_CreateLabel} 8u 15u 200u 9u "If unsure or connected from home, it's safe to leave it blank."
  Pop $proxyLabel
 
  ; === TextBox ===
  ${NSD_CreateText} 8u 26u 124u 11u ""
  Pop $proxyTextBox
  
  ; === Checkbox ===
  ${NSD_CreateCheckbox} 8u 42u 250u 11u " OpenShift Server is inside my local network (non-proxied)"
  Pop $proxyCheckbox
  nsDialogs::Show $proxyDialog
FunctionEnd

; dialog leave function
Function proxyPageLeave
  ${NSD_GetText} $proxyTextBox $HTTP_PROXY 
  
  ${NSD_GetState} $proxyCheckbox $0
  ${If} $0 <> 0
	WriteRegExpandStr ${env_hklm} "LIBRA_SERVER_PROXY" "$HTTP_PROXY"
  ${Else}
	WriteRegExpandStr ${env_hklm} "LIBRA_SERVER_PROXY" ""
  ${EndIf}
FunctionEnd

Var libraServerDialog
Var libraServerLabel
Var getupLibraServerRadio
Var redhatLibraServerRadio
Var customLibraServerRadio
Var customLibraServerTextBox
Var fullnameTextBox
Var rhloginTextBox
#Var passwordTextBox

; dialog create function
Function libraServerPage
  
  ; === libra_server (type: Dialog) ===
  nsDialogs::Create 1018
  Pop $libraServerDialog
  ${If} $libraServerDialog == error
    Abort
  ${EndIf}
  !insertmacro MUI_HEADER_TEXT "Configure OpenShift RHC" ""
  
  ${NSD_CreateLabel} 8u 3u 91u 11u "OpenShift Broker URL:"
  Pop $libraServerLabel

  ${NSD_CreateRadioButton} 8u 16u 300u 11u "Getup Cloud's OpenShift - https://broker.getupcloud.com"
  Pop $getupLibraServerRadio
  ${NSD_Check} $getupLibraServerRadio

  ${NSD_CreateRadioButton} 8u 32u 300u 11u "Red Hat's OpenShift Online - https://openshift.redhat.com"
  Pop $redhatLibraServerRadio

  ${NSD_CreateRadioButton} 8u 48u 38u 11u "Custom:"
  Pop $customLibraServerRadio
  ${NSD_CreateText} 50u 48u 155u 11u ""
  Pop $customLibraServerTextBox
  ${NSD_OnChange} $customLibraServerTextBox Custom_Libra_Server_Radio_Changed

  ${NSD_CreateHLine} 8u 70u 200u 11u
  ; ---------------------------------------- ;

  ExpandEnvStrings $fullname "%USERNAME%"
  ${NSD_CreateLabel} 8u 82u 72u 11u "Your Name"
  Pop $0
  ${NSD_CreateText}  80u 82u 125u 11u $fullname
  Pop $fullnameTextBox

  ${NSD_CreateLabel} 8u 98u 72u 11u "OpenShift Login"
  Pop $0
  ${NSD_CreateText}  80u 98u 125u 11u ""
  Pop $rhloginTextBox

  #${NSD_CreateLabel}    8u 114u 72u 11u "OpenShift Password"
  #Pop $0
  #${NSD_CreatePassword} 80u 114u 125u 11u ""
  #Pop $passwordTextBox

  ${NSD_SetFocus} $getupLibraServerRadio
  nsDialogs::Show $libraServerDialog
FunctionEnd

Function Custom_Libra_Server_Radio_Changed
	${NSD_Check}   $customLibraServerRadio
	${NSD_Uncheck} $getupLibraServerRadio
	${NSD_Uncheck} $redhatLibraServerRadio
FunctionEnd

; dialog leave function
Function libraServerPageLeave

  ${NSD_GetText} $customLibraServerTextBox $libraServerURL

  ${NSD_GetState} $getupLibraServerRadio $0
  ${If} $0 == ${BST_CHECKED}
    StrCpy $libraServerURL "https://broker.getupcloud.com"
  ${EndIf}

  ${NSD_GetState} $redhatLibraServerRadio $0
  ${If} $0 == ${BST_CHECKED}
    StrCpy $libraServerURL "https://openshift.redhat.com"
  ${EndIf}

  ${NSD_GetState} $customLibraServerRadio $0
  ${If} $0 == ${BST_CHECKED}
    ${NSD_GetText} $customLibraServerTextBox $libraServerURL
  ${EndIf}

  ${If} $libraServerURL == ""
    MessageBox MB_OK "Please, select one or insert a valid OpenShift broker URL."
    Abort
  ${EndIf}

  ${NSD_GetText} $fullnameTextBox $fullname
  ${If} $fullname == ""
    MessageBox MB_OK "Please, inform your name."
    ${NSD_SetFocus} $fullnameTextBox
    Abort
  ${EndIf}

  ${NSD_GetText} $rhloginTextBox $rhlogin
  ${If} $rhlogin == ""
    MessageBox MB_OK "Please, inform your login."
    ${NSD_SetFocus} $rhloginTextBox
    Abort
  ${EndIf}

  #${NSD_GetText} $passwordTextBox $password
  #${If} $password == ""
  #  MessageBox MB_OK "Please, inform your password."
  #  ${NSD_SetFocus} $passwordTextBox
  #  Abort
  #${EndIf}

  #MessageBox MB_OK "server: [$libraServerURL], name: [$fullname], login: [$rhlogin], passwd: [$password]"

  ; set variable
  WriteRegExpandStr ${env_hklm} "LIBRA_SERVER" "$libraServerURL"
FunctionEnd

Function .onInit
  !insertmacro MUI_LANGDLL_DISPLAY
FunctionEnd

Section "copy files" SEC01
  SetOutPath "$INSTDIR"
  SetOverwrite ifnewer
  File "rhc"
  File "rhc.bat"
  File "openshift.ico"
  CreateDirectory "$SMPROGRAMS\OpenShift"
  CreateShortCut "$SMPROGRAMS\OpenShift\rhc.lnk" "$INSTDIR\rhc.bat"
  CreateShortCut "$DESKTOP\rhc.lnk" "$INSTDIR\rhc.bat"
SectionEnd

Var status
Section "install git bash" SEC02
  SetOutPath "$INSTDIR"
  IfFileExists ${GIT_INSTALLER} installGit

  ; download and install
  NSISdl::download "https://msysgit.googlecode.com/files/${GIT_INSTALLER}" "${GIT_INSTALLER}"
  Pop $R0
  ${If} $R0 <> 'success'
    ; download not successfull
    MessageBox MB_ICONEXCLAMATION "Git download failed."
    Delete "$INSTDIR\${GIT_INSTALLER}"
    Quit
  ${EndIf}

  ; download successful
  installGit:
  ; run the one click installer
  ClearErrors
  ExecWait "${GIT_INSTALLER} /silent /nocancel /noicons"
  IfErrors onError
    Return
  onError:
    MessageBox MB_ICONEXCLAMATION "Git install failed. Please try again."
    Quit
SectionEnd

Section "install ruby" SEC03
  SetOutPath "$INSTDIR"
  ; download and install
  IfFileExists ${RUBY_INSTALLER} installRuby

  NSISdl::download "http://rubyforge.org/frs/download.php/76952/${RUBY_INSTALLER}" ${RUBY_INSTALLER}
  Pop $R0
  ${If} $R0 <> 'success'
    ; download not successfull
    MessageBox MB_ICONEXCLAMATION "Ruby download failed. Please try again."
    Delete "$INSTDIR\${RUBY_INSTALLER}"
    Quit
  ${EndIf}

  ; download successful
  installRuby:
  ; run the one click installer
  ClearErrors
  ExecWait '${RUBY_INSTALLER} /verysilent /noreboot /nocancel /noicons /dir="$INSTDIR/ruby"'
  IfErrors onError
    Return
  onError:
    MessageBox MB_ICONEXCLAMATION "Ruby install failed. Please try again."
    Quit
SectionEnd

Section "install rhc" SEC04
  SetOutPath "$INSTDIR"

  StrCpy $status ''
  ; install rhc locally
  ${If} $HTTP_PROXY == ''
    ExecWait '"$INSTDIR\ruby\bin\gem.bat" install rhc --no-rdoc --no-ri -V'
  ${Else}
    ExecWait '"$INSTDIR\ruby\bin\gem.bat" install --http-proxy "$HTTP_PROXY" rhc --no-rdoc --no-ri -V'
  ${EndIf}

  IfErrors onError
    Return
  onError:
    MessageBox MB_ICONEXCLAMATION 'Gem install failed. Please install the rhc gem manually: "$INSTDIR\ruby\bin\gem.bat" install rhc'
SectionEnd

Section -AdditionalIcons
  CreateShortCut "$SMPROGRAMS\rhc\Uninstall.lnk" "$INSTDIR\uninst.exe"
SectionEnd

Section -Post
  WriteUninstaller "$INSTDIR\uninst.exe"
  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\${RUBY_INSTALLER}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "$(^Name)"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninst.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\openshift.ico"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
  ${EnvVarUpdate} $0 "PATH" "A" "HKCU" "$INSTDIR"
SectionEnd


Function un.onUninstSuccess
  HideWindow
  MessageBox MB_ICONINFORMATION|MB_OK "You have successfully uninstalled $(^Name)."
FunctionEnd

Function un.onInit
!insertmacro MUI_UNGETLANGUAGE
  MessageBox MB_ICONQUESTION|MB_YESNO|MB_DEFBUTTON2 "Are you sure you want to completely remove $(^Name) and all of its components?" IDYES +2
  Abort
FunctionEnd

Section Uninstall
  Delete "$INSTDIR\${PRODUCT_NAME}.url"
  Delete "$INSTDIR\uninst.exe"
  Delete "$INSTDIR\rhc.bat"
  Delete "$INSTDIR\rhc"
  RMDir /r "$INSTDIR\ruby"

  Delete "$SMPROGRAMS\rhc\Uninstall.lnk"
  Delete "$SMPROGRAMS\rhc\Website.lnk"
  Delete "$DESKTOP\rhc.lnk"
  Delete "$SMPROGRAMS\rhc\rhc.lnk"
  Delete "$INSTDIR\openshift.ico"
  Delete "$INSTDIR\${GIT_INSTALLER}"
  Delete "$INSTDIR\${RUBY_INSTALLER}"

  RMDir "$SMPROGRAMS\rhc"
  RMDir "$INSTDIR"

  DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"
  SetAutoClose true
  ${un.EnvVarUpdate} $0 "PATH" "R" "HKCU" "$INSTDIR"
SectionEnd
