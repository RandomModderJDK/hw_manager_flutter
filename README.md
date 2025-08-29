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

## Getting Started / Installation
<details open>
<summary><h3 style="display:inline-block">An online(ish) app is enough for me </h3></summary>

> <b>BE WARNED: If you use the app with a bot token on the web, you are sending your token to a CORS proxy that redirects it to discord. Someone (in this case Cloudflare) could sniff your token. Unfortunately a CORS proxy is needed on the web, because discord does not send adequate CORS.</b>

If you took notice of this warning, you can just open the GitHub Pages app: [https://randommodderjdk.github.io/hw_manager_flutter](https://randommodderjdk.github.io/hw_manager_flutter)

<details> <summary><h4 style="display:inline-block">iOS / iPadOS web app</h4></summary>
You have two options to add the website (always needs internet connection):

> ##### 1. Use Safari's "Add to Homescreen": 
> Go to the website above and click on the share icon. There click on "Add to home screen", type in a name and submit.

> ##### 2. Use a profile (WebClip)
> Go to [https://ivi.cx/](https://ivi.cx/) and enter the details you want. You can use for example the asset provided in this repository as an icon. 

</details>

<details> <summary><h4 style="display:inline-block">Android homescreen app</h4></summary>
Use your browser to create a web app on android. Search for "Add Shortcut" or anything similar.

This is like the native app (except the security), especially when the browser caches it. Tested with Chromium-based browsers and firefox. 

</details>
</details>
<details open><summary><h3 style="display:inline-block">I prefer the native app</h3></summary>

**If you are on android** and go ahead to releases and download your arch.

**If you are on ios**, download the ipa (native app) in the releases, if you know how to install it. This is not really signed. I would recommend Alt-/Troll-/Sidestore. When Apple allows apps to finally be installed like on android, then do it that way.

**If you'd like any other platform**:
Clone this repo, (add your platform,), build HWM (and maybe contribute a GitHub action) yourself.
</details>
