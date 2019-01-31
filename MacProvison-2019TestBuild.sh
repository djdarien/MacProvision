#!/bin/bash
# 2019 New Year 3.0 Build - Darien Entwistle
echo  Macbook New Hire Provisoning -  2019 New Year 3.0 Build
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
#Enable Firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
#allow Signed Apps on Firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsigned on

sleep 4s
echo Now installing MSOFFICE2016
DOWNLOAD_URLS=( \
  # Office 365 BusinessPro Suite Installer
  "https://go.microsoft.com/fwlink/?linkid=2009112" \

  )

MAU_PATH="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app"
SECOND_MAU_PATH="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/Microsoft AU Daemon.app"
INSTALLER_TARGET="LocalSystem"

syslog -s -l error "MSOFFICE2016 - Starting Download/Install sequence."

for downloadUrl in "${DOWNLOAD_URLS[@]}"; do
  finalDownloadUrl=$(curl "$downloadUrl" -s -L -I -o /dev/null -w '%{url_effective}')
  pkgName=$(printf "%s" "${finalDownloadUrl[@]}" | sed 's@.*/@@')
  pkgPath="/tmp/$pkgName"
  syslog -s -l error "MSOFFICE2016 - Downloading %s\n" "$pkgName"

  # modified to attempt restartable downloads and prevent curl output to stderr
  until curl --retry 1 --retry-max-time 180 --max-time 180 --fail --silent -L -C - "$finalDownloadUrl" -o "$pkgPath"; do
    # Retries if the download takes more than 3 minutes and/or times out/fails
  	syslog -s -l error "MSOFFICE2016 - Preparing to re-try failed download: %s\n" "$pkgName"
    sleep 10
  done
  syslog -s -l error "MSOFFICE2016 - Installing %s\n" "$pkgName"
  # run installer with stderr redirected to dev null
  installerExitCode=1
  while [ "$installerExitCode" -ne 0 ]; do
    sudo /usr/sbin/installer -pkg "$pkgPath" -target "$INSTALLER_TARGET" > /dev/null 2>&1
    installerExitCode=$?
    if [ "$installerExitCode" -ne 0 ]; then
      syslog -s -l error "MSOFFICE2016 - Failed to install: %s\n" "$pkgPath"
      syslog -s -l error "MSOFFICE2016 - Installer exit code: %s\n" "$installerExitCode"
    fi
  done
  rm "$pkgPath"

done


# -- Modified from Script originally published at https://gist.github.com/erikng/7cede5be1c0ae2f85435
syslog -s -l error "MSOFFICE2016 - Registering Microsoft Auto Update (MAU)"
if [ -e "$MAU_PATH" ]; then
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -R -f -trusted "$MAU_PATH"
  if [ -e "$SECOND_MAU_PATH" ]; then
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -R -f -trusted "$SECOND_MAU_PATH"
  fi
fi

syslog -s -l error "MSOFFICE2016 - SCRIPT COMPLETE"

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
