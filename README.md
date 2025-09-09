[![style: lint](https://img.shields.io/badge/style-lint-4BC0F5.svg)](https://pub.dev/packages/lint)
<a href="https://apps.obtainium.imranr.dev/redirect?r=obtainium://app/%7B%22id%22%3A%22de.randomfactory.randommodder.hw_manager%22%2C%22url%22%3A%22https%3A%2F%2Fgithub.com%2Frandommodderjdk%2FHWM%22%2C%22author%22%3A%22randommodderjdk%22%2C%22name%22%3A%22HWM%22%2C%22preferredApkIndex%22%3A0%2C%22additionalSettings%22%3A%22%7B%5C%22includePrereleases%5C%22%3Afalse%2C%5C%22fallbackToOlderReleases%5C%22%3Atrue%2C%5C%22filterReleaseTitlesByRegEx%5C%22%3A%5C%22%5C%22%2C%5C%22filterReleaseNotesByRegEx%5C%22%3A%5C%22%5C%22%2C%5C%22verifyLatestTag%5C%22%3Afalse%2C%5C%22sortMethodChoice%5C%22%3A%5C%22date%5C%22%2C%5C%22useLatestAssetDateAsReleaseDate%5C%22%3Afalse%2C%5C%22releaseTitleAsVersion%5C%22%3Afalse%2C%5C%22trackOnly%5C%22%3Afalse%2C%5C%22versionExtractionRegEx%5C%22%3A%5C%22%5C%22%2C%5C%22matchGroupToUse%5C%22%3A%5C%22%5C%22%2C%5C%22versionDetection%5C%22%3Atrue%2C%5C%22releaseDateAsVersion%5C%22%3Afalse%2C%5C%22useVersionCodeAsOSVersion%5C%22%3Afalse%2C%5C%22apkFilterRegEx%5C%22%3A%5C%22%5C%22%2C%5C%22invertAPKFilter%5C%22%3Afalse%2C%5C%22autoApkFilterByArch%5C%22%3Atrue%2C%5C%22appName%5C%22%3A%5C%22HWM%5C%22%2C%5C%22appAuthor%5C%22%3A%5C%22RandomModderJDK%5C%22%2C%5C%22shizukuPretendToBeGooglePlay%5C%22%3Afalse%2C%5C%22allowInsecure%5C%22%3Afalse%2C%5C%22exemptFromBackgroundUpdates%5C%22%3Afalse%2C%5C%22skipUpdateNotifications%5C%22%3Afalse%2C%5C%22about%5C%22%3A%5C%22%5C%22%2C%5C%22refreshBeforeDownload%5C%22%3Afalse%7D%22%2C%22overrideSource%22%3Anull%7D"><img src="https://raw.githubusercontent.com/ImranR98/Obtainium/b1c8ac6f2ab08497189721a788a5763e28ff64cd/assets/graphics/badge_obtainium.png" alt="Get it on Obtainium" height="100"></a>
<a href="https://github.com/RandomModderJDK/HWM/releases">
<img src="https://user-images.githubusercontent.com/69304392/148696068-0cfea65d-b18f-4685-82b5-329a330b1c0d.png"
alt="Download from GitHub releases" height="100" /></a>

# Homework Manager (HWM/hw_manager_flutter)

Manage your homework, with untis and discord support.

You can take/import pictures and assign them to a homework. Sharing/Synchronization of homework is
also possible.

### Untis

Untis is a timetable "manager" for schools

HWM uses the Untis API to achieve two things:
First, it gets the point in time, when the next subjects lesson is going to be.
And secondly, for QOL, it can import the subjects you are going to have in the next time.

### Discord

You can use a combination of a bot and webhooks to achieve regulated homework ex-/import. The
discord bot must have read message permissions for the channels, that could be used for homeworks.
Furthermore, he should be member of only one guild.

You can "export"(send) your homework easily, by:

1. Creating and assigning a subject
2. Specifying a bot (token)
3. Creating a discord relation, this must be assigned to the target channel to support import
4. Specifying the webhook url for the given channel
5. Clicking send on the homework

If the discord relations are configured, you can just click on the fetch icon in the upper right
corner of the home screen. This may overwrite local changes, so be careful.

## TODO

- [ ] Qrcode generator to share webhooks and bot token

## Getting Started / Installation

<details open>
<summary><h3 style="display:inline-block">An online(ish) app is enough for me </h3></summary>

> <b>BE WARNED: If you use the app with a bot token on the web, you are sending your token to a CORS
> proxy that redirects it to discord. Someone (in this case Cloudflare) could sniff your token.
> Unfortunately a CORS proxy is needed on the web, because discord does not send adequate CORS.</b>

If you took notice of this warning, you can just open the GitHub Pages
app: [https://randommodderjdk.github.io/hw_manager_flutter](https://randommodderjdk.github.io/hw_manager_flutter)

<details> <summary><h4 style="display:inline-block">iOS / iPadOS web app</h4></summary>
You have two options to add the website (always needs internet connection):

> ##### 1. Use Safari's "Add to Homescreen":
> Go to the website above and click on the share icon. There click on "Add to home screen", type in
> a name and submit.

> ##### 2. Use a profile (WebClip)
> Go to [https://ivi.cx/](https://ivi.cx/) and enter the details you want. You can use for example
> the asset provided in this repository as an icon.

</details>

<details> <summary><h4 style="display:inline-block">Android homescreen app</h4></summary>
Use your browser to create a web app on android. Search for "Add Shortcut" or anything similar.

This is like the native app (except the security), especially when the browser caches it. Tested
with Chromium-based browsers and firefox.

</details>
</details>
<details open><summary><h3 style="display:inline-block">I prefer the native app [recommended]</h3></summary>

**If you are on android**, go ahead to releases and download your arch. Alternatively use Obtainium for automatic updates (see above).

**If you are on ios**, download the ipa (native app) in the releases, if you know how to install it.
This is not really signed. I would recommend Alt-/Sidestore. When Apple allows apps to
finally be installed like on android, then do it that way.

**If you'd like any other platform**:
Clone this repo, (add your platform,), build HWM (and maybe contribute a GitHub action) yourself.
</details>
