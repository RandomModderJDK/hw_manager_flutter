[![style: lint](https://img.shields.io/badge/style-lint-4BC0F5.svg)](https://pub.dev/packages/lint)

# Homework Manager (HWM/hw_manager_flutter)

Manage your homework, with untis and discord support.

You can take/import pictures and assign them to a homework. Sharing/Synchronization of homework is also possible.

### Untis

Untis is a timetable "manager" for schools

HWM uses the Untis API to achieve two things:
First, it gets the point in time, when the next subjects lesson is going to be.
And secondly, for QOL, it can import the subjects you are going to have in the next time.

### Discord

You can use a combination of a bot and webhooks to achieve regulated homework ex-/import. The discord bot must have read message permissions for the channels, that could be used for homeworks. Furthermore, he should be member of only one guild.

You can "export"(send) your homework easily, by:
1. Creating and assigning a subject
2. Specifying a bot (token)
3. Creating a discord relation, this must be assigned to the target channel to support import
4. Specifying the webhook url for the given channel
5. Clicking send on the homework


If the discord relations are configured, you can just click on the fetch icon in the upper right corner of the home screen. This may overwrite local changes, so be careful.

## Get Started / Installation

### An online(ish) app is enough for me

The GH page is called: [https://randommodderjdk.github.io/hw_manager_flutter](https://randommodderjdk.github.io/hw_manager_flutter)

#### iOS / iPadOS home screen

You have two options to add the website (always needs internet connection):

##### Use Safari's add to home screen
Go to the website above and click on the share icon. There click on "Add to home screen", type in a name and submit.

##### Use a profile (WebClip)
Go to [https://ivi.cx/](https://ivi.cx/) and enter the details you want. You can use for example the asset provided in this repository as an icon. 

<br>

#### Android home screen app

You can use chrome to create an web app on android. This is like the native app, especially when the browser caches it.


<br>


### I prefer the native app

**If you are on android** and do not mind the debug certificate go ahead to releases and download your arch.

**If you are on ios**, download the ipa (native app) in the releases, if you know how to install it. This is again not really signed. I would recommend Alt-/Troll-/Sidestore. When Apple allows apps to finally be installed like on android, then do it that way.

**If you'd like any other platform**:
Clone this repo, (add your platform,) and built HWM yourself.