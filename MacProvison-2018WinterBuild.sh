#!/bin/bash
# 2018 Winter Build - Darien Entwistle
echo  Macbook New Hire Provisoning - Mac OS High Sierra Xmas Build
say Welcome!
say Macbook Provisoning has started... standby..
#Downloads Google File stream
sleep 5s
sudo cd Desktop/
sudo curl -O https://dl.google.com/drive-file-stream/GoogleDriveFileStream.dmg
sleep 10s
#INstalls Google File Stream
hdiutil mount GoogleDriveFileStream.dmg; sudo installer -pkg /Volumes/Install\ Google\ Drive\ File\ Stream/GoogleDriveFileStream.pkg -target "/Volumes/Macintosh HD"; hdiutil unmount /Volumes/Install\ Google\ Drive\ File\ Stream/
sleep 5s

#install user admin
sudo installer -pkg create_uadmin-1.2.pkg -target "/Volumes/Macintosh HD"
sleep 1s
#Enable Firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
#allow Signed Apps on Firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsigned on


#Disable Guest account
sudo defaults write /Library/Preferences/com.apple.AppleFileServer guestAccess -bool NO
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server AllowGuestAccess -bool NO
echo Disabled Guest account!
#Disable animations when opening and closing windows.
sudo defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
# Disable animations when opening a Quick Look windowß
sudo defaults write -g QLPanelAnimationDuration -float 0
#Disable animation when opening the Info window in Finder
sudo defaults write com.apple.finder DisableAllAnimations -bool true


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


#Downloads & Installs Slack  - GITHUB source https://github.com/bwiessner/install_latest_slack_osx_app/blob/master/install_latest_slack_osx_app.sh
#gets current logged in user
consoleuser=$(ls -l /dev/console | cut -d " " -f4)

APP_NAME="Slack.app"
APP_PATH="/Applications/$APP_NAME"
APP_VERSION_KEY="CFBundleShortVersionString"


DOWNLOAD_URL="https://slack.com/ssb/download-osx"
finalDownloadUrl=$(curl "$DOWNLOAD_URL" -s -L -I -o /dev/null -w '%{url_effective}')
dmgName=$(printf "%s" "${finalDownloadUrl[@]}" | sed 's@.*/@@')
slackDmgPath="/tmp/$dmgName"

################################

#find new version of Slack
currentSlackVersion=$(/usr/bin/curl -s 'https://downloads.slack-edge.com/mac_releases/releases.json' | grep -o "[0-9]\.[0-9]\.[0-9]" | tail -1)

if [ -d "$APP_PATH" ]; then
    localSlackVersion=$(defaults read "$APP_PATH/Contents/Info.plist" "$APP_VERSION_KEY")
    if [ "$currentSlackVersion" = "$localSlackVersion" ]; then
        printf "Slack is already up-to-date. Version: %s" "$localSlackVersion"
        exit 0
    fi
fi

#find if slack is running
if pgrep '[S]lack'; then
    printf "Error: Slack is currently running!\n"
    exit 409
else

# Remove the existing Application
rm -rf /Applications/Slack.app

#downloads latest version of Slack
curl -L -o "$slackDmgPath" "$finalDownloadUrl"

#mount the .dmg
hdiutil attach -nobrowse $slackDmgPath

#Copy the update app into applications folder
sudo cp -R /Volumes/Slack*/Slack.app /Applications

#unmount and eject dmg
mountName=$(diskutil list | grep Slack | awk '{ print $3 }')
umount -f /Volumes/Slack*/
diskutil eject $mountName

#clean up /tmp download
rm -rf "$slackDmgPath"

# Slack permissions are really dumb
chown -R $consoleuser:admin "/Applications/Slack.app"

localSlackVersion=$(defaults read "$APP_PATH/Contents/Info.plist" "$APP_VERSION_KEY")
    if [ "$currentSlackVersion" = "$localSlackVersion" ]; then
        printf "Slack is now updated/installed. Version: %s" "$localSlackVersion"
    fi
fi

#slack will relaunch if it was previously running
if [ "$slackOn" == "" ] ; then
	exit 0
else
	su - "${consoleuser}" -c 'open -a /Applications/Slack.app'
fi
sleep 2s


echo  Provisioning has completed!
say Provisioning has completed!
echo GOODBYE!
say GOODBYE!
exit
