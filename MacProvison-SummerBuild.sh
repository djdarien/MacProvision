#!/bin/bash
echo  Macbook New Hire Provisoning - Mac OS High Sierra Spring Build

#Downloads Google Chat and File stream
sleep 5s
cd Desktop/
sudo mkdir GoogleApps
sleep 2s
sudo curl -O https://dl.google.com/chat/latest/InstallHangoutsChat.dmg
sleep 45s
sudo curl -O https://dl.google.com/drive-file-stream/GoogleDriveFileStream.dmg
sleep 10s
#INstalls Google File Stream
hdiutil mount GoogleDriveFileStream.dmg; sudo installer -pkg /Volumes/Install\ Google\ Drive\ File\ Stream/GoogleDriveFileStream.pkg -target "/Volumes/Macintosh HD"; hdiutil unmount /Volumes/Install\ Google\ Drive\ File\ Stream/
sleep 5s
#Enable Firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
#allow Signed Apps on Firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsigned on


#Disable Guest account
sudo defaults write /Library/Preferences/com.apple.AppleFileServer guestAccess -bool NO
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server AllowGuestAccess -bool NO

#Disable animations when opening and closing windows.
sudo defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
# Disable animations when opening a Quick Look windowß
sudo defaults write -g QLPanelAnimationDuration -float 0
#Disable animation when opening the Info window in Finde
sudo defaults write com.apple.finder DisableAllAnimations -bool true
#Make all animations faster that are used by Mission Control
sudo defaults write com.apple.dock expose-animation-duration -float 0.1

#update & install Google Chrome
dmgfile="googlechrome.dmg"
volname="Google Chrome"
logfile="/Library/Logs/GoogleChromeInstallScript.log"

url='https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg'

# Are we running on Intel?
if [ '`/usr/bin/uname -p`'="i386" -o '`/usr/bin/uname -p`'="x86_64" ]; then
		/bin/echo "--" >> ${logfile}
		/bin/echo "`date`: Downloading latest version." >> ${logfile}
		/usr/bin/curl -s -o /tmp/${dmgfile} ${url}
		/bin/echo "`date`: Mounting installer disk image." >> ${logfile}
		/usr/bin/hdiutil attach /tmp/${dmgfile} -nobrowse -quiet
		/bin/echo "`date`: Installing..." >> ${logfile}
		ditto -rsrc "/Volumes/${volname}/Google Chrome.app" "/Applications/Google Chrome.app"
		/bin/sleep 10
		/bin/echo "`date`: Unmounting installer disk image." >> ${logfile}
		/usr/bin/hdiutil detach $(/bin/df | /usr/bin/grep "${volname}" | awk '{print $1}') -quiet
		/bin/sleep 10
		/bin/echo "`date`: Deleting disk image." >> ${logfile}
		/bin/rm /tmp/"${dmgfile}"
else
	/bin/echo "`date`: ERROR: This script is for Intel Macs only." >> ${logfile}
fi

sleep 2s
echo  Provisioning has completed!
say Provisioning has completed!
echo GOODBYE!
say GOODBYE!
exit

