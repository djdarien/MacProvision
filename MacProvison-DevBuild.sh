#!/bin/bash
echo  Macbook New Hire Provisoning - Dev Build 2018


#Enable Firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
#allow Signed Apps on Firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsigned on


#Disable Guest account
sudo defaults write /Library/Preferences/com.apple.AppleFileServer guestAccess -bool NO
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server AllowGuestAccess -bool NO

#Remove All Default Icons from the Dock
sudo defaults delete com.apple.dock persistent-apps
sudo defaults delete com.apple.dock persistent-others
sudo killall Dock


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
